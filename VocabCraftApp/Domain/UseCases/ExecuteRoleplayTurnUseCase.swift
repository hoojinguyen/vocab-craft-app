import Foundation

public final class ExecuteRoleplayTurnUseCase: Sendable {
    private let llmProvider: LLMProviderProtocol

    public init(llmProvider: LLMProviderProtocol) {
        self.llmProvider = llmProvider
    }

    public func execute(
        scenario: RoleplayScenario,
        userUtterance: String,
        chatHistory: [LLMChatMessage]
    ) async throws -> RoleplayTurnOutput {
        // Fast local detection of target words in user input using word-boundary matching
        let detectedLocalWords = scenario.targetWordIds.filter { word in
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return false
            }
            let range = NSRange(location: 0, length: userUtterance.utf16.count)
            return regex.firstMatch(in: userUtterance, options: [], range: range) != nil
        }

        let topicDescriptor = scenario.topic.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        let systemPrompt = """
        You are \(scenario.characterName), a \(scenario.characterRole) in a roleplay conversation with the user who is a \(scenario.userRole).
        Maintain an authentic, friendly persona suitable for the scene: \(topicDescriptor).
        Target vocabulary for the user: \(scenario.targetWordIds.joined(separator: ", ")).
        Return JSON conforming to RoleplayTurnOutput schema:
        - characterReply: your in-character spoken dialogue
        - targetWordsUsed: list of target words the user used correctly in their message
        - refinementSuggestion: if the user's sentence could be phrased more naturally, provide the improved sentence; otherwise null
        - pedagogicalNote: brief encouragement or usage tip; otherwise null
        """

        var fullHistory = chatHistory
        fullHistory.append(LLMChatMessage(role: .user, content: userUtterance))

        let output: RoleplayTurnOutput = try await llmProvider.sendStructuredMessage(
            messages: fullHistory,
            systemPrompt: systemPrompt,
            responseSchema: RoleplayTurnOutput.self
        )
        // Union local detected words with LLM recognized words
        let combinedWords = Array(Set(output.targetWordsUsed + detectedLocalWords)).sorted()
        return RoleplayTurnOutput(
            characterReply: output.characterReply,
            targetWordsUsed: combinedWords,
            refinementSuggestion: output.refinementSuggestion,
            pedagogicalNote: output.pedagogicalNote
        )
    }
}
