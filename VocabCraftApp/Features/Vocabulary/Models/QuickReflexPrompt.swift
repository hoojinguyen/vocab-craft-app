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

/// Display decisions shared by the productive-recall stage card and its focused tests.
public struct QuickReflexDrillPhaseConfiguration: Equatable, Sendable {
    public let phase: QuickReflexPhase
    public let inputMode: QuickReflexInputMode

    public init(phase: QuickReflexPhase, inputMode: QuickReflexInputMode) {
        self.phase = phase
        self.inputMode = inputMode
    }

    public var hidesLemma: Bool { phase == .recallWord }
    public var showsTypingFallback: Bool { inputMode == .typing }
    public var stageNumber: Int {
        switch phase {
        case .recallWord:
            1
        case .recallCollocation:
            2
        case .produceSentence, .shadowModel, .result:
            3
        }
    }
}

public enum QuickReflexTimeDelta: Equatable, Sendable {
    case saved(milliseconds: Int)
    case slower(milliseconds: Int)
    case unchanged
}

public struct QuickReflexTimeComparison: Equatable, Sendable {
    public let recallWordDelta: QuickReflexTimeDelta
    public let collocationDelta: QuickReflexTimeDelta
    public let produceSentenceDelta: QuickReflexTimeDelta

    // Backward-compatible accessors
    public var retrieveDelta: QuickReflexTimeDelta { recallWordDelta }
    public var useDelta: QuickReflexTimeDelta { produceSentenceDelta }

    public init(
        currentRecallWordTimeMs: Int,
        previousRecallWordTimeMs: Int,
        currentCollocationTimeMs: Int = 0,
        previousCollocationTimeMs: Int = 0,
        currentProduceSentenceTimeMs: Int,
        previousProduceSentenceTimeMs: Int
    ) {
        recallWordDelta = Self.delta(current: currentRecallWordTimeMs, previous: previousRecallWordTimeMs)
        collocationDelta = Self.delta(current: currentCollocationTimeMs, previous: previousCollocationTimeMs)
        produceSentenceDelta = Self.delta(current: currentProduceSentenceTimeMs, previous: previousProduceSentenceTimeMs)
    }

    public init(currentRetrieveTimeMs: Int, previousRetrieveTimeMs: Int, currentUseTimeMs: Int, previousUseTimeMs: Int) {
        self.init(
            currentRecallWordTimeMs: currentRetrieveTimeMs,
            previousRecallWordTimeMs: previousRetrieveTimeMs,
            currentCollocationTimeMs: 0,
            previousCollocationTimeMs: 0,
            currentProduceSentenceTimeMs: currentUseTimeMs,
            previousProduceSentenceTimeMs: previousUseTimeMs
        )
    }

    private static func delta(current: Int, previous: Int) -> QuickReflexTimeDelta {
        if previous == 0 && current > 0 {
            return .unchanged
        }
        if current < previous {
            return .saved(milliseconds: previous - current)
        }
        if current > previous {
            return .slower(milliseconds: current - previous)
        }
        return .unchanged
    }
}
