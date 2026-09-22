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
        // Fast local detection of target words in user input
        let lowercasedInput = userUtterance.lowercased()
        let detectedLocalWords = scenario.targetWordIds.filter { word in
            lowercasedInput.contains(word.lowercased())
        }

        let systemPrompt = """
        You are \(scenario.characterName), a \(scenario.characterRole) in a roleplay conversation with the user who is a \(scenario.userRole).
        Maintain an authentic, friendly persona suitable for the scene: \(scenario.titleKey).
        Target vocabulary for the user: \(scenario.targetWordIds.joined(separator: ", ")).
        Return JSON conforming to RoleplayTurnOutput schema:
        - characterReply: your in-character spoken dialogue
        - targetWordsUsed: list of target words the user used correctly in their message
        - refinementSuggestion: if the user's sentence could be phrased more naturally, provide the improved sentence; otherwise null
        - pedagogicalNote: brief encouragement or usage tip; otherwise null
        """

        var fullHistory = chatHistory
        fullHistory.append(LLMChatMessage(role: .user, content: userUtterance))

        do {
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
        } catch {
            // Fallback response on provider failure if mock or recoverable
            return RoleplayTurnOutput(
                characterReply: "I hear you! That makes total sense in this situation.",
                targetWordsUsed: detectedLocalWords,
                refinementSuggestion: nil,
                pedagogicalNote: nil
            )
        }
    }
}
