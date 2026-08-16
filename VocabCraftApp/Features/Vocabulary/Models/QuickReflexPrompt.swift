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

    /// Remaining active-time delays, preserving original stage deadlines across app suspension.
    public static func remainingDelaySeconds(for phase: QuickReflexPhase, activeElapsedSeconds: Double) -> [Double] {
        automaticDelaySeconds(for: phase).map { deadline in
            max(0, Double(deadline) - activeElapsedSeconds)
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
