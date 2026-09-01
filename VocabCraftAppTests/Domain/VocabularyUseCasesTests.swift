import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class MockUserProgressActor: UserProgressRepositoryProtocol, @unchecked Sendable {
    private var storage: [Int64: UserWordProgressData] = [:]

    init(initialData: [UserWordProgressData] = []) {
        for item in initialData {
            storage[item.wordId] = item
        }
    }

    func recordChallengeResult(wordId: Int64, isCorrect: Bool, stageId: String?, deckId: String?) async throws {
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

    func toggleBookmark(wordId: Int64) async throws -> Bool {
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

    func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws {
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

    func clearNeedsReview(wordId: Int64) async throws {
        try await markWordReviewed(wordId: wordId, isCorrect: true)
    }

    func fetchAllProgress() async throws -> [UserWordProgressData] {
        Array(storage.values)
    }

    func getProgress(wordId: Int64) async throws -> UserWordProgressData? {
        storage[wordId]
    }

    func recordDrillResult(
        wordId: Int64,
        isCorrect: Bool,
        newStreak: Int,
        newModes: Set<ReflexBlitzMode>,
        isMastered: Bool,
        modeStats: ModeSuccessStats? = nil
    ) async throws {
        if let existing = storage[wordId] {
            storage[wordId] = UserWordProgressData(
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
            storage[wordId] = UserWordProgressData(
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

    func saveProgress(
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

final class VocabularyUseCasesTests: XCTestCase {
    var dataSource: SampleVocabularyDataSource!
    var stageRepo: StageProgressRepositoryImpl!

    override func setUp() {
        super.setUp()
        dataSource = SampleVocabularyDataSource()
        stageRepo = StageProgressRepositoryImpl(modelContext: nil)
    }

    func test_fetchPersonalVaultUseCase_filtersByTabAndComputesMetrics() async throws {
        let progressRepo = MockUserProgressActor(initialData: [
            UserWordProgressData(wordId: 1, masteryLevel: 4, isBookmarked: false, needsReview: false, mistakeCount: 0),
            UserWordProgressData(wordId: 2, masteryLevel: 1, isBookmarked: true, needsReview: true, mistakeCount: 2),
            UserWordProgressData(wordId: 3, masteryLevel: 5, isBookmarked: true, needsReview: false, mistakeCount: 0)
        ])
        let sut = FetchPersonalVaultUseCase(dataSource: dataSource, progressRepo: progressRepo)

        let allResult = try await sut.execute(filter: .all, searchQuery: nil)
        XCTAssertEqual(allResult.words.count, 3)
        XCTAssertEqual(allResult.metrics.totalWords, 3)
        XCTAssertEqual(allResult.metrics.needsReviewCount, 1)
        XCTAssertEqual(allResult.metrics.masteredCount, 2)
        XCTAssertEqual(allResult.metrics.bookmarkedCount, 2)

        let weakResult = try await sut.execute(filter: .needsReview, searchQuery: nil)
        XCTAssertEqual(weakResult.words.count, 1)
        XCTAssertEqual(weakResult.words.first?.id, 2)

        let masteredResult = try await sut.execute(filter: .mastered, searchQuery: nil)
        XCTAssertEqual(masteredResult.words.count, 2)

        let bookmarkedResult = try await sut.execute(filter: .bookmarked, searchQuery: nil)
        XCTAssertEqual(bookmarkedResult.words.count, 2)

        let searchResult = try await sut.execute(filter: .all, searchQuery: "Resilience")
        XCTAssertEqual(searchResult.words.count, 1)
        XCTAssertEqual(searchResult.words.first?.lemma, "Resilience")
    }

    func test_fetchPersonalVaultUseCase_fetchVaultWords_filtersByTabAndQuery() async throws {
        let progressRepo = MockUserProgressActor(initialData: [
            UserWordProgressData(wordId: 1, masteryLevel: 5, isBookmarked: false, isMastered: true),
            UserWordProgressData(wordId: 2, masteryLevel: 1, isBookmarked: true, isMastered: false),
            UserWordProgressData(wordId: 3, masteryLevel: 4, isBookmarked: true, isMastered: true)
        ])
        let sut = FetchPersonalVaultUseCase(dataSource: dataSource, progressRepo: progressRepo)

        let notMastered = try await sut.fetchVaultWords(filter: .notMastered, searchQuery: nil)
        XCTAssertEqual(notMastered.count, 1)
        XCTAssertEqual(notMastered.first?.id, 2)

        let mastered = try await sut.fetchVaultWords(filter: .mastered, searchQuery: nil)
        XCTAssertEqual(mastered.count, 2)

        let bookmarked = try await sut.fetchVaultWords(filter: .bookmarked, searchQuery: nil)
        XCTAssertEqual(bookmarked.count, 2)

        let searchResult = try await sut.fetchVaultWords(filter: .mastered, searchQuery: "Resilience")
        XCTAssertEqual(searchResult.count, 1)
        XCTAssertEqual(searchResult.first?.lemma, "Resilience")
    }

    func test_fetchPersonalVaultUseCase_skipsNonExistentWordsGracefully() async throws {
        let progressRepo = MockUserProgressActor(initialData: [
            UserWordProgressData(wordId: 1, masteryLevel: 4),
            UserWordProgressData(wordId: 999999, masteryLevel: 4)
        ])
        let sut = FetchPersonalVaultUseCase(dataSource: dataSource, progressRepo: progressRepo)

        let result = try await sut.execute(filter: .all, searchQuery: nil)
        XCTAssertEqual(result.words.count, 1)
        XCTAssertEqual(result.words.first?.id, 1)
        XCTAssertEqual(result.metrics.totalWords, 1)

        let vaultWords = try await sut.fetchVaultWords(filter: .mastered, searchQuery: nil)
        XCTAssertEqual(vaultWords.count, 1)
        XCTAssertEqual(vaultWords.first?.id, 1)
    }

    func test_reviewWeakWordsUseCase_skipsNonExistentWordsGracefully() async throws {
        let progressRepo = MockUserProgressActor(initialData: [
            UserWordProgressData(wordId: 999999, masteryLevel: 1, needsReview: true)
        ])
        let sut = ReviewWeakWordsUseCase(dataSource: dataSource, progressRepo: progressRepo)

        let weakWords = try await sut.fetchWeakWords()
        XCTAssertTrue(weakWords.isEmpty)
    }

    func test_reviewWeakWordsUseCase_fetchesWeakWordsAndClearsFlag() async throws {
        let progressRepo = MockUserProgressActor(initialData: [
            UserWordProgressData(wordId: 2, masteryLevel: 1, isBookmarked: false, needsReview: true, mistakeCount: 1)
        ])
        let sut = ReviewWeakWordsUseCase(dataSource: dataSource, progressRepo: progressRepo)

        let weakWords = try await sut.fetchWeakWords()
        XCTAssertEqual(weakWords.count, 1)
        XCTAssertEqual(weakWords.first?.id, 2)

        try await sut.markWordReviewed(wordId: 2, isCorrect: true)

        let updatedWeakWords = try await sut.fetchWeakWords()
        XCTAssertEqual(updatedWeakWords.count, 0)

        let updatedProgress = try await progressRepo.getProgress(wordId: 2)
        XCTAssertEqual(updatedProgress?.needsReview, false)
        XCTAssertEqual(updatedProgress?.masteryLevel, 2)
    }

    func test_toggleWordBookmarkUseCase_updatesBookmarkFlag() async throws {
        let progressRepo = MockUserProgressActor(initialData: [
            UserWordProgressData(wordId: 1, masteryLevel: 2, isBookmarked: false)
        ])
        let sut = ToggleWordBookmarkUseCase(progressRepo: progressRepo)

        let state1 = try await sut.execute(wordId: 1)
        XCTAssertTrue(state1)

        let state2 = try await sut.execute(wordId: 1)
        XCTAssertFalse(state2)
    }
}
