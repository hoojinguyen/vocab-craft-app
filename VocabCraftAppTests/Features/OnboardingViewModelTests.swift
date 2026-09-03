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
    private var testDefaults: UserDefaults!
    private var suiteName: String!

    private func makeSettings() -> UserSettingsStore {
        UserSettingsStore(defaults: testDefaults)
    }

    override func setUp() {
        super.setUp()
        suiteName = "test_onboarding_\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        if let suiteName {
            testDefaults?.removePersistentDomain(forName: suiteName)
        }
        super.tearDown()
    }

    func testInitialStateAndStepProgression() {
        let settings = makeSettings()
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
        let settings = makeSettings()
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
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        vm.selectedDeckId = "deck_business"
        vm.selectedCefrLevel = "B1"
        vm.selectedDailyWords = 15

        await vm.synthesizeRoadmap()

        XCTAssertNotNil(vm.roadmapResult)
        XCTAssertEqual(vm.roadmapResult?.starterWords.count, 3)
        XCTAssertEqual(useCase.invokedDeckId, "deck_business")
        XCTAssertEqual(useCase.invokedCefrLevel, "B1")
        XCTAssertEqual(useCase.invokedDailyGoalCount, 15)
        XCTAssertEqual(useCase.invokedNotificationTimeInterval, vm.selectedReminderInterval)
    }

    func testSynthesizeRoadmapFailureSetsLocalizedErrorMessage() async {
        let settings = makeSettings()
        let failingUseCase = FailingInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: failingUseCase, userSettings: settings)

        await vm.synthesizeRoadmap()

        XCTAssertNil(vm.roadmapResult)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.errorMessage, String(localized: "app.onboarding.reveal.error_generic"))
    }

    func testRetrySynthesisCancelsOldTaskAndStartsNewTask() {
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)
        vm.currentStep = .roadmapReveal

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
        XCTAssertEqual(vm.currentStep, .habit)
    }

    func testReplacedSynthesisTaskDoesNotResetIsSynthesizingPrematurely() async {
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        vm.retrySynthesis()
        XCTAssertTrue(vm.isSynthesizing)

        vm.retrySynthesis()
        XCTAssertTrue(vm.isSynthesizing)

        // Wait for active synthesis task to finish
        await vm.synthesisTask?.value
        XCTAssertFalse(vm.isSynthesizing)
        XCTAssertNotNil(vm.roadmapResult)
    }

    func testUpdateNotificationPermissionTrueSchedulesReminder() async {
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let scheduler = MockNotificationScheduler()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings, notificationScheduler: scheduler)

        vm.selectedReminderInterval = 45000
        vm.updateNotificationPermission(granted: true)
        await vm.notificationTask?.value

        XCTAssertTrue(settings.isNotificationEnabled)
        XCTAssertEqual(scheduler.scheduledInterval, 45000)
    }

    func testUpdateNotificationPermissionFalseCancelsReminder() async {
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let scheduler = MockNotificationScheduler()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings, notificationScheduler: scheduler)

        vm.updateNotificationPermission(granted: false)
        await vm.notificationTask?.value

        XCTAssertFalse(settings.isNotificationEnabled)
        XCTAssertTrue(scheduler.didCancel)
    }

    func testSkipOnboardingDisablesNotificationWhenPermissionNotGranted() async {
        let settings = makeSettings()
        settings.hasCompletedOnboarding = false
        settings.isNotificationEnabled = true
        let useCase = MockInitializeUserRoadmapUseCase()
        let scheduler = MockNotificationScheduler()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings, notificationScheduler: scheduler)

        vm.skipOnboarding()
        await vm.notificationTask?.value

        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertFalse(settings.isNotificationEnabled)
        XCTAssertTrue(scheduler.didCancel)
    }

    func testSkipOnboardingReschedulesNotificationToDefaultTimeWhenPermissionGranted() async {
        let settings = makeSettings()
        settings.hasCompletedOnboarding = false
        let useCase = MockInitializeUserRoadmapUseCase()
        let scheduler = MockNotificationScheduler()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings, notificationScheduler: scheduler)

        vm.updateNotificationPermission(granted: true)
        await vm.notificationTask?.value

        vm.skipOnboarding()
        await vm.notificationTask?.value

        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertTrue(settings.isNotificationEnabled)
        XCTAssertEqual(settings.notificationTimeInterval, 72000)
        XCTAssertEqual(scheduler.scheduledInterval, 72000)
    }

    func testRapidNotificationPermissionTogglesSerializeDeterministically() async {
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let scheduler = MockNotificationScheduler()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings, notificationScheduler: scheduler)

        vm.selectedReminderInterval = 28800
        vm.updateNotificationPermission(granted: true)
        vm.updateNotificationPermission(granted: false)
        vm.updateNotificationPermission(granted: true)

        await vm.notificationTask?.value

        XCTAssertTrue(settings.isNotificationEnabled)
        XCTAssertEqual(scheduler.scheduledInterval, 28800)
    }

    func testLateNotificationPermissionCallbackAfterSkipIsIgnored() async {
        let settings = makeSettings()
        settings.hasCompletedOnboarding = false
        let useCase = MockInitializeUserRoadmapUseCase()
        let scheduler = MockNotificationScheduler()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings, notificationScheduler: scheduler)

        vm.skipOnboarding()
        await vm.notificationTask?.value
        XCTAssertFalse(settings.isNotificationEnabled)

        // Late callback from async system dialog after skip
        vm.updateNotificationPermission(granted: true)
        await vm.notificationTask?.value

        XCTAssertFalse(settings.isNotificationEnabled)
        XCTAssertFalse(vm.hasGrantedNotificationPermission)
    }

    func testImmediatePreviousStepCancelsSynthesisWithoutLeavingIsSynthesizingTrue() async {
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings)

        vm.currentStep = .habit
        vm.nextStep()
        vm.previousStep()

        await vm.synthesisTask?.value
        XCTAssertEqual(vm.currentStep, .habit)
        XCTAssertFalse(vm.isSynthesizing)
        XCTAssertNil(vm.roadmapResult)
    }

    func testSynthesizeRoadmapSchedulesReminderWhenNotificationEnabled() async {
        let settings = makeSettings()
        settings.isNotificationEnabled = true
        let useCase = MockInitializeUserRoadmapUseCase()
        let scheduler = MockNotificationScheduler()
        let vm = OnboardingViewModel(useCase: useCase, userSettings: settings, notificationScheduler: scheduler)

        vm.selectedReminderInterval = 36000
        await vm.synthesizeRoadmap()

        XCTAssertEqual(scheduler.scheduledInterval, 36000)
    }

    func testCompleteOnboardingAndDismissPersistsStarterWordsAndStageProgress() async {
        let settings = makeSettings()
        settings.hasCompletedOnboarding = false
        settings.currentStreak = 0
        let useCase = MockInitializeUserRoadmapUseCase()
        let progressRepo = MockUserProgressRepository()
        let stageRepo = MockStageProgressRepository()
        let vm = OnboardingViewModel(
            useCase: useCase,
            userSettings: settings,
            progressRepo: progressRepo,
            stageRepo: stageRepo
        )

        await vm.synthesizeRoadmap()
        XCTAssertNotNil(vm.roadmapResult)

        vm.completeOnboardingAndDismiss()
        await vm.completionTask?.value

        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertEqual(settings.currentStreak, 1)
        XCTAssertEqual(progressRepo.recordChallengeCallCount, 3)
        XCTAssertGreaterThanOrEqual(stageRepo.saveCallCount, 1)

        let savedStage = try? await stageRepo.fetchStageProgress(stageId: vm.roadmapResult!.startingStage.id)
        XCTAssertNotNil(savedStage)
        XCTAssertEqual(savedStage?.score, 3)
    }

    func testSkipOnboardingDoesNotPersistProgressOrAdvanceStreak() async {
        let settings = makeSettings()
        settings.hasCompletedOnboarding = false
        settings.currentStreak = 0
        let useCase = MockInitializeUserRoadmapUseCase()
        let progressRepo = MockUserProgressRepository()
        let stageRepo = MockStageProgressRepository()
        let vm = OnboardingViewModel(
            useCase: useCase,
            userSettings: settings,
            progressRepo: progressRepo,
            stageRepo: stageRepo
        )

        vm.skipOnboarding()
        await vm.completionTask?.value

        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertEqual(settings.currentStreak, 0)
        XCTAssertEqual(progressRepo.recordChallengeCallCount, 0)
        XCTAssertEqual(stageRepo.saveCallCount, 0)
    }

    func testCompleteOnboardingAndDismissAbortsStageSaveWhenFetchFails() async {
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let progressRepo = MockUserProgressRepository()
        let throwingStageRepo = ThrowingFetchStageProgressRepository()
        let vm = OnboardingViewModel(
            useCase: useCase,
            userSettings: settings,
            progressRepo: progressRepo,
            stageRepo: throwingStageRepo
        )

        await vm.synthesizeRoadmap()
        vm.startFirstLesson()
        XCTAssertTrue(vm.isPresentingMiniLesson)

        vm.completeOnboardingAndDismiss()
        await vm.completionTask?.value

        XCTAssertFalse(settings.hasCompletedOnboarding)
        XCTAssertEqual(settings.currentStreak, 0)
        XCTAssertFalse(vm.isPresentingMiniLesson)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(progressRepo.recordChallengeCallCount, 3)
        XCTAssertEqual(throwingStageRepo.saveCallCount, 0)
    }

    func testCompleteOnboardingRetryDoesNotDuplicateWordProgress() async {
        let settings = makeSettings()
        let useCase = MockInitializeUserRoadmapUseCase()
        let progressRepo = MockUserProgressRepository()
        let flakyStageRepo = FlakyStageProgressRepository()
        let vm = OnboardingViewModel(
            useCase: useCase,
            userSettings: settings,
            progressRepo: progressRepo,
            stageRepo: flakyStageRepo
        )

        await vm.synthesizeRoadmap()
        vm.startFirstLesson()

        flakyStageRepo.shouldThrow = true
        vm.completeOnboardingAndDismiss()
        XCTAssertTrue(vm.isCompleting)
        await vm.completionTask?.value

        XCTAssertFalse(vm.isCompleting)
        XCTAssertFalse(settings.hasCompletedOnboarding)
        XCTAssertEqual(progressRepo.recordChallengeCallCount, 3)

        flakyStageRepo.shouldThrow = false
        vm.completeOnboardingAndDismiss()
        XCTAssertTrue(vm.isCompleting)
        await vm.completionTask?.value

        XCTAssertFalse(vm.isCompleting)
        XCTAssertTrue(settings.hasCompletedOnboarding)
        XCTAssertEqual(settings.currentStreak, 1)
        XCTAssertEqual(progressRepo.recordChallengeCallCount, 3)
        XCTAssertEqual(flakyStageRepo.saveCallCount, 1)
    }
}

final class FlakyStageProgressRepository: StageProgressRepositoryProtocol, @unchecked Sendable {
    @MainActor var shouldThrow: Bool = false
    @MainActor var saveCallCount: Int = 0

    @MainActor func fetchStageProgress(stageId: String) async throws -> UserStageProgress? {
        if shouldThrow {
            struct FlakyError: Error {}
            throw FlakyError()
        }
        return nil
    }

    @MainActor func fetchCompletedStageIds(deckId: String) async throws -> Set<String> { [] }
    @MainActor func fetchAllStageProgress() async throws -> [UserStageProgress] { [] }
    @MainActor func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int, progressFraction: Double) async throws {
        saveCallCount += 1
    }
}

final class ThrowingFetchStageProgressRepository: StageProgressRepositoryProtocol, @unchecked Sendable {
    @MainActor var saveCallCount: Int = 0

    @MainActor func fetchStageProgress(stageId: String) async throws -> UserStageProgress? {
        struct TestFetchError: Error {}
        throw TestFetchError()
    }

    @MainActor func fetchCompletedStageIds(deckId: String) async throws -> Set<String> { [] }
    @MainActor func fetchAllStageProgress() async throws -> [UserStageProgress] { [] }
    @MainActor func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int, progressFraction: Double) async throws {
        saveCallCount += 1
    }
}

final class MockNotificationScheduler: NotificationSchedulerProtocol, @unchecked Sendable {
    var scheduledInterval: Double?
    var didCancel: Bool = false

    func scheduleDailyReminder(at timeInterval: Double) async {
        scheduledInterval = timeInterval
    }

    func cancelDailyReminder() async {
        didCancel = true
    }
}

final class FailingInitializeUserRoadmapUseCase: InitializeUserRoadmapUseCaseProtocol, @unchecked Sendable {
    func execute(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    ) async throws -> RoadmapInitializationResult {
        throw OnboardingDomainError.stageNotFound(deckId)
    }
}
