import Foundation
import os

/// Record of a batch lesson result recording call captured by `MockUserProgressRepository`.
public struct RecordedBatchLessonCall: Sendable, Equatable {
    public let practicedWordIds: [Int64]
    public let weakWordIds: Set<Int64>
    public let stageId: String?
    public let deckId: String?

    public init(
        practicedWordIds: [Int64],
        weakWordIds: Set<Int64>,
        stageId: String? = nil,
        deckId: String? = nil
    ) {
        self.practicedWordIds = practicedWordIds
        self.weakWordIds = weakWordIds
        self.stageId = stageId
        self.deckId = deckId
    }
}

/// In-memory mock implementation of `UserProgressRepositoryProtocol` for testing, previews, and mock container mode.
public final class MockUserProgressRepository: UserProgressRepositoryProtocol, @unchecked Sendable {
    private struct State {
        var storage: [Int64: UserWordProgressData] = [:]
        var recordChallengeCallCount: Int = 0
        var recordedBatchCalls: [RecordedBatchLessonCall] = []
    }

    private let stateLock: OSAllocatedUnfairLock<State>

    public var recordChallengeCallCount: Int {
        stateLock.withLock { $0.recordChallengeCallCount }
    }

    public var recordedBatchCalls: [RecordedBatchLessonCall] {
        stateLock.withLock { $0.recordedBatchCalls }
    }

    public init(initialData: [UserWordProgressData] = []) {
        var initialStorage: [Int64: UserWordProgressData] = [:]
        for item in initialData {
            initialStorage[item.wordId] = item
        }
        self.stateLock = OSAllocatedUnfairLock(initialState: State(storage: initialStorage, recordChallengeCallCount: 0))
    }

    public func recordChallengeResult(wordId: Int64, isCorrect: Bool, stageId: String?, deckId: String?) async throws {
        stateLock.withLock { state in
            state.recordChallengeCallCount += 1
            if let existing = state.storage[wordId] {
                let updatedMastery = isCorrect ? min(5, existing.masteryLevel + 1) : existing.masteryLevel
                let updatedMistakes = isCorrect ? existing.mistakeCount : existing.mistakeCount + 1
                state.storage[wordId] = UserWordProgressData(
                    wordId: existing.wordId,
                    cefrLevel: existing.cefrLevel,
                    masteryLevel: updatedMastery,
                    isBookmarked: existing.isBookmarked,
                    easeFactor: existing.easeFactor,
                    intervalDays: existing.intervalDays,
                    nextReviewDate: existing.nextReviewDate,
                    lastReviewDate: Date(),
                    totalReviews: existing.totalReviews + 1,
                    needsReview: !isCorrect,
                    mistakeCount: updatedMistakes,
                    sourceDeckId: deckId ?? existing.sourceDeckId,
                    sourceNodeId: stageId ?? existing.sourceNodeId,
                    consecutiveCorrectStreak: existing.consecutiveCorrectStreak,
                    practicedModes: existing.practicedModes,
                    isMastered: existing.isMastered,
                    modeStats: existing.modeStats
                )
            } else {
                state.storage[wordId] = UserWordProgressData(
                    wordId: wordId,
                    cefrLevel: "A1",
                    masteryLevel: isCorrect ? 1 : 0,
                    isBookmarked: false,
                    needsReview: !isCorrect,
                    mistakeCount: isCorrect ? 0 : 1,
                    sourceDeckId: deckId,
                    sourceNodeId: stageId
                )
            }
        }
    }

    public func toggleBookmark(wordId: Int64) async throws -> Bool {
        stateLock.withLock { state in
            if let existing = state.storage[wordId] {
                let newState = !existing.isBookmarked
                state.storage[wordId] = UserWordProgressData(
                    wordId: existing.wordId,
                    cefrLevel: existing.cefrLevel,
                    masteryLevel: existing.masteryLevel,
                    isBookmarked: newState,
                    easeFactor: existing.easeFactor,
                    intervalDays: existing.intervalDays,
                    nextReviewDate: existing.nextReviewDate,
                    lastReviewDate: existing.lastReviewDate,
                    totalReviews: existing.totalReviews,
                    needsReview: existing.needsReview,
                    mistakeCount: existing.mistakeCount,
                    sourceDeckId: existing.sourceDeckId,
                    sourceNodeId: existing.sourceNodeId,
                    consecutiveCorrectStreak: existing.consecutiveCorrectStreak,
                    practicedModes: existing.practicedModes,
                    isMastered: existing.isMastered,
                    modeStats: existing.modeStats
                )
                return newState
            } else {
                state.storage[wordId] = UserWordProgressData(
                    wordId: wordId,
                    isBookmarked: true
                )
                return true
            }
        }
    }

    public func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws {
        stateLock.withLock { state in
            if let existing = state.storage[wordId] {
                let newMastery = isCorrect ? min(5, existing.masteryLevel + 1) : existing.masteryLevel
                let newMistakes = isCorrect ? existing.mistakeCount : existing.mistakeCount + 1
                state.storage[wordId] = UserWordProgressData(
                    wordId: existing.wordId,
                    cefrLevel: existing.cefrLevel,
                    masteryLevel: newMastery,
                    isBookmarked: existing.isBookmarked,
                    easeFactor: existing.easeFactor,
                    intervalDays: existing.intervalDays,
                    nextReviewDate: existing.nextReviewDate,
                    lastReviewDate: Date(),
                    totalReviews: existing.totalReviews + 1,
                    needsReview: !isCorrect,
                    mistakeCount: newMistakes,
                    sourceDeckId: existing.sourceDeckId,
                    sourceNodeId: existing.sourceNodeId,
                    consecutiveCorrectStreak: existing.consecutiveCorrectStreak,
                    practicedModes: existing.practicedModes,
                    isMastered: existing.isMastered,
                    modeStats: existing.modeStats
                )
            } else {
                state.storage[wordId] = UserWordProgressData(
                    wordId: wordId,
                    masteryLevel: isCorrect ? 1 : 0,
                    needsReview: !isCorrect,
                    mistakeCount: isCorrect ? 0 : 1
                )
            }
        }
    }

    public func clearNeedsReview(wordId: Int64) async throws {
        try await markWordReviewed(wordId: wordId, isCorrect: true)
    }

    public func fetchAllProgress() async throws -> [UserWordProgressData] {
        stateLock.withLock { Array($0.storage.values) }
    }

    public func getProgress(wordId: Int64) async throws -> UserWordProgressData? {
        stateLock.withLock { $0.storage[wordId] }
    }

    public func recordDrillResult(
        wordId: Int64,
        isCorrect: Bool,
        newStreak: Int,
        newModes: Set<ReflexBlitzMode>,
        isMastered: Bool,
        modeStats: ModeSuccessStats? = nil
    ) async throws {
        stateLock.withLock { state in
            if let existing = state.storage[wordId] {
                state.storage[wordId] = UserWordProgressData(
                    wordId: existing.wordId,
                    cefrLevel: existing.cefrLevel,
                    masteryLevel: isMastered ? 5 : (isCorrect ? max(1, existing.masteryLevel) : existing.masteryLevel),
                    isBookmarked: existing.isBookmarked,
                    easeFactor: existing.easeFactor,
                    intervalDays: existing.intervalDays,
                    nextReviewDate: existing.nextReviewDate,
                    lastReviewDate: Date(),
                    totalReviews: existing.totalReviews + 1,
                    needsReview: !isCorrect,
                    mistakeCount: isCorrect ? existing.mistakeCount : existing.mistakeCount + 1,
                    sourceDeckId: existing.sourceDeckId,
                    sourceNodeId: existing.sourceNodeId,
                    consecutiveCorrectStreak: newStreak,
                    practicedModes: newModes,
                    isMastered: isMastered,
                    modeStats: modeStats ?? existing.modeStats
                )
            } else {
                state.storage[wordId] = UserWordProgressData(
                    wordId: wordId,
                    cefrLevel: "A1",
                    masteryLevel: isMastered ? 5 : (isCorrect ? 1 : 0),
                    isBookmarked: false,
                    needsReview: !isCorrect,
                    mistakeCount: isCorrect ? 0 : 1,
                    consecutiveCorrectStreak: newStreak,
                    practicedModes: newModes,
                    isMastered: isMastered,
                    modeStats: modeStats ?? ModeSuccessStats()
                )
            }
        }
    }

    private static func makeExistingProgressData(
        existing: UserWordProgressData,
        isWeak: Bool,
        stageId: String?,
        deckId: String?,
        now: Date
    ) -> UserWordProgressData {
        if isWeak {
            return UserWordProgressData(
                wordId: existing.wordId,
                cefrLevel: existing.cefrLevel,
                masteryLevel: existing.masteryLevel,
                isBookmarked: existing.isBookmarked,
                easeFactor: max(1.3, existing.easeFactor - 0.2),
                intervalDays: 1,
                nextReviewDate: now,
                lastReviewDate: now,
                totalReviews: existing.totalReviews + 1,
                needsReview: true,
                mistakeCount: existing.mistakeCount + 1,
                sourceDeckId: deckId ?? existing.sourceDeckId,
                sourceNodeId: stageId ?? existing.sourceNodeId,
                consecutiveCorrectStreak: 0,
                practicedModes: existing.practicedModes,
                isMastered: existing.isMastered,
                modeStats: existing.modeStats
            )
        } else {
            let srs = SRSEngine.calculateNextInterval(
                currentMastery: existing.masteryLevel,
                easeFactor: existing.easeFactor,
                isCorrect: true,
                responseTimeMs: 2000
            )
            let nextReview = Calendar.current.date(byAdding: .day, value: srs.intervalDays, to: now) ?? now
            return UserWordProgressData(
                wordId: existing.wordId,
                cefrLevel: existing.cefrLevel,
                masteryLevel: min(5, existing.masteryLevel + 1),
                isBookmarked: existing.isBookmarked,
                easeFactor: srs.easeFactor,
                intervalDays: srs.intervalDays,
                nextReviewDate: nextReview,
                lastReviewDate: now,
                totalReviews: existing.totalReviews + 1,
                needsReview: false,
                mistakeCount: existing.mistakeCount,
                sourceDeckId: deckId ?? existing.sourceDeckId,
                sourceNodeId: stageId ?? existing.sourceNodeId,
                consecutiveCorrectStreak: existing.consecutiveCorrectStreak + 1,
                practicedModes: existing.practicedModes,
                isMastered: existing.isMastered,
                modeStats: existing.modeStats
            )
        }
    }

    private static func makeNewProgressData(
        wordId: Int64,
        isWeak: Bool,
        stageId: String?,
        deckId: String?,
        now: Date
    ) -> UserWordProgressData {
        if isWeak {
            return UserWordProgressData(
                wordId: wordId,
                cefrLevel: "A1",
                masteryLevel: 0,
                isBookmarked: false,
                easeFactor: 2.3,
                intervalDays: 1,
                nextReviewDate: now,
                lastReviewDate: now,
                totalReviews: 1,
                needsReview: true,
                mistakeCount: 1,
                sourceDeckId: deckId,
                sourceNodeId: stageId,
                consecutiveCorrectStreak: 0
            )
        } else {
            let srs = SRSEngine.calculateNextInterval(
                currentMastery: 0,
                easeFactor: 2.5,
                isCorrect: true,
                responseTimeMs: 2000
            )
            let nextReview = Calendar.current.date(byAdding: .day, value: srs.intervalDays, to: now) ?? now
            return UserWordProgressData(
                wordId: wordId,
                cefrLevel: "A1",
                masteryLevel: min(5, srs.nextMastery),
                isBookmarked: false,
                easeFactor: srs.easeFactor,
                intervalDays: srs.intervalDays,
                nextReviewDate: nextReview,
                lastReviewDate: now,
                totalReviews: 1,
                needsReview: false,
                mistakeCount: 0,
                sourceDeckId: deckId,
                sourceNodeId: stageId,
                consecutiveCorrectStreak: 1
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    private static func makeBatchProgressData(
        existing: UserWordProgressData?,
        wordId: Int64,
        isWeak: Bool,
        stageId: String?,
        deckId: String?,
        now: Date
    ) -> UserWordProgressData {
        if let existing {
            return makeExistingProgressData(
                existing: existing,
                isWeak: isWeak,
                stageId: stageId,
                deckId: deckId,
                now: now
            )
        } else {
            return makeNewProgressData(
                wordId: wordId,
                isWeak: isWeak,
                stageId: stageId,
                deckId: deckId,
                now: now
            )
        }
    }

    public func recordBatchLessonResults(
        practicedWordIds: [Int64],
        weakWordIds: Set<Int64>,
        stageId: String?,
        deckId: String?
    ) async throws {
        stateLock.withLock { state in
            state.recordChallengeCallCount += weakWordIds.count
            state.recordedBatchCalls.append(
                RecordedBatchLessonCall(
                    practicedWordIds: practicedWordIds,
                    weakWordIds: weakWordIds,
                    stageId: stageId,
                    deckId: deckId
                )
            )
            let now = Date()
            var processedWordIds = Set<Int64>()
            for wordId in practicedWordIds {
                guard !processedWordIds.contains(wordId) else { continue }
                processedWordIds.insert(wordId)
                let isWeak = weakWordIds.contains(wordId)
                let existing = state.storage[wordId]
                state.storage[wordId] = Self.makeBatchProgressData(
                    existing: existing,
                    wordId: wordId,
                    isWeak: isWeak,
                    stageId: stageId,
                    deckId: deckId,
                    now: now
                )
            }
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
    ) async throws {
        stateLock.withLock { state in
            let existing = state.storage[wordId]
            state.storage[wordId] = UserWordProgressData(
                wordId: wordId,
                cefrLevel: cefrLevel,
                masteryLevel: masteryLevel,
                isBookmarked: isBookmarked,
                needsReview: needsReview,
                mistakeCount: mistakeCount,
                sourceDeckId: sourceDeckId,
                sourceNodeId: sourceNodeId,
                consecutiveCorrectStreak: existing?.consecutiveCorrectStreak ?? 0,
                practicedModes: existing?.practicedModes ?? [],
                isMastered: existing?.isMastered ?? false,
                modeStats: existing?.modeStats ?? ModeSuccessStats()
            )
        }
    }
}
