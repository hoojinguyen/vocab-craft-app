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

    func testAppContainerWiresProgressActorToVocabRepo() async throws {
        let appContainer = AppContainer(modelContainer: container)
        let decks = try await appContainer.vocabularyDataSource.fetchTopicDecks()
        XCTAssertFalse(decks.isEmpty)
        XCTAssertNotNil(appContainer.resetUserProgressUseCase)
    }
}

#endif
