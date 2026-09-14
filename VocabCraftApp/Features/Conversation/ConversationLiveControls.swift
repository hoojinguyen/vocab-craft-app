#if DEBUG
import CraftUIKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ConversationLiveControls: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var session: ConversationLiveSession
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftProgressBar(progress: session.progress)

            if !session.liveTranscript.isEmpty {
                Text(verbatim: session.liveTranscript)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(theme.colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, theme.spacing.base)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(session.liveTranscript)
            }

            status
            actions
        }
    }

    @ViewBuilder private var status: some View {
        switch session.phase {
        case .ready:
            Text(AppStrings.Conversation.rolePrompt)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textPrimary)

        case .preparing:
            CraftTactileMicHubView(
                speechState: .preparing,
                customSubtitle: AppStrings.Conversation.Live.rawPreparing,
                onTapMic: session.pause
            )

        case .partnerPlayback:
            CraftSpeakerButton(
                isPlaying: true,
                label: AppStrings.Conversation.Live.partner,
                action: {}
            )
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AppStrings.Conversation.Live.partner)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityRemoveTraits(.isButton)

        case .listening:
            CraftTactileMicHubView(
                speechState: .listening(),
                customSubtitle: AppStrings.Conversation.Live.rawListening,
                onTapMic: session.pause
            )

        case .evaluating:
            CraftTactileMicHubView(
                speechState: .processing,
                customSubtitle: AppStrings.Conversation.Live.rawEvaluating,
                onTapMic: {}
            )

        case let .waitingToRetry(_, failure):
            retryStatus(for: failure)

        case .completed:
            Label(AppStrings.Conversation.completed, systemImage: "checkmark.circle.fill")
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.statusSuccess)

        case .paused:
            Text(AppStrings.Conversation.pause)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textSecondary)

        case .awaitingContinue:
            Text(AppStrings.Conversation.continue)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.textSecondary)
        }
    }

    @ViewBuilder private func retryStatus(for failure: ConversationLiveFailure) -> some View {
        VStack(spacing: theme.spacing.xs) {
            switch failure {
            case .permissionDenied:
                Text(AppStrings.Conversation.Live.permission)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.statusDanger)
                    .multilineTextAlignment(.center)
                #if canImport(UIKit)
                CraftButton(AppStrings.Conversation.Live.openSettings, variant: .secondary, size: .sm) {
                    openSettings()
                }
                #endif

            case .recognitionUnavailable:
                Text(AppStrings.Conversation.Live.unavailable)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.statusWarning)
                    .multilineTextAlignment(.center)

            case .captureFailed:
                Text(AppStrings.Conversation.Live.captureError)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.statusDanger)
                    .multilineTextAlignment(.center)

            case .playbackFailed:
                Text(AppStrings.Conversation.Live.playbackError)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.statusDanger)
                    .multilineTextAlignment(.center)

            case .noSpeech:
                Text(AppStrings.Conversation.noSpeech)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.statusWarning)
                    .multilineTextAlignment(.center)

            case .readAgain:
                Text(AppStrings.Conversation.waitingRetry)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.statusWarning)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder private var actions: some View {
        switch session.phase {
        case .ready:
            Picker(
                AppStrings.Conversation.rolePrompt,
                selection: Binding(get: { session.role }, set: { session.chooseRole($0) })
            ) {
                Text(verbatim: AppStrings.Conversation.roleA).tag(ConversationRole.speakerA)
                Text(verbatim: AppStrings.Conversation.roleB).tag(ConversationRole.speakerB)
            }
            .pickerStyle(.segmented)

            HStack(spacing: theme.spacing.sm) {
                CraftButton(AppStrings.Conversation.start, action: session.start)
                CraftButton(
                    AppStrings.Conversation.Live.hearSample,
                    variant: .ghost,
                    isLoading: session.isPlayingSample
                ) {
                    Task { await session.playCurrentSample() }
                }
            }

        case .preparing, .partnerPlayback, .listening:
            CraftButton(AppStrings.Conversation.pause, variant: .secondary, action: session.pause)

        case .evaluating:
            EmptyView()

        case .waitingToRetry:
            HStack(spacing: theme.spacing.sm) {
                CraftButton(AppStrings.Conversation.retry, action: session.retry)
                CraftButton(
                    AppStrings.Conversation.Live.hearSample,
                    variant: .secondary,
                    isLoading: session.isPlayingSample
                ) {
                    Task { await session.playCurrentSample() }
                }
            }

        case .paused:
            CraftButton(AppStrings.Conversation.resume, action: session.resume)

        case .awaitingContinue:
            CraftButton(AppStrings.Conversation.continue, action: session.continueRestoredAttempt)

        case .completed:
            VStack(spacing: theme.spacing.xs) {
                CraftButton(AppStrings.Conversation.switchRole, action: session.switchRole)
                CraftButton(
                    AppStrings.Conversation.Live.anotherSample,
                    variant: .secondary,
                    action: onGenerate
                )
                .disabled(session.regenerationStatus == .loading)
            }
        }
    }

    private func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
#endif
