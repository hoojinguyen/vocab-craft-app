import Foundation

public enum QuickReflexPhase: Equatable, Sendable {
    case retrieve
    case useInSentence
    case result
}

public enum QuickReflexInputMode: Equatable, Sendable {
    case voice
    case typing
}

public struct QuickReflexStagePrompt: Equatable, Sendable {
    public let phase: QuickReflexPhase
    public let promptText: String
    public let targetExpression: String
    public let hints: [String]

    public init(
        phase: QuickReflexPhase,
        promptText: String,
        targetExpression: String,
        hints: [String]
    ) {
        self.phase = phase
        self.promptText = promptText
        self.targetExpression = targetExpression
        self.hints = hints
    }
}

public struct QuickReflexPrompts: Equatable, Sendable {
    public let retrieve: QuickReflexStagePrompt
    public let use: QuickReflexStagePrompt

    public init(retrieve: QuickReflexStagePrompt, use: QuickReflexStagePrompt) {
        self.retrieve = retrieve
        self.use = use
    }
}
