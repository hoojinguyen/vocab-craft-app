import Foundation
import SwiftData

extension UserWordProgress {
    public var practicedModes: Set<ReflexBlitzMode> {
        get {
            guard !practicedModesRaw.isEmpty else { return [] }
            let modes = practicedModesRaw.split(separator: ",").compactMap { ReflexBlitzMode(rawValue: String($0)) }
            return Set(modes)
        }
        set {
            practicedModesRaw = newValue.map(\.rawValue).sorted().joined(separator: ",")
        }
    }
}

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
    public let needsReview: Bool
    public let mistakeCount: Int
    public let sourceDeckId: String?
    public let sourceNodeId: String?
    public let consecutiveCorrectStreak: Int
    public let practicedModes: Set<ReflexBlitzMode>
    public let isMastered: Bool
    public let modeStats: ModeSuccessStats

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
        practicedModes: Set<ReflexBlitzMode> = [],
        isMastered: Bool = false,
        modeStats: ModeSuccessStats = ModeSuccessStats()
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
        self.practicedModes = practicedModes
        self.isMastered = isMastered
        self.modeStats = modeStats
    }
}

#if canImport(SwiftDataMacros)
@ModelActor
public actor UserProgressModelActor: UserProgressRepositoryProtocol {
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

    // swiftlint:disable:next function_parameter_count
    public func saveProgress(
        wordId: Int64,
        cefrLevel: String,
        masteryLevel: Int,
        isBookmarked: Bool,
        needsReview: Bool,
        mistakeCount: Int,
        sourceDeckId: String?,
        sourceNodeId: String?
    ) throws {
        if let existing = try fetchEntity(wordId: wordId) {
            existing.cefrLevel = cefrLevel
            existing.masteryLevel = masteryLevel
            existing.isBookmarked = isBookmarked
            existing.needsReview = needsReview
            existing.mistakeCount = mistakeCount
            existing.sourceDeckId = sourceDeckId
            existing.sourceNodeId = sourceNodeId
            existing.lastReviewDate = Date()
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                cefrLevel: cefrLevel,
                masteryLevel: masteryLevel,
                isBookmarked: isBookmarked,
                needsReview: needsReview,
                mistakeCount: mistakeCount,
                sourceDeckId: sourceDeckId,
                sourceNodeId: sourceNodeId
            )
            modelContext.insert(newProgress)
        }
        try modelContext.save()
    }

    public func recordChallengeResult(wordId: Int64, isCorrect: Bool, stageId: String?, deckId: String?) throws {
        if let existing = try fetchEntity(wordId: wordId) {
            if isCorrect {
                existing.masteryLevel = min(5, existing.masteryLevel + 1)
            } else {
                existing.needsReview = true
                existing.mistakeCount += 1
            }
            if let stageId { existing.sourceNodeId = stageId }
            if let deckId { existing.sourceDeckId = deckId }
            existing.lastReviewDate = Date()
            existing.totalReviews += 1
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                cefrLevel: "A1",
                masteryLevel: isCorrect ? 1 : 0,
                isBookmarked: false,
                needsReview: !isCorrect,
                mistakeCount: isCorrect ? 0 : 1,
                sourceDeckId: deckId,
                sourceNodeId: stageId
            )
            newProgress.totalReviews = 1
            modelContext.insert(newProgress)
        }
        try modelContext.save()
    }

    public func toggleBookmark(wordId: Int64) throws -> Bool {
        if let existing = try fetchEntity(wordId: wordId) {
            existing.isBookmarked.toggle()
            let state = existing.isBookmarked
            try modelContext.save()
            return state
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                isBookmarked: true
            )
            modelContext.insert(newProgress)
            try modelContext.save()
            return true
        }
    }

    public func markWordReviewed(wordId: Int64, isCorrect: Bool) throws {
        if let existing = try fetchEntity(wordId: wordId) {
            if isCorrect {
                existing.needsReview = false
                existing.masteryLevel = min(5, existing.masteryLevel + 1)
            } else {
                existing.needsReview = true
                existing.mistakeCount += 1
            }
            existing.lastReviewDate = Date()
            existing.totalReviews += 1
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                masteryLevel: isCorrect ? 1 : 0,
                needsReview: !isCorrect,
                mistakeCount: isCorrect ? 0 : 1
            )
            newProgress.totalReviews = 1
            modelContext.insert(newProgress)
        }
        try modelContext.save()
    }

    public func clearNeedsReview(wordId: Int64) throws {
        try markWordReviewed(wordId: wordId, isCorrect: true)
    }

    public func recordDrillResult(
        wordId: Int64,
        isCorrect: Bool,
        newStreak: Int,
        newModes: Set<ReflexBlitzMode>,
        isMastered: Bool
    ) throws {
        if let existing = try fetchEntity(wordId: wordId) {
            existing.consecutiveCorrectStreak = newStreak
            existing.practicedModes = newModes
            existing.isMastered = isMastered
            existing.lastReviewDate = Date()
            existing.totalReviews += 1
            if isMastered {
                existing.masteryLevel = 5
            }
            if !isCorrect {
                existing.needsReview = true
                existing.mistakeCount += 1
            } else {
                existing.needsReview = false
            }
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                cefrLevel: "A1",
                masteryLevel: isMastered ? 5 : (isCorrect ? 1 : 0),
                isBookmarked: false,
                needsReview: !isCorrect,
                mistakeCount: isCorrect ? 0 : 1,
                consecutiveCorrectStreak: newStreak,
                practicedModesRaw: newModes.map(\.rawValue).sorted().joined(separator: ","),
                isMastered: isMastered
            )
            newProgress.totalReviews = 1
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
#else
public actor UserProgressModelActor: UserProgressRepositoryProtocol {
    private var records: [Int64: UserWordProgress] = [:]

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
        if let existing = records[wordId] {
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
            records[wordId] = newProgress
        }
    }

    // swiftlint:disable:next function_parameter_count
    public func saveProgress(
        wordId: Int64,
        cefrLevel: String,
        masteryLevel: Int,
        isBookmarked: Bool,
        needsReview: Bool,
        mistakeCount: Int,
        sourceDeckId: String?,
        sourceNodeId: String?
    ) throws {
        if let existing = records[wordId] {
            existing.cefrLevel = cefrLevel
            existing.masteryLevel = masteryLevel
            existing.isBookmarked = isBookmarked
            existing.needsReview = needsReview
            existing.mistakeCount = mistakeCount
            existing.sourceDeckId = sourceDeckId
            existing.sourceNodeId = sourceNodeId
            existing.lastReviewDate = Date()
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                cefrLevel: cefrLevel,
                masteryLevel: masteryLevel,
                isBookmarked: isBookmarked,
                needsReview: needsReview,
                mistakeCount: mistakeCount,
                sourceDeckId: sourceDeckId,
                sourceNodeId: sourceNodeId
            )
            records[wordId] = newProgress
        }
    }

    public func recordChallengeResult(wordId: Int64, isCorrect: Bool, stageId: String?, deckId: String?) throws {
        if let existing = records[wordId] {
            if isCorrect {
                existing.masteryLevel = min(5, existing.masteryLevel + 1)
            } else {
                existing.needsReview = true
                existing.mistakeCount += 1
            }
            if let stageId { existing.sourceNodeId = stageId }
            if let deckId { existing.sourceDeckId = deckId }
            existing.lastReviewDate = Date()
            existing.totalReviews += 1
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                cefrLevel: "A1",
                masteryLevel: isCorrect ? 1 : 0,
                isBookmarked: false,
                needsReview: !isCorrect,
                mistakeCount: isCorrect ? 0 : 1,
                sourceDeckId: deckId,
                sourceNodeId: stageId
            )
            newProgress.totalReviews = 1
            records[wordId] = newProgress
        }
    }

    public func toggleBookmark(wordId: Int64) throws -> Bool {
        if let existing = records[wordId] {
            existing.isBookmarked.toggle()
            return existing.isBookmarked
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                isBookmarked: true
            )
            records[wordId] = newProgress
            return true
        }
    }

    public func markWordReviewed(wordId: Int64, isCorrect: Bool) throws {
        if let existing = records[wordId] {
            if isCorrect {
                existing.needsReview = false
                existing.masteryLevel = min(5, existing.masteryLevel + 1)
            } else {
                existing.needsReview = true
                existing.mistakeCount += 1
            }
            existing.lastReviewDate = Date()
            existing.totalReviews += 1
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                masteryLevel: isCorrect ? 1 : 0,
                needsReview: !isCorrect,
                mistakeCount: isCorrect ? 0 : 1
            )
            newProgress.totalReviews = 1
            records[wordId] = newProgress
        }
    }

    public func clearNeedsReview(wordId: Int64) throws {
        try markWordReviewed(wordId: wordId, isCorrect: true)
    }

    public func recordDrillResult(
        wordId: Int64,
        isCorrect: Bool,
        newStreak: Int,
        newModes: Set<ReflexBlitzMode>,
        isMastered: Bool
    ) throws {
        if let existing = records[wordId] {
            existing.consecutiveCorrectStreak = newStreak
            existing.practicedModes = newModes
            existing.isMastered = isMastered
            existing.lastReviewDate = Date()
            existing.totalReviews += 1
            if isMastered {
                existing.masteryLevel = 5
            }
            if !isCorrect {
                existing.needsReview = true
                existing.mistakeCount += 1
            } else {
                existing.needsReview = false
            }
        } else {
            let newProgress = UserWordProgress(
                wordId: wordId,
                cefrLevel: "A1",
                masteryLevel: isMastered ? 5 : (isCorrect ? 1 : 0),
                isBookmarked: false,
                needsReview: !isCorrect,
                mistakeCount: isCorrect ? 0 : 1,
                consecutiveCorrectStreak: newStreak,
                practicedModesRaw: newModes.map(\.rawValue).sorted().joined(separator: ","),
                isMastered: isMastered
            )
            newProgress.totalReviews = 1
            records[wordId] = newProgress
        }
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

    public func resetAllProgress() throws {
        records.removeAll()
    }

    public func logDrillRecord(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) throws {}
}
#endif
