import Foundation

/// An on-device adaptive dialogue engine providing contextual character responses,
/// target vocabulary detection, and three distinct conversational branching suggestions.
public final class OnDeviceContextDialogueEngine: Sendable {
    public enum UserIntent: Sendable {
        case greeting
        case ordering
        case question
        case closing
        case statement
    }

    public init() {}

    public func generateTurn(
        scenario: RoleplayScenario,
        userUtterance: String,
        conversationHistory: [RoleplayMessage]
    ) async throws -> RoleplayTurnOutput {
        let trimmedUtterance = userUtterance.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetWordsUsed = detectTargetWords(in: trimmedUtterance, candidateWords: scenario.targetWordIds)
        let intent = classifyIntent(of: trimmedUtterance)
        let priorUserTurns: Int
        if conversationHistory.last?.sender == .user &&
            conversationHistory.last?.text.trimmingCharacters(in: .whitespacesAndNewlines) == trimmedUtterance {
            priorUserTurns = max(0, conversationHistory.filter { $0.sender == .user }.count - 1)
        } else {
            priorUserTurns = conversationHistory.filter { $0.sender == .user }.count
        }
        let userTurnCount = priorUserTurns + 1

        let isConcluded = determineConclusion(
            intent: intent,
            userTurnCount: userTurnCount,
            targetWordsUsed: targetWordsUsed,
            allTargetWords: scenario.targetWordIds
        )

        let characterReply = generateCharacterReply(
            scenario: scenario,
            userUtterance: trimmedUtterance,
            intent: intent,
            userTurnCount: userTurnCount,
            isConcluded: isConcluded
        )

        let suggestedResponses = generateThreeBranchSuggestions(
            scenario: scenario,
            targetWordsUsed: targetWordsUsed,
            userTurnCount: userTurnCount,
            isConcluded: isConcluded
        )

        let refinementSuggestion = generateRefinement(for: trimmedUtterance, scenario: scenario)
        let pedagogicalNote = generatePedagogicalNote(
            scenario: scenario,
            targetWordsUsed: targetWordsUsed,
            userTurnCount: userTurnCount
        )

        return RoleplayTurnOutput(
            characterReply: characterReply,
            targetWordsUsed: targetWordsUsed,
            refinementSuggestion: refinementSuggestion,
            pedagogicalNote: pedagogicalNote,
            suggestedResponses: suggestedResponses,
            isConcluded: isConcluded
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

    // MARK: - Intent Classification

    public func classifyIntent(of utterance: String) -> UserIntent {
        let lower = utterance.lowercased()

        if isClosingPhrase(lower) {
            return .closing
        }
        if isGreetingPhrase(lower) {
            return .greeting
        }
        if isOrderingPhrase(lower) {
            return .ordering
        }
        if isQuestionPhrase(lower) {
            return .question
        }
        return .statement
    }

    private func isClosingPhrase(_ text: String) -> Bool {
        let closingTokens = [
            "goodbye", "bye", "see you", "that's all", "that is all",
            "thank you, bye", "have a good day", "have a great day", "check please"
        ]
        return closingTokens.contains { text.contains($0) }
    }

    private func isGreetingPhrase(_ text: String) -> Bool {
        let greetings = ["hello", "hi", "hey", "good morning", "good afternoon", "good evening"]
        return greetings.contains { text.hasPrefix($0) || text == $0 }
    }

    private func isOrderingPhrase(_ text: String) -> Bool {
        let orderingPhrases = [
            "i would like", "i'd like", "could i have", "can i get",
            "may i have", "please give me", "i will take", "i'll have",
            "order", "i want"
        ]
        return orderingPhrases.contains { text.contains($0) }
    }

    private func isQuestionPhrase(_ text: String) -> Bool {
        if text.hasSuffix("?") { return true }
        let questionStarters = [
            "what", "where", "how", "when", "why", "who", "which",
            "do you", "could you", "can you", "is there", "are there", "would you"
        ]
        return questionStarters.contains { text.hasPrefix($0) }
    }

    // MARK: - Turn Conclusion

    private func determineConclusion(
        intent: UserIntent,
        userTurnCount: Int,
        targetWordsUsed: [String],
        allTargetWords: [String]
    ) -> Bool {
        if intent == .closing && userTurnCount >= 2 {
            return true
        }
        if userTurnCount >= 3 && targetWordsUsed.count >= 2 {
            return true
        }
        if userTurnCount >= 4 {
            return true
        }
        return false
    }

    // MARK: - Character Reply Generation

    private func generateCharacterReply(
        scenario: RoleplayScenario,
        userUtterance: String,
        intent: UserIntent,
        userTurnCount: Int,
        isConcluded: Bool
    ) -> String {
        switch scenario.topic {
        case .dining:
            return generateDiningReply(
                intent: intent,
                turn: userTurnCount,
                isConcluded: isConcluded,
                utterance: userUtterance
            )
        case .travel:
            return generateTravelReply(
                intent: intent,
                turn: userTurnCount,
                isConcluded: isConcluded
            )
        case .interview, .workplace:
            return generateInterviewReply(
                intent: intent,
                turn: userTurnCount,
                isConcluded: isConcluded
            )
        case .dailyLife:
            return generateDailyLifeReply(
                intent: intent,
                turn: userTurnCount,
                isConcluded: isConcluded
            )
        }
    }

    private func generateDiningReply(intent: UserIntent, turn: Int, isConcluded: Bool, utterance: String) -> String {
        if isConcluded {
            return "All set! Here is your receipt and order. Thank you for visiting Craft Cafe, have a wonderful day!"
        }
        if turn <= 1 {
            let lower = utterance.lowercased()
            if lower.contains("pastry") || lower.contains("beverage") {
                return "Great choice! Would you like your beverage hot or iced? And should I warm up the pastry for you?"
            }
            if intent == .greeting {
                return "Hello! Welcome to Craft Cafe. What delicious beverage or pastry can I prepare for you today?"
            }
            return "Great choice! Would you like your beverage hot or iced? We also have fresh complimentary pastries today."
        }
        if turn == 2 {
            return "Coming right up! That will be $6.50. You can tap your card right on the reader."
        }
        return "Here is your order and receipt. Enjoy your treat, and have a wonderful day!"
    }

    private func generateTravelReply(intent: UserIntent, turn: Int, isConcluded: Bool) -> String {
        if isConcluded {
            return "You're all set! Don't hesitate to dial 0 if you need anything at all. Have a wonderful stay with us!"
        }
        if turn <= 1 {
            if intent == .greeting {
                return "Good afternoon and welcome to Grand Vista Hotel! Checking in with a reservation today?"
            }
            return "Welcome! I found your reservation right here. May I please see your passport or ID card?"
        }
        if turn == 2 {
            return "Thank you. Here is your keycard for room 402. Our complimentary breakfast and amenities like the pool are on the 5th floor."
        }
        return "Everything is arranged for your stay. Please let us know if we can accommodate anything else!"
    }

    private func generateInterviewReply(intent: UserIntent, turn: Int, isConcluded: Bool) -> String {
        if isConcluded {
            return "Thank you for those insightful questions. We are very excited about your background and will follow up soon. Have a great day!"
        }
        if turn <= 1 {
            return "Thank you for sharing that. Could you tell me about a time you had to collaborate under a tight deadline?"
        }
        if turn == 2 {
            return "That demonstrates excellent initiative and innovative problem solving. Do you have any questions for us about the role?"
        }
        return "Thank you for your response. We appreciate you taking the time to share your perspective with us."
    }

    private func generateDailyLifeReply(intent: UserIntent, turn: Int, isConcluded: Bool) -> String {
        if isConcluded {
            return "That covers everything wonderfully! Thank you for the great conversation, have a wonderful day!"
        }
        if turn <= 1 {
            return "That sounds very interesting! Could you tell me a little bit more about what you have in mind?"
        }
        return "I understand completely. What would you like to explore next?"
    }
}

// MARK: - Three Branching Suggestions & Feedback

extension OnDeviceContextDialogueEngine {
    public func generateThreeBranchSuggestions(
        scenario: RoleplayScenario,
        targetWordsUsed: [String],
        userTurnCount: Int,
        isConcluded: Bool
    ) -> [String] {
        let branch1 = generateTargetWordBranch(
            scenario: scenario,
            targetWordsUsed: targetWordsUsed,
            isConcluded: isConcluded
        )
        let branch2 = generateQuestionBranch(
            scenario: scenario,
            userTurnCount: userTurnCount,
            isConcluded: isConcluded
        )
        let branch3 = generateReactionBranch(
            scenario: scenario,
            userTurnCount: userTurnCount,
            isConcluded: isConcluded
        )
        return [branch1, branch2, branch3]
    }

    private func generateTargetWordBranch(
        scenario: RoleplayScenario,
        targetWordsUsed: [String],
        isConcluded: Bool
    ) -> String {
        if isConcluded {
            return "Thank you for helping me, have a wonderful day!"
        }

        let unusedWords = scenario.targetWordIds.filter { word in
            !targetWordsUsed.contains(word.lowercased())
        }
        let chosenWord = unusedWords.first ?? scenario.targetWordIds.first ?? "target"

        switch chosenWord.lowercased() {
        case "pastry":
            return "Could I also get a fresh pastry with that, please?"
        case "beverage":
            return "I'd like to order a warm beverage, please."
        case "complimentary":
            return "Do you offer any complimentary water or snacks?"
        case "reservation":
            return "I have a reservation under my name for two nights."
        case "amenities":
            return "Could you tell me more about the hotel amenities?"
        case "accommodate":
            return "Could you accommodate an early check-in if possible?"
        case "collaborate":
            return "I took initiative to collaborate across teams on this project."
        case "innovative":
            return "We developed an innovative solution to solve the challenge."
        case "initiative":
            return "I took the initiative to streamline our team's workflow."
        default:
            return "Could I please ask about the \(chosenWord)?"
        }
    }

    private func generateQuestionBranch(
        scenario: RoleplayScenario,
        userTurnCount: Int,
        isConcluded: Bool
    ) -> String {
        if isConcluded {
            return "Could you give me a receipt before I go?"
        }

        switch scenario.topic {
        case .dining:
            return userTurnCount <= 1
                ? "What pastry would you recommend to pair with my drink?"
                : "Could I also get a receipt for this order?"
        case .travel:
            return userTurnCount <= 1
                ? "What time is the complimentary breakfast served in the morning?"
                : "Could the front desk accommodate a late checkout tomorrow?"
        case .interview, .workplace:
            return userTurnCount <= 1
                ? "How does the team foster initiative and support innovative ideas?"
                : "What does success look like for this position in the first 90 days?"
        case .dailyLife:
            return "Could you tell me more about that?"
        }
    }

    private func generateReactionBranch(
        scenario: RoleplayScenario,
        userTurnCount: Int,
        isConcluded: Bool
    ) -> String {
        if isConcluded {
            return "Thanks so much, goodbye!"
        }

        switch scenario.topic {
        case .dining:
            return userTurnCount <= 1
                ? "That sounds wonderful, thank you so much!"
                : "Here is my card to tap. Have a great day!"
        case .travel:
            return userTurnCount <= 1
                ? "Certainly, here is my ID. Thank you for your help!"
                : "That sounds perfect, thank you and have a wonderful day!"
        case .interview, .workplace:
            return userTurnCount <= 1
                ? "I really appreciate this opportunity to discuss my experience."
                : "Thank you so much for your time, I look forward to hearing from you!"
        case .dailyLife:
            return "Thank you, that sounds great!"
        }
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
