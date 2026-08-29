import CraftUIKit
import SwiftUI

/// Main container view for the Mixed Reflex Drill session.
/// Seamlessly manages 4 randomized multi-sensory interactive modes:
/// 1. Multiple Choice (.multipleChoice - 4.5s)
/// 2. Speaking (.speaking - 6.0s) with continuous speech recognition & waveform
/// 3. Typing (.typing - 7.5s) with auto-focused TextField
/// 4. Listening (.listening - 5.5s) with automatic TTS audio stimulus
///
/// Fully incorporates the Loop-Back mechanism: any failed or timed-out word
/// is immediately requeued at the end of the session with a fresh alternative mode.
public struct MixedReflexDrillView: View {
    @Environment(\.craftTheme) private var theme
    @Bindable public var viewModel: MixedReflexDrillViewModel
    public var speechService: ContinuousReflexSpeechProtocol?
    public let onFinish: () -> Void

    @State private var timerTask: Task<Void, Never>?
    @State private var fractionRemaining: Double = 1.0
    @State private var elapsedTimeMs: Int = 0
    @State private var cardPhase: ReflexCardPhase = .activeCountdown
    @State private var typingText: String = ""
    @State private var liveTranscript: String = ""
    @State private var isKeyboardFallbackActive: Bool = false
    @State private var currentOptions: [ReflexBlitzOption] = []
    @State private var showExitAlert: Bool = false
    @State private var wordStartTime: Date?

    public init(
        viewModel: MixedReflexDrillViewModel,
        speechService: ContinuousReflexSpeechProtocol? = nil,
        onFinish: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.speechService = speechService
        self.onFinish = onFinish
    }

    public var isReviewed: Bool {
        if case .reviewed = cardPhase { return true }
        return false
    }

    public var reviewedResult: ReflexCardResult? {
        if case .reviewed(let result) = cardPhase { return result }
        return nil
    }

    public var isResultCorrect: Bool {
        reviewedResult?.isCorrect ?? false
    }

    public var isResultTimeout: Bool {
        reviewedResult?.isTimeout ?? false
    }

    public var timerStage: ReflexBlitzTimerStage {
        guard let current = viewModel.currentItem else { return .steady }
        let limit = current.assignedMode.timeLimitSeconds * 1000.0
        let warningThreshold = limit * (3.5 / 6.0)
        let urgentThreshold = limit * (5.0 / 6.0)
        if Double(elapsedTimeMs) < warningThreshold {
            return .steady
        } else if Double(elapsedTimeMs) < urgentThreshold {
            return .warning
        } else {
            return .urgent
        }
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            if viewModel.isCompleted, let summary = viewModel.sessionSummary {
                MixedReflexSummaryView(
                    summary: summary,
                    onSpeakWord: { lemma in
                        viewModel.playAudio(for: lemma)
                    },
                    onRetry: {
                        viewModel.restartSession()
                        if let first = viewModel.currentItem {
                            startDrillItem(first)
                        }
                    },
                    onDone: onFinish
                )
                .transition(.opacity)
            } else if let currentItem = viewModel.currentItem {
                drillingSessionContent(currentItem: currentItem)
                    .transition(.opacity)
            }
        }
        .onAppear {
            setupSpeechServiceCallbacks()
            if let current = viewModel.currentItem {
                startDrillItem(current)
            }
        }
        .onDisappear {
            stopDrillSession()
        }
        .alert(AppStrings.ReflexBlitz.exitDialogTitleText, isPresented: $showExitAlert) {
            Button(AppStrings.ReflexBlitz.exitDialogCancelText, role: .cancel) {}
            Button(AppStrings.ReflexBlitz.exitDialogConfirmText, role: .destructive) {
                stopDrillSession()
                onFinish()
            }
        } message: {
            Text(AppStrings.ReflexBlitz.exitDialogMessageText)
        }
        .sensoryFeedback(.success, trigger: isResultCorrect) { _, isCorrect in isCorrect }
        .sensoryFeedback(.error, trigger: isResultTimeout || (isReviewed && !isResultCorrect)) { _, isError in isError }
    }

    // MARK: - Drilling Session Main Content
    @ViewBuilder
    private func drillingSessionContent(currentItem: MixedReflexDrillItem) -> some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: theme.spacing.sm) {
                ReflexHeaderBarView(
                    currentIndex: viewModel.currentIndex,
                    totalCount: viewModel.queue.count,
                    comboStreak: viewModel.comboStreak,
                    fractionRemaining: fractionRemaining,
                    timerStage: timerStage,
                    attempts: viewModel.attempts,
                    wordStartTime: wordStartTime,
                    timeLimitSeconds: currentItem.assignedMode.timeLimitSeconds,
                    isTimerActive: cardPhase == .activeCountdown,
                    showSkipInHeader: false,
                    onClose: {
                        showExitAlert = true
                    },
                    onSkip: {
                        handleTimeout()
                    }
                )
                .padding(.top, theme.spacing.sm)

                challengeCard(for: currentItem)

                Spacer(minLength: theme.spacing.xs)

                // Skip Button for Speaking / Typing
                if cardPhase == .activeCountdown && (currentItem.assignedMode == .speaking || currentItem.assignedMode == .typing) {
                    CraftButton(
                        AppStrings.ReflexBlitz.skip,
                        iconName: "forward.fill",
                        variant: .outline,
                        size: .md,
                        isFullWidth: true,
                        style: .outlined,
                        action: {
                            handleTimeout()
                        }
                    )
                    .padding(.horizontal, theme.spacing.lg)
                    .padding(.bottom, theme.spacing.lg)
                    .transition(.opacity)
                }
            }

            // Floating Bottom Feedback Sheet Overlay
            if case .reviewed(let result) = cardPhase {
                CraftFeedbackSheet(
                    status: result.isCorrect ? .success : (result.isTimeout ? .warning : .error),
                    title: result.isCorrect ? AppStrings.ReflexBlitz.correctTitleText : (result.isTimeout ? AppStrings.ReflexBlitz.timeoutTitleText : AppStrings.ReflexBlitz.incorrectTitleText),
                    actionTitle: AppStrings.ReflexBlitz.continueCTAText,
                    streakCount: viewModel.comboStreak > 1 ? viewModel.comboStreak : nil,
                    style: .tactile3D,
                    onContinue: {
                        advanceToNextItem()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }

    // MARK: - Challenge Card Container
    @ViewBuilder
    private func challengeCard(for item: MixedReflexDrillItem) -> some View {
        let isReviewed = cardPhase.isReviewed
        let reviewedResult = cardPhase.reviewResult
        let isResultCorrect = reviewedResult?.isCorrect ?? false
        let isResultTimeout = reviewedResult?.isTimeout ?? false
        let timerStage = ReflexBlitzTimerCalculator.timerStage(
            fractionRemaining: fractionRemaining,
            isReviewed: isReviewed
        )
        let currentHintStage = item.assignedMode.hintStage(forElapsedTimeMs: elapsedTimeMs)
        let isHintActive = currentHintStage >= 1

        if item.assignedMode == .multipleChoice {
            ReflexMultipleChoiceModeView(
                word: item,
                options: currentOptions,
                isReviewed: isReviewed,
                isResultCorrect: isResultCorrect,
                isResultTimeout: isResultTimeout,
                showHint: isHintActive,
                hintStage: currentHintStage,
                selectedOptionText: reviewedResult?.selectedOption,
                clozeStages: viewModel.currentClozeStages,
                clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
                displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
                cardBorderColor: theme.colors.hairline.opacity(0.4),
                eliminatedOptionId: viewModel.currentEliminatedOptionId,
                onSelectOption: { option in
                    selectOption(option)
                },
                onReplayAudio: {
                    viewModel.playAudioForCurrentWord()
                }
            )
            .padding(.horizontal, theme.spacing.base)
        } else {
            ReflexCardContainerView(
                isReviewed: isReviewed,
                isCorrect: isResultCorrect,
                isTimeout: isResultTimeout,
                timerStage: timerStage
            ) {
                if isReviewed {
                    ReflexReviewedConsolidationView(
                        word: item,
                        mode: item.assignedMode,
                        reviewResult: reviewedResult,
                        displayedSentence: item.completedSentenceWithTargetWord,
                        onReplayAudio: {
                            viewModel.playAudioForCurrentWord()
                        }
                    )
                } else {
                    switch item.assignedMode {
                    case .speaking:
                        ReflexSpeakingModeView(
                            word: item,
                            liveTranscript: liveTranscript,
                            elapsedTimeMs: elapsedTimeMs,
                            showHint: isHintActive,
                            hintStage: currentHintStage,
                            clozeStages: viewModel.currentClozeStages,
                            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
                            displayedSentence: item.clozeSentenceEn,
                            hintBadgeText: viewModel.currentHintBadgeText,
                            onSwitchToKeyboard: {
                                isKeyboardFallbackActive.toggle()
                            }
                        )
                    case .typing:
                        ReflexTypingModeView(
                            word: item,
                            typingText: $typingText,
                            showHint: isHintActive,
                            hintStage: currentHintStage,
                            clozeStages: viewModel.currentClozeStages,
                            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
                            displayedSentence: item.clozeSentenceEn,
                            hintBadgeText: viewModel.currentHintBadgeText,
                            onSubmit: {
                                submitTypingAnswer(typingText)
                            }
                        )
                    case .listening:
                        ReflexListeningModeView(
                            word: item,
                            options: currentOptions,
                            hintStage: currentHintStage,
                            eliminatedOptionId: viewModel.currentEliminatedOptionId,
                            onPlayAudio: {
                                viewModel.playAudioForCurrentWord()
                            },
                            onSelectOption: { option in
                                selectOption(option)
                            }
                        )
                    case .multipleChoice:
                        EmptyView()
                    }
                }
            }
        }
    }

    // MARK: - Drill Item Lifecycle & Timer
    private func startDrillItem(_ item: MixedReflexDrillItem) {
        timerTask?.cancel()
        fractionRemaining = 1.0
        elapsedTimeMs = 0
        cardPhase = .activeCountdown
        typingText = ""
        liveTranscript = ""
        isKeyboardFallbackActive = false
        wordStartTime = Date()

        if item.assignedMode == .multipleChoice || item.assignedMode == .listening {
            currentOptions = viewModel.generateOptions(for: item)
        } else {
            currentOptions = []
        }

        if item.assignedMode == .speaking {
            speechService?.setTargetWord(lemma: item.word.lemma, contextualPhrases: [item.word.exampleSentenceEn])
            speechService?.resumeListening()
        } else {
            speechService?.pauseListening()
        }

        if item.assignedMode == .listening {
            viewModel.playAudioForCurrentWord()
        }

        let timeLimit = item.assignedMode.timeLimitSeconds
        timerTask = Task { @MainActor in
            let startTime = Date()
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(30))
                let elapsed = Date().timeIntervalSince(startTime)
                self.elapsedTimeMs = Int(elapsed * 1000)
                let remaining = max(0, 1.0 - (elapsed / timeLimit))
                self.fractionRemaining = remaining

                if remaining <= 0 {
                    handleTimeout()
                    break
                }
            }
        }
    }

    private func selectOption(_ option: ReflexBlitzOption) {
        guard cardPhase == .activeCountdown else { return }
        timerTask?.cancel()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: option.isCorrect,
                responseTimeMs: max(500, elapsedTimeMs),
                isTimeout: false,
                selectedOption: option.text
            ))
        }

        Task {
            await viewModel.submitAnswer(isCorrect: option.isCorrect, responseTimeMs: max(500, elapsedTimeMs))
        }
    }

    private func submitTypingAnswer(_ text: String) {
        guard cardPhase == .activeCountdown, let current = viewModel.currentItem else { return }
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isCorrect = cleanText == current.word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard isCorrect else { return }

        timerTask?.cancel()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: true,
                responseTimeMs: max(500, elapsedTimeMs),
                isTimeout: false,
                typedText: text
            ))
        }

        Task {
            await viewModel.submitAnswer(isCorrect: true, responseTimeMs: max(500, elapsedTimeMs))
        }
    }

    private func handleTimeout() {
        guard cardPhase == .activeCountdown else { return }
        timerTask?.cancel()
        fractionRemaining = 0.0

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: max(1000, elapsedTimeMs),
                isTimeout: true
            ))
        }

        Task {
            await viewModel.submitAnswer(isCorrect: false, responseTimeMs: max(1000, elapsedTimeMs))
        }
    }

    private func advanceToNextItem() {
        viewModel.advanceToNextItem()
        if let nextItem = viewModel.currentItem {
            startDrillItem(nextItem)
        }
    }

    private func setupSpeechServiceCallbacks() {
        speechService?.onMatchDetected = { matched in
            Task { @MainActor in
                guard cardPhase == .activeCountdown, let current = viewModel.currentItem else { return }
                let isCorrect = matched.lowercased().contains(current.word.lemma.lowercased())
                if isCorrect {
                    timerTask?.cancel()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        cardPhase = .reviewed(result: ReflexCardResult(
                            isCorrect: true,
                            responseTimeMs: max(500, elapsedTimeMs),
                            isTimeout: false,
                            recognizedSpoken: matched
                        ))
                    }
                    await viewModel.submitAnswer(isCorrect: true, responseTimeMs: max(500, elapsedTimeMs))
                }
            }
        }

        speechService?.onTranscriptUpdate = { transcript in
            Task { @MainActor in
                self.liveTranscript = transcript
            }
        }
    }

    private func stopDrillSession() {
        timerTask?.cancel()
        speechService?.stopSession()
    }
}
