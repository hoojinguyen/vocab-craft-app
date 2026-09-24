import CraftUIKit
import SwiftUI

/// Full-screen calling screen for real-time voice roleplay conversations with an AI character.
@MainActor
public struct RoleplayVoiceCallView: View {
    @State private var viewModel: RoleplayVoiceCallViewModel
    private let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme

    public init(viewModel: RoleplayVoiceCallViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.md) {
                // Top Header HUD
                topHeaderBar

                // Target Words Horizontal Strip
                targetWordsStrip

                Spacer()

                // Center Stage: Voice Orb & State Text
                centerVoiceOrbStage

                Spacer()

                // Bottom Subtitle Card & Action Controls
                bottomControlsStage
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.sm)
        }
        .task {
            await viewModel.startCall()
        }
        .onChange(of: viewModel.masteredTargetWords.count) { _, _ in
            viewModel.checkForNewTargetWordMastered()
        }
        #if os(iOS)
        .fullScreenCover(item: $viewModel.sessionSummary) { summary in
            RoleplaySummaryView(summary: summary) {
                onDismiss()
            }
        }
        #else
        .sheet(item: $viewModel.sessionSummary) { summary in
            RoleplaySummaryView(summary: summary) {
                onDismiss()
            }
        }
        #endif
    }

    private var topHeaderBar: some View {
        HStack {
            CraftIconButton(
                symbol: .close,
                size: .md,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.Common.close
            ) {
                Task { await viewModel.endCall() }
            }

            Spacer()

            VStack(spacing: theme.spacing.xxs) {
                Text(viewModel.scenario.characterName)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(viewModel.scenario.characterRole)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            CraftBadge(
                AppStrings.AIAssistant.callActiveBadge,
                variant: .subtle,
                tone: .success,
                size: .sm
            )
        }
    }

    private var targetWordsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                Text(AppStrings.AIAssistant.targetWordsTitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                ForEach(viewModel.scenario.targetWordIds, id: \.self) { word in
                    let isMastered = viewModel.masteredTargetWords.contains(word)
                    CraftBadge(
                        LocalizedStringKey(word),
                        iconName: isMastered ? "checkmark.circle.fill" : nil,
                        variant: isMastered ? .solid : .subtle,
                        tone: isMastered ? .success : .neutral,
                        size: .sm
                    )
                    .scaleEffect(isMastered ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isMastered)
                }
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
        }
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    }

    private var centerVoiceOrbStage: some View {
        VStack(spacing: theme.spacing.lg) {
            CraftVoiceOrbView(state: viewModel.state)

            Text(stateDescription)
                .font(theme.typography.bodyLarge)
                .foregroundStyle(theme.colors.textSecondary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        }
    }

    private var bottomControlsStage: some View {
        VStack(spacing: theme.spacing.md) {
            if viewModel.isSubtitlesVisible {
                subtitlesCard
            }

            HStack(spacing: theme.spacing.lg) {
                // Subtitles toggle
                CraftIconButton(
                    symbol: .docText,
                    size: .lg,
                    variant: viewModel.isSubtitlesVisible ? .filled : .subtle,
                    accessibilityLabelKey: AppStrings.AIAssistant.toggleCaptions
                ) {
                    viewModel.toggleSubtitles()
                }

                // Hang Up Button (Red)
                Button {
                    Task { await viewModel.endCall() }
                } label: {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(theme.colors.textInverse)
                        .padding(theme.spacing.base)
                        .background(theme.colors.danger)
                        .clipShape(Circle())
                }
                .accessibilityLabel(AppStrings.AIAssistant.endCall)

                // Mute toggle
                CraftIconButton(
                    symbol: viewModel.isMuted ? .slash : .audio,
                    size: .lg,
                    variant: viewModel.isMuted ? .filled : .subtle,
                    accessibilityLabelKey: viewModel.isMuted ? AppStrings.AIAssistant.unmuteMicrophone : AppStrings.AIAssistant.muteMicrophone
                ) {
                    viewModel.toggleMute()
                }
            }
        }
    }

    private var subtitlesCard: some View {
        CraftCard(
            style: .elevated,
            cornerRadius: theme.radii.lg,
            padding: theme.spacing.md
        ) {
            Text(currentSubtitleText)
                .font(theme.typography.bodyMedium)
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineLimit(3)
        }
    }

    private var stateDescription: LocalizedStringKey {
        switch viewModel.state {
        case .idle: return AppStrings.AIAssistant.stateIdle
        case .speaking: return AppStrings.AIAssistant.stateSpeaking
        case .listening: return AppStrings.AIAssistant.stateListening
        case .thinking: return AppStrings.AIAssistant.stateThinking
        case .ended: return AppStrings.AIAssistant.stateEnded
        }
    }

    private var currentSubtitleText: String {
        switch viewModel.state {
        case .speaking(let text):
            return text
        case .listening(let transcript):
            return transcript.isEmpty ? "..." : transcript
        case .thinking:
            return "..."
        case .idle, .ended:
            return ""
        }
    }
}
