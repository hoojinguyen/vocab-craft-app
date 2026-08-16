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
    public let sentenceFrame: String?

    public init(
        phase: QuickReflexPhase,
        promptText: String,
        targetExpression: String,
        hints: [String],
        sentenceFrame: String? = nil
    ) {
        self.phase = phase
        self.promptText = promptText
        self.targetExpression = targetExpression
        self.hints = hints
        self.sentenceFrame = sentenceFrame
    }
}

/// The distinct automatic assistance cadence for each productive-recall stage.
public enum QuickReflexHintTiming {
    public static func automaticDelaySeconds(for phase: QuickReflexPhase) -> [Int] {
        switch phase {
        case .retrieve:
            [4, 7]
        case .useInSentence:
            [5]
        case .result:
            []
        }
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
