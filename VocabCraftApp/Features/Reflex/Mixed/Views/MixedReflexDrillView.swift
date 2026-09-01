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
    public var speechEngine: (any ReflexSpeechEngineProtocol)?
    public let onFinish: () -> Void
    public let startWithCountdown: Bool

    @State private var isCountingDown: Bool
    @State private var timerTask: Task<Void, Never>?
    @State private var fractionRemaining: Double = 1.0
    @State private var elapsedTimeMs: Int = 0
    @State private var cardPhase: ReflexCardPhase = .activeCountdown
    @State private var typingText: String = ""
    @State private var liveTranscript: String = ""
    @State private var currentOptions: [ReflexBlitzOption] = []
    @State private var showExitAlert: Bool = false
    @State private var wordStartTime: Date?

    public init(
        viewModel: MixedReflexDrillViewModel,
        speechEngine: (any ReflexSpeechEngineProtocol)? = nil,
        startWithCountdown: Bool = true,
        onFinish: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.speechEngine = speechEngine ?? ResilientReflexSpeechEngine()
        self.startWithCountdown = startWithCountdown
        self.onFinish = onFinish
        self._isCountingDown = State(initialValue: startWithCountdown)
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
                    onReDrillWeak: {
                        viewModel.reDrillWeakWords()
                        isCountingDown = true
                        let contextualPhrases = viewModel.queue.map(\.word.lemma)
                        speechEngine?.startSession(contextualPhrases: contextualPhrases)
                    },
                    onFinish: onFinish
                )
                .transition(.opacity)
            } else if isCountingDown, let currentItem = viewModel.currentItem {
                ReflexCountdownOverlayView(
                    count: 3,
                    title: AppStrings.Practice.mixedDrillTitleText,
                    subtitle: AppStrings.Practice.mixedDrillSubtitleText,
                    iconName: "bolt.fill",
                    tintColor: theme.colors.brandPrimary,
                    onFinish: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isCountingDown = false
                            startDrillItem(currentItem)
                        }
                    }
                )
                .transition(.opacity)
            } else if let currentItem = viewModel.currentItem {
                drillingSessionContent(currentItem: currentItem)
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            setupSpeechEngineCallbacks()
            let contextualPhrases = viewModel.queue.map(\.word.lemma)
            speechEngine?.startSession(contextualPhrases: contextualPhrases)
            if !isCountingDown, let current = viewModel.currentItem {
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
                    .id("\(viewModel.currentIndex)-\(currentItem.id)")
                    .transition(.opacity)

                Spacer(minLength: theme.spacing.xs)

                // Skip Button for Typing
                if cardPhase == .activeCountdown && currentItem.assignedMode == .typing {
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
                    streakCount: nil,
                    style: .tactile3D,
                    onContinue: {
                        advanceToNextItem()
                    }
                )
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(100)
            }
        }
    }
}

// MARK: - Challenge Cards
private extension MixedReflexDrillView {
    @ViewBuilder
    func challengeCard(for item: MixedReflexDrillItem) -> some View {
        let currentHintStage = item.assignedMode.hintStage(forElapsedTimeMs: elapsedTimeMs)
        let isHintActive = currentHintStage >= 1

        switch item.assignedMode {
        case .multipleChoice:
            multipleChoiceChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
        case .listening:
            listeningChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
        case .typing:
            typingChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
        case .speaking:
            speakingChallengeCard(for: item, hintStage: currentHintStage, isHintActive: isHintActive)
        }
    }

    @ViewBuilder
    func multipleChoiceChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexMultipleChoiceModeView(
            word: item,
            options: currentOptions,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
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
    }

    @ViewBuilder
    func typingChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexTypingModeView(
            word: item,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
            typingText: $typingText,
            userSubmittedText: reviewedResult?.typedText ?? typingText,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
            hintBadgeText: viewModel.currentHintBadgeText,
            onSubmit: {
                submitTypingAnswer(typingText)
            },
            onReplayAudio: {
                viewModel.playAudioForCurrentWord()
            }
        )
        .id(item.id)
        .padding(.horizontal, theme.spacing.base)
    }

    @ViewBuilder
    func listeningChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexListeningModeView(
            word: item,
            options: currentOptions,
            elapsedTimeMs: elapsedTimeMs,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
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
    }

    @ViewBuilder
    func speakingChallengeCard(for item: MixedReflexDrillItem, hintStage: Int, isHintActive: Bool) -> some View {
        ReflexSpeakingModeView(
            word: item,
            isReviewed: isReviewed,
            isResultCorrect: isResultCorrect,
            isResultTimeout: isResultTimeout,
            showHint: isHintActive,
            hintStage: hintStage,
            clozeStages: viewModel.currentClozeStages,
            clozeParts: ReflexClozeFormatter.extractTemplateParts(from: item.clozeSentenceEn),
            displayedSentence: isReviewed ? item.completedSentenceWithTargetWord : item.clozeSentenceEn,
            hintBadgeText: viewModel.currentHintBadgeText,
            speechState: cardPhase == .activeCountdown ? .listening() : .evaluated(overallScore: isResultCorrect ? 100 : 0),
            liveTranscript: liveTranscript,
            onCantSpeakNow: {
                timerTask?.cancel()
                if viewModel.allowSpeakingSkip {
                    viewModel.skipSpeakingCurrentWord()
                    if let next = viewModel.currentItem {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            startDrillItem(next)
                        }
                    }
                } else {
                    handleTimeout()
                }
            },
            onReplayAudio: {
                viewModel.playAudioForCurrentWord()
            }
        )
        .padding(.horizontal, theme.spacing.base)
    }
}

// MARK: - Drill Actions & Lifecycle
private extension MixedReflexDrillView {
    func startDrillItem(_ item: MixedReflexDrillItem) {
        timerTask?.cancel()
        fractionRemaining = 1.0
        elapsedTimeMs = 0
        cardPhase = .activeCountdown
        typingText = ""
        liveTranscript = ""
        wordStartTime = Date()

        if item.assignedMode == .multipleChoice || item.assignedMode == .listening {
            currentOptions = viewModel.generateOptions(for: item)
        } else {
            currentOptions = []
        }

        if item.assignedMode == .speaking {
            if let engine = speechEngine, !engine.isSessionActive {
                let phrases = viewModel.queue.map(\.word.lemma)
                engine.startSession(contextualPhrases: phrases)
            }
            speechEngine?.beginWord(
                targetLemma: item.word.lemma,
                contextualPhrases: [item.word.exampleSentenceEn]
            )
        } else {
            speechEngine?.endWord()
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

    func selectOption(_ option: ReflexBlitzOption) {
        guard cardPhase == .activeCountdown else { return }
        timerTask?.cancel()
        speechEngine?.endWord()
        speechEngine?.finalizeWordAudio()

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

    func submitTypingAnswer(_ text: String) {
        guard cardPhase == .activeCountdown, let current = viewModel.currentItem else { return }
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        let isCorrect = cleanText.lowercased() == current.word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        timerTask?.cancel()
        speechEngine?.endWord()
        speechEngine?.finalizeWordAudio()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: max(500, elapsedTimeMs),
                isTimeout: false,
                typedText: cleanText
            ))
        }

        if isCorrect {
            SoundEffectService.shared.playSuccessChime()
        } else {
            SoundEffectService.shared.playIncorrectChime()
        }

        Task {
            await viewModel.submitAnswer(isCorrect: isCorrect, responseTimeMs: max(500, elapsedTimeMs))
        }
    }

    func handleTimeout() {
        guard cardPhase == .activeCountdown else { return }
        timerTask?.cancel()
        speechEngine?.endWord()
        fractionRemaining = 0.0
        speechEngine?.finalizeWordAudio()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: max(1000, elapsedTimeMs),
                isTimeout: true
            ))
        }

        if viewModel.currentItem?.assignedMode != .listening {
            viewModel.playAudioForCurrentWord()
        }

        Task {
            await viewModel.submitAnswer(isCorrect: false, responseTimeMs: max(1000, elapsedTimeMs))
        }
    }

    func advanceToNextItem() {
        viewModel.advanceToNextItem()
        if let nextItem = viewModel.currentItem {
            startDrillItem(nextItem)
        }
    }

    func setupSpeechEngineCallbacks() {
        if let speechEngine {
            speechEngine.onMatchDetected = { matched in
                Task { @MainActor in
                    guard cardPhase == .activeCountdown, let current = viewModel.currentItem else { return }
                    let isCorrect = ReflexSpeechMatcher.isReflexMatch(spokenText: matched, targetLemma: current.word.lemma) || matched.lowercased().contains(current.word.lemma.lowercased())
                    if isCorrect {
                        timerTask?.cancel()
                        speechEngine.finalizeWordAudio()
                        SoundEffectService.shared.playSuccessChime()
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

            speechEngine.onTranscriptUpdate = { transcript in
                Task { @MainActor in
                    self.liveTranscript = transcript
                }
            }

            speechEngine.onError = { error in
                print("[MixedReflexDrillView] Speech engine error: \(error.localizedDescription)")
            }
        }
    }

    func stopDrillSession() {
        timerTask?.cancel()
        speechEngine?.stopSession()
    }
}
