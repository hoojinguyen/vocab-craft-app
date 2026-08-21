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
    @State private var itemStartTime: Date?
    @State private var fractionRemaining: Double = 1.0
    @State private var elapsedTimeMs: Int = 0
    @State private var cardPhase: ReflexCardPhase = .activeCountdown
    @State private var typingText: String = ""
    @State private var liveTranscript: String = ""
    @State private var isKeyboardFallbackActive: Bool = false
    @State private var currentOptions: [ReflexBlitzOption] = []
    @State private var showExitAlert: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @FocusState private var isTextFieldFocused: Bool

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
            // Header Bar with Close, Progress Bar, Step Counter, Combo Flame
            sessionHeaderBar(currentItem: currentItem)
                .padding(.top, 10)

            // Dynamic Mode Badge & Dynamic Pulse Timer Bar
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

            // Challenge Interactive Card
            challengeCard(for: currentItem)
                .padding(.horizontal, 16)

            Spacer(minLength: 8)

            // Bottom Advance / Skip Dock in Thumb Reach Zone
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
            // Close Button
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
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .accessibilityLabel("Đóng bài luyện tập")

            Spacer()

            // Center Segmented Step Counter
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    ForEach(0..<max(1, viewModel.queue.count), id: \.self) { index in
                        Capsule()
                            .fill(stepSegmentColor(for: index))
                            .frame(height: 4)
                            .frame(maxWidth: 16)
                    }
                }

                Text("\(viewModel.currentIndex + 1) / \(viewModel.queue.count)")
                    .font(.caption2.monospacedDigit().bold())
                    .foregroundColor(.vocabMuted)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tiến độ: câu \(viewModel.currentIndex + 1) trên \(viewModel.queue.count)")

            Spacer()

            // Combo Flame Badge
            if viewModel.comboStreak >= 2 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .symbolRenderingMode(.multicolor)
                    Text("x\(viewModel.comboStreak)")
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
                reviewedCardView(for: item)
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
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
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
            activeMultipleChoiceView(for: item)
        case .speaking:
            if isKeyboardFallbackActive {
                activeTypingView(for: item)
            } else {
                activeSpeakingView(for: item)
            }
        case .typing:
            activeTypingView(for: item)
        case .listening:
            activeListeningView(for: item)
        }
    }

    // MARK: - Mode 1: Multiple Choice
    @ViewBuilder
    private func activeMultipleChoiceView(for item: MixedReflexDrillItem) -> some View {
        wordPromptHeader(for: item.word)

        clozeSentenceView(for: item.word, isReviewed: false)

        dividerLine

        // 2x2 Option Grid
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(Array(currentOptions.enumerated()), id: \.element.id) { index, option in
                Button(action: {
                    handleAnswerSubmission(isCorrect: option.isCorrect, selectedOption: option.text)
                }) {
                    HStack(spacing: 8) {
                        Text(optionLetter(for: index))
                            .font(.caption.bold())
                            .foregroundColor(.vocabMuted)
                            .frame(width: 22, height: 22)
                            .background(Color.vocabMuted.opacity(0.12))
                            .clipShape(Circle())

                        Text(option.text)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.vocabInk)
                            .lineLimit(2)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: 50, alignment: .leading)
                    .background(Color.vocabCanvas)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.vocabHairline, lineWidth: 1)
                    )
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Lựa chọn \(optionLetter(for: index)): \(option.text)")
            }
        }
    }

    // MARK: - Mode 2: Speaking
    @ViewBuilder
    private func activeSpeakingView(for item: MixedReflexDrillItem) -> some View {
        wordPromptHeader(for: item.word)

        clozeSentenceView(for: item.word, isReviewed: false)

        dividerLine

        // Waveform & Listening State Dock
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<9, id: \.self) { idx in
                    Capsule()
                        .fill(Color.vocabMint)
                        .frame(width: 3.5, height: CGFloat(8 + ((idx * 5 + (elapsedTimeMs / 60)) % 18)))
                        .animation(.easeInOut(duration: 0.1), value: elapsedTimeMs)
                }
            }
            .frame(height: 26)
            .accessibilityHidden(true)

            if liveTranscript.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.caption2)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.vocabMint)

                    Text("Đang lắng nghe phát âm...")
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.vocabMuted)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                        .foregroundColor(.vocabHeroAccent)

                    Text(liveTranscript)
                        .font(.footnote.bold())
                        .foregroundColor(.vocabHeroAccent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.vocabHeroAccent.opacity(0.12))
                .clipShape(Capsule())
            }

            // Keyboard Fallback Switch
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    isKeyboardFallbackActive = true
                    speechService?.pauseListening()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "keyboard")
                        .font(.caption2)
                    Text("Chuyển sang gõ từ")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundColor(.vocabMuted)
                .padding(.top, 4)
                .frame(minHeight: 44)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.vocabCanvas.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Mode 3: Typing
    @ViewBuilder
    private func activeTypingView(for item: MixedReflexDrillItem) -> some View {
        wordPromptHeader(for: item.word)

        clozeSentenceView(for: item.word, isReviewed: false)

        dividerLine

        HStack(spacing: 8) {
            TextField("Gõ từ tiếng Anh...", text: $typingText)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.vocabCanvas)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isTextFieldFocused ? Color.vocabHeroAccent : Color.vocabHairline, lineWidth: isTextFieldFocused ? 1.5 : 1)
                )
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit {
                    submitTypingAnswer(for: item.word)
                }

            Button(action: {
                submitTypingAnswer(for: item.word)
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(typingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .vocabMuted.opacity(0.35) : .vocabHeroAccent)
            }
            .disabled(typingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Gửi câu trả lời đã gõ")
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func submitTypingAnswer(for word: VaultWordItem) {
        let input = typingText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !input.isEmpty else { return }
        let target = word.lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let isCorrect = input == target
        handleAnswerSubmission(isCorrect: isCorrect, typedText: typingText)
    }

    // MARK: - Mode 4: Listening
    @ViewBuilder
    private func activeListeningView(for item: MixedReflexDrillItem) -> some View {
        // Lemma is hidden during listening drill!
        VStack(spacing: 12) {
            // Audio wave visualizer
            HStack(spacing: 5) {
                ForEach(0..<11, id: \.self) { idx in
                    Capsule()
                        .fill(Color.vocabHeroAccent)
                        .frame(width: 3.5, height: CGFloat(8 + ((idx * 6 + (elapsedTimeMs / 60)) % 22)))
                        .animation(.easeInOut(duration: 0.1), value: elapsedTimeMs)
                }
            }
            .frame(height: 28)
            .accessibilityHidden(true)

            Button(action: {
                viewModel.playAudioForCurrentWord()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 15, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                    Text("Nghe lại phát âm")
                        .font(.subheadline.bold())
                }
                .foregroundColor(.vocabHeroAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.vocabHeroAccent.opacity(0.35), lineWidth: 1)
                )
                .frame(minHeight: 44)
            }
            .buttonStyle(BentoCardButtonStyle())
            .accessibilityLabel("Nghe lại phát âm")

            Text("Chọn nghĩa tiếng Việt chính xác của từ vừa nghe")
                .font(.caption.weight(.medium))
                .foregroundColor(.vocabMuted)
        }
        .padding(.vertical, 4)

        dividerLine

        // 1-column Definition Options List
        VStack(spacing: 8) {
            ForEach(Array(currentOptions.enumerated()), id: \.element.id) { index, option in
                Button(action: {
                    handleAnswerSubmission(isCorrect: option.isCorrect, selectedOption: option.text)
                }) {
                    HStack(spacing: 8) {
                        Text(optionLetter(for: index))
                            .font(.caption.bold())
                            .foregroundColor(.vocabMuted)
                            .frame(width: 22, height: 22)
                            .background(Color.vocabMuted.opacity(0.12))
                            .clipShape(Circle())

                        Text(option.text)
                            .font(.subheadline)
                            .foregroundColor(.vocabInk)
                            .lineLimit(2)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
                    .background(Color.vocabCanvas)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.vocabHairline, lineWidth: 1)
                    )
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Lựa chọn \(optionLetter(for: index)): \(option.text)")
            }
        }
    }

    // MARK: - Reviewed Card State View
    @ViewBuilder
    private func reviewedCardView(for item: MixedReflexDrillItem) -> some View {
        VStack(spacing: 12) {
            // Status Header Badge
            HStack(spacing: 6) {
                Image(systemName: isResultCorrect ? "checkmark.circle.fill" : (isResultTimeout ? "clock.badge.exclamationmark.fill" : "xmark.circle.fill"))
                    .font(.headline.bold())
                    .symbolRenderingMode(.hierarchical)

                Text(isResultCorrect ? "Chính xác!" : (isResultTimeout ? "Hết thời gian!" : "Chưa chính xác"))
                    .font(.headline.bold())
                    .fontDesign(.rounded)
            }
            .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background((isResultCorrect ? Color.vocabMint : Color.vocabCoral).opacity(0.14))
            .clipShape(Capsule())

            // Correct Lemma & Speaker
            HStack(alignment: .center, spacing: 8) {
                Text(item.word.lemma)
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.vocabInk)

                Button(action: {
                    viewModel.playAudioForCurrentWord()
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.vocabHeroAccent)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.vocabHeroAccent.opacity(0.25), lineWidth: 0.8)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Nghe phát âm từ \(item.word.lemma)")
            }

            // Phonetics & POS
            let meta = [item.word.pos, item.word.phonetic].filter { !$0.isEmpty }.joined(separator: " • ")
            if !meta.isEmpty {
                Text(meta)
                    .font(.caption.monospaced())
                    .foregroundColor(.vocabMuted)
            }

            // Vietnamese Definition
            Text(item.word.definitionVi)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.vocabInk.opacity(0.85))
                .multilineTextAlignment(.center)

            // Complete Sentence
            if !item.word.exampleSentenceEn.isEmpty {
                dividerLine

                Text(item.word.exampleSentenceEn)
                    .font(.subheadline.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Prompt Header Component
    private func wordPromptHeader(for word: VaultWordItem) -> some View {
        VStack(spacing: 4) {
            if !word.pos.isEmpty {
                Text(word.pos.uppercased())
                    .font(.caption2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.vocabHeroAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.vocabHeroAccent.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(word.definitionVi)
                .font(.headline.weight(.bold))
                .foregroundColor(.vocabInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    // MARK: - Cloze Sentence Component
    private func clozeSentenceView(for word: VaultWordItem, isReviewed: Bool) -> some View {
        let sentence = word.exampleSentenceEn
        guard !sentence.isEmpty else {
            return AnyView(EmptyView())
        }

        let cloze = ReflexClozeFormatter.formatCloze(sentenceEn: sentence, lemma: word.lemma)
        let (prefix, suffix) = ReflexClozeFormatter.extractTemplateParts(from: cloze)

        return AnyView(
            VStack(spacing: 4) {
                if !suffix.isEmpty || cloze != prefix {
                    Text(prefix)
                        .font(.subheadline.weight(.medium))
                        .fontDesign(.serif)
                        .foregroundColor(.vocabInk)
                    +
                    Text(isReviewed ? word.lemma : "[ _______ ]")
                        .font(.subheadline.bold())
                        .fontDesign(isReviewed ? .serif : .monospaced)
                        .foregroundColor(isReviewed ? (isResultCorrect ? .vocabMint : .vocabCoral) : .vocabHeroAccent)
                    +
                    Text(suffix)
                        .font(.subheadline.weight(.medium))
                        .fontDesign(.serif)
                        .foregroundColor(.vocabInk)
                } else {
                    Text(sentence)
                        .font(.subheadline.weight(.medium))
                        .fontDesign(.serif)
                        .foregroundColor(.vocabInk)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 4)
        )
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color.vocabHairline, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 4)
    }

    private func optionLetter(for index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return index < letters.count ? letters[index] : "\(index + 1)"
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
        itemStartTime = startTime
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

        speechService?.onMatchDetected = { matchedLemma in
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
