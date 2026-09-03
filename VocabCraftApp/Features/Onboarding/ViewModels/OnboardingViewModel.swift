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
    public private(set) var synthesisTask: Task<Void, Never>?
    public private(set) var notificationTask: Task<Void, Never>?
    private var synthesisGeneration: Int = 0

    public init(
        useCase: InitializeUserRoadmapUseCaseProtocol,
        userSettings: UserSettingsStore,
        notificationScheduler: (any NotificationSchedulerProtocol)? = nil
    ) {
        self.useCase = useCase
        self.userSettings = userSettings
        self.notificationScheduler = notificationScheduler
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
        userSettings.isNotificationEnabled = granted
        notificationTask?.cancel()
        if granted {
            notificationTask = Task {
                await notificationScheduler?.scheduleDailyReminder(at: selectedReminderInterval)
            }
        } else {
            notificationTask = Task {
                await notificationScheduler?.cancelDailyReminder()
            }
        }
    }

    public func skipOnboarding() {
        synthesisGeneration += 1
        synthesisTask?.cancel()
        synthesisTask = nil
        isSynthesizing = false
        userSettings.selectedGoalDeckId = "deck_daily"
        userSettings.assessedCefrLevel = "A1"
        userSettings.dailyGoalCount = 10
        userSettings.notificationTimeInterval = 72000
        userSettings.hasCompletedOnboarding = true

        if userSettings.isNotificationEnabled {
            notificationTask?.cancel()
            notificationTask = Task {
                await notificationScheduler?.scheduleDailyReminder(at: 72000)
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
        userSettings.hasCompletedOnboarding = true
    }
}
