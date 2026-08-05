import Foundation

/// Domain model for user's SRS progress item.
public struct SRSProgressItem: Equatable, Sendable {
    public let wordId: Int64
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

/// Repository abstraction for Spaced Repetition persistence.
public protocol SRSRepositoryProtocol: Sendable {
    func getProgress(wordId: Int64) async throws -> SRSProgressItem?
    func saveProgress(_ item: SRSProgressItem) async throws
    func logReflexSession(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) async throws
}
