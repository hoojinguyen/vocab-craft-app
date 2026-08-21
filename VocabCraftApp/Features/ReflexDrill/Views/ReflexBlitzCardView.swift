import SwiftUI

/// Structural breakdown of a cloze sentence for inline styled reveal.
public struct ClozeSentenceParts: Equatable, Sendable {
    public let prefix: String
    public let slot: String
    public let suffix: String

    public init(prefix: String, slot: String, suffix: String) {
        self.prefix = prefix
        self.slot = slot
        self.suffix = suffix
    }
}

/// Challenge card view for Reflex Blitz drill supporting 4 modalities (Speaking, Typing, Multiple Choice, Listening)
/// and a paused review consolidation state.
public struct ReflexBlitzCardView: View {
    public let word: ReflexBlitzWordItem
    public let mode: ReflexBlitzMode
    public let cardPhase: ReflexCardPhase
    public let options: [ReflexBlitzOption]
    public let fractionRemaining: Double
    public let timerStage: ReflexBlitzTimerStage
    public let showHint: Bool
    public let isCorrect: Bool
    public let isTimeout: Bool
    public let liveTranscript: String
    public let elapsedTimeMs: Int
    public let isKeyboardFallbackActive: Bool
    @Binding public var keyboardInputText: String
    public let onSelectOption: ((ReflexBlitzOption) -> Void)?
    public let onSubmitKeyboard: (() -> Void)?
    public let onReplayAudio: (() -> Void)?

    @FocusState private var isTextFieldFocused: Bool
    @State private var shakeOffset: CGFloat = 0

    public init(
        word: ReflexBlitzWordItem,
        mode: ReflexBlitzMode = .speaking,
        cardPhase: ReflexCardPhase = .activeCountdown,
        options: [ReflexBlitzOption] = [],
        fractionRemaining: Double = 1.0,
        timerStage: ReflexBlitzTimerStage = .steady,
        showHint: Bool = false,
        isCorrect: Bool = false,
        isTimeout: Bool = false,
        liveTranscript: String = "",
        elapsedTimeMs: Int = 0,
        isKeyboardFallbackActive: Bool = false,
        keyboardInputText: Binding<String> = .constant(""),
        onSelectOption: ((ReflexBlitzOption) -> Void)? = nil,
        onSubmitKeyboard: (() -> Void)? = nil,
        onReplayAudio: (() -> Void)? = nil
    ) {
        self.word = word
        self.mode = mode
        self.cardPhase = cardPhase
        self.options = options
        self.fractionRemaining = fractionRemaining
        self.timerStage = timerStage
        self.showHint = showHint
        self.isCorrect = isCorrect
        self.isTimeout = isTimeout
        self.liveTranscript = liveTranscript
        self.elapsedTimeMs = elapsedTimeMs
        self.isKeyboardFallbackActive = isKeyboardFallbackActive
        self._keyboardInputText = keyboardInputText
        self.onSelectOption = onSelectOption
        self.onSubmitKeyboard = onSubmitKeyboard
        self.onReplayAudio = onReplayAudio
    }

    public var isReviewed: Bool {
        if case .reviewed = cardPhase {
            return true
        }
        return isCorrect || isTimeout
    }

    public var reviewResult: ReflexCardResult? {
        if case .reviewed(let result) = cardPhase {
            return result
        }
        if isCorrect || isTimeout {
            return ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: elapsedTimeMs,
                isTimeout: isTimeout
            )
        }
        return nil
    }

    public var isResultCorrect: Bool {
        if let result = reviewResult {
            return result.isCorrect
        }
        return isCorrect
    }

    public var isResultTimeout: Bool {
        if let result = reviewResult {
            return result.isTimeout
        }
        return isTimeout
    }

    public var selectedOptionText: String? {
        reviewResult?.selectedOption
    }

    public var displayedSentence: String {
        if isReviewed {
            return word.completedSentenceWithTargetWord
        } else {
            return word.clozeSentenceEn
        }
    }

    public var cardBorderColor: Color {
        if isReviewed {
            return isResultCorrect ? .vocabMint : .vocabCoral
        } else {
            switch timerStage {
            case .steady:
                return Color.vocabHairline.opacity(0.6)
            case .warning:
                return Color.vocabPeach.opacity(0.8)
            case .urgent:
                return Color.vocabCoral
            }
        }
    }

    public var timerStrokeColor: Color {
        if isResultCorrect {
            return .vocabMint
        } else if isResultTimeout {
            return .vocabCoral
        } else {
            switch timerStage {
            case .steady:
                return .vocabHeroAccent
            case .warning:
                return .vocabPeach
            case .urgent:
                return .vocabCoral
            }
        }
    }

    public var slotRepresentation: String {
        if isReviewed {
            return word.lemma
        } else if showHint {
            let initial = String(word.lemma.prefix(1)).lowercased()
            let dotsCount = max(1, word.lemma.count - 1)
            return "[ \(initial)" + String(repeating: " •", count: dotsCount) + " ]"
        } else {
            let dotsCount = max(3, min(6, word.lemma.count))
            let dots = String(repeating: "• ", count: dotsCount).trimmingCharacters(in: .whitespaces)
            return "[ \(dots) ]"
        }
    }

    public var clozeParts: ClozeSentenceParts? {
        guard word.hasClozeSlot else { return nil }
        let slot = isReviewed ? word.lemma : slotRepresentation
        return ClozeSentenceParts(prefix: word.clozePrefix, slot: slot, suffix: word.clozeSuffix)
    }

    public var body: some View {
        VStack(spacing: 18) {
            if isReviewed {
                ReflexBlitzCardReviewedView(
                    word: word,
                    mode: mode,
                    isReviewed: isReviewed,
                    isResultCorrect: isResultCorrect,
                    isResultTimeout: isResultTimeout,
                    options: options,
                    reviewResult: reviewResult,
                    selectedOptionText: selectedOptionText,
                    clozeParts: clozeParts,
                    displayedSentence: displayedSentence,
                    onReplayAudio: onReplayAudio
                )
            } else {
                activeCountdownContentView
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cardBorderColor, lineWidth: isReviewed ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .offset(x: shakeOffset)
        .padding(.horizontal)
        .onChange(of: isReviewed) { _, reviewed in
            if reviewed && !isResultCorrect {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.2, blendDuration: 0.15)) {
                    shakeOffset = 6
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    shakeOffset = 0
                }
            }
        }
    }
}

// MARK: - Active Countdown Subviews

extension ReflexBlitzCardView {
    @ViewBuilder
    private var activeCountdownContentView: some View {
        switch mode {
        case .speaking:
            activeSpeakingContent
        case .typing:
            activeTypingContent
        case .multipleChoice:
            activeMultipleChoiceContent
        case .listening:
            activeListeningContent
        }
    }

    @ViewBuilder
    private var activeSpeakingContent: some View {
        triggerArea
        sentenceArea
        scaffoldingArea
        dividerLine
        if isKeyboardFallbackActive {
            typingInputDockView
        } else {
            livingAudioDockView
        }
    }

    @ViewBuilder
    private var activeTypingContent: some View {
        triggerArea
        sentenceArea
        scaffoldingArea
        dividerLine
        typingInputDockView
    }

    @ViewBuilder
    private var activeMultipleChoiceContent: some View {
        triggerArea
        sentenceArea
        scaffoldingArea
        dividerLine
        activeOptionsGrid
    }

    @ViewBuilder
    private var activeListeningContent: some View {
        // Listening mode stimulus: Hero Audio Player Widget + Replay cue (Lemma & Cloze hidden!)
        VStack(spacing: 16) {
            // Pulsing Audio Visualizer
            HStack(spacing: 6) {
                ForEach(0..<11, id: \.self) { index in
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.vocabHeroAccent, Color.vocabHeroAccent.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: 3.5,
                            height: CGFloat(10 + ((index * 6 + (elapsedTimeMs / 60)) % 22))
                        )
                        .animation(.easeInOut(duration: 0.1), value: elapsedTimeMs)
                }
            }
            .frame(height: 32)
            .accessibilityHidden(true)

            if let onReplayAudio = onReplayAudio {
                Button(action: onReplayAudio) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 16, weight: .bold))
                            .symbolRenderingMode(.hierarchical)
                            .symbolEffect(.pulse, options: .repeating)

                        Text("Nghe lại phát âm")

                            .font(.subheadline.weight(.bold))
                    }
                    .foregroundColor(.vocabHeroAccent)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.vocabHeroAccent.opacity(0.3), lineWidth: 1)
                    )
                    .frame(minHeight: 44)
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Nghe lại phát âm")
            }

            Text("Chọn nghĩa tiếng Việt của từ vừa nghe")
                .font(.footnote.weight(.medium))
                .foregroundColor(.vocabMuted)
        }
        .padding(.vertical, 8)

        dividerLine

        activeOptionsGrid
    }

    // MARK: - Subviews & Areas

    @ViewBuilder
    private var triggerArea: some View {
        VStack(spacing: 6) {
            if !word.pos.isEmpty {
                Text(word.pos.uppercased())
                    .font(.caption2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.vocabHeroAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.vocabHeroAccent.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(word.definitionVi)
                .font(.title3.weight(.bold))
                .foregroundColor(.vocabInk)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .accessibilityLabel("Nghĩa tiếng Việt: \(word.definitionVi)")
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private var sentenceArea: some View {
        sentenceView
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(.horizontal, 8)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isResultCorrect)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isResultTimeout)
            .accessibilityLabel(
                isReviewed
                    ? "Câu hoàn chỉnh: \(word.completedSentenceWithTargetWord)"
                    : "Câu điền từ: \(word.clozeSentenceEn)"
            )
    }

    @ViewBuilder
    private var scaffoldingArea: some View {
        if isReviewed && !word.ipa.isEmpty {
            HStack(spacing: 5) {
                Image(systemName: "waveform")
                    .font(.caption2)
                    .symbolRenderingMode(.hierarchical)
                Text(word.ipa)
                    .font(.subheadline.monospaced())
                    .lineLimit(1)
            }
            .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                (isResultCorrect ? Color.vocabMint : Color.vocabCoral).opacity(0.14)
            )
            .clipShape(Capsule())
            .transition(.scale.combined(with: .opacity))
            .accessibilityLabel("Phiên âm IPA: \(word.ipa)")
        } else if showHint && !isReviewed {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.min.fill")
                    .font(.caption2)
                    .symbolRenderingMode(.hierarchical)
                Text("Gợi ý: \(word.initialLetterHint)")
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color.vocabPeach.opacity(0.16))
            .foregroundColor(.vocabPeach)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.vocabPeach.opacity(0.35), lineWidth: 1)
            )
            .transition(.scale.combined(with: .opacity))
            .accessibilityLabel("Gợi ý ký tự đầu: \(word.initialLetterHint)")
        }
    }

    @ViewBuilder
    private var sentenceView: some View {
        if let parts = clozeParts {
            if isReviewed {
                Text(parts.prefix)
                    .font(.title3.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
                +
                Text(parts.slot)
                    .font(.title3.weight(.bold))
                    .fontDesign(.serif)
                    .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
                +
                Text(parts.suffix)
                    .font(.title3.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
            } else {
                Text(parts.prefix)
                    .font(.title3.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
                +
                Text(parts.slot)
                    .font(.title3.bold())
                    .fontDesign(.monospaced)
                    .foregroundColor(slotTextColor)
                +
                Text(parts.suffix)
                    .font(.title3.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
            }
        } else {
            Text(displayedSentence)
                .font(.title3.weight(isReviewed ? .bold : .medium))
                .fontDesign(.serif)
                .foregroundColor(isReviewed ? (isResultCorrect ? .vocabMint : .vocabCoral) : .vocabInk)
        }
    }

    private var slotTextColor: Color {
        if isReviewed {
            return isResultCorrect ? .vocabMint : .vocabCoral
        } else if showHint {
            return .vocabPeach
        } else {
            return .vocabHeroAccent
        }
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Color.vocabHairline.opacity(0.6), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 8)
    }

    private func optionLetter(for index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        if index >= 0 && index < letters.count {
            return letters[index]
        }
        return "\(index + 1)"
    }

    @ViewBuilder
    private var activeOptionsGrid: some View {
        let isMultipleChoice = mode == .multipleChoice
        let gridColumns = isMultipleChoice
            ? [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            : [GridItem(.flexible())]

        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                Button(action: {
                    onSelectOption?(option)
                }) {
                    HStack(spacing: 10) {
                        Text(optionLetter(for: index))
                            .font(.caption.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundColor(.vocabMuted)
                            .frame(width: 24, height: 24)
                            .background(Color.vocabMuted.opacity(0.12))
                            .clipShape(Circle())

                        Text(option.text)
                            .font(isMultipleChoice ? .subheadline.weight(.semibold) : .subheadline)
                            .foregroundColor(.vocabInk)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                    .background(Color.vocabCanvas)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.vocabHairline.opacity(0.8), lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Lựa chọn \(optionLetter(for: index)): \(option.text)")
            }
        }
    }

    @ViewBuilder
    private var typingInputDockView: some View {
        HStack(spacing: 10) {
            TextField("Gõ từ tiếng Anh...", text: $keyboardInputText)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.vocabCanvas)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            isTextFieldFocused ? Color.vocabHeroAccent : Color.vocabHairline.opacity(0.8),
                            lineWidth: isTextFieldFocused ? 1.5 : 1
                        )
                )
                .autocorrectionDisabled()
                #if os(iOS)
                .textInputAutocapitalization(.never)
                #endif
                .onSubmit {
                    onSubmitKeyboard?()
                }
                .accessibilityLabel("Ô nhập từ tiếng Anh")

            Button(action: {
                onSubmitKeyboard?()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34, weight: .bold))
                    .symbolRenderingMode(.hierarchical)
                    .symbolEffect(.bounce, value: keyboardInputText.count)
                    .foregroundColor(
                        keyboardInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .vocabMuted.opacity(0.35)
                            : .vocabHeroAccent
                    )
            }
            .disabled(keyboardInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Gửi câu trả lời đã gõ")
        }
        .padding(.horizontal, 4)
        .onAppear {
            if !isReviewed {
                isTextFieldFocused = true
            }
        }
    }

    @ViewBuilder
    private var livingAudioDockView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(0..<9, id: \.self) { index in
                    Capsule()
                        .fill(
                            isResultCorrect
                                ? Color.vocabMint
                                : (isResultTimeout ? Color.vocabCoral : timerStrokeColor)
                        )
                        .frame(
                            width: 3.5,
                            height: CGFloat(8 + ((index * 5 + (elapsedTimeMs / 70)) % 16))
                        )
                        .animation(.easeInOut(duration: 0.12), value: elapsedTimeMs)
                }
            }
            .frame(height: 24)
            .accessibilityHidden(true)

            if liveTranscript.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.caption2)
                        .symbolRenderingMode(.hierarchical)
                        .symbolEffect(.pulse, options: .repeating)

                    Text("Đang lắng nghe phát âm...")
                        .font(.footnote.weight(.medium))
                }
                .foregroundColor(.vocabMuted)
                .transition(.opacity)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                        .symbolRenderingMode(.hierarchical)

                    Text(liveTranscript)
                        .font(.footnote.weight(.bold))
                }
                .foregroundColor(timerStrokeColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(timerStrokeColor.opacity(0.12))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.vocabCanvas.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: liveTranscript.isEmpty)
        .accessibilityLabel(liveTranscript.isEmpty ? "Đang chờ phát âm..." : "Nhận diện giọng nói: \(liveTranscript)")
    }
}
