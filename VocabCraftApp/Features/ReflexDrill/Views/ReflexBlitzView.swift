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

            case .countdown:
                CraftCountdownOverlay(
                    startNumber: 3,
                    title: viewModel.selectedMode.title,
                    subtitle: viewModel.selectedMode.instructionPrompt,
                    iconName: viewModel.selectedMode.iconName,
                    tintColor: modalityTintColor(for: viewModel.selectedMode),
                    onFinish: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.beginSessionDirectly()
                        }
                    }
                )
                .transition(.opacity)

            case .drilling, .timeoutRevealing:
                drillingView
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

    private func modalityTintColor(for mode: ReflexBlitzMode) -> Color {
        switch mode {
        case .speaking:
            return theme.colors.brandPrimary
        case .typing:
            return theme.colors.streakLegendary
        case .multipleChoice:
            return theme.colors.statusSuccess
        case .listening:
            return theme.colors.statusInfo
        }
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
        ZStack(alignment: .bottom) {
            // Main stable content area (Header + Card)
            VStack(spacing: theme.spacing.sm) {
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

                if let word = viewModel.currentWord {
                    ReflexBlitzCardView(
                        word: word,
                        mode: viewModel.selectedMode,
                        cardPhase: viewModel.cardPhase,
                        options: viewModel.currentOptions,
                        fractionRemaining: viewModel.fractionRemaining,
                        timerStage: viewModel.timerStage,
                        showHint: viewModel.showHint,
                        hintStage: viewModel.hintStage,
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
                }

                Spacer(minLength: theme.spacing.xs)

                // Skip Button for Speaking / Typing
                if viewModel.cardPhase == .activeCountdown && (viewModel.selectedMode == .speaking || viewModel.selectedMode == .typing) {
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
                    .padding(.bottom, theme.spacing.lg)
                    .transition(.opacity)
                }
            }

            // Floating Bottom Feedback Sheet Overlay
            if case .reviewed(let result) = viewModel.cardPhase {
                CraftFeedbackSheet(
                    status: result.isCorrect ? .success : (result.isTimeout ? .warning : .error),
                    title: result.isCorrect ? AppStrings.ReflexBlitz.correctTitleText : (result.isTimeout ? AppStrings.ReflexBlitz.timeoutTitleText : AppStrings.ReflexBlitz.incorrectTitleText),
                    actionTitle: AppStrings.ReflexBlitz.continueCTAText,
                    streakCount: nil,
                    style: .tactile3D,
                    onContinue: {
                        typingInput = ""
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            viewModel.advanceToNextWord()
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.cardPhase)
    }

    private func submitKeyboard() {
        let text = typingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.submitKeyboardInput(text)
        typingInput = ""
    }
}
