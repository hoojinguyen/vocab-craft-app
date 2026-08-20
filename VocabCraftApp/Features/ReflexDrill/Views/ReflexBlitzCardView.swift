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

/// Challenge card view for Spoken Reflex Blitz drill.
/// Features clean spatial hierarchy (Trigger -> Context -> Scaffolding / Pronunciation -> Audio Dock / Typing Fallback),
/// progressive disclosure for phonetics and hints, dynamic cloze slot, and an integrated audio dock / keyboard fallback.
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

    public var slotRepresentation: String {
        if isCorrect || isTimeout {
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
        let slot = isCorrect || isTimeout ? word.lemma : slotRepresentation
        return ClozeSentenceParts(prefix: prefix, slot: slot, suffix: suffix)
    }

    public var body: some View {
        VStack(spacing: 18) {
            // 1. TRIGGER AREA: Part of Speech & Vietnamese Meaning
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

            // 2. CONTEXT AREA: English Cloze Sentence with Dynamic Interactive Slot
            sentenceView
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 8)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isCorrect)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isTimeout)
                .accessibilityLabel(
                    isTimeout
                        ? "Câu hoàn chỉnh: \(word.exampleSentenceEn)"
                        : (isCorrect ? "Câu hoàn chỉnh: \(word.completedSentenceWithTargetWord)" : "Câu điền từ: \(word.clozeSentenceEn)")
                )

            // 3. PRONUNCIATION & SCAFFOLDING AREA (Progressive Disclosure)
            if (isCorrect || isTimeout) && !word.ipa.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                    Text(word.ipa)
                        .font(.subheadline.monospaced())
                        .lineLimit(1)
                }
                .foregroundColor(isCorrect ? .vocabMint : .vocabCoral)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    isCorrect
                        ? Color.vocabMint.opacity(0.14)
                        : Color.vocabCoral.opacity(0.14)
                )
                .clipShape(Capsule())
                .transition(.scale.combined(with: .opacity))
                .accessibilityLabel("Phiên âm IPA: \(word.ipa)")
            }

            if showHint && !isCorrect && !isTimeout {
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

            // Organic Divider
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

            // 4. BOTTOM ACTION DOCK: Living Audio Waveform or Keyboard Fallback
            if isKeyboardFallbackActive {
                keyboardDockView
            } else {
                livingAudioDockView
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.vocabHairline.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        .padding(.horizontal)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var sentenceView: some View {
        if let parts = clozeParts {
            if isCorrect || isTimeout {
                Text(parts.prefix)
                    .font(.title3.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundColor(.vocabInk)
                +
                Text(parts.slot)
                    .font(.title3.weight(.bold))
                    .fontDesign(.serif)
                    .foregroundColor(isCorrect ? .vocabMint : .vocabCoral)
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
                .font(.title3.weight(isCorrect || isTimeout ? .bold : .medium))
                .fontDesign(.serif)
                .foregroundColor(isCorrect ? .vocabMint : (isTimeout ? .vocabCoral : .vocabInk))
        }
    }

    private var slotTextColor: Color {
        if isCorrect {
            return .vocabMint
        } else if isTimeout {
            return .vocabCoral
        } else if showHint {
            return .vocabPeach
        } else {
            return .vocabHeroAccent
        }
    }

    @ViewBuilder
    private var keyboardDockView: some View {
        HStack(spacing: 10) {
            TextField("Gõ từ tiếng Anh...", text: $keyboardInputText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.vocabCanvas)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.vocabHairline.opacity(0.8), lineWidth: 1)
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
    }

    @ViewBuilder
    private var livingAudioDockView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 5) {
                ForEach(0..<9, id: \.self) { index in
                    Capsule()
                        .fill(
                            isCorrect
                                ? Color.vocabMint
                                : (isTimeout ? Color.vocabCoral : timerStrokeColor)
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
