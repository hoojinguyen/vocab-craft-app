import Foundation
import Observation

public struct DisplayChatMessage: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let isUser: Bool
    public let text: String
    public let characterName: String?
    public let refinementSuggestion: String?
    public var isRefinementExpanded: Bool

    public init(
        id: UUID = UUID(),
        isUser: Bool,
        text: String,
        characterName: String? = nil,
        refinementSuggestion: String? = nil,
        isRefinementExpanded: Bool = false
    ) {
        self.id = id
        self.isUser = isUser
        self.text = text
        self.characterName = characterName
        self.refinementSuggestion = refinementSuggestion
        self.isRefinementExpanded = isRefinementExpanded
    }
}

@Observable
@MainActor
public final class RoleplayRoomViewModel {
    public let scenario: RoleplayScenario
    public var messages: [DisplayChatMessage] = []
    public var masteredWords: Set<String> = []
    public var isSending: Bool = false
    public var inputText: String = ""
    public var isRecording: Bool = false
    public var sessionSummary: RoleplaySessionSummary?

    private let executeTurnUseCase: ExecuteRoleplayTurnUseCase
    private let completeSessionUseCase: CompleteRoleplaySessionUseCase
    private var chatHistory: [LLMChatMessage] = []
    private var gatheredRefinements: [SentenceRefinementPair] = []

    public init(
        scenario: RoleplayScenario,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase
    ) {
        self.scenario = scenario
        self.executeTurnUseCase = executeTurnUseCase
        self.completeSessionUseCase = completeSessionUseCase

        // Setup initial greeting
        let greeting = DisplayChatMessage(
            isUser: false,
            text: scenario.initialGreeting,
            characterName: scenario.characterName
        )
        self.messages.append(greeting)
        self.chatHistory.append(LLMChatMessage(role: .model, content: scenario.initialGreeting))
    }

    public func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        inputText = ""
        isSending = true
        defer { isSending = false }

        let userMsg = DisplayChatMessage(isUser: true, text: trimmed)
        messages.append(userMsg)
        let userMsgIndex = messages.count - 1

        do {
            let output = try await executeTurnUseCase.execute(
                scenario: scenario,
                userUtterance: trimmed,
                chatHistory: chatHistory
            )

            // Update user message with refinement if available
            if let ref = output.refinementSuggestion {
                messages[userMsgIndex] = DisplayChatMessage(
                    id: messages[userMsgIndex].id,
                    isUser: true,
                    text: trimmed,
                    refinementSuggestion: ref
                )
                gatheredRefinements.append(SentenceRefinementPair(
                    originalUserSentence: trimmed,
                    refinedNativeSentence: ref
                ))
            }

            // Append character response
            let aiMsg = DisplayChatMessage(
                isUser: false,
                text: output.characterReply,
                characterName: scenario.characterName
            )
            messages.append(aiMsg)

            // Update state
            chatHistory.append(LLMChatMessage(role: .user, content: trimmed))
            chatHistory.append(LLMChatMessage(role: .model, content: output.characterReply))

            for word in output.targetWordsUsed {
                masteredWords.insert(word)
            }
        } catch {
            let fallbackMsg = DisplayChatMessage(
                isUser: false,
                text: String(localized: "app.ai_assistant.room.fallback_reply", defaultValue: "I see! Please go on."),
                characterName: scenario.characterName
            )
            messages.append(fallbackMsg)
        }
    }

    public func finishSession() async {
        let summary = await completeSessionUseCase.execute(
            scenarioId: scenario.id,
            totalTurns: messages.filter { $0.isUser }.count,
            targetWordsAttempted: scenario.targetWordIds,
            targetWordsMastered: Array(masteredWords),
            refinements: gatheredRefinements
        )
        self.sessionSummary = summary
    }

    public func toggleRefinement(for id: UUID) {
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            var msg = messages[idx]
            msg.isRefinementExpanded.toggle()
            messages[idx] = msg
        }
    }
}
