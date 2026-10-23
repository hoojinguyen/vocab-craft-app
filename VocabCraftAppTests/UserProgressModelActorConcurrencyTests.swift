import Foundation
#if canImport(SwiftDataMacros) || canImport(SwiftData)
import SwiftData
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class UserProgressModelActorConcurrencyTests: XCTestCase {
    var container: ModelContainer!
    var actor: UserProgressModelActor!

    override func setUp() async throws {
        let schema = Schema([UserWordProgress.self, ReflexSessionLog.self, WidgetCurrentState.self, QuickReflexAttemptRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        actor = UserProgressModelActor(modelContainer: container)
    }

    func testActorReturnsSendableValueType() async throws {
        try await actor.saveProgress(wordId: 42, cefrLevel: "B2", masteryLevel: 3)
        let data = try await actor.getProgressData(wordId: 42)
        XCTAssertNotNil(data)
        XCTAssertEqual(data?.wordId, 42)
        XCTAssertEqual(data?.cefrLevel, "B2")
        XCTAssertEqual(data?.masteryLevel, 3)
    }

    func testFetchAllProgressData() async throws {
        try await actor.saveProgress(wordId: 10, cefrLevel: "A1", masteryLevel: 1)
        try await actor.saveProgress(wordId: 20, cefrLevel: "B1", masteryLevel: 2)

        let allData = try await actor.fetchAllProgressData()
        XCTAssertEqual(allData.count, 2)
        XCTAssertTrue(allData.contains { $0.wordId == 10 && $0.masteryLevel == 1 })
        XCTAssertTrue(allData.contains { $0.wordId == 20 && $0.masteryLevel == 2 })
    }

    func testResetAllProgressClearsData() async throws {
        try await actor.saveProgress(wordId: 42, masteryLevel: 4)
        let levelsBefore = try await actor.fetchAllMasteryLevels()
        XCTAssertEqual(levelsBefore[42], 4)

        try await actor.resetAllProgress()
        let levelsAfter = try await actor.fetchAllMasteryLevels()
        XCTAssertTrue(levelsAfter.isEmpty)
    }

    func testRecordBatchLessonResultsPersistsAllWordsInSingleTransaction() async throws {
        let practicedIds: [Int64] = [1001, 1002, 1003]
        let weakIds: Set<Int64> = [1002]

        try await actor.recordBatchLessonResults(
            practicedWordIds: practicedIds,
            weakWordIds: weakIds,
            stageId: "stage_test",
            deckId: "deck_test"
        )

        let w1001 = try await actor.getProgressData(wordId: 1001)
        XCTAssertNotNil(w1001)
        XCTAssertEqual(w1001?.masteryLevel, 1)
        XCTAssertEqual(w1001?.needsReview, false)
        XCTAssertEqual(w1001?.mistakeCount, 0)
        XCTAssertEqual(w1001?.consecutiveCorrectStreak, 1)

        let w1002 = try await actor.getProgressData(wordId: 1002)
        XCTAssertNotNil(w1002)
        XCTAssertEqual(w1002?.masteryLevel, 0)
        XCTAssertEqual(w1002?.needsReview, true)
        XCTAssertEqual(w1002?.mistakeCount, 1)
        XCTAssertEqual(w1002?.consecutiveCorrectStreak, 0)
        XCTAssertEqual(w1002?.intervalDays, 1)

        let w1003 = try await actor.getProgressData(wordId: 1003)
        XCTAssertNotNil(w1003)
        XCTAssertEqual(w1003?.masteryLevel, 1)
        XCTAssertEqual(w1003?.needsReview, false)

        // Second pass: correct repetition of 1001 increments mastery and streak
        try await actor.recordBatchLessonResults(
            practicedWordIds: [1001],
            weakWordIds: [],
            stageId: "stage_test",
            deckId: "deck_test"
        )

        let updated1001 = try await actor.getProgressData(wordId: 1001)
        XCTAssertEqual(updated1001?.masteryLevel, 2)
        XCTAssertEqual(updated1001?.consecutiveCorrectStreak, 2)
        XCTAssertEqual(updated1001?.needsReview, false)
    }

    func testRecordBatchLessonResultsDefensiveUnionPersistsDisjointWeakWords() async throws {
        // Mismatched caller arguments: 2002 is marked weak but omitted from practicedWordIds
        let practicedIds: [Int64] = [2001]
        let weakIds: Set<Int64> = [2002]

        try await actor.recordBatchLessonResults(
            practicedWordIds: practicedIds,
            weakWordIds: weakIds,
            stageId: "stage_test",
            deckId: "deck_test"
        )

        let w2001 = try await actor.getProgressData(wordId: 2001)
        XCTAssertNotNil(w2001)
        XCTAssertEqual(w2001?.masteryLevel, 1)
        XCTAssertEqual(w2001?.needsReview, false)

        let w2002 = try await actor.getProgressData(wordId: 2002)
        XCTAssertNotNil(w2002)
        XCTAssertEqual(w2002?.masteryLevel, 0)
        XCTAssertEqual(w2002?.needsReview, true)
        XCTAssertEqual(w2002?.mistakeCount, 1)
    }

    func testSRSRepositoryResetAllProgressClearsData() async throws {
        let srsRepo = SRSRepositoryImpl(modelContext: container.mainContext)
        let item = SRSProgressItem(wordId: 99, masteryLevel: 4)
        try await srsRepo.saveProgress(item)

        let loaded = try await srsRepo.getProgress(wordId: 99)
        XCTAssertNotNil(loaded)

        try await srsRepo.resetAllProgress()
        let afterReset = try await srsRepo.getProgress(wordId: 99)
        XCTAssertNil(afterReset)
    }

    func testResetUserProgressUseCaseExecutesRepositoryReset() async throws {
        let mockRepo = MockSRSRepository()
        let useCase = ResetUserProgressUseCase(srsRepository: mockRepo)
        XCTAssertFalse(mockRepo.resetAllProgressCalled)

        try await useCase.executeResetAllProgress()
        XCTAssertTrue(mockRepo.resetAllProgressCalled)
    }

    func testMarkWordReviewedCorrectReschedulesDueWord() async throws {
        let now = Date()
        let past = now.addingTimeInterval(-3 * 86_400)
        try await actor.saveProgress(wordId: 60, masteryLevel: 2, nextReviewDate: past, easeFactor: 2.5, intervalDays: 1)

        try await actor.markWordReviewed(wordId: 60, isCorrect: true)

        let expected = SRSEngine.calculateNextInterval(
            currentMastery: 2,
            easeFactor: 2.5,
            isCorrect: true,
            responseTimeMs: SmartReviewScheduling.responseTimeMs
        )
        let row = try await actor.getProgressData(wordId: 60)
        XCTAssertEqual(row?.masteryLevel, 3)
        XCTAssertEqual(row?.needsReview, false)
        XCTAssertEqual(row?.intervalDays, expected.intervalDays)
        XCTAssertEqual(row?.easeFactor, expected.easeFactor)
        XCTAssertGreaterThan(row?.nextReviewDate ?? past, now)
    }

    func testMarkWordReviewedIncorrectSchedulesTomorrow() async throws {
        let before = Date()
        try await actor.saveProgress(wordId: 61, masteryLevel: 3, nextReviewDate: before.addingTimeInterval(-86_400), intervalDays: 6)

        try await actor.markWordReviewed(wordId: 61, isCorrect: false)

        let row = try await actor.getProgressData(wordId: 61)
        XCTAssertEqual(row?.needsReview, true)
        XCTAssertEqual(row?.mistakeCount, 1)
        XCTAssertEqual(row?.intervalDays, 1)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: before) ?? before
        let delta = abs((row?.nextReviewDate ?? .distantPast).timeIntervalSince(tomorrow))
        XCTAssertLessThan(delta, 60)
    }

    func testMarkWordReviewedWithoutRowInsertsScheduledProgress() async throws {
        let before = Date()
        try await actor.markWordReviewed(wordId: 62, isCorrect: true)

        let row = try await actor.getProgressData(wordId: 62)
        XCTAssertEqual(row?.masteryLevel, 1)
        XCTAssertEqual(row?.totalReviews, 1)
        XCTAssertEqual(row?.intervalDays, 1)
        XCTAssertGreaterThan(row?.nextReviewDate ?? before, before)
    }

    func testClearNeedsReviewDoesNotChangeSchedule() async throws {
        let scheduled = Date().addingTimeInterval(5 * 86_400)
        try await actor.saveProgress(wordId: 63, masteryLevel: 2, nextReviewDate: scheduled, easeFactor: 2.1, intervalDays: 5)

        try await actor.clearNeedsReview(wordId: 63)

        let row = try await actor.getProgressData(wordId: 63)
        XCTAssertEqual(row?.masteryLevel, 3)
        XCTAssertEqual(row?.intervalDays, 5)
        XCTAssertEqual(row?.easeFactor, 2.1)
        XCTAssertEqual(row?.nextReviewDate, scheduled)
    }

    func testReviewedWordIsNoLongerDueAfterGrading() async throws {
        let now = Date()
        try await actor.saveProgress(wordId: 1, masteryLevel: 2, nextReviewDate: now.addingTimeInterval(-86_400))
        let useCase = ReviewWeakWordsUseCase(dataSource: BundledVocabularyDataSource(), progressRepo: actor)

        let dueBefore = try await useCase.fetchDueWords(now: now)
        XCTAssertEqual(dueBefore.map(\.id), [1])

        try await useCase.markWordReviewed(wordId: 1, isCorrect: true)

        let dueAfter = try await useCase.fetchDueWords(now: now)
        XCTAssertTrue(dueAfter.isEmpty)
    }

    func testAppContainerWiresProgressActorToVocabRepo() async throws {
        let appContainer = AppContainer(modelContainer: container)
        let decks = try await appContainer.vocabularyDataSource.fetchTopicDecks()
        XCTAssertFalse(decks.isEmpty)
        XCTAssertNotNil(appContainer.resetUserProgressUseCase)
    }
}

#endif
