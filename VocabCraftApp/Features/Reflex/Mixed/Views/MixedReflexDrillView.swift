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
    @State private var speechStartTask: Task<Void, Never>?
    @State private var fractionRemaining: Double = 1.0
    @State private var cardPhase: ReflexCardPhase = .activeCountdown
    @State private var typingText: String = ""
    @State private var liveTranscript: String = ""
    @State private var currentOptions: [ReflexBlitzOption] = []
    @State private var showExitAlert: Bool = false
    @State private var currentTimerStage: ReflexBlitzTimerStage = .steady
    @State private var hintStage: Int = 0

    public var wordStartTime: Date? {
        get { viewModel.wordStartTime }
        nonmutating set { viewModel.wordStartTime = newValue }
    }

    public var elapsedTimeMs: Int {
        get {
            if let wordStartTime {
                return max(0, Int(Date().timeIntervalSince(wordStartTime) * 1000))
            }
            return viewModel.elapsedTimeMs
        }
        nonmutating set { viewModel.elapsedTimeMs = newValue }
    }

    public var speechState: CraftSpeechState {
        get { viewModel.speechState }
        nonmutating set { viewModel.speechState = newValue }
    }

    public var isPermissionDenied: Bool {
        get { viewModel.isPermissionDenied }
        nonmutating set { viewModel.isPermissionDenied = newValue }
    }

    public var showPermissionAlert: Bool {
        get { viewModel.showPermissionAlert }
        nonmutating set { viewModel.showPermissionAlert = newValue }
    }

    public var permissionNotice: ReflexPermissionNotice? {
        get { viewModel.permissionNotice }
        nonmutating set { viewModel.permissionNotice = newValue }
    }

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
        get { currentTimerStage }
        nonmutating set { currentTimerStage = newValue }
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
                        speechEngine?.startSession(contextualPhrases: contextualPhrases, lazy: true)
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
            speechEngine?.startSession(contextualPhrases: contextualPhrases, lazy: true)
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
        .alert(
            permissionNotice?.title ?? AppStrings.Lesson.permissionTitleText,
            isPresented: $viewModel.showPermissionAlert,
            presenting: permissionNotice
        ) { notice in
            Button(notice.settingsActionTitle) {
                openSettings()
                dismissPermissionAlert()
            }
            Button(notice.dismissActionTitle, role: .cancel) {
                dismissPermissionAlert()
            }
        } message: { notice in
            Text(notice.message)
        }
        .onChange(of: viewModel.showPermissionAlert) { wasPresented, isPresented in
            if wasPresented && !isPresented && permissionNotice != nil {
                dismissPermissionAlert()
            }
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
        let currentHintStage = max(hintStage, item.assignedMode.hintStage(forElapsedTimeMs: elapsedTimeMs))
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
            speechState: cardPhase == .activeCountdown ? speechState : .evaluated(overallScore: isResultCorrect ? 100 : 0),
            liveTranscript: liveTranscript,
            onCantSpeakNow: {
                speechStartTask?.cancel()
                speechStartTask = nil
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
public extension MixedReflexDrillView {
    private func finalizeActiveEngineAndTimers() {
        speechStartTask?.cancel()
        speechStartTask = nil
        timerTask?.cancel()
        timerTask = nil
        speechEngine?.finalizeWordAudio()
        speechEngine?.endWord()
    }

    private func recordResponseTime() -> Int {
        let elapsedMs = wordStartTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 500
        let responseTimeMs = max(500, elapsedMs)
        let timeLimit = viewModel.currentItem?.assignedMode.timeLimitSeconds ?? 6.0
        fractionRemaining = max(0.0, min(1.0, 1.0 - (Double(elapsedMs) / 1000.0 / timeLimit)))
        viewModel.elapsedTimeMs = responseTimeMs
        return responseTimeMs
    }

    func startDrillItem(_ item: MixedReflexDrillItem) {
        finalizeActiveEngineAndTimers()
        wordStartTime = nil
        timerStage = .steady
        hintStage = 0
        fractionRemaining = 1.0
        elapsedTimeMs = 0
        cardPhase = .activeCountdown
        typingText = ""
        liveTranscript = ""

        if item.assignedMode == .multipleChoice || item.assignedMode == .listening {
            currentOptions = viewModel.generateOptions(for: item)
        } else {
            currentOptions = []
        }

        if item.assignedMode == .speaking {
            if isPermissionDenied {
                speechState = .unavailable
                if !viewModel.showPermissionAlert {
                    wordStartTime = Date()
                    startTimer(for: item)
                }
                return
            }

            speechState = .preparing
            if let engine = speechEngine, !engine.isSessionActive {
                let phrases = viewModel.queue.map(\.word.lemma)
                engine.startSession(contextualPhrases: phrases, lazy: true)
            }

            if let speechEngine {
                speechStartTask = Task { @MainActor in
                    do {
                        try await speechEngine.startListening(
                            targetLemma: item.word.lemma,
                            contextualPhrases: [item.word.exampleSentenceEn]
                        )
                        guard !Task.isCancelled else { return }
                        guard viewModel.currentItem?.id == item.id else { return }
                        speechState = .listening()
                        if !viewModel.showPermissionAlert {
                            wordStartTime = Date()
                            startTimer(for: item)
                        }
                    } catch let error as SpeechCaptureError where error == .speechRecognitionDenied || error == .microphoneDenied {
                        guard !Task.isCancelled, viewModel.currentItem?.id == item.id else { return }
                        handlePermissionDenied()
                    } catch {
                        guard !Task.isCancelled, viewModel.currentItem?.id == item.id else { return }
                        speechState = .unavailable
                        if !viewModel.showPermissionAlert {
                            wordStartTime = Date()
                            startTimer(for: item)
                        }
                    }
                }
            } else {
                speechState = .unavailable
                if !viewModel.showPermissionAlert {
                    wordStartTime = Date()
                    startTimer(for: item)
                }
            }
        } else {
            speechState = isPermissionDenied ? .unavailable : .idle
            speechEngine?.endWord()
            if item.assignedMode == .listening {
                viewModel.playAudioForCurrentWord()
            }
            if !viewModel.showPermissionAlert {
                wordStartTime = Date()
                startTimer(for: item)
            }
        }
    }

    private func startTimer(for item: MixedReflexDrillItem) {
        timerTask?.cancel()
        if wordStartTime == nil {
            wordStartTime = Date()
        }
        timerStage = .steady
        hintStage = 0
        let timeLimit = item.assignedMode.timeLimitSeconds

        timerTask = Task { @MainActor in
            // Milestone 1: Hint 1 (40%)
            let hint1Delay = timeLimit * 0.40
            try? await Task.sleep(for: .seconds(hint1Delay))
            guard !Task.isCancelled else { return }
            self.hintStage = 1

            // Milestone 2: Warning (60%)
            let warningDelay = timeLimit * 0.20
            try? await Task.sleep(for: .seconds(warningDelay))
            guard !Task.isCancelled else { return }
            self.timerStage = .warning

            // Milestone 3: Hint 2 (70%)
            let hint2Delay = timeLimit * 0.10
            try? await Task.sleep(for: .seconds(hint2Delay))
            guard !Task.isCancelled else { return }
            self.hintStage = 2

            // Milestone 4: Urgent (80%)
            let urgentDelay = timeLimit * 0.10
            try? await Task.sleep(for: .seconds(urgentDelay))
            guard !Task.isCancelled else { return }
            self.timerStage = .urgent

            // Milestone 5: Timeout (100%)
            let timeoutDelay = timeLimit * 0.20
            try? await Task.sleep(for: .seconds(timeoutDelay))
            guard !Task.isCancelled else { return }
            self.handleTimeout()
        }
    }

    func selectOption(_ option: ReflexBlitzOption) {
        guard cardPhase == .activeCountdown else { return }
        finalizeActiveEngineAndTimers()
        let responseTimeMs = recordResponseTime()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: option.isCorrect,
                responseTimeMs: responseTimeMs,
                isTimeout: false,
                selectedOption: option.text
            ))
        }

        Task {
            await viewModel.submitAnswer(isCorrect: option.isCorrect, responseTimeMs: responseTimeMs)
        }
    }

    func submitTypingAnswer(_ text: String) {
        guard cardPhase == .activeCountdown, let current = viewModel.currentItem else { return }
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else { return }

        let isCorrect = cleanText.lowercased() == current.word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        finalizeActiveEngineAndTimers()
        let responseTimeMs = recordResponseTime()

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: responseTimeMs,
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
            await viewModel.submitAnswer(isCorrect: isCorrect, responseTimeMs: responseTimeMs)
        }
    }

    func handleTimeout() {
        guard cardPhase == .activeCountdown else { return }
        finalizeActiveEngineAndTimers()
        fractionRemaining = 0.0
        let elapsedMs = wordStartTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 500
        let responseTimeMs = max(500, elapsedMs)
        viewModel.elapsedTimeMs = responseTimeMs

        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            cardPhase = .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: responseTimeMs,
                isTimeout: true
            ))
        }

        if viewModel.currentItem?.assignedMode != .listening {
            viewModel.playAudioForCurrentWord()
        }

        Task {
            await viewModel.submitAnswer(isCorrect: false, responseTimeMs: responseTimeMs)
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
            let vm = viewModel
            speechEngine.onMatchDetected = { [weak vm] matched in
                Task { @MainActor [weak vm] in
                    guard self.cardPhase == .activeCountdown, let vm, let current = vm.currentItem else { return }
                    let isCorrect = ReflexSpeechMatcher.isReflexMatch(spokenText: matched, targetLemma: current.word.lemma)
                    if isCorrect {
                        self.finalizeActiveEngineAndTimers()
                        let responseTimeMs = self.recordResponseTime()

                        SoundEffectService.shared.playSuccessChime()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            self.cardPhase = .reviewed(result: ReflexCardResult(
                                isCorrect: true,
                                responseTimeMs: responseTimeMs,
                                isTimeout: false,
                                recognizedSpoken: matched
                            ))
                        }
                        await vm.submitAnswer(isCorrect: true, responseTimeMs: responseTimeMs)
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
        finalizeActiveEngineAndTimers()
        speechEngine?.stopSession()
    }

    func dismissPermissionAlert() {
        permissionNotice = nil
        viewModel.showPermissionAlert = false
        if case .activeCountdown = cardPhase, let current = viewModel.currentItem {
            wordStartTime = Date()
            startTimer(for: current)
        }
    }

    func handlePermissionDenied() {
        finalizeActiveEngineAndTimers()
        speechEngine?.stopSession()
        isPermissionDenied = true
        speechState = .unavailable
        permissionNotice = ReflexPermissionNotice()
        showPermissionAlert = true
        viewModel.fallbackSpeakingItemsToTyping()
        if let current = viewModel.currentItem {
            startDrillItem(current)
        }
    }

    func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }
}
