import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class InitializeUserRoadmapUseCaseTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "has_completed_onboarding")
        UserDefaults.standard.removeObject(forKey: "selected_goal_deck_id")
        UserDefaults.standard.removeObject(forKey: "assessed_cefr_level")
        UserDefaults.standard.removeObject(forKey: "daily_goal_count")
        UserDefaults.standard.removeObject(forKey: "notification_time_interval")
    }

    @MainActor
    func testInitializeRoadmapForBeginnerA1() async throws {
        let dataSource = SampleVocabularyDataSource()
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore()

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: dataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        let result = try await useCase.execute(
            deckId: "deck_daily",
            cefrLevel: "A1",
            dailyGoalCount: 10,
            notificationTimeInterval: 72000
        )

        XCTAssertEqual(settings.selectedGoalDeckId, "deck_daily")
        XCTAssertEqual(settings.assessedCefrLevel, "A1")
        XCTAssertEqual(settings.dailyGoalCount, 10)
        XCTAssertEqual(settings.notificationTimeInterval, 72000)

        // Stage 1 of deck_daily should be the starting stage
        XCTAssertEqual(result.startingStage.id, "stage_daily_1")
        XCTAssertEqual(result.starterWords.count, 3)

        // No stages should be marked completed for A1
        let allProgress = try await stageRepo.fetchAllStageProgress()
        XCTAssertTrue(allProgress.isEmpty || allProgress.allSatisfy { !$0.isCompleted })
    }

    @MainActor
    func testInitializeRoadmapForIntermediateB1AutoUnlocksFoundationalStage() async throws {
        let dataSource = SampleVocabularyDataSource()
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore()

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: dataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        let result = try await useCase.execute(
            deckId: "deck_daily",
            cefrLevel: "B1",
            dailyGoalCount: 15,
            notificationTimeInterval: 28800
        )

        // Preceding stage (stage_daily_1) should be marked completed
        let progressList = try await stageRepo.fetchAllStageProgress()
        let completedStage = progressList.first { $0.stageId == "stage_daily_1" }
        XCTAssertNotNil(completedStage)
        XCTAssertTrue(completedStage?.isCompleted == true)
        XCTAssertEqual(completedStage?.progressFraction, 1.0)

        // Starting stage is stage_daily_2
        XCTAssertEqual(result.startingStage.id, "stage_daily_2")
        XCTAssertEqual(result.starterWords.count, 3)
    }
}
