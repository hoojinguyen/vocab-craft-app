import Foundation
import SwiftData

#if canImport(SwiftDataMacros) || canImport(SwiftData)
@ModelActor
public actor UserProgressModelActor: UserProgressRepositoryProtocol {
    func fetchEntity(wordId: Int64) throws -> UserWordProgress? {
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
            totalReviews: item.totalReviews,
            needsReview: item.needsReview,
            mistakeCount: item.mistakeCount,
            sourceDeckId: item.sourceDeckId,
            sourceNodeId: item.sourceNodeId,
            consecutiveCorrectStreak: item.consecutiveCorrectStreak,
            practicedModes: item.practicedModes,
            isMastered: item.isMastered,
            modeStats: item.modeStats
        )
    }

    public func getProgress(wordId: Int64) throws -> UserWordProgressData? {
        try getProgressData(wordId: wordId)
    }

    public func fetchProgress(for wordId: Int64) throws -> UserWordProgressData? {
        try getProgressData(wordId: wordId)
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
                totalReviews: item.totalReviews,
                needsReview: item.needsReview,
                mistakeCount: item.mistakeCount,
                sourceDeckId: item.sourceDeckId,
                sourceNodeId: item.sourceNodeId,
                consecutiveCorrectStreak: item.consecutiveCorrectStreak,
                practicedModes: item.practicedModes,
                isMastered: item.isMastered,
                modeStats: item.modeStats
            )
        }
    }

    public func fetchAllProgress() throws -> [UserWordProgressData] {
        try fetchAllProgressData()
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
}
#else
public actor UserProgressModelActor: UserProgressRepositoryProtocol {
    var records: [Int64: UserWordProgress] = [:]

    public init(modelContainer: Any? = nil) {}

    public func getProgressData(wordId: Int64) throws -> UserWordProgressData? {
        guard let item = records[wordId] else { return nil }
        return UserWordProgressData(
            wordId: item.wordId,
            cefrLevel: item.cefrLevel,
            masteryLevel: item.masteryLevel,
            isBookmarked: item.isBookmarked,
            easeFactor: item.easeFactor,
            intervalDays: item.intervalDays,
            nextReviewDate: item.nextReviewDate,
            lastReviewDate: item.lastReviewDate,
            totalReviews: item.totalReviews,
            needsReview: item.needsReview,
            mistakeCount: item.mistakeCount,
            sourceDeckId: item.sourceDeckId,
            sourceNodeId: item.sourceNodeId,
            consecutiveCorrectStreak: item.consecutiveCorrectStreak,
            practicedModes: item.practicedModes,
            isMastered: item.isMastered,
            modeStats: item.modeStats
        )
    }

    public func getProgress(wordId: Int64) throws -> UserWordProgressData? {
        try getProgressData(wordId: wordId)
    }

    public func fetchProgress(for wordId: Int64) throws -> UserWordProgressData? {
        try getProgressData(wordId: wordId)
    }

    public func fetchAllProgressData() throws -> [UserWordProgressData] {
        records.values.map { item in
            UserWordProgressData(
                wordId: item.wordId,
                cefrLevel: item.cefrLevel,
                masteryLevel: item.masteryLevel,
                isBookmarked: item.isBookmarked,
                easeFactor: item.easeFactor,
                intervalDays: item.intervalDays,
                nextReviewDate: item.nextReviewDate,
                lastReviewDate: item.lastReviewDate,
                totalReviews: item.totalReviews,
                needsReview: item.needsReview,
                mistakeCount: item.mistakeCount,
                sourceDeckId: item.sourceDeckId,
                sourceNodeId: item.sourceNodeId,
                consecutiveCorrectStreak: item.consecutiveCorrectStreak,
                practicedModes: item.practicedModes,
                isMastered: item.isMastered,
                modeStats: item.modeStats
            )
        }
    }

    public func fetchAllProgress() throws -> [UserWordProgressData] {
        try fetchAllProgressData()
    }

    public func fetchAllMasteryLevels() throws -> [Int64: Int] {
        var map: [Int64: Int] = [:]
        for item in records.values {
            map[item.wordId] = item.masteryLevel
        }
        return map
    }

    public func fetchAllProgressSummaryMap() throws -> [Int64: UserProgressSummary] {
        var map: [Int64: UserProgressSummary] = [:]
        for item in records.values {
            map[item.wordId] = UserProgressSummary(masteryLevel: item.masteryLevel, isBookmarked: item.isBookmarked)
        }
        return map
    }
}
#endif
