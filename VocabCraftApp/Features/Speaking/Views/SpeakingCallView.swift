import CraftUIKit
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SpeakingCallDependencies {
    let controller: SpeakingCallController
    let repository: any SpeakingRepositoryProtocol
    let analyzer: AnalyzeSpeakingSessionUseCase
}

// Owns saved-session work independently of SwiftUI's cancellable presentation task.
@MainActor
@Observable
final class SpeakingCallCompletion {
    enum Phase { case idle, saving, analyzing, saveFailed, completed }
    private(set) var phase: Phase = .idle
    private var hasExited = false

    func run(
        _ session: SpeakingSessionSnapshot,
        repository: any SpeakingRepositoryProtocol,
        analyzer: AnalyzeSpeakingSessionUseCase,
        onShowResult: @escaping @MainActor (UUID) -> Void
    ) async {
        guard phase == .idle || phase == .saveFailed else { return }
        phase = .saving
        // Dismissing the call must not cancel saving or the analysis of saved data.
        let work = Task { @MainActor in
            do {
                try await repository.save(session)
            } catch {
                phase = .saveFailed
                return
            }
            phase = .analyzing
            _ = await analyzer.execute(sessionId: session.id)
            phase = .completed
            guard !hasExited else { return }
            onShowResult(session.id)
        }
        await work.value
    }

    func exit() -> Bool {
        guard phase == .analyzing else { return false }
        leave()
        return true
    }

    func leave() { hasExited = true }
}

struct SpeakingCallViewContent: Equatable {
    let statusKey: String
    let timeLeft: Int?
    let showsHint: Bool
    let showsReconnecting: Bool
    let failure: SpeakingCallFailure?
    let showsProgress: Bool

    static func make(
        phase: SpeakingCallPhase,
        elapsed: TimeInterval,
        duration: TimeInterval,
        completionPhase: SpeakingCallCompletion.Phase = .idle
    ) -> Self {
        var statusKey: String
        let failure: SpeakingCallFailure?
        switch phase {
        case .idle, .connecting:
            statusKey = "app.speaking.call.connecting"
            failure = nil
        case .live:
            statusKey = ""
            failure = nil
        case .reconnecting:
            statusKey = "app.speaking.call.reconnecting"
            failure = nil
        case let .failed(value):
            statusKey = failureKey(value)
            failure = value
        case .ended:
            statusKey = "app.speaking.call.ended"
            failure = nil
        }

        switch completionPhase {
        case .saving: statusKey = "app.speaking.call.saving"
        case .analyzing: statusKey = "app.speaking.result.analyzing"
        case .idle, .saveFailed, .completed: break
        }
        let isActive = phase == .live || phase == .reconnecting
        let timeLeft = isActive ? max(0, Int(ceil(duration - elapsed))) : nil
        return Self(
            statusKey: statusKey,
            timeLeft: timeLeft,
            showsHint: phase == .live,
            showsReconnecting: phase == .reconnecting,
            failure: failure,
            showsProgress: completionPhase == .saving || completionPhase == .analyzing
        )
    }

    static func shouldDismissAfterEndRequest(
        startingPhase: SpeakingCallPhase,
        resultingPhase: SpeakingCallPhase,
        hasResult: Bool,
        hasBeenLive: Bool = false
    ) -> Bool {
        guard !hasBeenLive, !hasResult else { return false }
        if case .ended = resultingPhase { return true }
        return false
    }

    private static func failureKey(_ failure: SpeakingCallFailure) -> String {
        switch failure {
        case .missingKey: "app.speaking.error.missing_key"
        case .unauthorized: "app.speaking.error.unauthorized"
        case .quotaExceeded: "app.speaking.error.quota"
        case .offline: "app.speaking.error.offline"
        case .network: "app.speaking.error.network"
        case .microphoneDenied: "app.speaking.error.microphone_denied"
        case .unknown: "app.speaking.error.unknown"
        }
    }
}

struct SpeakingCallView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appRouter) private var appRouter

    let plan: SpeakingSessionPlan
    let dependencies: SpeakingCallDependencies
    let onShowResult: (UUID) -> Void

    @State private var subtitlesVisible = false
    @State private var persistenceFailed = false
    @State private var failureDialogDismissed = false
    @State private var completionRetry = 0
    @State private var completion = SpeakingCallCompletion()
    @State private var previousIdleTimerDisabled = false

    private var controller: SpeakingCallController { dependencies.controller }
    private var content: SpeakingCallViewContent {
        SpeakingCallViewContent.make(
            phase: controller.phase,
            elapsed: controller.elapsed,
            duration: TimeInterval(plan.blueprint.durationSeconds),
            completionPhase: completion.phase
        )
    }

    var body: some View {
        VStack(spacing: theme.spacing.lg) {
            header
            Spacer(minLength: theme.spacing.xl)
            speakingIndicator
            status
            Spacer(minLength: theme.spacing.xl)
            subtitleControl
            if subtitlesVisible {
                transcript
            }
            actions
        }
        .padding(theme.spacing.base)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.canvasBackground)
        .interactiveDismissDisabled()
        .task { await runCallLifecycle() }
        .task(id: completionTaskID) { await persistAndAnalyze() }
        .onDisappear {
            completion.leave()
            guard !controller.phase.isTerminal else { return }
            Task { await controller.end() }
        }
        .craftDialog(
            isPresented: Binding(
                get: { content.failure != nil && !failureDialogDismissed },
                set: { failureDialogDismissed = !$0 }
            ),
            titleKey: content.failure.map(failureMessageKey) ?? AppStrings.Speaking.errorUnknown,
            primaryButtonTitleKey: failureActionTitle,
            primaryButtonVariant: .primary,
            primaryAction: handleFailureAction,
            cancelButtonTitleKey: nil,
            dismissOnBackdropTap: false
        )
        .craftDialog(
            isPresented: $persistenceFailed,
            titleKey: AppStrings.Speaking.errorSaveFailed,
            primaryButtonTitleKey: AppStrings.Speaking.errorTryAgain,
            primaryButtonVariant: .primary,
            primaryAction: { completionRetry += 1 },
            cancelButtonTitleKey: AppStrings.Speaking.errorExit,
            cancelAction: { dismiss() },
            dismissOnBackdropTap: false
        )
    }

    private var header: some View {
        HStack {
            CraftText(LocalizedStringKey(plan.blueprint.titleKey), style: .titleLarge)
            Spacer()
            CraftIconButton(
                iconName: "phone.down.fill",
                variant: .danger,
                accessibilityLabelKey: controller.phase.isTerminal ? AppStrings.Speaking.errorExit : AppStrings.Speaking.callEnd
            ) {
                let startingPhase = controller.phase
                Task {
                    if completion.exit() {
                        dismiss()
                        return
                    }
                    await controller.end()
                    guard SpeakingCallViewContent.shouldDismissAfterEndRequest(
                        startingPhase: startingPhase,
                        resultingPhase: controller.phase,
                        hasResult: controller.result != nil,
                        hasBeenLive: controller.hasBeenLive
                    ) else { return }
                    dismiss()
                }
            }
        }
    }

    private var speakingIndicator: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surfaceElevated)
                .frame(width: theme.spacing.xxl * 3, height: theme.spacing.xxl * 3)
            if controller.isAISpeaking {
                CraftPulsingAuraRing(color: theme.colors.brandPrimary, size: theme.spacing.xxl * 3, lineWidth: theme.spacing.xs)
            }
            CraftIcon("waveform", size: .xl, color: theme.colors.brandPrimary)
        }
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var status: some View {
        if content.showsProgress {
            CraftSpinner()
                .accessibilityLabel(LocalizedStringKey(content.statusKey))
        }
        if !content.statusKey.isEmpty {
            CraftText(
                LocalizedStringKey(content.statusKey), style: .headline,
                color: content.showsReconnecting ? theme.colors.statusWarning : theme.colors.textSecondary
            )
        }
        if completion.phase == .analyzing {
            CraftText(AppStrings.Speaking.callAnalysisSavedHint, style: .bodyMedium, color: theme.colors.textSecondary)
        }
        if let timeLeft = content.timeLeft {
            CraftText(AppStrings.Speaking.callTimeLeftText(remainingSeconds: timeLeft), style: .bodyMedium)
        }
    }

    private var subtitleControl: some View {
        CraftToggle(
            isOn: $subtitlesVisible,
            title: subtitlesVisible ? AppStrings.Speaking.callSubtitlesHide : AppStrings.Speaking.callSubtitlesShow
        )
    }

    private var transcript: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: theme.spacing.sm) {
                ForEach(Array(controller.turns.enumerated()), id: \.offset) { _, turn in
                    CraftText(turn.text, style: .bodyMedium, color: turn.speaker == .ai ? theme.colors.textPrimary : theme.colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxHeight: theme.spacing.xxl * 3)
    }

    @ViewBuilder
    private var actions: some View {
        if completion.phase == .analyzing {
            CraftButton(AppStrings.Speaking.errorExit, variant: .secondary, isFullWidth: true) {
                if completion.exit() { dismiss() }
            }
        }
        if content.showsHint {
            CraftButton(AppStrings.Speaking.callHint, variant: .secondary, isFullWidth: true) {
                Task { await controller.requestHint() }
            }
        }
    }

    private var completionTaskID: String {
        guard let result = controller.result else { return "idle" }
        return "\(result.id.uuidString)-\(completionRetry)"
    }

    private func runCallLifecycle() async {
        #if canImport(UIKit)
        previousIdleTimerDisabled = UIApplication.shared.isIdleTimerDisabled
        UIApplication.shared.isIdleTimerDisabled = true
        defer { UIApplication.shared.isIdleTimerDisabled = previousIdleTimerDisabled }
        #endif

        await controller.start()
        if Task.isCancelled {
            await controller.end()
            return
        }
        while !controller.phase.isTerminal {
            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                await controller.end()
                return
            }
        }
    }

    private func persistAndAnalyze() async {
        guard let result = controller.result else { return }
        await completion.run(result, repository: dependencies.repository, analyzer: dependencies.analyzer, onShowResult: onShowResult)
        guard !Task.isCancelled else { return }
        persistenceFailed = completion.phase == .saveFailed
    }

    private var failureActionTitle: LocalizedStringKey? {
        switch content.failure {
        case .missingKey, .unauthorized, .microphoneDenied: AppStrings.Speaking.errorOpenSettings
        case .quotaExceeded, .offline, .network, .unknown, nil: AppStrings.Speaking.errorExit
        }
    }

    private func handleFailureAction() {
        failureDialogDismissed = true
        switch content.failure {
        case .missingKey, .unauthorized:
            appRouter.selectTab(.settings)
            dismiss()
        case .microphoneDenied:
            #if canImport(UIKit)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            #endif
            dismiss()
        case .quotaExceeded, .offline, .network, .unknown, nil:
            dismiss()
        }
    }

    private func failureMessageKey(_ failure: SpeakingCallFailure) -> LocalizedStringKey {
        switch failure {
        case .missingKey: AppStrings.Speaking.errorMissingKey
        case .unauthorized: AppStrings.Speaking.errorUnauthorized
        case .quotaExceeded: AppStrings.Speaking.errorQuota
        case .offline: AppStrings.Speaking.errorOffline
        case .network: AppStrings.Speaking.errorNetwork
        case .microphoneDenied: AppStrings.Speaking.errorMicrophoneDenied
        case .unknown: AppStrings.Speaking.errorUnknown
        }
    }
}

private extension SpeakingCallPhase {
    var isTerminal: Bool {
        switch self {
        case .ended, .failed: true
        case .idle, .connecting, .live, .reconnecting: false
        }
    }
}
