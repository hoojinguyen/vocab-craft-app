@testable import VocabCraftApp
import XCTest

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

    func test_fetchTopicDecksUseCase_returnsDecksWithCalculatedWordCounts() async throws {
        let sut = FetchTopicDecksUseCase(dataSource: dataSource, stageRepo: stageRepo)
        let decks = try await sut.execute()
        XCTAssertEqual(decks.count, 4)
        XCTAssertGreaterThan(decks.first?.totalWords ?? 0, 0)
    }

    func test_fetchDeckRoadmapUseCase_unlocksFirstStageByDefault() async throws {
        let sut = FetchDeckRoadmapUseCase(dataSource: dataSource, stageRepo: stageRepo)
        let stages = try await sut.execute(deckId: "deck_daily")
        XCTAssertEqual(stages.count, 2)
        XCTAssertEqual(stages.first?.state, .active)
        XCTAssertEqual(stages.last?.state, .locked)
    }

    func test_completeStageChallengeUseCase_flagsIncorrectWordsAndUnlocksNext() async throws {
        let sut = CompleteStageChallengeUseCase(stageRepo: stageRepo, progressRepo: MockUserProgressActor())
        let results = [
            WordChallengeResult(wordId: 1, isCorrect: true, timeTakenMs: 1200),
            WordChallengeResult(wordId: 2, isCorrect: false, timeTakenMs: 3000)
        ]
        let summary = try await sut.execute(stageId: "stage_daily_1", deckId: "deck_daily", results: results)
        XCTAssertEqual(summary.correctCount, 1)
        XCTAssertEqual(summary.weakWordIds, [2])
        XCTAssertEqual(summary.xpEarned, 10)
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
