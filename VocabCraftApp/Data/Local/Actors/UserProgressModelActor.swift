import Foundation
import SwiftData

public struct UserProgressSummary: Sendable {
    public let masteryLevel: Int
    public let isBookmarked: Bool
    
    public init(masteryLevel: Int, isBookmarked: Bool) {
        self.masteryLevel = masteryLevel
        self.isBookmarked = isBookmarked
    }
}

@ModelActor
public actor UserProgressModelActor {
    public func getProgress(wordId: Int64) throws -> UserWordProgress? {
        var descriptor = FetchDescriptor<UserWordProgress>(
            predicate: #Predicate { $0.wordId == wordId }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
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
        if let existing = try getProgress(wordId: wordId) {
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

    public func fetchAllProgress() throws -> [UserWordProgress] {
        let descriptor = FetchDescriptor<UserWordProgress>()
        return try modelContext.fetch(descriptor)
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

    public func logDrillRecord(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) throws {
        let record = ReflexSessionLog(drillId: drillId, responseTimeMs: responseTimeMs, accuracyScore: accuracyScore)
        modelContext.insert(record)
        try modelContext.save()
    }
}
