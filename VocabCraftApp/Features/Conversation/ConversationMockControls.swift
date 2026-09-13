#if DEBUG
import CraftUIKit
import SwiftUI

struct ConversationMockControls: View {
    @Environment(\.craftTheme) private var theme
    @Bindable var session: ConversationMockSession
    @Binding var simulateFailure: Bool
    let onGenerate: () -> Void

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftProgressBar(progress: session.progress)
            status
            actions
            DisclosureGroup(AppStrings.Conversation.debugScenario) {
                Picker(AppStrings.Conversation.debugScenario, selection: $session.selectedOutcome) {
                    Text(verbatim: AppStrings.Conversation.outcomePass).tag(ConversationMockOutcome.pass)
                    Text(verbatim: AppStrings.Conversation.outcomeRetry).tag(ConversationMockOutcome.retry)
                    Text(verbatim: AppStrings.Conversation.outcomeNoSpeech).tag(ConversationMockOutcome.noSpeech)
                }
                .pickerStyle(.segmented)
                Toggle(AppStrings.Conversation.simulateGenerationFailure, isOn: $simulateFailure)
                if !isRunning {
                    CraftButton(AppStrings.Conversation.newConversation, variant: .ghost, size: .sm, action: onGenerate)
                        .disabled(session.regenerationStatus == .loading)
                }
                if session.regenerationStatus == .failed {
                    Text(AppStrings.Conversation.generationFailure)
                        .foregroundStyle(theme.colors.statusDanger)
                }
            }
            .font(theme.typography.caption)
        }
    }

    @ViewBuilder private var status: some View {
        switch session.phase {
        case .preview:
            Text(AppStrings.Conversation.rolePrompt).font(theme.typography.headline)
        case .partnerPlayback:
            CraftSpeakerButton(isPlaying: true, label: AppStrings.Conversation.partnerSpeaking, action: {})
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(AppStrings.Conversation.partnerSpeaking)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityRemoveTraits(.isButton)
        case .listening:
            CraftTactileMicHubView(
                speechState: .listening(),
                customSubtitle: AppLocalized.string("app.conversation.mock_listening"),
                onTapMic: {}
            )
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(AppStrings.Conversation.mockListening)
            .accessibilityAddTraits(.isStaticText)
            .accessibilityRemoveTraits(.isButton)
        case let .waitingToRetry(_, outcome):
            Text(outcome == .noSpeech ? AppStrings.Conversation.noSpeech : AppStrings.Conversation.waitingRetry)
                .foregroundStyle(theme.colors.statusWarning)
        case .completed:
            Label(AppStrings.Conversation.completed, systemImage: "checkmark.circle.fill")
                .foregroundStyle(theme.colors.statusSuccess)
        case .paused, .awaitingContinue:
            Text(AppStrings.Conversation.continue)
        }
    }

    @ViewBuilder private var actions: some View {
        switch session.phase {
        case .preview:
            Picker(AppStrings.Conversation.rolePrompt, selection: Binding(get: { session.role }, set: { session.chooseRole($0) })) {
                Text(verbatim: AppStrings.Conversation.roleA).tag(ConversationRole.speakerA)
                Text(verbatim: AppStrings.Conversation.roleB).tag(ConversationRole.speakerB)
            }
            .pickerStyle(.segmented)
            CraftButton(AppStrings.Conversation.start, action: session.start)
        case .partnerPlayback, .listening:
            CraftButton(AppStrings.Conversation.pause, variant: .secondary, action: session.pause)
        case .waitingToRetry:
            CraftButton(AppStrings.Conversation.retry, action: session.retry)
        case .paused:
            CraftButton(AppStrings.Conversation.resume, action: session.resume)
        case .awaitingContinue:
            CraftButton(AppStrings.Conversation.continue, action: session.continueRestoredAttempt)
        case .completed:
            CraftButton(AppStrings.Conversation.switchRole, action: session.switchRole)
        }
    }

    private var isRunning: Bool {
        switch session.phase {
        case .partnerPlayback, .listening: true
        default: false
        }
    }
}
#endif
