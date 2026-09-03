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
    public private(set) var synthesisTask: Task<Void, Never>?

    public init(useCase: InitializeUserRoadmapUseCaseProtocol, userSettings: UserSettingsStore) {
        self.useCase = useCase
        self.userSettings = userSettings
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
        synthesisTask?.cancel()
        synthesisTask = nil
    }

    public func updateNotificationPermission(granted: Bool) {
        userSettings.isNotificationEnabled = granted
    }

    public func skipOnboarding() {
        synthesisTask?.cancel()
        synthesisTask = nil
        userSettings.selectedGoalDeckId = "deck_daily"
        userSettings.assessedCefrLevel = "A1"
        userSettings.dailyGoalCount = 10
        userSettings.notificationTimeInterval = 72000
        userSettings.hasCompletedOnboarding = true
    }

    public func retrySynthesis() {
        synthesisTask?.cancel()
        synthesisTask = Task { await synthesizeRoadmap() }
    }

    public func synthesizeRoadmap() async {
        isSynthesizing = true
        errorMessage = nil

        // Visual animation staging
        synthesisPhaseTextKey = "app.onboarding.reveal.analyzing"
        guard !Task.isCancelled else { isSynthesizing = false; return }
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { isSynthesizing = false; return }

        synthesisPhaseTextKey = "app.onboarding.reveal.curating"
        try? await Task.sleep(nanoseconds: 300_000_000)
        guard !Task.isCancelled else { isSynthesizing = false; return }

        do {
            let result = try await useCase.execute(
                deckId: selectedDeckId,
                cefrLevel: selectedCefrLevel,
                dailyGoalCount: selectedDailyWords,
                notificationTimeInterval: selectedReminderInterval
            )
            guard !Task.isCancelled else { isSynthesizing = false; return }
            self.roadmapResult = result
            self.synthesisPhaseTextKey = "app.onboarding.reveal.ready"
        } catch is CancellationError {
            guard !Task.isCancelled else { isSynthesizing = false; return }
        } catch {
            guard !Task.isCancelled else { isSynthesizing = false; return }
            self.errorMessage = String(localized: "app.onboarding.reveal.error_generic")
        }

        try? await Task.sleep(nanoseconds: 200_000_000)
        self.isSynthesizing = false
    }

    public func startFirstLesson() {
        isPresentingMiniLesson = true
    }

    public func completeOnboardingAndDismiss() {
        userSettings.hasCompletedOnboarding = true
    }
}
