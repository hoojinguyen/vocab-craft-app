import Foundation

/// The user's input modality during a quick-reflex attempt.
public enum QuickReflexInputMode: String, CaseIterable, Equatable, Sendable {
    case voice
    case typing
}

/// The learner's self-reported confidence after a quick-reflex attempt.
public enum QuickReflexConfidence: String, CaseIterable, Equatable, Sendable {
    case uncertain
    case comfortable
}

/// A persistence-neutral record of one quick-reflex learning attempt.
public struct QuickReflexAttempt: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let wordId: Int64
    public let recallWordTimeMs: Int
    public let collocationTimeMs: Int
    public let produceSentenceTimeMs: Int
    public let recallWordSucceeded: Bool
    public let collocationSucceeded: Bool
    public let produceSentenceSucceeded: Bool
    public let shadowPronunciationScore: Double?
    public let maxHintLevel: Int
    public let inputMode: QuickReflexInputMode
    public let retryCount: Int
    public let confidence: QuickReflexConfidence
    public let timestamp: Date

    // Backward-compatible accessors
    public var retrieveTimeMs: Int { recallWordTimeMs }
    public var useTimeMs: Int { produceSentenceTimeMs }
    public var retrieveSucceeded: Bool { recallWordSucceeded }
    public var useSucceeded: Bool { produceSentenceSucceeded }

    /// Creates a learning attempt with its complete response and confidence signals across all ladder stages.
    public init(
        id: UUID = UUID(),
        wordId: Int64,
        recallWordTimeMs: Int,
        collocationTimeMs: Int,
        produceSentenceTimeMs: Int,
        recallWordSucceeded: Bool,
        collocationSucceeded: Bool,
        produceSentenceSucceeded: Bool,
        shadowPronunciationScore: Double? = nil,
        maxHintLevel: Int,
        inputMode: QuickReflexInputMode,
        retryCount: Int,
        confidence: QuickReflexConfidence,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.recallWordTimeMs = recallWordTimeMs
        self.collocationTimeMs = collocationTimeMs
        self.produceSentenceTimeMs = produceSentenceTimeMs
        self.recallWordSucceeded = recallWordSucceeded
        self.collocationSucceeded = collocationSucceeded
        self.produceSentenceSucceeded = produceSentenceSucceeded
        self.shadowPronunciationScore = shadowPronunciationScore
        self.maxHintLevel = maxHintLevel
        self.inputMode = inputMode
        self.retryCount = retryCount
        self.confidence = confidence
        self.timestamp = timestamp
    }

    /// Legacy initializer overload for backward compatibility during transitions.
    public init(
        id: UUID = UUID(),
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
        self.init(
            id: id,
            wordId: wordId,
            recallWordTimeMs: retrieveTimeMs,
            collocationTimeMs: 0,
            produceSentenceTimeMs: useTimeMs,
            recallWordSucceeded: retrieveSucceeded,
            collocationSucceeded: retrieveSucceeded,
            produceSentenceSucceeded: useSucceeded,
            shadowPronunciationScore: nil,
            maxHintLevel: maxHintLevel,
            inputMode: inputMode,
            retryCount: retryCount,
            confidence: confidence,
            timestamp: timestamp
        )
    }
}
