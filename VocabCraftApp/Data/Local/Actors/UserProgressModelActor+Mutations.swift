import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData

// MARK: - Mutations (SwiftData)
extension UserProgressModelActor {
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
        isMastered: Bool,
        modeStats: ModeSuccessStats? = nil
    ) throws {
        if let existing = try fetchEntity(wordId: wordId) {
            existing.consecutiveCorrectStreak = newStreak
            existing.practicedModes = newModes
            existing.isMastered = isMastered
            existing.lastReviewDate = Date()
            existing.totalReviews += 1
            if let modeStats {
                existing.modeStats = modeStats
            }
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
                isMastered: isMastered,
                modeSuccessCountsRaw: modeStats.map { ModeSuccessStatsCodec.encode($0) } ?? ""
            )
            newProgress.totalReviews = 1
            modelContext.insert(newProgress)
        }
        try modelContext.save()
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
// MARK: - Mutations (Fallback Mock)
extension UserProgressModelActor {
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
        isMastered: Bool,
        modeStats: ModeSuccessStats? = nil
    ) throws {
        if let existing = records[wordId] {
            existing.consecutiveCorrectStreak = newStreak
            existing.practicedModes = newModes
            existing.isMastered = isMastered
            existing.lastReviewDate = Date()
            existing.totalReviews += 1
            if let modeStats {
                existing.modeStats = modeStats
            }
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
                isMastered: isMastered,
                modeSuccessCountsRaw: modeStats.map { ModeSuccessStatsCodec.encode($0) } ?? ""
            )
            newProgress.totalReviews = 1
            records[wordId] = newProgress
        }
    }

    public func resetAllProgress() throws {
        records.removeAll()
    }

    public func logDrillRecord(drillId: Int64, responseTimeMs: Int, accuracyScore: Double) throws {}
}
#endif
