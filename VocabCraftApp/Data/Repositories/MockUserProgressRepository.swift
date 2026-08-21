import Foundation

/// In-memory mock implementation of `UserProgressRepositoryProtocol` for testing, previews, and mock container mode.
public final class MockUserProgressRepository: UserProgressRepositoryProtocol, @unchecked Sendable {
    private var storage: [Int64: UserWordProgressData] = [:]

    public init(initialData: [UserWordProgressData] = []) {
        for item in initialData {
            storage[item.wordId] = item
        }
    }

    public func recordChallengeResult(wordId: Int64, isCorrect: Bool, stageId: String?, deckId: String?) async throws {
        if let existing = storage[wordId] {
            let updatedMastery = isCorrect ? min(5, existing.masteryLevel + 1) : existing.masteryLevel
            let updatedMistakes = isCorrect ? existing.mistakeCount : existing.mistakeCount + 1
            storage[wordId] = UserWordProgressData(
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
                sourceNodeId: stageId ?? existing.sourceNodeId
            )
        } else {
            storage[wordId] = UserWordProgressData(
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

    public func toggleBookmark(wordId: Int64) async throws -> Bool {
        if let existing = storage[wordId] {
            let newState = !existing.isBookmarked
            storage[wordId] = UserWordProgressData(
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
                sourceNodeId: existing.sourceNodeId
            )
            return newState
        } else {
            storage[wordId] = UserWordProgressData(
                wordId: wordId,
                isBookmarked: true
            )
            return true
        }
    }

    public func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws {
        if let existing = storage[wordId] {
            let newMastery = isCorrect ? min(5, existing.masteryLevel + 1) : existing.masteryLevel
            let newMistakes = isCorrect ? existing.mistakeCount : existing.mistakeCount + 1
            storage[wordId] = UserWordProgressData(
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
                sourceNodeId: existing.sourceNodeId
            )
        } else {
            storage[wordId] = UserWordProgressData(
                wordId: wordId,
                masteryLevel: isCorrect ? 1 : 0,
                needsReview: !isCorrect,
                mistakeCount: isCorrect ? 0 : 1
            )
        }
    }

    public func clearNeedsReview(wordId: Int64) async throws {
        try await markWordReviewed(wordId: wordId, isCorrect: true)
    }

    public func fetchAllProgress() async throws -> [UserWordProgressData] {
        Array(storage.values)
    }

    public func getProgress(wordId: Int64) async throws -> UserWordProgressData? {
        storage[wordId]
    }

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
        storage[wordId] = UserWordProgressData(
            wordId: wordId,
            cefrLevel: cefrLevel,
            masteryLevel: masteryLevel,
            isBookmarked: isBookmarked,
            needsReview: needsReview,
            mistakeCount: mistakeCount,
            sourceDeckId: sourceDeckId,
            sourceNodeId: sourceNodeId
        )
    }
}
