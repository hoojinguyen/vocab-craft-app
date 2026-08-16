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

    public init(
        wordId: Int64,
        cefrLevel: String = "A1",
        masteryLevel: Int = 0,
        isBookmarked: Bool = false,
        easeFactor: Double = 2.5,
        intervalDays: Int = 1,
        nextReviewDate: Date = Date(),
        lastReviewDate: Date = Date(),
        totalReviews: Int = 0
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
    public var retrieveTimeMs: Int
    public var useTimeMs: Int
    public var retrieveSucceeded: Bool
    public var useSucceeded: Bool
    public var maxHintLevel: Int
    public var inputModeRawValue: String
    public var retryCount: Int
    public var confidenceRawValue: String
    public var timestamp: Date

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
        self.retrieveTimeMs = retrieveTimeMs
        self.useTimeMs = useTimeMs
        self.retrieveSucceeded = retrieveSucceeded
        self.useSucceeded = useSucceeded
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
