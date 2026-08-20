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

    private static let clozeRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\[\\s*_{3,}\\s*\\]|_{3,}")
    }()

    public var clozeParts: ClozeSentenceParts? {
        guard let regex = Self.clozeRegex else {
            return nil
        }
        let text = word.clozeSentenceEn
        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: nsRange),
              let matchRange = Range(match.range, in: text) else {
            return nil
        }
        let prefix = String(text[..<matchRange.lowerBound])
        let suffix = String(text[matchRange.upperBound...])
        let slot = isReviewed ? word.lemma : slotRepresentation
        return ClozeSentenceParts(prefix: prefix, slot: slot, suffix: suffix)
    }

    public var body: some View {
        VStack(spacing: 18) {
            if isReviewed {
                reviewedContentView
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
        .padding(.horizontal)
    }

    // MARK: - Active Countdown Content

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
        // Listening mode stimulus: Audio waveform + replay button (Lemma & Cloze hidden!)
        VStack(spacing: 12) {
            HStack(spacing: 5) {
                ForEach(0..<9, id: \.self) { index in
                    Capsule()
                        .fill(timerStrokeColor)
                        .frame(
                            width: 3.5,
                            height: CGFloat(8 + ((index * 5 + (elapsedTimeMs / 70)) % 16))
                        )
                        .animation(.easeInOut(duration: 0.12), value: elapsedTimeMs)
                }
            }
            .frame(height: 24)
            .accessibilityHidden(true)

            if let onReplayAudio = onReplayAudio {
                Button(action: onReplayAudio) {
                    HStack(spacing: 8) {
                        Image(systemName: "speaker.wave.2.fill")
                        Text("Nghe lại phát âm")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.vocabHeroAccent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.vocabHeroAccent.opacity(0.12))
                    .clipShape(Capsule())
                    .frame(minHeight: 44)
                }
                .buttonStyle(BentoCardButtonStyle())
                .accessibilityLabel("Nghe lại phát âm")
            }

            Text("Chọn nghĩa tiếng Việt của từ vừa nghe")
                .font(.footnote)
                .foregroundColor(.vocabMuted)
        }
        .padding(.vertical, 4)

        dividerLine

        activeOptionsGrid
    }

    // MARK: - Reviewed Content

    @ViewBuilder
    private var reviewedContentView: some View {
        VStack(spacing: 14) {
            // Status Header Badge
            HStack(spacing: 6) {
                Image(systemName: isResultCorrect ? "checkmark.circle.fill" : (isResultTimeout ? "clock.badge.exclamationmark.fill" : "xmark.circle.fill"))
                    .font(.subheadline.bold())
                Text(isResultCorrect ? "Chính xác!" : (isResultTimeout ? "Hết thời gian!" : "Chưa chính xác"))
                    .font(.subheadline.bold())
            }
            .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background((isResultCorrect ? Color.vocabMint : Color.vocabCoral).opacity(0.12))
            .clipShape(Capsule())

            // Target Lemma, POS, IPA, Audio Speaker Button
            VStack(spacing: 6) {
                HStack(alignment: .center, spacing: 10) {
                    Text(word.lemma)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.vocabInk)

                    if !word.pos.isEmpty {
                        Text(word.pos.uppercased())
                            .font(.caption2.weight(.bold))
                            .fontDesign(.rounded)
                            .foregroundColor(.vocabHeroAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.vocabHeroAccent.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    if let onReplayAudio = onReplayAudio {
                        Button(action: onReplayAudio) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.vocabHeroAccent)
                                .frame(width: 36, height: 36)
                                .background(Color.vocabHeroAccent.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .buttonStyle(BentoCardButtonStyle())
                        .accessibilityLabel("Phát âm lại từ")
                    }
                }

                if !word.ipa.isEmpty {
                    Text(word.ipa)
                        .font(.subheadline.monospaced())
                        .foregroundColor(.vocabMuted)
                        .accessibilityLabel("Phiên âm IPA: \(word.ipa)")
                }

                Text(word.definitionVi)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.vocabInk)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }

            dividerLine

            // Completed Context Sentence with Highlighted Target Word & Vietnamese translation
            VStack(spacing: 6) {
                sentenceView
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 8)

                if !word.exampleSentenceVi.isEmpty {
                    Text(word.exampleSentenceVi)
                        .font(.subheadline)
                        .foregroundColor(.vocabMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }

            // Options feedback or speech/typing feedback
            if (mode == .multipleChoice || mode == .listening) && !options.isEmpty {
                dividerLine
                reviewedOptionsGrid
            } else if mode == .speaking, let spoken = reviewResult?.recognizedSpoken, !spoken.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption)
                    Text("Nhận diện: \(spoken)")
                        .font(.caption.bold())
                }
                .foregroundColor(.vocabMint)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.vocabMint.opacity(0.12))
                .clipShape(Capsule())
            } else if mode == .typing, let typed = reviewResult?.typedText, !typed.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "keyboard")
                        .font(.caption)
                    Text("Đã nhập: \(typed)")
                        .font(.caption.bold())
                }
                .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background((isResultCorrect ? Color.vocabMint : Color.vocabCoral).opacity(0.12))
                .clipShape(Capsule())
            }
        }
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
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption2)
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
            ? [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
            : [GridItem(.flexible())]

        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                Button(action: {
                    onSelectOption?(option)
                }) {
                    HStack(spacing: 8) {
                        Text(optionLetter(for: index))
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.vocabMuted)
                            .frame(width: 22, height: 22)
                            .background(Color.vocabMuted.opacity(0.12))
                            .clipShape(Circle())

                        Text(option.text)
                            .font(isMultipleChoice ? .subheadline.weight(.semibold) : .subheadline)
                            .foregroundColor(.vocabInk)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    .background(Color.vocabCanvas)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
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
    private var reviewedOptionsGrid: some View {
        let isMultipleChoice = mode == .multipleChoice
        let gridColumns = isMultipleChoice
            ? [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
            : [GridItem(.flexible())]

        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let isSelected = (option.text == selectedOptionText)
                let isCorrect = option.isCorrect

                HStack(spacing: 8) {
                    Text(optionLetter(for: index))
                        .font(.caption2.weight(.bold))
                        .foregroundColor(
                            isSelected
                                ? (isCorrect ? .vocabMint : .vocabCoral)
                                : (isCorrect ? .vocabMint : .vocabMuted)
                        )
                        .frame(width: 22, height: 22)
                        .background(
                            (isSelected
                                ? (isCorrect ? Color.vocabMint : Color.vocabCoral)
                                : (isCorrect ? Color.vocabMint : Color.vocabMuted)
                            ).opacity(0.15)
                        )
                        .clipShape(Circle())

                    Text(option.text)
                        .font(isMultipleChoice ? .subheadline.weight(.semibold) : .subheadline)
                        .foregroundColor(
                            isSelected
                                ? (isCorrect ? .vocabMint : .vocabCoral)
                                : (isCorrect ? .vocabMint : .vocabInk.opacity(0.6))
                        )
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Spacer(minLength: 0)

                    if isSelected {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isCorrect ? .vocabMint : .vocabCoral)
                            .font(.subheadline)
                    } else if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.vocabMint)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                .background(
                    isSelected
                        ? (isCorrect ? Color.vocabMint.opacity(0.12) : Color.vocabCoral.opacity(0.12))
                        : (isCorrect ? Color.vocabMint.opacity(0.08) : Color.vocabCanvas.opacity(0.5))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            isSelected
                                ? (isCorrect ? Color.vocabMint : Color.vocabCoral)
                                : (isCorrect ? Color.vocabMint : Color.vocabHairline.opacity(0.4)),
                            lineWidth: isSelected || isCorrect ? 1.5 : 1
                        )
                )
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
                .padding(.vertical, 11)
                .background(Color.vocabCanvas)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
                    .font(.system(size: 32))
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
                HStack(spacing: 5) {
                    Image(systemName: "mic.fill")
                        .font(.caption2)
                    Text("Đang lắng nghe phát âm...")
                        .font(.footnote)
                }
                .foregroundColor(.vocabMuted)
                .transition(.opacity)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                    Text(liveTranscript)
                        .font(.footnote.weight(.bold))
                }
                .foregroundColor(timerStrokeColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(timerStrokeColor.opacity(0.12))
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.vocabCanvas.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: liveTranscript.isEmpty)
        .accessibilityLabel(liveTranscript.isEmpty ? "Đang chờ phát âm..." : "Nhận diện giọng nói: \(liveTranscript)")
    }
}
