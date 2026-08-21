import XCTest
import SwiftData
@testable import VocabCraftApp

final class StageProgressRepositoryTests: XCTestCase {
    var container: ModelContainer!
    var sut: StageProgressRepositoryImpl!

    @MainActor
    override func setUp() {
        super.setUp()
        let schema = Schema([UserWordProgress.self, UserStageProgress.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        sut = StageProgressRepositoryImpl(modelContext: container.mainContext)
    }

    @MainActor
    func test_markStageCompleted_persistsAndReturnsCompletedState() async throws {
        try await sut.saveStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 90)
        let progress = try await sut.fetchStageProgress(stageId: "stage_daily_1")
        XCTAssertNotNil(progress)
        XCTAssertTrue(progress!.isCompleted)
        XCTAssertEqual(progress!.score, 90)
    }

    @MainActor
    func test_fetchCompletedStageIds_returnsCorrectIdsForDeck() async throws {
        try await sut.saveStageProgress(stageId: "stage_daily_1", deckId: "deck_daily", isCompleted: true, score: 100)
        let ids = try await sut.fetchCompletedStageIds(deckId: "deck_daily")
        XCTAssertEqual(ids, ["stage_daily_1"])
    }

    @MainActor
    func test_fetchStageProgress_returnsNilWhenNotFound() async throws {
        let progress = try await sut.fetchStageProgress(stageId: "non_existent_stage")
        XCTAssertNil(progress)
    }

    @MainActor
    func test_saveStageProgress_updatesExistingProgress() async throws {
        try await sut.saveStageProgress(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: false, score: 50)
        let initial = try await sut.fetchStageProgress(stageId: "stage_daily_2")
        XCTAssertNotNil(initial)
        XCTAssertFalse(initial!.isCompleted)
        XCTAssertEqual(initial!.score, 50)

        try await sut.saveStageProgress(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 95)
        let updated = try await sut.fetchStageProgress(stageId: "stage_daily_2")
        XCTAssertNotNil(updated)
        XCTAssertTrue(updated!.isCompleted)
        XCTAssertEqual(updated!.score, 95)
    }

    @MainActor
    func test_fetchCompletedStageIds_ignoresIncompleteStages() async throws {
        try await sut.saveStageProgress(stageId: "stage_1", deckId: "deck_travel", isCompleted: true, score: 80)
        try await sut.saveStageProgress(stageId: "stage_2", deckId: "deck_travel", isCompleted: false, score: 40)
        try await sut.saveStageProgress(stageId: "stage_3", deckId: "deck_business", isCompleted: true, score: 100)

        let travelCompletedIds = try await sut.fetchCompletedStageIds(deckId: "deck_travel")
        XCTAssertEqual(travelCompletedIds, ["stage_1"])

        let businessCompletedIds = try await sut.fetchCompletedStageIds(deckId: "deck_business")
        XCTAssertEqual(businessCompletedIds, ["stage_3"])
    }

    @MainActor
    func test_repository_withNilContext_returnsGracefulFallbacks() async throws {
        let nilSut = StageProgressRepositoryImpl(modelContext: nil)
        let progress = try await nilSut.fetchStageProgress(stageId: "stage_1")
        XCTAssertNil(progress)

        let completedIds = try await nilSut.fetchCompletedStageIds(deckId: "deck_1")
        XCTAssertTrue(completedIds.isEmpty)

        // Should not throw or crash
        try await nilSut.saveStageProgress(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 100)
    }
}
