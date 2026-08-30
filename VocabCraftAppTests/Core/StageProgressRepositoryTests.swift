#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

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
        XCTAssertEqual(progress!.progressFraction, 1.0, accuracy: 0.001)
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
        XCTAssertEqual(initial!.progressFraction, 0.0, accuracy: 0.001)

        try await sut.saveStageProgress(stageId: "stage_daily_2", deckId: "deck_daily", isCompleted: true, score: 95)
        let updated = try await sut.fetchStageProgress(stageId: "stage_daily_2")
        XCTAssertNotNil(updated)
        XCTAssertTrue(updated!.isCompleted)
        XCTAssertEqual(updated!.score, 95)
        XCTAssertEqual(updated!.progressFraction, 1.0, accuracy: 0.001)
    }

    @MainActor
    func test_saveStageProgress_withExplicitProgressFraction_persistsFraction() async throws {
        try await sut.saveStageProgress(
            stageId: "stage_daily_fraction",
            deckId: "deck_daily",
            isCompleted: false,
            score: 40,
            progressFraction: 0.5
        )
        let progress = try await sut.fetchStageProgress(stageId: "stage_daily_fraction")
        XCTAssertNotNil(progress)
        XCTAssertFalse(progress!.isCompleted)
        XCTAssertEqual(progress!.score, 40)
        XCTAssertEqual(progress!.progressFraction, 0.5, accuracy: 0.001)

        // Update with completed fraction
        try await sut.saveStageProgress(
            stageId: "stage_daily_fraction",
            deckId: "deck_daily",
            isCompleted: true,
            score: 100,
            progressFraction: 1.0
        )
        let updated = try await sut.fetchStageProgress(stageId: "stage_daily_fraction")
        XCTAssertNotNil(updated)
        XCTAssertTrue(updated!.isCompleted)
        XCTAssertEqual(updated!.score, 100)
        XCTAssertEqual(updated!.progressFraction, 1.0, accuracy: 0.001)
    }

    @MainActor
    func test_fetchAllStageProgress_returnsAllPersistedStages() async throws {
        let initial = try await sut.fetchAllStageProgress()
        XCTAssertTrue(initial.isEmpty)

        try await sut.saveStageProgress(
            stageId: "stage_1",
            deckId: "deck_a",
            isCompleted: true,
            score: 100,
            progressFraction: 1.0
        )
        try await sut.saveStageProgress(
            stageId: "stage_2",
            deckId: "deck_a",
            isCompleted: false,
            score: 50,
            progressFraction: 0.5
        )
        try await sut.saveStageProgress(
            stageId: "stage_3",
            deckId: "deck_b",
            isCompleted: false,
            score: 0,
            progressFraction: 0.0
        )

        let all = try await sut.fetchAllStageProgress()
        XCTAssertEqual(all.count, 3)
        let ids = Set(all.map(\.stageId))
        XCTAssertEqual(ids, ["stage_1", "stage_2", "stage_3"])
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

        let allProgress = try await nilSut.fetchAllStageProgress()
        XCTAssertTrue(allProgress.isEmpty)

        // Should not throw or crash
        try await nilSut.saveStageProgress(stageId: "stage_1", deckId: "deck_1", isCompleted: true, score: 100)
        try await nilSut.saveStageProgress(
            stageId: "stage_1",
            deckId: "deck_1",
            isCompleted: true,
            score: 100,
            progressFraction: 1.0
        )
    }

    @MainActor
    func test_mockStageProgressRepository_savesAndFetchesWithProgressFraction() async throws {
        let mockRepo = MockStageProgressRepository()

        let emptyAll = try await mockRepo.fetchAllStageProgress()
        XCTAssertTrue(emptyAll.isEmpty)

        try await mockRepo.saveStageProgress(
            stageId: "mock_stage_1",
            deckId: "mock_deck",
            isCompleted: false,
            score: 60,
            progressFraction: 0.6
        )

        let progress = try await mockRepo.fetchStageProgress(stageId: "mock_stage_1")
        XCTAssertNotNil(progress)
        XCTAssertFalse(progress!.isCompleted)
        XCTAssertEqual(progress!.score, 60)
        XCTAssertEqual(progress!.progressFraction, 0.6, accuracy: 0.001)

        // Update
        try await mockRepo.saveStageProgress(
            stageId: "mock_stage_1",
            deckId: "mock_deck",
            isCompleted: true,
            score: 100,
            progressFraction: 1.0
        )
        let updated = try await mockRepo.fetchStageProgress(stageId: "mock_stage_1")
        XCTAssertNotNil(updated)
        XCTAssertTrue(updated!.isCompleted)
        XCTAssertEqual(updated!.progressFraction, 1.0, accuracy: 0.001)

        let completedIds = try await mockRepo.fetchCompletedStageIds(deckId: "mock_deck")
        XCTAssertEqual(completedIds, ["mock_stage_1"])

        let all = try await mockRepo.fetchAllStageProgress()
        XCTAssertEqual(all.count, 1)
    }
}

#endif
