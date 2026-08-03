import Foundation
import SwiftData

@Model
public final class UserWordProgress {
    @Attribute(.unique) public var wordId: Int64
    public var masteryLevel: Int
    public var easeFactor: Double
    public var intervalDays: Int
    public var nextReviewDate: Date
    public var lastReviewDate: Date
    public var totalReviews: Int

    public init(
        wordId: Int64,
        masteryLevel: Int = 0,
        easeFactor: Double = 2.5,
        intervalDays: Int = 1,
        nextReviewDate: Date = Date(),
        lastReviewDate: Date = Date(),
        totalReviews: Int = 0
    ) {
        self.wordId = wordId
        self.masteryLevel = masteryLevel
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
