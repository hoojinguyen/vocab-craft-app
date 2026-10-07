import CraftUIKit
import SwiftUI

/// Full-screen calling screen for real-time voice roleplay conversations with an AI character.
@MainActor
public struct RoleplayVoiceCallView: View {
    @State private var viewModel: RoleplayVoiceCallViewModel
    private let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme
    @Environment(\.appContainer) private var appContainer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLivePulsing: Bool = false
    @State private var showVoicePicker: Bool = false

    public init(viewModel: RoleplayVoiceCallViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            if let summary = viewModel.sessionSummary {
                RoleplaySummaryView(summary: summary) {
                    onDismiss()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                activeCallStage
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.sessionSummary != nil)
        .task {
            await viewModel.startCall()
        }
        .onChange(of: viewModel.masteredTargetWords.count) { _, _ in
            viewModel.checkForNewTargetWordMastered()
        }
        .onChange(of: viewModel.isCallCancelled) { _, isCancelled in
            if isCancelled {
                onDismiss()
            }
        }
        .alert(
            AppStrings.AIAssistant.discardConfirmTitle,
            isPresented: $viewModel.showDiscardAlert
        ) {
            Button(AppStrings.Common.cancel, role: .cancel) {}
            Button(AppStrings.Common.confirm, role: .destructive) {
                viewModel.cancelCall()
                onDismiss()
            }
        } message: {
            Text(AppStrings.AIAssistant.discardConfirmMessage)
        }
        .sheet(isPresented: $showVoicePicker) {
            RoleplayVoicePickerSheet(
                store: appContainer.userSettingsStore,
                ttsService: appContainer.ttsService
            )
        }
    }

    private var activeCallStage: some View {
        VStack(spacing: theme.spacing.md) {
            // Top Header HUD
            topHeaderBar

            // Target Words Horizontal Strip
            targetWordsStrip

            Spacer(minLength: theme.spacing.sm)

            // Center Stage: Voice Orb & State Text
            centerVoiceOrbStage
                .frame(maxWidth: .infinity)

            Spacer(minLength: theme.spacing.sm)

            // Bottom Subtitle Card, Scaffolding Drawer & Action Controls
            bottomControlsStage
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.xs)
        .safeAreaPadding(.top)
        .safeAreaPadding(.bottom)
    }

    private var topHeaderBar: some View {
        HStack {
            CraftIconButton(
                symbol: .close,
                size: .md,
                variant: .subtle,
                accessibilityLabelKey: AppStrings.Common.close
            ) {
                viewModel.handleCloseButton()
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

            HStack(spacing: theme.spacing.xs) {
                CraftIconButton(
                    symbol: .audio,
                    size: .sm,
                    variant: .ghost,
                    accessibilityLabelKey: AppStrings.AIAssistant.selectVoiceTitle
                ) {
                    showVoicePicker = true
                }

                liveIndicatorBadge
            }
        }
    }

    private var liveIndicatorBadge: some View {
        HStack(spacing: theme.spacing.xxs) {
            ZStack {
                if !reduceMotion {
                    Circle()
                        .fill(theme.colors.statusSuccess.opacity(0.35))
                        .frame(width: theme.spacing.sm, height: theme.spacing.sm)
                        .scaleEffect(isLivePulsing ? 1.4 : 1.0)
                        .opacity(isLivePulsing ? 0.2 : 0.8)
                }

                Circle()
                    .fill(theme.colors.statusSuccess)
                    .frame(width: theme.spacing.xs, height: theme.spacing.xs)
            }

            Text(Self.liveBadgeKey)
                .font(theme.typography.caption)
                .fontWeight(.medium)
                .foregroundStyle(theme.colors.statusSuccess)
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xxs)
        .background(theme.colors.statusSuccess.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(AppStrings.AIAssistant.callLiveBadge))
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isLivePulsing = true
            }
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
                    Group {
                        if isMastered {
                            CraftBadge(
                                verbatim: word,
                                symbol: .checkmarkCircle,
                                variant: .solid,
                                tone: .success,
                                size: .sm
                            )
                        } else {
                            CraftBadge(
                                verbatim: word,
                                variant: .subtle,
                                tone: .neutral,
                                size: .sm
                            )
                        }
                    }
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
            CraftVoiceOrbView(
                state: viewModel.state,
                audioLevel: viewModel.audioLevel
            )
            .frame(width: 140, height: 140)

            Text(stateDescription)
                .font(theme.typography.bodyLarge)
                .foregroundStyle(theme.colors.textSecondary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.state)
        }
    }

    private var bottomControlsStage: some View {
        VStack(spacing: theme.spacing.md) {
            if viewModel.isSubtitlesVisible && viewModel.state != .idle && viewModel.state != .ended {
                subtitlesCard
                    .transition(.opacity)
            }

            if viewModel.state != .idle && viewModel.state != .ended {
                RoleplaySuggestedDrawer(viewModel: viewModel)
            }

            // Fixed height container for manual turn button / error banner
            ZStack {
                if viewModel.engine.audioErrorMessage != nil {
                    HStack(spacing: theme.spacing.xs) {
                        CraftIcon(.sparkles, size: .sm, color: theme.colors.statusDanger)
                        Text(AppStrings.AICall.retryListening)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.statusDanger)
                    }
                    .accessibilityAddTraits(.isButton)
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.engine.retryListening() }
                } else if case .listening = viewModel.state {
                    CraftButton(
                        AppStrings.AICall.finishSpeaking,
                        variant: .secondary,
                        size: .sm
                    ) {
                        viewModel.finishSpeaking()
                    }
                }
            }
            .frame(height: 48) // Fixed height prevents jumping!

            bottomActionButtons
        }
    }

    private var bottomActionButtons: some View {
        HStack(spacing: theme.spacing.lg) {
            // Subtitles toggle (Left)
            CraftIconButton(
                symbol: Self.subtitlesSymbol(),
                size: .lg,
                variant: viewModel.isSubtitlesVisible ? .filled : .subtle,
                accessibilityLabelKey: AppStrings.AIAssistant.toggleCaptions
            ) {
                viewModel.toggleSubtitles()
            }

            // Hang Up Button (Middle)
            CraftIconButton(
                symbol: .phoneDown,
                size: .xl,
                shape: .circle,
                variant: .danger,
                accessibilityLabelKey: AppStrings.AIAssistant.endCall
            ) {
                Task { await viewModel.endCall() }
            }

            // Mute toggle (Right)
            CraftIconButton(
                symbol: Self.micSymbol(isMuted: viewModel.isMuted),
                size: .lg,
                variant: viewModel.isMuted ? .filled : .subtle,
                accessibilityLabelKey: Self.micAccessibilityKey(isMuted: viewModel.isMuted)
            ) {
                viewModel.toggleMute()
            }
        }
    }

    private var subtitlesCard: some View {
        CraftCard(
            style: .glass,
            cornerRadius: theme.radii.lg,
            padding: theme.spacing.md
        ) {
            VStack(spacing: theme.spacing.xs) {
                switch viewModel.state {
                case .speaking(let text):
                    Text(text)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .lineLimit(4)

                case .listening(let transcript):
                    if let previousAI = lastAIMessageText, !previousAI.isEmpty {
                        Text(previousAI)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .opacity(0.6)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .lineLimit(2)
                    }

                    if viewModel.isMuted {
                        Text(AppStrings.AICall.micMuted)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.statusWarning)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .lineLimit(2)
                    } else if transcript.isEmpty {
                        Text(AppStrings.AICall.listeningPrompt)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textMuted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .lineLimit(2)
                    } else {
                        Text(transcript)
                            .font(theme.typography.bodyMedium)
                            .foregroundStyle(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .lineLimit(3)
                    }

                case .thinking:
                    if let previousAI = lastAIMessageText, !previousAI.isEmpty {
                        Text(previousAI)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                            .opacity(0.6)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .lineLimit(2)
                    }

                    Text(AppStrings.AIAssistant.stateThinking)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .lineLimit(2)

                case .idle, .ended, .error:
                    EmptyView()
                }
            }
        }
    }

    private var lastAIMessageText: String? {
        viewModel.engine.messages.last(where: {
            if case .character = $0.sender { return true }
            return false
        })?.text ?? viewModel.scenario.initialGreeting
    }

    private var stateDescription: LocalizedStringKey {
        switch viewModel.state {
        case .idle: return AppStrings.AIAssistant.stateIdle
        case .speaking: return AppStrings.AIAssistant.stateSpeaking
        case .listening: return AppStrings.AIAssistant.stateListening
        case .thinking: return AppStrings.AIAssistant.stateThinking
        case .error(let error): return LocalizedStringKey(error.localizedKey)
        case .ended: return AppStrings.AIAssistant.stateEnded
        }
    }
}

// MARK: - Testing Hooks
extension RoleplayVoiceCallView {
    public static func micSymbol(isMuted: Bool) -> CraftSymbol {
        isMuted ? .micSlash : .mic
    }

    public static func micAccessibilityKey(isMuted: Bool) -> LocalizedStringKey {
        isMuted ? AppStrings.AIAssistant.callMicUnmute : AppStrings.AIAssistant.callMicMute
    }

    public static func subtitlesSymbol() -> CraftSymbol {
        .quoteBubble
    }

    public static var liveBadgeKey: LocalizedStringKey {
        AppStrings.AIAssistant.callLiveBadge
    }
}
