import SwiftUI

// MARK: - Multiple Choice Section
public struct MixedDrillMultipleChoiceSection: View {
    public let word: VaultWordItem
    public let options: [ReflexBlitzOption]
    public let onSelectOption: (ReflexBlitzOption) -> Void

    public init(
        word: VaultWordItem,
        options: [ReflexBlitzOption],
        onSelectOption: @escaping (ReflexBlitzOption) -> Void
    ) {
        self.word = word
        self.options = options
        self.onSelectOption = onSelectOption
    }

    public var body: some View {
        VStack(spacing: 14) {
            MixedDrillPromptHeader(word: word)

            MixedDrillClozeSentence(word: word, isReviewed: false)

            Rectangle()
                .fill(Color.vocabHairline)
                .frame(height: 1)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button(action: {
                        onSelectOption(option)
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
    }

    private func optionLetter(for index: Int) -> String {
        switch index {
        case 0: return "A"
        case 1: return "B"
        case 2: return "C"
        case 3: return "D"
        default: return "\(index + 1)"
        }
    }
}

// MARK: - Speaking Section
public struct MixedDrillSpeakingSection: View {
    public let word: VaultWordItem
    public let liveTranscript: String
    public let elapsedTimeMs: Int
    public let onSwitchToKeyboard: () -> Void

    public init(
        word: VaultWordItem,
        liveTranscript: String,
        elapsedTimeMs: Int,
        onSwitchToKeyboard: @escaping () -> Void
    ) {
        self.word = word
        self.liveTranscript = liveTranscript
        self.elapsedTimeMs = elapsedTimeMs
        self.onSwitchToKeyboard = onSwitchToKeyboard
    }

    private func speechWaveformHeight(for index: Int) -> CGFloat {
        let offset: Int = index * 5 + (elapsedTimeMs / 60)
        let dynamicHeight: Int = 8 + (offset % 18)
        return CGFloat(dynamicHeight)
    }

    public var body: some View {
        VStack(spacing: 14) {
            MixedDrillPromptHeader(word: word)

            MixedDrillClozeSentence(word: word, isReviewed: false)

            Rectangle()
                .fill(Color.vocabHairline)
                .frame(height: 1)

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<9, id: \.self) { idx in
                        Capsule()
                            .fill(Color.vocabMint)
                            .frame(width: 3.5, height: speechWaveformHeight(for: idx))
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

                Button(action: onSwitchToKeyboard) {
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
    }
}

// MARK: - Typing Section
public struct MixedDrillTypingSection: View {
    public let word: VaultWordItem
    @Binding public var typingText: String
    public let onSubmit: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    public init(
        word: VaultWordItem,
        typingText: Binding<String>,
        onSubmit: @escaping () -> Void
    ) {
        self.word = word
        self._typingText = typingText
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: 14) {
            MixedDrillPromptHeader(word: word)

            MixedDrillClozeSentence(word: word, isReviewed: false)

            Rectangle()
                .fill(Color.vocabHairline)
                .frame(height: 1)

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
                        onSubmit()
                    }

                Button(action: onSubmit) {
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
    }
}

// MARK: - Listening Section
public struct MixedDrillListeningSection: View {
    public let options: [ReflexBlitzOption]
    public let elapsedTimeMs: Int
    public let onPlayAudio: () -> Void
    public let onSelectOption: (ReflexBlitzOption) -> Void

    public init(
        options: [ReflexBlitzOption],
        elapsedTimeMs: Int,
        onPlayAudio: @escaping () -> Void,
        onSelectOption: @escaping (ReflexBlitzOption) -> Void
    ) {
        self.options = options
        self.elapsedTimeMs = elapsedTimeMs
        self.onPlayAudio = onPlayAudio
        self.onSelectOption = onSelectOption
    }

    private func listeningWaveformHeight(for index: Int) -> CGFloat {
        let offset: Int = index * 6 + (elapsedTimeMs / 60)
        let dynamicHeight: Int = 8 + (offset % 22)
        return CGFloat(dynamicHeight)
    }

    public var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 12) {
                HStack(spacing: 5) {
                    ForEach(0..<11, id: \.self) { idx in
                        Capsule()
                            .fill(Color.vocabHeroAccent)
                            .frame(width: 3.5, height: listeningWaveformHeight(for: idx))
                            .animation(.easeInOut(duration: 0.1), value: elapsedTimeMs)
                    }
                }
                .frame(height: 28)
                .accessibilityHidden(true)

                Button(action: onPlayAudio) {
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

            Rectangle()
                .fill(Color.vocabHairline)
                .frame(height: 1)

            VStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    Button(action: {
                        onSelectOption(option)
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
    }

    private func optionLetter(for index: Int) -> String {
        switch index {
        case 0: return "A"
        case 1: return "B"
        case 2: return "C"
        case 3: return "D"
        default: return "\(index + 1)"
        }
    }
}

// MARK: - Reviewed Section
public struct MixedDrillReviewedSection: View {
    public let item: MixedReflexDrillItem
    public let result: ReflexCardResult?
    public let onPlayAudio: () -> Void

    public init(
        item: MixedReflexDrillItem,
        result: ReflexCardResult?,
        onPlayAudio: @escaping () -> Void
    ) {
        self.item = item
        self.result = result
        self.onPlayAudio = onPlayAudio
    }

    private var isResultCorrect: Bool { result?.isCorrect ?? false }
    private var isResultTimeout: Bool { result?.isTimeout ?? false }

    public var body: some View {
        VStack(spacing: 12) {
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

            HStack(alignment: .center, spacing: 8) {
                Text(item.word.lemma)
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.vocabInk)

                Button(action: onPlayAudio) {
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

            let meta = [item.word.pos, item.word.phonetic].filter { !$0.isEmpty }.joined(separator: " • ")
            if !meta.isEmpty {
                Text(meta)
                    .font(.caption.monospaced())
                    .foregroundColor(.vocabMuted)
            }

            Text(item.word.definitionVi)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.vocabInk.opacity(0.85))
                .multilineTextAlignment(.center)

            if !item.word.exampleSentenceEn.isEmpty {
                Rectangle()
                    .fill(Color.vocabHairline)
                    .frame(height: 1)

                Text(item.word.exampleSentenceEn)
                    .font(.subheadline.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Reusable Helpers
public struct MixedDrillPromptHeader: View {
    public let word: VaultWordItem

    public init(word: VaultWordItem) {
        self.word = word
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(word.lemma)
                .font(.title3.weight(.bold))
                .fontDesign(.rounded)
                .foregroundColor(.vocabInk)

            if !word.phonetic.isEmpty {
                Text(word.phonetic)
                    .font(.caption.monospaced())
                    .foregroundColor(.vocabMuted)
            }

            Spacer()

            if !word.pos.isEmpty {
                Text(word.pos)
                    .font(.caption2.bold())
                    .foregroundColor(.vocabMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.vocabSurfaceSoft)
                    .clipShape(Capsule())
            }
        }
    }
}

public struct MixedDrillClozeSentence: View {
    public let word: VaultWordItem
    public let isReviewed: Bool

    public init(word: VaultWordItem, isReviewed: Bool) {
        self.word = word
        self.isReviewed = isReviewed
    }

    public var body: some View {
        if !word.exampleSentenceEn.isEmpty {
            VStack(spacing: 4) {
                if isReviewed {
                    Text(word.exampleSentenceEn)
                        .font(.body.weight(.medium))
                        .fontDesign(.serif)
                        .foregroundColor(.vocabInk)
                        .multilineTextAlignment(.center)
                } else {
                    clozeFormattedSentence
                }

                if !word.exampleSentenceVi.isEmpty {
                    Text(word.exampleSentenceVi)
                        .font(.caption)
                        .foregroundColor(.vocabMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var clozeFormattedSentence: some View {
        if let range = word.exampleSentenceEn.range(of: word.lemma, options: .caseInsensitive) {
            let prefix = String(word.exampleSentenceEn[..<range.lowerBound])
            let suffix = String(word.exampleSentenceEn[range.upperBound...])
            (
                Text(prefix)
                    .font(.body.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
                +
                Text(" [ ______ ] ")
                    .font(.body.bold())
                    .fontDesign(.monospaced)
                    .foregroundColor(.vocabHeroAccent)
                +
                Text(suffix)
                    .font(.body.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
            )
            .multilineTextAlignment(.center)
        } else {
            Text(word.exampleSentenceEn)
                .font(.body.weight(.medium))
                .fontDesign(.serif)
                .foregroundColor(.vocabInk)
                .multilineTextAlignment(.center)
        }
    }
}
