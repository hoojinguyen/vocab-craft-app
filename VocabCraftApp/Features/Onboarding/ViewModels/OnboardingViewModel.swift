import Foundation
import Observation

@MainActor
@Observable
public final class OnboardingViewModel {
    public var currentStep: OnboardingStep = .goal
    public var selectedDeckId: String = "deck_daily"
    public var selectedCefrLevel: String = "A1"
    public var selectedDailyWords: Int = 10
    public var selectedReminderInterval: Double = 72000 // 20:00

    public var isSynthesizing: Bool = false
    public var synthesisPhaseTextKey: String = "app.onboarding.reveal.analyzing"
    public var roadmapResult: RoadmapInitializationResult?
    public var isPresentingMiniLesson: Bool = false
    public var errorMessage: String?

    private let useCase: InitializeUserRoadmapUseCaseProtocol
    private let userSettings: UserSettingsStore
    private let notificationScheduler: (any NotificationSchedulerProtocol)?
    private let progressRepo: (any UserProgressRepositoryProtocol)?
    private let stageRepo: (any StageProgressRepositoryProtocol)?
    public private(set) var synthesisTask: Task<Void, Never>?
    public private(set) var notificationTask: Task<Void, Never>?
    public private(set) var completionTask: Task<Void, Never>?
    public private(set) var hasGrantedNotificationPermission: Bool = false
    private var synthesisGeneration: Int = 0
    private var notificationGeneration: Int = 0

    public init(
        useCase: InitializeUserRoadmapUseCaseProtocol,
        userSettings: UserSettingsStore,
        notificationScheduler: (any NotificationSchedulerProtocol)? = nil,
        progressRepo: (any UserProgressRepositoryProtocol)? = nil,
        stageRepo: (any StageProgressRepositoryProtocol)? = nil
    ) {
        self.useCase = useCase
        self.userSettings = userSettings
        self.notificationScheduler = notificationScheduler
        self.progressRepo = progressRepo
        self.stageRepo = stageRepo
    }

    public var canGoBack: Bool {
        currentStep.rawValue > 0 && !isSynthesizing
    }

    public var canContinue: Bool {
        switch currentStep {
        case .goal:
            return !selectedDeckId.isEmpty
        case .proficiency:
            return !selectedCefrLevel.isEmpty
        case .habit:
            return selectedDailyWords > 0
        case .roadmapReveal:
            return roadmapResult != nil && !isSynthesizing
        }
    }

    public func nextStep() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = next
        if currentStep == .roadmapReveal && roadmapResult == nil {
            synthesisTask = Task { await synthesizeRoadmap() }
        }
    }

    public func previousStep() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
        roadmapResult = nil
        synthesisGeneration += 1
        synthesisTask?.cancel()
        synthesisTask = nil
        isSynthesizing = false
    }

    public func updateNotificationPermission(granted: Bool) {
        guard !userSettings.hasCompletedOnboarding else { return }
        hasGrantedNotificationPermission = granted
        userSettings.isNotificationEnabled = granted

        let previousTask = notificationTask
        notificationGeneration += 1
        let currentGen = notificationGeneration
        notificationTask?.cancel()

        notificationTask = Task {
            _ = await previousTask?.result
            guard !Task.isCancelled, notificationGeneration == currentGen else { return }
            if granted {
                await notificationScheduler?.scheduleDailyReminder(at: selectedReminderInterval)
            } else {
                await notificationScheduler?.cancelDailyReminder()
            }
        }
    }

    public func skipOnboarding() {
        synthesisGeneration += 1
        synthesisTask?.cancel()
        synthesisTask = nil
        completionTask?.cancel()
        completionTask = nil
        isSynthesizing = false
        userSettings.selectedGoalDeckId = "deck_daily"
        userSettings.assessedCefrLevel = "A1"
        userSettings.dailyGoalCount = 10
        userSettings.notificationTimeInterval = 72000
        userSettings.currentStreak = 0
        userSettings.hasCompletedOnboarding = true

        let previousTask = notificationTask
        notificationGeneration += 1
        let currentGen = notificationGeneration
        notificationTask?.cancel()

        if hasGrantedNotificationPermission {
            userSettings.isNotificationEnabled = true
            notificationTask = Task {
                _ = await previousTask?.result
                guard !Task.isCancelled, notificationGeneration == currentGen else { return }
                await notificationScheduler?.scheduleDailyReminder(at: 72000)
            }
        } else {
            userSettings.isNotificationEnabled = false
            notificationTask = Task {
                _ = await previousTask?.result
                guard !Task.isCancelled, notificationGeneration == currentGen else { return }
                await notificationScheduler?.cancelDailyReminder()
            }
        }
    }

    public func retrySynthesis() {
        synthesisGeneration += 1
        isSynthesizing = true
        errorMessage = nil
        synthesisTask?.cancel()
        synthesisTask = Task { await synthesizeRoadmap() }
    }

    public func synthesizeRoadmap() async {
        guard !Task.isCancelled else { return }
        synthesisGeneration += 1
        let currentGen = synthesisGeneration
        isSynthesizing = true
        errorMessage = nil

        // Visual animation staging
        synthesisPhaseTextKey = "app.onboarding.reveal.analyzing"
        guard !Task.isCancelled, synthesisGeneration == currentGen else { return }
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled, synthesisGeneration == currentGen else { return }

        synthesisPhaseTextKey = "app.onboarding.reveal.curating"
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled, synthesisGeneration == currentGen else { return }

        do {
            let result = try await useCase.execute(
                deckId: selectedDeckId,
                cefrLevel: selectedCefrLevel,
                dailyGoalCount: selectedDailyWords,
                notificationTimeInterval: selectedReminderInterval
            )
            guard !Task.isCancelled, synthesisGeneration == currentGen else { return }
            self.roadmapResult = result
            self.synthesisPhaseTextKey = "app.onboarding.reveal.ready"
            if userSettings.isNotificationEnabled {
                await notificationScheduler?.scheduleDailyReminder(at: selectedReminderInterval)
            }
        } catch is CancellationError {
            guard !Task.isCancelled, synthesisGeneration == currentGen else { return }
        } catch {
            guard !Task.isCancelled, synthesisGeneration == currentGen else { return }
            self.errorMessage = String(localized: "app.onboarding.reveal.error_generic")
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        guard synthesisGeneration == currentGen else { return }
        self.isSynthesizing = false
    }

    public func startFirstLesson() {
        isPresentingMiniLesson = true
    }

    public func completeOnboardingAndDismiss() {
        let starterWords = roadmapResult?.starterWords ?? VocabularySampleDataset.starterWords()
        let stageId = roadmapResult?.startingStage.id ?? "stage_daily_1"
        let deckId = userSettings.selectedGoalDeckId

        completionTask?.cancel()
        completionTask = Task { @MainActor in
            do {
                if let progressRepo = self.progressRepo {
                    for word in starterWords {
                        guard !Task.isCancelled else { return }
                        try await progressRepo.recordChallengeResult(
                            wordId: word.id,
                            isCorrect: true,
                            stageId: stageId,
                            deckId: deckId
                        )
                    }
                }

                guard !Task.isCancelled else { return }
                if let stageRepo = self.stageRepo {
                    let existing = try await stageRepo.fetchStageProgress(stageId: stageId)
                    let isCompleted = existing?.isCompleted ?? false
                    let newScore = max(existing?.score ?? 0, starterWords.count)
                    let newFraction = max(existing?.progressFraction ?? 0.0, 0.3)
                    try await stageRepo.saveStageProgress(
                        stageId: stageId,
                        deckId: deckId,
                        isCompleted: isCompleted,
                        score: newScore,
                        progressFraction: newFraction
                    )
                }

                guard !Task.isCancelled else { return }
                userSettings.hasCompletedOnboarding = true
                userSettings.currentStreak = max(userSettings.currentStreak, 1)
            } catch is CancellationError {
                // Task cancelled
            } catch {
                guard !Task.isCancelled else { return }
                isPresentingMiniLesson = false
                errorMessage = String(
                    localized: "app.onboarding.error.save_progress_failed",
                    defaultValue: "Failed to save progress. Please try again.",
                    bundle: .module
                )
            }
        }
    }
}
