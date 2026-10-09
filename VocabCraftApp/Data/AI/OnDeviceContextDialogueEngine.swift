import Foundation

/// An on-device adaptive dialogue engine providing contextual character responses,
/// target vocabulary detection, and three distinct conversational branching suggestions.
public final class OnDeviceContextDialogueEngine: Sendable {
    public init() {}

    public func generateTurn(
        scenario: RoleplayScenario,
        userUtterance: String,
        conversationHistory: [RoleplayMessage]
    ) async throws -> RoleplayTurnOutput {
        let trimmedUtterance = userUtterance.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetWordsUsed = detectTargetWords(in: trimmedUtterance, candidateWords: scenario.targetWordIds)

        // Compute missing target words: candidate target words minus words detected in prior history and current utterance.
        var historicalDetected = Set<String>(targetWordsUsed.map { $0.lowercased() })
        for message in conversationHistory where message.sender == .user {
            let words = detectTargetWords(in: message.text, candidateWords: scenario.targetWordIds)
            for word in words {
                historicalDetected.insert(word.lowercased())
            }
        }
        let missingWords = scenario.targetWordIds.filter { word in
            !historicalDetected.contains(word.lowercased())
        }

        let priorUserTurns: Int
        if conversationHistory.last?.sender == .user &&
            conversationHistory.last?.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedUtterance {
            priorUserTurns = max(0, conversationHistory.filter { $0.sender == .user }.count - 1)
        } else {
            priorUserTurns = conversationHistory.filter { $0.sender == .user }.count
        }
        let userTurnCount = priorUserTurns + 1

        let currentState = ScenarioStateReducer.inferCurrentState(
            from: conversationHistory,
            topic: scenario.topic
        )

        let intent = DialogueIntentClassifier().classify(
            utterance: trimmedUtterance,
            scenario: scenario
        )

        let turnResult = ScenarioStateReducer.reduce(
            currentState: currentState,
            intent: intent,
            userUtterance: trimmedUtterance,
            userTurnCount: userTurnCount,
            missingWords: missingWords,
            scenario: scenario
        )

        let refinementSuggestion = generateRefinement(for: trimmedUtterance, scenario: scenario)
        let pedagogicalNote = generatePedagogicalNote(
            scenario: scenario,
            targetWordsUsed: targetWordsUsed,
            userTurnCount: userTurnCount
        )

        return RoleplayTurnOutput(
            characterReply: turnResult.characterReply,
            targetWordsUsed: targetWordsUsed,
            refinementSuggestion: refinementSuggestion,
            pedagogicalNote: pedagogicalNote,
            suggestedResponses: turnResult.suggestedResponses,
            isConcluded: turnResult.isConcluded
        )
    }

    public func generateTurn(
        messages: [LLMChatMessage],
        systemPrompt: String
    ) async throws -> RoleplayTurnOutput {
        let lastUserMessage = messages.last(where: { $0.role == .user })?.content ?? ""
        let expectedWords = parseTargetWords(systemPrompt: systemPrompt, messages: messages)
        let scenario = resolveScenario(
            systemPrompt: systemPrompt,
            messages: messages,
            expectedWords: expectedWords
        )

        // Extract prior messages, excluding the current user utterance being processed
        var priorMessages = messages
        if let lastIdx = priorMessages.lastIndex(where: { $0.role == .user }) {
            priorMessages.remove(at: lastIdx)
        }

        let history = priorMessages.compactMap { msg -> RoleplayMessage? in
            switch msg.role {
            case .user:
                return RoleplayMessage(sender: .user, text: msg.content)
            case .model:
                return RoleplayMessage(sender: .character(name: scenario.characterName), text: msg.content)
            case .system:
                return nil
            }
        }

        return try await generateTurn(
            scenario: scenario,
            userUtterance: lastUserMessage,
            conversationHistory: history
        )
    }
}

// MARK: - Prompt & Scenario Parsing Helpers

extension OnDeviceContextDialogueEngine {
    public func parseTargetWords(systemPrompt: String, messages: [LLMChatMessage]) -> [String] {
        var parsedWords: [String] = []
        let promptSources = [systemPrompt] + messages.filter { $0.role == .system }.map(\.content)

        let prefixes = [
            "expected target words:",
            "target vocabulary for the user:",
            "target words:"
        ]

        for text in promptSources {
            let lower = text.lowercased()
            for prefix in prefixes {
                if let range = lower.range(of: prefix) {
                    let substring = text[range.upperBound...]
                    let line = substring.split(separator: "\n").first ?? substring[...]
                    let words = line.split(separator: ",").map { token in
                        token.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
                    }.filter { !$0.isEmpty }
                    parsedWords.append(contentsOf: words)
                }
            }
        }

        return parsedWords
    }

    public func resolveScenario(
        systemPrompt: String,
        messages: [LLMChatMessage],
        expectedWords: [String]
    ) -> RoleplayScenario {
        let allPromptText = ([systemPrompt] + messages.map(\.content)).joined(separator: " ").lowercased()
        let standardScenarios = RoleplayScenarioCatalog.standardScenarios

        // 1. Match by Scenario ID or Title or Character Name
        for standard in standardScenarios {
            if allPromptText.contains(standard.id.lowercased())
                || allPromptText.contains(standard.titleKey.lowercased())
                || allPromptText.contains(standard.characterName.lowercased()) {
                return mergeScenarioWords(standard, additionalWords: expectedWords)
            }
        }

        // 2. Match by Topic keywords
        let lowerExpected = expectedWords.map { $0.lowercased() }
        let isCafe = allPromptText.contains("cafe")
            || allPromptText.contains("barista")
            || lowerExpected.contains("beverage")
            || lowerExpected.contains("pastry")
        if isCafe, let cafeScenario = standardScenarios.first(where: { $0.topic == .dining }) {
            return mergeScenarioWords(cafeScenario, additionalWords: expectedWords)
        }

        let isHotel = allPromptText.contains("hotel")
            || allPromptText.contains("concierge")
            || lowerExpected.contains("reservation")
            || lowerExpected.contains("amenities")
        if isHotel, let hotelScenario = standardScenarios.first(where: { $0.topic == .travel }) {
            return mergeScenarioWords(hotelScenario, additionalWords: expectedWords)
        }

        let isInterview = allPromptText.contains("interview")
            || allPromptText.contains("hiring manager")
            || lowerExpected.contains("collaborate")
            || lowerExpected.contains("innovative")
        if isInterview, let interviewScenario = standardScenarios.first(where: { $0.topic == .interview }) {
            return mergeScenarioWords(interviewScenario, additionalWords: expectedWords)
        }

        // 3. Fallback
        let baseScenario = standardScenarios.first ?? RoleplayScenario.cafeMock
        return mergeScenarioWords(baseScenario, additionalWords: expectedWords)
    }

    public func mergeScenarioWords(_ scenario: RoleplayScenario, additionalWords: [String]) -> RoleplayScenario {
        guard !additionalWords.isEmpty else { return scenario }
        let merged = Array(Set(scenario.targetWordIds + additionalWords)).sorted()
        return RoleplayScenario(
            id: scenario.id,
            titleKey: scenario.titleKey,
            descriptionKey: scenario.descriptionKey,
            topic: scenario.topic,
            difficulty: scenario.difficulty,
            characterName: scenario.characterName,
            characterRole: scenario.characterRole,
            userRole: scenario.userRole,
            initialGreeting: scenario.initialGreeting,
            targetWordIds: merged,
            iconSymbol: scenario.iconSymbol,
            starterSuggestions: scenario.starterSuggestions
        )
    }
}

// MARK: - Target Word Detection, Intent & Character Replies

extension OnDeviceContextDialogueEngine {
    public func detectTargetWords(in utterance: String, candidateWords: [String]) -> [String] {
        guard !utterance.isEmpty else { return [] }
        var detected = Set<String>()
        let lowercasedUtterance = utterance.lowercased()

        for word in candidateWords {
            let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !normalizedWord.isEmpty else { continue }

            if ReflexSpeechMatcher.isReflexMatch(
                spokenText: utterance,
                targetLemma: normalizedWord,
                toleranceThreshold: 0.70
            ) {
                detected.insert(normalizedWord)
                continue
            }

            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: normalizedWord))\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(
                    lowercasedUtterance.startIndex..<lowercasedUtterance.endIndex,
                    in: lowercasedUtterance
                )
                if regex.firstMatch(in: lowercasedUtterance, range: range) != nil {
                    detected.insert(normalizedWord)
                    continue
                }
            }

            if normalizedWord.count >= 4 && lowercasedUtterance.contains(normalizedWord) {
                detected.insert(normalizedWord)
            }
        }

        return Array(detected).sorted()
    }

    // MARK: - Intent Classification & Suggestions Delegation

    public func classifyIntent(of utterance: String, scenario: RoleplayScenario = .cafeMock) -> UserIntent {
        DialogueIntentClassifier().classify(utterance: utterance, scenario: scenario)
    }

    public func generateThreeBranchSuggestions(
        scenario: RoleplayScenario,
        targetWordsUsed: [String],
        userTurnCount: Int,
        isConcluded: Bool
    ) -> [String] {
        let missingWords = scenario.targetWordIds.filter { word in
            !targetWordsUsed.contains { $0.caseInsensitiveCompare(word) == .orderedSame }
        }
        let currentState = ScenarioStateReducer.inferCurrentState(from: [], topic: scenario.topic)
        let result = ScenarioStateReducer.reduce(
            currentState: currentState,
            intent: .generalStatement,
            userUtterance: "",
            userTurnCount: userTurnCount,
            missingWords: missingWords,
            scenario: scenario
        )
        return result.suggestedResponses
    }

    // MARK: - Pedagogical Feedback

    private func generateRefinement(for utterance: String, scenario: RoleplayScenario) -> String? {
        let lower = utterance.lowercased()
        if lower.contains("i want a") || lower.contains("give me a") {
            return "More polite: 'Could I please have a...' or 'I would like...'"
        }
        return nil
    }

    private func generatePedagogicalNote(
        scenario: RoleplayScenario,
        targetWordsUsed: [String],
        userTurnCount: Int
    ) -> String? {
        if !targetWordsUsed.isEmpty {
            return "Great use of target vocabulary in natural dialogue!"
        }
        switch scenario.topic {
        case .dining:
            return "In a cafe, specifying 'hot or iced' makes ordering seamless."
        case .travel:
            return "Using 'under the name' is standard when checking in."
        case .interview, .workplace:
            return "Strong action verbs clearly demonstrate your impact."
        case .dailyLife:
            return nil
        }
    }
}
