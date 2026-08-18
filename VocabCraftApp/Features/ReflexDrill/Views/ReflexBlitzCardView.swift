import SwiftUI

/// Challenge card view for Spoken Reflex Blitz drill.
/// Features a perimeter countdown stroke timer, morphing cloze sentence to completed target word,
/// IPA phonetic notation, progressive scaffolding hint pill, and an integrated bottom audio dock / keyboard fallback.
public struct ReflexBlitzCardView: View {
    public let word: ReflexBlitzWordItem
    public let fractionRemaining: Double
    public let timerStage: ReflexBlitzTimerStage
    public let showHint: Bool
    public let isCorrect: Bool
    public let isTimeout: Bool
    public let liveTranscript: String
    public let elapsedTimeMs: Int
    public let isKeyboardFallbackActive: Bool
    @Binding public var keyboardInputText: String
    public let onSubmitKeyboard: () -> Void

    public init(
        word: ReflexBlitzWordItem,
        fractionRemaining: Double = 1.0,
        timerStage: ReflexBlitzTimerStage = .steady,
        showHint: Bool = false,
        isCorrect: Bool = false,
        isTimeout: Bool = false,
        liveTranscript: String = "",
        elapsedTimeMs: Int = 0,
        isKeyboardFallbackActive: Bool = false,
        keyboardInputText: Binding<String> = .constant(""),
        onSubmitKeyboard: @escaping () -> Void = {}
    ) {
        self.word = word
        self.fractionRemaining = fractionRemaining
        self.timerStage = timerStage
        self.showHint = showHint
        self.isCorrect = isCorrect
        self.isTimeout = isTimeout
        self.liveTranscript = liveTranscript
        self.elapsedTimeMs = elapsedTimeMs
        self.isKeyboardFallbackActive = isKeyboardFallbackActive
        self._keyboardInputText = keyboardInputText
        self.onSubmitKeyboard = onSubmitKeyboard
    }

    public var displayedSentence: String {
        if isTimeout {
            return word.exampleSentenceEn
        } else if isCorrect {
            return word.completedSentenceWithTargetWord
        } else {
            return word.clozeSentenceEn
        }
    }

    public var timerStrokeColor: Color {
        if isCorrect {
            return .vocabMint
        } else if isTimeout {
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

    private var sentenceAttributedString: AttributedString {
        let raw = displayedSentence
        var attr = AttributedString(raw)
        if isCorrect {
            attr.foregroundColor = .vocabInk
            if let range = attr.range(of: word.lemma, options: .caseInsensitive) {
                attr[range].foregroundColor = .vocabMint
                attr[range].inlinePresentationIntent = .stronglyEmphasized
            }
        } else if isTimeout {
            attr.foregroundColor = .vocabCoral
        } else {
            attr.foregroundColor = .vocabInk
        }
        return attr
    }

    public var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 4)

            // English Cloze / Completed Sentence
            Text(sentenceAttributedString)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .animation(.easeInOut(duration: 0.2), value: isTimeout)
                .animation(.easeInOut(duration: 0.2), value: isCorrect)
                .accessibilityLabel(
                    isTimeout
                        ? "Câu hoàn chỉnh: \(word.exampleSentenceEn)"
                        : (isCorrect ? "Câu hoàn chỉnh: \(word.completedSentenceWithTargetWord)" : "Câu điền từ: \(word.clozeSentenceEn)")
                )

            // Vietnamese Definition
            Text(word.definitionVi)
                .font(.headline)
                .foregroundColor(.vocabInk)
                .multilineTextAlignment(.center)
                .accessibilityLabel("Nghĩa tiếng Việt: \(word.definitionVi)")

            // IPA Subtitle Badge
            if !word.ipa.isEmpty {
                Text(word.ipa)
                    .font(.subheadline.monospaced())
                    .foregroundColor(isCorrect ? .vocabMint : .vocabMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        isCorrect
                            ? Color.vocabMint.opacity(0.12)
                            : Color.vocabMuted.opacity(0.08)
                    )
                    .clipShape(Capsule())
                    .transition(.opacity)
                    .accessibilityLabel("Phiên âm: \(word.ipa)")
            }

            // Scaffolding Hint Pill
            if showHint && !isCorrect && !isTimeout {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption2)
                    Text(word.ipa.isEmpty ? "Gợi ý: \(word.initialLetterHint)" : "Gợi ý: \(word.initialLetterHint) • \(word.ipa)")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.vocabPeach.opacity(0.15))
                .foregroundColor(.vocabPeach)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.vocabPeach.opacity(0.4), lineWidth: 1)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Gợi ý: \(word.initialLetterHint)")
            }

            Spacer(minLength: 4)

            // Hairline Divider
            Rectangle()
                .fill(Color.vocabHairline.opacity(0.5))
                .frame(height: 1)
                .padding(.horizontal, 8)

            // Integrated Voice Dock / Keyboard Fallback
            if isKeyboardFallbackActive {
                HStack(spacing: 10) {
                    TextField("Gõ từ tiếng Anh...", text: $keyboardInputText)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.vocabCanvas)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.vocabHairline, lineWidth: 1)
                        )
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                        .onSubmit {
                            onSubmitKeyboard()
                        }
                        .accessibilityLabel("Ô nhập từ tiếng Anh thay thế giọng nói")

                    Button(action: onSubmitKeyboard) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(
                                keyboardInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? .vocabMuted.opacity(0.4)
                                    : .vocabHeroAccent
                            )
                    }
                    .disabled(keyboardInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Gửi câu trả lời đã gõ")
                }
                .padding(.horizontal, 4)
            } else {
                VStack(spacing: 6) {
                    HStack(spacing: 5) {
                        ForEach(0..<7, id: \.self) { index in
                            Capsule()
                                .fill(isCorrect ? Color.vocabMint : (isTimeout ? Color.vocabCoral : timerStrokeColor))
                                .frame(
                                    width: 4,
                                    height: CGFloat(8 + ((index * 7 + (elapsedTimeMs / 80)) % 18))
                                )
                                .animation(.easeInOut(duration: 0.15), value: elapsedTimeMs)
                        }
                    }
                    .frame(height: 26)
                    .accessibilityHidden(true)

                    Text(liveTranscript.isEmpty ? "Nói từ tiếng Anh vào micro..." : "\"\(liveTranscript)...\"")
                        .font(.caption)
                        .fontWeight(liveTranscript.isEmpty ? .regular : .semibold)
                        .foregroundColor(liveTranscript.isEmpty ? .vocabMuted : .vocabInk)
                        .lineLimit(1)
                        .accessibilityLabel(liveTranscript.isEmpty ? "Đang chờ phát âm..." : "Nhận diện giọng nói: \(liveTranscript)")
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.vocabHairline.opacity(0.4), lineWidth: 3.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .trim(from: 0, to: CGFloat(max(0.0, min(1.0, fractionRemaining))))
                .stroke(
                    timerStrokeColor,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: fractionRemaining)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        .padding(.horizontal)
    }
}
