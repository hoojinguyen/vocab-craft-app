import Foundation
import SpeechKit

public final class ExecuteRoleplayTurnUseCase: Sendable {
    private let llmProvider: LLMProviderProtocol

    public init(llmProvider: LLMProviderProtocol) {
        self.llmProvider = llmProvider
    }

    public func execute(
        scenario: RoleplayScenario,
        userUtterance: String,
        chatHistory: [LLMChatMessage],
        suggestedResponses: [String] = []
    ) async throws -> RoleplayTurnOutput {
        var detectedLocalWords = Set<String>()

        // Tier 1: Target word detection across inflections and phonetic variations
        for word in scenario.targetWordIds where ReflexSpeechMatcher.isReflexMatch(
            spokenText: userUtterance,
            targetLemma: word,
            toleranceThreshold: 0.70
        ) {
            detectedLocalWords.insert(word)
        }

        // Tier 2: Candidate suggestion alignment (starter suggestions & previous turn suggested responses)
        var candidateSuggestions: [String] = []
        for candidate in scenario.starterSuggestions + suggestedResponses {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && !candidateSuggestions.contains(trimmed) {
                candidateSuggestions.append(trimmed)
            }
        }

        var recognizedCandidate: String?
        var highestCandidateScore: Double = 0.0

        for candidate in candidateSuggestions {
            let eval = FuzzySpeechMatcher.evaluate(
                spokenText: userUtterance,
                targetSentence: candidate,
                passThreshold: 0.70
            )
            if eval.isPassed {
                if eval.overallScore > highestCandidateScore {
                    highestCandidateScore = eval.overallScore
                    recognizedCandidate = candidate
                }
                for word in scenario.targetWordIds where ReflexSpeechMatcher.isReflexMatch(
                    spokenText: candidate,
                    targetLemma: word,
                    toleranceThreshold: 0.70
                ) {
                    detectedLocalWords.insert(word)
                }
            }
        }

        let topicDescriptor = scenario.topic.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        var systemPrompt = """
        You are \(scenario.characterName), a \(scenario.characterRole) in a roleplay conversation with the user who is a \(scenario.userRole).
        Maintain an authentic, friendly persona suitable for the scene: \(topicDescriptor).
        Target vocabulary for the user: \(scenario.targetWordIds.joined(separator: ", ")).

        CONVERSATION & BREVITY RULES (CRITICAL):
        - `characterReply`: Strictly 1 to 2 short sentences, maximum 25 words total. Speak naturally as in real life dialogue.
        - NEVER include asterisks, stage directions, or facial descriptions (*smiles*, *nods*). Spoken dialogue only!
        - Keep the interaction flowing naturally with a quick prompt or conversational response.

        REFINEMENT RULES:
        - `refinementSuggestion`: Only provide an improved sentence if the user's message has clear grammatical errors, awkward word choice, or unnatural phrasing.
        - If the user's sentence is already natural and grammatically correct English, RETURN NULL. Never rephrase a correct sentence.
        - When provided, keep the improved sentence natural and concise (under 12 words).

        SUGGESTED RESPONSES RULES:
        - `suggestedResponses`: Generate exactly 2 to 3 distinct, natural candidate responses (3 to 7 words each) following these branches:
          1. Target Word: A response naturally using one of the target words: \(scenario.targetWordIds.joined(separator: ", ")).
          2. Inquiry/Question: A natural polite question or request continuing the conversation.
          3. Casual Reaction: A colloquial remark or response.

        - `targetWordsUsed`: list of target words the user actually used correctly in their message.
        - `pedagogicalNote`: brief praise or tip (under 8 words); otherwise null.
        - `isConcluded`: boolean, false unless the interaction has reached a natural conclusion.

        Return JSON conforming to RoleplayTurnOutput schema.
        """

        if let recognizedCandidate {
            systemPrompt += "\nRecognized suggested response attempted by user: \"\(recognizedCandidate)\"."
        }

        var fullHistory = chatHistory
        fullHistory.append(LLMChatMessage(role: .user, content: userUtterance))

        let output: RoleplayTurnOutput = try await llmProvider.sendStructuredMessage(
            messages: fullHistory,
            systemPrompt: systemPrompt,
            responseSchema: RoleplayTurnOutput.self
        )
        // Union local detected words with LLM recognized words
        let combinedWords = detectedLocalWords.union(output.targetWordsUsed).sorted()
        let cleanedReply = Self.cleanSpokenDialogue(output.characterReply)
        return RoleplayTurnOutput(
            characterReply: cleanedReply,
            targetWordsUsed: combinedWords,
            refinementSuggestion: output.refinementSuggestion,
            pedagogicalNote: output.pedagogicalNote,
            suggestedResponses: output.suggestedResponses,
            isConcluded: output.isConcluded
        )
    }

    public static func cleanSpokenDialogue(_ text: String) -> String {
        let stripped = text.replacingOccurrences(of: #"\*[^*]*\*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^\s*"(.*)"\s*$"#, with: "$1", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return stripped.isEmpty ? text : stripped
    }

    public func execute(
        scenario: RoleplayScenario,
        conversation: [RoleplayMessage],
        suggestedResponses: [String] = []
    ) async throws -> RoleplayTurnOutput {
        let userUtterance = conversation.last(where: { $0.sender == .user })?.text ?? ""
        let previousMessages: [RoleplayMessage]
        if let lastIndex = conversation.lastIndex(where: { $0.sender == .user }) {
            previousMessages = Array(conversation.prefix(upTo: lastIndex))
        } else {
            previousMessages = []
        }
        let chatHistory = previousMessages.map { msg -> LLMChatMessage in
            switch msg.sender {
            case .user:
                return LLMChatMessage(role: .user, content: msg.text)
            case .character:
                return LLMChatMessage(role: .model, content: msg.text)
            }
        }
        return try await execute(
            scenario: scenario,
            userUtterance: userUtterance,
            chatHistory: chatHistory,
            suggestedResponses: suggestedResponses
        )
    }
}
