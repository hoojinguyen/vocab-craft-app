import Foundation
import SwiftData

public struct UserProgressSummary: Sendable, Equatable {
    public let masteryLevel: Int
    public let isBookmarked: Bool

    public init(masteryLevel: Int, isBookmarked: Bool) {
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
    }
}

public struct UserWordProgressData: Sendable, Equatable {
    public let wordId: Int64
    public let cefrLevel: String
    public let masteryLevel: Int
    public let isBookmarked: Bool
    public let easeFactor: Double
    public let intervalDays: Int
    public let nextReviewDate: Date
    public let lastReviewDate: Date
    public let totalReviews: Int

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

@ModelActor
public actor UserProgressModelActor {
    private func fetchEntity(wordId: Int64) throws -> UserWordProgress? {
        var descriptor = FetchDescriptor<UserWordProgress>(
            predicate: #Predicate { $0.wordId == wordId }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    public func getProgressData(wordId: Int64) throws -> UserWordProgressData? {
        guard let item = try fetchEntity(wordId: wordId) else { return nil }
        return UserWordProgressData(
            wordId: item.wordId,
            cefrLevel: item.cefrLevel,
            masteryLevel: item.masteryLevel,
            isBookmarked: item.isBookmarked,
            easeFactor: item.easeFactor,
            intervalDays: item.intervalDays,
            nextReviewDate: item.nextReviewDate,
            lastReviewDate: item.lastReviewDate,
            totalReviews: item.totalReviews
        )
    }

    public func saveProgress(
        wordId: Int64,
        cefrLevel: String = "A1",
        masteryLevel: Int = 0,
        isBookmarked: Bool = false,
        nextReviewDate: Date = Date(),
        lastReviewDate: Date = Date(),
        easeFactor: Double = 2.5,
        intervalDays: Int = 1,
        totalReviews: Int = 0
    ) throws {
        if let existing = try fetchEntity(wordId: wordId) {
            existing.cefrLevel = cefrLevel
            existing.masteryLevel = masteryLevel
            existing.isBookmarked = isBookmarked
            existing.nextReviewDate = nextReviewDate
            existing.lastReviewDate = lastReviewDate
            existing.easeFactor = easeFactor
            existing.intervalDays = intervalDays
            existing.totalReviews = totalReviews
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                cefrLevel: cefrLevel,
                masteryLevel: masteryLevel,
                isBookmarked: isBookmarked,
                easeFactor: easeFactor,
                intervalDays: intervalDays,
                nextReviewDate: nextReviewDate,
                lastReviewDate: lastReviewDate,
                totalReviews: totalReviews
            )
            modelContext.insert(newProgress)
        }
        try modelContext.save()
    }

    public func fetchAllProgressData() throws -> [UserWordProgressData] {
        let descriptor = FetchDescriptor<UserWordProgress>()
        let items = try modelContext.fetch(descriptor)
        return items.map { item in
            UserWordProgressData(
                wordId: item.wordId,
                cefrLevel: item.cefrLevel,
                masteryLevel: item.masteryLevel,
                isBookmarked: item.isBookmarked,
                easeFactor: item.easeFactor,
                intervalDays: item.intervalDays,
                nextReviewDate: item.nextReviewDate,
                lastReviewDate: item.lastReviewDate,
                totalReviews: item.totalReviews
            )
        }
    }

    public func fetchAllMasteryLevels() throws -> [Int64: Int] {
        var descriptor = FetchDescriptor<UserWordProgress>()
        descriptor.propertiesToFetch = [\.wordId, \.masteryLevel]
        let items = try modelContext.fetch(descriptor)
        var map: [Int64: Int] = [:]
        map.reserveCapacity(items.count)
        for item in items {
            map[item.wordId] = item.masteryLevel
        }
        return map
    }

    public func fetchAllProgressSummaryMap() throws -> [Int64: UserProgressSummary] {
        var descriptor = FetchDescriptor<UserWordProgress>()
        descriptor.propertiesToFetch = [\.wordId, \.masteryLevel, \.isBookmarked]
        let items = try modelContext.fetch(descriptor)
        var map: [Int64: UserProgressSummary] = [:]
        map.reserveCapacity(items.count)
        for item in items {
            map[item.wordId] = UserProgressSummary(masteryLevel: item.masteryLevel, isBookmarked: item.isBookmarked)
        }
        return map
    }

    public func resetAllProgress() throws {
        try modelContext.delete(model: UserWordProgress.self)
        try modelContext.delete(model: ReflexSessionLog.self)
        try modelContext.delete(model: QuickReflexAttemptRecord.self)
        try modelContext.save()
    }

    public func logDrillRecord(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) throws {
        let record = ReflexSessionLog(drillId: drillId, responseTimeMs: responseTimeMs, accuracyScore: accuracyScore)
        modelContext.insert(record)
        try modelContext.save()
    }
}
