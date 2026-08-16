import Foundation

/// The learner's self-reported confidence after a quick-reflex attempt.
public enum QuickReflexConfidence: String, CaseIterable, Equatable, Sendable {
    case uncertain
    case comfortable
}

/// A persistence-neutral record of one quick-reflex learning attempt.
public struct QuickReflexAttempt: Equatable, Sendable {
    public let wordId: Int64
    public let retrieveTimeMs: Int
    public let useTimeMs: Int
    public let retrieveSucceeded: Bool
    public let useSucceeded: Bool
    public let maxHintLevel: Int
    public let inputMode: QuickReflexInputMode
    public let retryCount: Int
    public let confidence: QuickReflexConfidence
    public let timestamp: Date

    /// Creates a learning attempt with its complete response and confidence signals.
    public init(
        wordId: Int64,
        retrieveTimeMs: Int,
        useTimeMs: Int,
        retrieveSucceeded: Bool,
        useSucceeded: Bool,
        maxHintLevel: Int,
        inputMode: QuickReflexInputMode,
        retryCount: Int,
        confidence: QuickReflexConfidence,
        timestamp: Date = Date()
    ) {
        self.wordId = wordId
        self.retrieveTimeMs = retrieveTimeMs
        self.useTimeMs = useTimeMs
        self.retrieveSucceeded = retrieveSucceeded
        self.useSucceeded = useSucceeded
        self.maxHintLevel = maxHintLevel
        self.inputMode = inputMode
        self.retryCount = retryCount
        self.confidence = confidence
        self.timestamp = timestamp
    }
}
