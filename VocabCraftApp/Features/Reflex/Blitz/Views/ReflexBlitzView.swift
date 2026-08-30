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
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            if viewModel.phase == .countdown {
                viewModel.startCountdown()
            }
        }
        .onDisappear {
            viewModel.cancelSession()
        }
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
        let requiredStage = viewModel.selectedMode == .listening ? 2 : 3
        guard viewModel.hintStage >= requiredStage else { return nil }
        return viewModel.currentEliminatedOptionId ?? viewModel.currentOptions.first(where: { !$0.isCorrect })?.id
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
                        .id("\(viewModel.currentWordIndex)-\(word.id)")
                        .transition(.opacity)
                }

                Spacer(minLength: theme.spacing.xs)
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
                        advanceToNextWord()
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }

    @ViewBuilder
    private func cardContent(for word: ReflexBlitzWordItem) -> some View {
        if viewModel.selectedMode == .multipleChoice {
            multipleChoiceCard(for: word)
        } else if viewModel.selectedMode == .typing {
            typingCard(for: word)
        } else if viewModel.selectedMode == .listening {
            listeningCard(for: word)
        } else if viewModel.selectedMode == .speaking {
            speakingCard(for: word)
        }
    }

    @ViewBuilder
    private func speakingCard(for word: ReflexBlitzWordItem) -> some View {
        ReflexSpeakingModeView(
            word: word,
            isReviewed: isReviewed,
            isResultCorrect: viewModel.currentAttemptIsCorrect,
            isResultTimeout: isReviewedTimeout,
            showHint: viewModel.showHint,
            hintStage: viewModel.hintStage,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: word.clozeSentenceEn),
            displayedSentence: isReviewed ? word.completedSentenceWithTargetWord : word.clozeSentenceEn,
            hintBadgeText: viewModel.currentHintBadgeText,
            speechState: viewModel.cardPhase == .activeCountdown ? .listening() : .evaluated(overallScore: viewModel.currentAttemptIsCorrect ? 100 : 0),
            liveTranscript: viewModel.liveTranscript,
            onReplayAudio: {
                viewModel.speakCurrentWord()
            }
        )
        .padding(.horizontal, theme.spacing.base)
    }

    @ViewBuilder
    private func multipleChoiceCard(for word: ReflexBlitzWordItem) -> some View {
        ReflexMultipleChoiceModeView(
            word: word,
            options: viewModel.currentOptions,
            isReviewed: isReviewed,
            isResultCorrect: viewModel.currentAttemptIsCorrect,
            isResultTimeout: isReviewedTimeout,
            showHint: viewModel.showHint,
            hintStage: viewModel.hintStage,
            selectedOptionText: reviewResult?.selectedOption,
            clozeStages: viewModel.currentClozeStages,
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
    }

    @ViewBuilder
    private func typingCard(for word: ReflexBlitzWordItem) -> some View {
        ReflexTypingModeView(
            word: word,
            isReviewed: isReviewed,
            isResultCorrect: viewModel.currentAttemptIsCorrect,
            isResultTimeout: isReviewedTimeout,
            showHint: viewModel.showHint,
            hintStage: viewModel.hintStage,
            typingText: $typingInput,
            userSubmittedText: reviewResult?.typedText ?? typingInput,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: word.clozeSentenceEn),
            displayedSentence: isReviewed ? word.completedSentenceWithTargetWord : word.clozeSentenceEn,
            hintBadgeText: viewModel.currentHintBadgeText,
            onSubmit: {
                viewModel.submitTypingAnswer(typingInput)
            },
            onReplayAudio: {
                viewModel.speakCurrentWord()
            }
        )
        .id(word.id)
        .padding(.horizontal, theme.spacing.base)
    }

    @ViewBuilder
    private func listeningCard(for word: ReflexBlitzWordItem) -> some View {
        ReflexListeningModeView(
            word: word,
            options: viewModel.currentOptions,
            elapsedTimeMs: viewModel.elapsedTimeMs,
            isReviewed: isReviewed,
            isResultCorrect: viewModel.currentAttemptIsCorrect,
            isResultTimeout: isReviewedTimeout,
            showHint: viewModel.showHint,
            hintStage: viewModel.hintStage,
            selectedOptionText: reviewResult?.selectedOption,
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
    }

    private func advanceToNextWord() {
        typingInput = ""
        viewModel.advanceToNextWord()
    }
}
