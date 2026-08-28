import SwiftUI

/// Main container view for the Redesigned Reflex Blitz drill experience.
/// Manages phase transitions (mode selection, countdown, drilling, and summary),
/// 4 distinct drill modalities (Speaking, Typing, Multiple Choice, Listening),
/// and the paused review consolidation dock.
public struct ReflexBlitzView: View {
    public var viewModel: ReflexBlitzViewModel
    @State private var typingInput: String = ""
    public var onDismiss: () -> Void

    public init(viewModel: ReflexBlitzViewModel, onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.vocabCanvas
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
                    ReflexCountdownOverlayView(
                        count: viewModel.countdownCount,
                        mode: viewModel.selectedMode
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
        VStack(spacing: 16) {
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
            .padding(.top, 12)

            Spacer(minLength: 12)

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

            Spacer(minLength: 12)

            // Ergonomic Advance Dock / Bottom Skip button in Thumb Zone
            ReflexBlitzAdvanceDockView(
                cardPhase: viewModel.cardPhase,
                onAdvance: {
                    typingInput = ""
                    viewModel.advanceToNextWord()
                },
                onSkip: {
                    viewModel.handleTimeout()
                }
            )
            .padding(.bottom, 16)
        }
    }

    private func submitKeyboard() {
        let text = typingInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.submitKeyboardInput(text)
        typingInput = ""
    }
}
