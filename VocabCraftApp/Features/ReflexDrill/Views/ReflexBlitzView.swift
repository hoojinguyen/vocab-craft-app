import CraftUIKit
import SwiftUI

/// Main container view for the Redesigned Reflex Blitz drill experience.
/// Manages phase transitions (mode selection, countdown, drilling, and summary),
/// 4 distinct drill modalities (Speaking, Typing, Multiple Choice, Listening),
/// and the docked CraftFeedbackSheet review state.
public struct ReflexBlitzView: View {
    @Environment(\.craftTheme) private var theme
    public var viewModel: ReflexBlitzViewModel
    @State private var typingInput: String = ""
    public var onDismiss: () -> Void

    public init(viewModel: ReflexBlitzViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            switch viewModel.phase {
            case .modeSelection:
                ReflexBlitzModeSelectionView(
                    weeklyPracticedCount: viewModel.weeklyPracticedCount,
                    weakWordsCount: viewModel.weakWordsCount,
                    averageSpeedSeconds: viewModel.averageSpeedSeconds,
                    onSelectMode: { mode in
                        viewModel.selectMode(mode)
                    },
                    onSelectConfig: { config in
                        viewModel.applyReviewConfig(config)
                    },
                    onDismiss: {
                        viewModel.cancelSession()
                        onDismiss()
                    }
                )
                .transition(.opacity)

            case .summary:
                if let summary = viewModel.sessionSummary {
                    ReflexBlitzSummaryView(
                        summary: summary,
                        onSpeakWord: { lemma in
                            viewModel.speakLemma(lemma)
                        },
                        onReDrillWeak: {
                            viewModel.reDrillWeakWords()
                        },
                        onFinish: onDismiss
                    )
                    .transition(.opacity)
                }

            case .countdown, .drilling, .timeoutRevealing:
                drillingView

                if viewModel.phase == .countdown {
                    CraftCountdownOverlay(
                        startNumber: 3,
                        title: viewModel.selectedMode.title,
                        onFinish: {
                            viewModel.beginSessionDirectly()
                        }
                    )
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            if viewModel.phase == .countdown {
                viewModel.startCountdown()
            }
        }
        .onDisappear {
            viewModel.cancelSession()
        }
        .sensoryFeedback(.success, trigger: viewModel.currentAttemptIsCorrect) { _, isCorrect in isCorrect }
        .sensoryFeedback(.impact(weight: .heavy), trigger: isReviewedTimeout) { _, isTimeout in isTimeout }
        .sensoryFeedback(.error, trigger: isReviewedIncorrect) { _, isIncorrect in isIncorrect }
    }

    private var isReviewedIncorrect: Bool {
        if case .reviewed(let result) = viewModel.cardPhase {
            return !result.isCorrect
        }
        return false
    }

    private var isReviewedTimeout: Bool {
        if case .reviewed(let result) = viewModel.cardPhase {
            return result.isTimeout
        }
        return viewModel.phase == .timeoutRevealing
    }

    @ViewBuilder
    public var drillingView: some View {
        VStack(spacing: theme.spacing.md) {
            // Header Bar with Mode Badge, Step Counter, Combo Streak, and Close Button
            ReflexBlitzHeaderView(
                currentIndex: viewModel.currentWordIndex,
                totalCount: viewModel.words.count,
                comboStreak: viewModel.comboStreak,
                fractionRemaining: viewModel.fractionRemaining,
                timerStage: viewModel.timerStage,
                mode: viewModel.selectedMode,
                attempts: viewModel.attempts,
                wordStartTime: viewModel.wordStartTime,
                timeLimitSeconds: viewModel.selectedMode.timeLimitSeconds,
                isTimerActive: viewModel.cardPhase == .activeCountdown,
                onClose: {
                    viewModel.cancelSession()
                    viewModel.phase = .modeSelection
                },
                onSkip: {
                    viewModel.handleTimeout()
                },
                showSkipInHeader: false
            )
            .padding(.top, theme.spacing.sm)

            Spacer(minLength: theme.spacing.xs)

            // Challenge Card with 4-mode presentation & reviewed consolidation state
            if let word = viewModel.currentWord {
                ReflexBlitzCardView(
                    word: word,
                    mode: viewModel.selectedMode,
                    cardPhase: viewModel.cardPhase,
                    options: viewModel.currentOptions,
                    fractionRemaining: viewModel.fractionRemaining,
                    timerStage: viewModel.timerStage,
                    showHint: viewModel.showHint,
                    isCorrect: viewModel.currentAttemptIsCorrect,
                    isTimeout: isReviewedTimeout,
                    liveTranscript: viewModel.liveTranscript,
                    elapsedTimeMs: viewModel.elapsedTimeMs,
                    isKeyboardFallbackActive: viewModel.isKeyboardFallbackActive,
                    keyboardInputText: $typingInput,
                    onSelectOption: { option in
                        viewModel.selectOption(option)
                    },
                    onSubmitKeyboard: {
                        submitKeyboard()
                    },
                    onReplayAudio: {
                        viewModel.speakCurrentWord()
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            Spacer(minLength: theme.spacing.xs)

            // Bottom Dock: Skip button during active countdown for Speaking/Typing, CraftFeedbackSheet on review
            bottomDockArea
                .padding(.bottom, theme.spacing.md)
        }
    }

    @ViewBuilder
    private var bottomDockArea: some View {
        switch viewModel.cardPhase {
        case .activeCountdown:
            if viewModel.selectedMode == .speaking || viewModel.selectedMode == .typing {
                CraftButton(
                    AppStrings.ReflexBlitz.skip,
                    iconName: "forward.fill",
                    variant: .outline,
                    size: .md,
                    isFullWidth: true,
                    style: .outlined,
                    action: {
                        viewModel.skip()
                    }
                )
                .padding(.horizontal, theme.spacing.lg)
                .transition(.opacity)
            }
        case .reviewed(let result):
            CraftFeedbackSheet(
                status: result.isCorrect ? .success : (result.isTimeout ? .warning : .error),
                title: result.isCorrect ? "Chính xác!" : (result.isTimeout ? "Hết thời gian!" : "Chưa chính xác"),
                actionTitle: AppStrings.ReflexBlitz.continueCTAText,
                style: .tactile3D,
                onContinue: {
                    typingInput = ""
                    viewModel.advanceToNextWord()
                },
                extraContent: {
                    if let word = viewModel.currentWord {
                        feedbackExtraContent(word: word, result: result)
                    }
                }
            )
            .padding(.horizontal, theme.spacing.base)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    @ViewBuilder
    private func feedbackExtraContent(word: ReflexBlitzWordItem, result: ReflexCardResult) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            HStack(spacing: theme.spacing.sm) {
                CraftText(word.lemma, style: .titleMedium, color: theme.colors.textPrimary)

                if !word.pos.isEmpty {
                    CraftBadge(word.pos.uppercased(), variant: .subtle, tone: .primary, size: .sm, shape: .capsule)
                }

                if !word.ipa.isEmpty {
                    CraftText(word.ipa, style: .caption, color: theme.colors.textMuted)
                }

                Spacer()

                CraftSpeakerButton(
                    variant: .subtle,
                    size: .sm,
                    isPlaying: false,
                    label: LocalizedStringKey("craft.audio.pronounce"),
                    action: {
                        viewModel.speakCurrentWord()
                    }
                )
            }

            CraftText(word.definitionVi, style: .bodyMedium, color: theme.colors.textPrimary)

            if !word.clozeSentenceEn.isEmpty {
                CraftText(word.completedSentenceWithTargetWord, style: .bodyMedium, color: theme.colors.textSecondary)
            }

            if !word.exampleSentenceVi.isEmpty {
                CraftText(word.exampleSentenceVi, style: .caption, color: theme.colors.textMuted)
            }
        }
        .padding(theme.spacing.sm)
        .background(theme.colors.surfaceSubtle)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
    }

    private func submitKeyboard() {
        let text = typingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.submitKeyboardInput(text)
        typingInput = ""
    }
}
