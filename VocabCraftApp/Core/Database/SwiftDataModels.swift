import Foundation
import SwiftData

@Model
public final class UserWordProgress {
    @Attribute(.unique) public var wordId: Int64
    public var cefrLevel: String
    public var masteryLevel: Int
    public var isBookmarked: Bool
    public var easeFactor: Double
    public var intervalDays: Int
    public var nextReviewDate: Date
    public var lastReviewDate: Date
    public var totalReviews: Int
    public var needsReview: Bool
    public var mistakeCount: Int
    public var sourceDeckId: String?
    public var sourceNodeId: String?
    public var consecutiveCorrectStreak: Int
    public var practicedModesRaw: String
    public var isMastered: Bool

    public init(
        wordId: Int64,
        cefrLevel: String = "A1",
        masteryLevel: Int = 0,
        isBookmarked: Bool = false,
        easeFactor: Double = 2.5,
        intervalDays: Int = 1,
        nextReviewDate: Date = Date(),
        lastReviewDate: Date = Date(),
        totalReviews: Int = 0,
        needsReview: Bool = false,
        mistakeCount: Int = 0,
        sourceDeckId: String? = nil,
        sourceNodeId: String? = nil,
        consecutiveCorrectStreak: Int = 0,
        practicedModesRaw: String = "",
        isMastered: Bool = false
    ) {
        self.wordId = wordId
        self.cefrLevel = cefrLevel
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
        self.easeFactor = easeFactor
        self.intervalDays = intervalDays
        self.nextReviewDate = nextReviewDate
        self.lastReviewDate = lastReviewDate
        self.totalReviews = totalReviews
        self.needsReview = needsReview
        self.mistakeCount = mistakeCount
        self.sourceDeckId = sourceDeckId
        self.sourceNodeId = sourceNodeId
        self.consecutiveCorrectStreak = consecutiveCorrectStreak
        self.practicedModesRaw = practicedModesRaw
        self.isMastered = isMastered
    }
}

@Model
public final class UserStageProgress {
    @Attribute(.unique) public var stageId: String
    public var deckId: String
    public var isCompleted: Bool
    public var score: Int
    public var completedAt: Date

    public init(stageId: String, deckId: String, isCompleted: Bool = false, score: Int = 0, completedAt: Date = Date()) {
        self.stageId = stageId
        self.deckId = deckId
        self.isCompleted = isCompleted
        self.score = score
        self.completedAt = completedAt
    }
}

@Model
public final class ReflexSessionLog {
    @Attribute(.unique) public var id: UUID
    public var drillId: Int64
    public var responseTimeMs: Int
    public var accuracyScore: Double
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        drillId: Int64,
        responseTimeMs: Int,
        accuracyScore: Double,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.drillId = drillId
        self.responseTimeMs = responseTimeMs
        self.accuracyScore = accuracyScore
        self.timestamp = timestamp
    }
}

@Model
public final class QuickReflexAttemptRecord {
    @Attribute(.unique) public var id: UUID
    public var wordId: Int64
    public var recallWordTimeMs: Int
    public var collocationTimeMs: Int
    public var produceSentenceTimeMs: Int
    public var recallWordSucceeded: Bool
    public var collocationSucceeded: Bool
    public var produceSentenceSucceeded: Bool
    public var shadowPronunciationScore: Double?
    public var maxHintLevel: Int
    public var inputModeRawValue: String
    public var retryCount: Int
    public var confidenceRawValue: String
    public var timestamp: Date

    // Backward-compatible computed properties
    public var retrieveTimeMs: Int {
        get { recallWordTimeMs }
        set { recallWordTimeMs = newValue }
    }
    public var useTimeMs: Int {
        get { produceSentenceTimeMs }
        set { produceSentenceTimeMs = newValue }
    }
    public var retrieveSucceeded: Bool {
        get { recallWordSucceeded }
        set { recallWordSucceeded = newValue }
    }
    public var useSucceeded: Bool {
        get { produceSentenceSucceeded }
        set { produceSentenceSucceeded = newValue }
    }

    public init(
        id: UUID = UUID(),
        wordId: Int64,
        recallWordTimeMs: Int,
        collocationTimeMs: Int = 0,
        produceSentenceTimeMs: Int,
        recallWordSucceeded: Bool,
        collocationSucceeded: Bool,
        produceSentenceSucceeded: Bool,
        shadowPronunciationScore: Double? = nil,
        maxHintLevel: Int,
        inputModeRawValue: String,
        retryCount: Int,
        confidenceRawValue: String,
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
        self.inputModeRawValue = inputModeRawValue
        self.retryCount = retryCount
        self.confidenceRawValue = confidenceRawValue
        self.timestamp = timestamp
    }

    /// Legacy initializer overload for backward compatibility
    public init(
        id: UUID = UUID(),
        wordId: Int64,
        retrieveTimeMs: Int,
        useTimeMs: Int,
        retrieveSucceeded: Bool,
        useSucceeded: Bool,
        maxHintLevel: Int,
        inputModeRawValue: String,
        retryCount: Int,
        confidenceRawValue: String,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.recallWordTimeMs = retrieveTimeMs
        self.collocationTimeMs = 0
        self.produceSentenceTimeMs = useTimeMs
        self.recallWordSucceeded = retrieveSucceeded
        self.collocationSucceeded = retrieveSucceeded
        self.produceSentenceSucceeded = useSucceeded
        self.shadowPronunciationScore = nil
        self.maxHintLevel = maxHintLevel
        self.inputModeRawValue = inputModeRawValue
        self.retryCount = retryCount
        self.confidenceRawValue = confidenceRawValue
        self.timestamp = timestamp
    }
}

@Model
public final class WidgetCurrentState {
    @Attribute(.unique) public var id: String
    public var currentWordId: Int64
    public var lemma: String
    public var ipaUs: String
    public var definitionVi: String
    public var exampleEn: String
    public var lastUpdated: Date

    public init(
        id: String = "default_widget",
        currentWordId: Int64,
        lemma: String,
        ipaUs: String,
        definitionVi: String,
        exampleEn: String,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.currentWordId = currentWordId
        self.lemma = lemma
        self.ipaUs = ipaUs
        self.definitionVi = definitionVi
        self.exampleEn = exampleEn
        self.lastUpdated = lastUpdated
    }
}
