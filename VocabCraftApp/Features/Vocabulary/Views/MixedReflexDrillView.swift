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
    @State private var shakeOffset: CGFloat = 0

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

    public var body: some View {
        ZStack {
            Color.vocabCanvas
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
        .alert("Thoát bài luyện tập?", isPresented: $showExitAlert) {
            Button("Tiếp tục luyện tập", role: .cancel) {}
            Button("Thoát", role: .destructive) {
                stopDrillSession()
                onFinish()
            }
        } message: {
            Text("Tiến độ của các từ chưa hoàn thành sẽ không được lưu vào phiên này.")
        }
        .sensoryFeedback(.success, trigger: isResultCorrect) { _, isCorrect in isCorrect }
        .sensoryFeedback(.error, trigger: isResultTimeout || (isReviewed && !isResultCorrect)) { _, isError in isError }
    }

    // MARK: - Drilling Session Main Content
    @ViewBuilder
    private func drillingSessionContent(currentItem: MixedReflexDrillItem) -> some View {
        VStack(spacing: 14) {
            sessionHeaderBar(currentItem: currentItem)
                .padding(.top, 10)

            VStack(spacing: 8) {
                DynamicReflexModeBadge(mode: currentItem.assignedMode)

                DynamicPulseTimerBar(
                    fractionRemaining: fractionRemaining,
                    totalDurationSeconds: currentItem.assignedMode.timeLimitSeconds,
                    isActive: cardPhase == .activeCountdown
                )
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 8)

            challengeCard(for: currentItem)
                .padding(.horizontal, 16)

            Spacer(minLength: 8)

            ReflexBlitzAdvanceDockView(
                cardPhase: cardPhase,
                onAdvance: {
                    advanceToNextItem()
                },
                onSkip: {
                    handleTimeout()
                }
            )
            .padding(.bottom, 12)
        }
    }

    // MARK: - Header Bar
    private func sessionHeaderBar(currentItem: MixedReflexDrillItem) -> some View {
        HStack(alignment: .center) {
            Button(action: {
                showExitAlert = true
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.vocabInk)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.vocabHairline, lineWidth: 1)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Thoát bài luyện tập")

            Spacer()

            HStack(spacing: 4) {
                ForEach(0..<viewModel.queue.count, id: \.self) { idx in
                    Capsule()
                        .fill(stepSegmentColor(for: idx))
                        .frame(width: max(4, min(14, 180.0 / Double(max(1, viewModel.queue.count)))), height: 5)
                }
            }

            Spacer()

            if viewModel.comboStreak > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.caption2.bold())
                        .foregroundColor(.vocabPeach)
                    Text("\(viewModel.comboStreak)x")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundColor(.vocabPeach)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.vocabPeach.opacity(0.14))
                .clipShape(Capsule())
                .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
    }

    private func stepSegmentColor(for index: Int) -> Color {
        if index < viewModel.attempts.count {
            return viewModel.attempts[index].isCorrect ? Color.vocabMint : Color.vocabCoral
        } else if index == viewModel.currentIndex {
            return Color.vocabHeroAccent
        } else {
            return Color.vocabHairline.opacity(0.4)
        }
    }

    // MARK: - Challenge Card Container
    @ViewBuilder
    private func challengeCard(for item: MixedReflexDrillItem) -> some View {
        VStack(spacing: 16) {
            if isReviewed {
                MixedDrillReviewedSection(
                    item: item,
                    result: reviewedResult,
                    onPlayAudio: {
                        viewModel.playAudioForCurrentWord()
                    }
                )
            } else {
                activeChallengeContent(for: item)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(cardBorderColor, lineWidth: isReviewed ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        .offset(x: shakeOffset)
    }

    private var cardBorderColor: Color {
        if isReviewed {
            return isResultCorrect ? .vocabMint : .vocabCoral
        } else {
            return Color.vocabHairline
        }
    }

    // MARK: - Active Challenge Content by Mode
    @ViewBuilder
    private func activeChallengeContent(for item: MixedReflexDrillItem) -> some View {
        switch item.assignedMode {
        case .multipleChoice:
            MixedDrillMultipleChoiceSection(
                word: item.word,
                options: currentOptions,
                onSelectOption: { option in
                    handleAnswerSubmission(isCorrect: option.isCorrect, selectedOption: option.text)
                }
            )
        case .speaking:
            if isKeyboardFallbackActive {
                MixedDrillTypingSection(
                    word: item.word,
                    typingText: $typingText,
                    onSubmit: {
                        submitTypingAnswer(for: item.word)
                    }
                )
            } else {
                MixedDrillSpeakingSection(
                    word: item.word,
                    liveTranscript: liveTranscript,
                    elapsedTimeMs: elapsedTimeMs,
                    onSwitchToKeyboard: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            isKeyboardFallbackActive = true
                            speechService?.pauseListening()
                        }
                    }
                )
            }
        case .typing:
            MixedDrillTypingSection(
                word: item.word,
                typingText: $typingText,
                onSubmit: {
                    submitTypingAnswer(for: item.word)
                }
            )
        case .listening:
            MixedDrillListeningSection(
                options: currentOptions,
                elapsedTimeMs: elapsedTimeMs,
                onPlayAudio: {
                    viewModel.playAudioForCurrentWord()
                },
                onSelectOption: { option in
                    handleAnswerSubmission(isCorrect: option.isCorrect, selectedOption: option.text)
                }
            )
        }
    }

    private func submitTypingAnswer(for word: VaultWordItem) {
        let input = typingText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !input.isEmpty else { return }
        let target = word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isCorrect = input == target
        handleAnswerSubmission(isCorrect: isCorrect, typedText: typingText)
    }

    // MARK: - Session Execution & Drill Flow Logic
    private func startDrillItem(_ item: MixedReflexDrillItem) {
        timerTask?.cancel()
        cardPhase = .activeCountdown
        typingText = ""
        liveTranscript = ""
        isKeyboardFallbackActive = false
        fractionRemaining = 1.0
        elapsedTimeMs = 0

        let startTime = Date()
        currentOptions = viewModel.generateOptions(for: item)

        if item.assignedMode == .listening {
            viewModel.playAudioForCurrentWord()
        }

        if item.assignedMode == .speaking {
            speechService?.startSession()
            speechService?.setTargetWord(lemma: item.word.lemma, contextualPhrases: [item.word.exampleSentenceEn])
        }

        let timeLimit = item.assignedMode.timeLimitSeconds
        timerTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(50))
                guard !Task.isCancelled else { break }
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0.0, min(1.0, 1.0 - (elapsed / timeLimit)))
                self.fractionRemaining = remaining
                self.elapsedTimeMs = Int(elapsed * 1000)

                if elapsed >= timeLimit {
                    handleTimeout()
                    break
                }
            }
        }
    }

    private func handleAnswerSubmission(isCorrect: Bool, selectedOption: String? = nil, typedText: String? = nil) {
        timerTask?.cancel()
        speechService?.pauseListening()

        let responseTime = max(200, elapsedTimeMs)
        let result = ReflexCardResult(
            isCorrect: isCorrect,
            responseTimeMs: responseTime,
            isTimeout: false,
            selectedOption: selectedOption,
            typedText: typedText,
            recognizedSpoken: liveTranscript
        )

        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            cardPhase = .reviewed(result: result)
        }

        if !isCorrect {
            triggerErrorShake()
        }

        Task { @MainActor in
            await viewModel.submitAnswer(isCorrect: isCorrect, responseTimeMs: responseTime)
        }
    }

    private func handleTimeout() {
        guard cardPhase == .activeCountdown, let current = viewModel.currentItem else { return }
        timerTask?.cancel()
        speechService?.pauseListening()

        let timeoutTimeMs = Int(current.assignedMode.timeLimitSeconds * 1000)
        let result = ReflexCardResult(
            isCorrect: false,
            responseTimeMs: timeoutTimeMs,
            isTimeout: true
        )

        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            cardPhase = .reviewed(result: result)
        }

        triggerErrorShake()

        Task { @MainActor in
            await viewModel.submitAnswer(isCorrect: false, responseTimeMs: timeoutTimeMs)
        }
    }

    private func triggerErrorShake() {
        withAnimation(.spring(response: 0.12, dampingFraction: 0.2)) {
            shakeOffset = 6
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            shakeOffset = 0
        }
    }

    private func advanceToNextItem() {
        if viewModel.isCompleted {
            return
        }
        if let next = viewModel.currentItem {
            startDrillItem(next)
        }
    }

    private func setupSpeechServiceCallbacks() {
        speechService?.onTranscriptUpdate = { transcript in
            Task { @MainActor in
                self.liveTranscript = transcript
            }
        }

        speechService?.onMatchDetected = { _ in
            Task { @MainActor in
                guard self.cardPhase == .activeCountdown else { return }
                self.handleAnswerSubmission(isCorrect: true)
            }
        }
    }

    private func stopDrillSession() {
        timerTask?.cancel()
        timerTask = nil
        speechService?.stopSession()
    }
}
