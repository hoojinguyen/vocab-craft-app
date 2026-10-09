import Foundation

/// Adaptive Apple dialogue provider utilizing on-device Apple Intelligence foundation models
/// when available (iOS 26+), and falling back smoothly to `OnDeviceContextDialogueEngine` on iOS 17/18.
public final class AppleIntelligenceOrLocalDialogueProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "apple_intelligence_or_local"
    private let engine: OnDeviceContextDialogueEngine

    public init(engine: OnDeviceContextDialogueEngine = OnDeviceContextDialogueEngine()) {
        self.engine = engine
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        let lastUserMessage = messages.last(where: { $0.role == .user })?.content ?? ""
        let expectedWords = parseTargetWords(systemPrompt: systemPrompt, messages: messages)
        let scenario = resolveScenario(
            systemPrompt: systemPrompt,
            messages: messages,
            expectedWords: expectedWords
        )

        let history = messages.compactMap { msg -> RoleplayMessage? in
            switch msg.role {
            case .user:
                return RoleplayMessage(sender: .user, text: msg.content)
            case .model:
                return RoleplayMessage(sender: .character(name: scenario.characterName), text: msg.content)
            case .system:
                return nil
            }
        }

        let output = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: lastUserMessage,
            conversationHistory: history
        )

        if let typedResult = output as? T {
            return typedResult
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Unsupported output schema for AppleIntelligenceOrLocalDialogueProvider: expected \(responseSchema)"
            )
        )
    }

    // MARK: - Prompt & Scenario Parsing Helpers

    private func parseTargetWords(systemPrompt: String, messages: [LLMChatMessage]) -> [String] {
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

    private func resolveScenario(
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

    private func mergeScenarioWords(_ scenario: RoleplayScenario, additionalWords: [String]) -> RoleplayScenario {
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
