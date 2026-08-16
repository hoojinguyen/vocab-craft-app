import Foundation

public enum QuickReflexPhase: Equatable, Sendable {
    case recallWord
    case recallCollocation
    case produceSentence
    case shadowModel
    case result

    // Backward-compatibility aliases
    public static let retrieve: QuickReflexPhase = .recallWord
    public static let useInSentence: QuickReflexPhase = .produceSentence
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
    public let modelAudioSentenceEn: String?

    public init(
        phase: QuickReflexPhase,
        promptText: String,
        targetExpression: String,
        hints: [String] = [],
        sentenceFrame: String? = nil,
        modelAudioSentenceEn: String? = nil
    ) {
        self.phase = phase
        self.promptText = promptText
        self.targetExpression = targetExpression
        self.hints = hints
        self.sentenceFrame = sentenceFrame
        self.modelAudioSentenceEn = modelAudioSentenceEn
    }
}

/// The distinct automatic assistance cadence for each productive-recall stage.
public enum QuickReflexHintTiming {
    public static func automaticDelaySeconds(for phase: QuickReflexPhase) -> [Int] {
        switch phase {
        case .recallWord:
            [3, 6]
        case .recallCollocation:
            [4]
        case .produceSentence:
            [5]
        case .shadowModel, .result:
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
    public let recallWord: QuickReflexStagePrompt
    public let recallCollocation: QuickReflexStagePrompt
    public let produceSentence: QuickReflexStagePrompt
    public let modelSentenceEn: String

    public init(
        recallWord: QuickReflexStagePrompt,
        recallCollocation: QuickReflexStagePrompt,
        produceSentence: QuickReflexStagePrompt,
        modelSentenceEn: String
    ) {
        self.recallWord = recallWord
        self.recallCollocation = recallCollocation
        self.produceSentence = produceSentence
        self.modelSentenceEn = modelSentenceEn
    }

    // Backward-compatibility accessors
    public var retrieve: QuickReflexStagePrompt { recallWord }
    public var use: QuickReflexStagePrompt { produceSentence }
}
