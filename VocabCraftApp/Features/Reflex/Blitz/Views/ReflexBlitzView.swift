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
    @State private var isConfettiTriggered: Bool = false
    public var onDismiss: () -> Void
    public var onFinishSession: ((ReflexBlitzSessionSummary) -> Void)?

    public init(
        viewModel: ReflexBlitzViewModel,
        onDismiss: @escaping () -> Void,
        onFinishSession: ((ReflexBlitzSessionSummary) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.onFinishSession = onFinishSession
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
                        onFinish: {
                            if let onFinishSession {
                                onFinishSession(summary)
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    viewModel.resetToModeSelection()
                                }
                            }
                        }
                    )
                    .transition(.opacity)
                    .craftConfetti(isTriggered: $isConfettiTriggered, particleCount: 35)
                    .onAppear {
                        if summary.ratingTier == .master {
                            isConfettiTriggered = true
                        }
                    }
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

    private var isReviewed: Bool {
        if case .reviewed = viewModel.cardPhase {
            return true
        }
        return false
    }

    private var reviewResult: ReflexCardResult? {
        if case .reviewed(let result) = viewModel.cardPhase {
            return result
        }
        return nil
    }

    private var isReviewedIncorrect: Bool {
        if let result = reviewResult {
            return !result.isCorrect
        }
        return false
    }

    private var isReviewedTimeout: Bool {
        if let result = reviewResult {
            return result.isTimeout
        }
        return viewModel.phase == .timeoutRevealing
    }

    private var eliminatedOptionId: String? {
        guard viewModel.hintStage >= 3 else { return nil }
        return viewModel.currentOptions.first(where: { !$0.isCorrect })?.id
    }

    @ViewBuilder
    public var drillingView: some View {
        ZStack(alignment: .bottom) {
            // Main stable content area (Header + Card)
            VStack(spacing: theme.spacing.sm) {
                ReflexHeaderBarView(
                    currentIndex: viewModel.currentWordIndex,
                    totalCount: viewModel.words.count,
                    comboStreak: viewModel.comboStreak,
                    fractionRemaining: viewModel.fractionRemaining,
                    timerStage: viewModel.timerStage,
                    attempts: viewModel.attempts,
                    wordStartTime: viewModel.wordStartTime,
                    timeLimitSeconds: viewModel.selectedMode.timeLimitSeconds,
                    isTimerActive: viewModel.cardPhase == .activeCountdown,
                    showSkipInHeader: false,
                    onClose: {
                        viewModel.cancelSession()
                        viewModel.phase = .modeSelection
                    },
                    onSkip: {
                        viewModel.handleTimeout()
                    }
                )
                .padding(.top, theme.spacing.sm)

                if let word = viewModel.currentWord {
                    cardContent(for: word)
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
                    onAction: {
                        advanceToNextWord()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }

    @ViewBuilder
    private func cardContent(for word: ReflexBlitzWordItem) -> some View {
        if viewModel.selectedMode == .multipleChoice {
            ReflexMultipleChoiceModeView(
                word: word,
                options: viewModel.currentOptions,
                isReviewed: isReviewed,
                isResultCorrect: viewModel.currentAttemptIsCorrect,
                isResultTimeout: isReviewedTimeout,
                showHint: viewModel.showHint,
                hintStage: viewModel.hintStage,
                selectedOptionText: reviewResult?.selectedOption,
                clozeParts: ReflexClozeFormatter.extractTemplateParts(from: word.clozeSentenceEn),
                displayedSentence: isReviewed ? word.completedSentenceWithTargetWord : word.clozeSentenceEn,
                cardBorderColor: theme.colors.hairline.opacity(0.4),
                eliminatedOptionId: eliminatedOptionId,
                onSelectOption: { option in
                    viewModel.selectOption(option)
                },
                onReplayAudio: {
                    viewModel.speakCurrentWord()
                }
            )
            .padding(.horizontal, theme.spacing.base)
        } else {
            ReflexCardContainerView(
                isReviewed: isReviewed,
                isCorrect: viewModel.currentAttemptIsCorrect,
                isTimeout: isReviewedTimeout,
                timerStage: viewModel.timerStage
            ) {
                if isReviewed {
                    ReflexReviewedConsolidationView(
                        word: word,
                        mode: viewModel.selectedMode,
                        reviewResult: reviewResult,
                        displayedSentence: word.completedSentenceWithTargetWord,
                        onReplayAudio: {
                            viewModel.speakCurrentWord()
                        }
                    )
                } else {
                    switch viewModel.selectedMode {
                    case .speaking:
                        ReflexSpeakingModeView(
                            word: word,
                            liveTranscript: viewModel.liveTranscript,
                            elapsedTimeMs: viewModel.elapsedTimeMs,
                            onSwitchToKeyboard: {
                                viewModel.toggleKeyboardFallback()
                            }
                        )
                    case .typing:
                        ReflexTypingModeView(
                            word: word,
                            typingText: $typingInput,
                            onSubmit: {
                                viewModel.submitTypingAnswer(typingInput)
                            }
                        )
                    case .listening:
                        ReflexListeningModeView(
                            word: word,
                            options: viewModel.currentOptions,
                            onSelectOption: { option in
                                viewModel.selectOption(option)
                            },
                            onReplayAudio: {
                                viewModel.speakCurrentWord()
                            }
                        )
                    case .multipleChoice:
                        EmptyView()
                    }
                }
            }
        }
    }

    private func advanceToNextWord() {
        typingInput = ""
        viewModel.advanceToNextWord()
    }
}
