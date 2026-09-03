import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class MockInitializeUserRoadmapUseCase: InitializeUserRoadmapUseCaseProtocol, @unchecked Sendable {
    var invokedDeckId: String?
    var invokedCefrLevel: String?
    var invokedDailyGoalCount: Int?
    var invokedNotificationTimeInterval: Double?

    func execute(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    ) async throws -> RoadmapInitializationResult {
        invokedDeckId = deckId
        invokedCefrLevel = cefrLevel
        invokedDailyGoalCount = dailyGoalCount
        invokedNotificationTimeInterval = notificationTimeInterval

        return RoadmapInitializationResult(
            startingStage: SubTopicStageDTO(
                id: "stage_test",
                deckId: deckId,
                title: "Test Stage",
                iconName: "star",
                sortOrder: 1
            ),
            starterWords: [
                TopicWordDTO(id: 1, stageId: "stage_test", lemma: "Hello", phonetic: "/həˈloʊ/", pos: "noun", cefrLevel: "A1", definitionVi: "Xin chào", definitionEn: "Used as a greeting", exampleEn: "Hello world", exampleVi: "Xin chào thế giới"),
                TopicWordDTO(id: 2, stageId: "stage_test", lemma: "World", phonetic: "/wɜːrld/", pos: "noun", cefrLevel: "A1", definitionVi: "Thế giới", definitionEn: "The earth with its countries", exampleEn: "Around the world", exampleVi: "Khắp thế giới"),
                TopicWordDTO(id: 3, stageId: "stage_test", lemma: "Craft", phonetic: "/kræft/", pos: "noun", cefrLevel: "B1", definitionVi: "Kỹ nghệ", definitionEn: "An activity involving skill", exampleEn: "Learn the craft", exampleVi: "Học kỹ nghệ")
            ]
        )
    }
}

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "has_completed_onboarding")
        defaults.removeObject(forKey: "selected_goal_deck_id")
        defaults.removeObject(forKey: "assessed_cefr_level")
        defaults.removeObject(forKey: "daily_goal_count")
        defaults.removeObject(forKey: "notification_time_interval")
    }

    func testInitialStateAndStepProgression() {
        let settings = UserSettingsStore()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        XCTAssertEqual(vm.currentStep, .goal)
        XCTAssertFalse(vm.canGoBack)
        XCTAssertTrue(vm.canContinue) // Default goal is selected

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .proficiency)
        XCTAssertTrue(vm.canGoBack)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .habit)

        vm.nextStep()
        XCTAssertEqual(vm.currentStep, .roadmapReveal)

        vm.previousStep()
        XCTAssertEqual(vm.currentStep, .habit)
        vm.synthesisTask?.cancel()
    }

    func testSkipSetsDefaultsAndCompletes() {
        let settings = UserSettingsStore()
        settings.hasCompletedOnboarding = false
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        vm.skipOnboarding()

        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertEqual(settings.selectedGoalDeckId, "deck_daily")
        XCTAssertEqual(settings.assessedCefrLevel, "A1")
        XCTAssertEqual(settings.dailyGoalCount, 10)
    }

    func testGenerateRoadmapPopulatesResult() async {
        let settings = UserSettingsStore()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        vm.selectedDeckId = "deck_business"
        vm.selectedCefrLevel = "B1"
        vm.selectedDailyWords = 15

        await vm.synthesizeRoadmap()

        XCTAssertNotNil(vm.roadmapResult)
        XCTAssertEqual(vm.roadmapResult?.starterWords.count, 3)
    }

    func testRetrySynthesisCancelsOldTaskAndStartsNewTask() {
        let settings = UserSettingsStore()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        vm.retrySynthesis()
        let task1 = vm.synthesisTask
        XCTAssertNotNil(task1)

        vm.retrySynthesis()
        let task2 = vm.synthesisTask
        XCTAssertNotNil(task2)
        XCTAssertTrue(task1?.isCancelled == true)

        vm.previousStep()
        XCTAssertNil(vm.synthesisTask)
        XCTAssertTrue(task2?.isCancelled == true)
    }
}
