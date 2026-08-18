import SwiftUI

/// Custom shape that traces clockwise along the rounded rectangle perimeter starting at top-center.
/// Eliminates rotationEffect bugs that cause stroke geometry overflow and rendering glitches.
public struct PerimeterCountdownShape: Shape {
    public var cornerRadius: CGFloat = 24

    public init(cornerRadius: CGFloat = 24) {
        self.cornerRadius = cornerRadius
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(cornerRadius, min(rect.width, rect.height) / 2)
        let midX = rect.midX
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        // Start at top center
        path.move(to: CGPoint(x: midX, y: minY))
        // Top right straight line
        path.addLine(to: CGPoint(x: maxX - r, y: minY))
        // Top right rounded corner arc
        path.addArc(
            center: CGPoint(x: maxX - r, y: minY + r),
            radius: r,
            startAngle: .radians(-.pi / 2),
            endAngle: .radians(0),
            clockwise: false
        )
        // Right vertical edge
        path.addLine(to: CGPoint(x: maxX, y: maxY - r))
        // Bottom right rounded corner arc
        path.addArc(
            center: CGPoint(x: maxX - r, y: maxY - r),
            radius: r,
            startAngle: .radians(0),
            endAngle: .radians(.pi / 2),
            clockwise: false
        )
        // Bottom horizontal edge
        path.addLine(to: CGPoint(x: minX + r, y: maxY))
        // Bottom left rounded corner arc
        path.addArc(
            center: CGPoint(x: minX + r, y: maxY - r),
            radius: r,
            startAngle: .radians(.pi / 2),
            endAngle: .radians(.pi),
            clockwise: false
        )
        // Left vertical edge
        path.addLine(to: CGPoint(x: minX, y: minY + r))
        // Top left rounded corner arc
        path.addArc(
            center: CGPoint(x: minX + r, y: minY + r),
            radius: r,
            startAngle: .radians(.pi),
            endAngle: .radians(3 * .pi / 2),
            clockwise: false
        )
        // Complete path back to top center
        path.addLine(to: CGPoint(x: midX, y: minY))
        path.closeSubpath()

        return path
    }
}

/// Challenge card view for Spoken Reflex Blitz drill.
/// Features a perimeter countdown stroke timer, clear cognitive visual hierarchy (Trigger -> Context -> Pronunciation),
/// dynamic cloze slot with progressive scaffolding, and an integrated audio dock / keyboard fallback.
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

    private var slotRepresentation: String {
        if isCorrect || isTimeout {
            return word.lemma
        } else if showHint {
            let initial = String(word.lemma.prefix(1)).lowercased()
            let dotsCount = max(1, word.lemma.count - 1)
            return "❲ \(initial)" + String(repeating: " •", count: dotsCount) + " ❳"
        } else {
            let dotsCount = max(3, min(6, word.lemma.count))
            let dots = String(repeating: "• ", count: dotsCount).trimmingCharacters(in: .whitespaces)
            return "❲ \(dots) ❳"
        }
    }

    public var body: some View {
        VStack(spacing: 18) {
            // 1. TRIGGER AREA: Part of Speech & Vietnamese Meaning
            VStack(spacing: 8) {
                if !word.pos.isEmpty {
                    Text(word.pos.uppercased())
                        .font(.caption2.weight(.bold))
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
            .padding(.top, 4)

            // 2. CONTEXT AREA: English Cloze Sentence with Dynamic Interactive Slot
            sentenceView
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 10)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isCorrect)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isTimeout)
                .accessibilityLabel(
                    isTimeout
                        ? "Câu hoàn chỉnh: \(word.exampleSentenceEn)"
                        : (isCorrect ? "Câu hoàn chỉnh: \(word.completedSentenceWithTargetWord)" : "Câu điền từ: \(word.clozeSentenceEn)")
                )

            // 3. PRONUNCIATION & SCAFFOLDING AREA
            HStack(spacing: 8) {
                if !word.ipa.isEmpty {
                    HStack(spacing: 5) {
                        Image(systemName: "waveform")
                            .font(.caption2)
                        Text(word.ipa)
                            .font(.subheadline.monospaced())
                    }
                    .foregroundColor(isCorrect ? .vocabMint : (isTimeout ? .vocabCoral : .vocabMuted))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        isCorrect
                            ? Color.vocabMint.opacity(0.14)
                            : (isTimeout ? Color.vocabCoral.opacity(0.14) : Color.vocabMuted.opacity(0.08))
                    )
                    .clipShape(Capsule())
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
            }

            Spacer(minLength: 4)

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
        .frame(maxWidth: .infinity, minHeight: 310)
        .background(Color.vocabSurfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            // Background subtle track
            PerimeterCountdownShape(cornerRadius: 24)
                .stroke(Color.vocabHairline.opacity(0.25), lineWidth: 3.5)
        )
        .overlay(
            // Active countdown perimeter contour stroke (clock-wise, zero rotation bug)
            PerimeterCountdownShape(cornerRadius: 24)
                .trim(from: 0, to: CGFloat(max(0.0, min(1.0, fractionRemaining))))
                .stroke(
                    timerStrokeColor,
                    style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                )
                .animation(.linear(duration: 0.05), value: fractionRemaining)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 16, x: 0, y: 8)
        .padding(.horizontal)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var sentenceView: some View {
        if !isCorrect && !isTimeout {
            if let regex = try? NSRegularExpression(pattern: "\\[\\s*_{3,}\\s*\\]|_{3,}") {
                let text = word.clozeSentenceEn
                let nsRange = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: nsRange),
                   let matchRange = Range(match.range, in: text) {
                    let prefix = String(text[..<matchRange.lowerBound])
                    let suffix = String(text[matchRange.upperBound...])
                    
                    Text(prefix)
                        .font(.title3.weight(.medium))
                        .foregroundColor(.vocabInk)
                    +
                    Text(" \(slotRepresentation) ")
                        .font(.title3.bold())
                        .foregroundColor(slotTextColor)
                    +
                    Text(suffix)
                        .font(.title3.weight(.medium))
                        .foregroundColor(.vocabInk)
                } else {
                    Text(displayedSentence)
                        .font(.title3.weight(.medium))
                        .foregroundColor(.vocabInk)
                }
            } else {
                Text(displayedSentence)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.vocabInk)
            }
        } else {
            Text(displayedSentence)
                .font(.title3.weight(.bold))
                .foregroundColor(isCorrect ? .vocabMint : .vocabCoral)
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
        VStack(spacing: 7) {
            HStack(spacing: 6) {
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

            Text(liveTranscript.isEmpty ? "Nói từ tiếng Anh vào micro..." : "\"\(liveTranscript)...\"")
                .font(.footnote)
                .fontWeight(liveTranscript.isEmpty ? .regular : .semibold)
                .foregroundColor(liveTranscript.isEmpty ? .vocabMuted : .vocabInk)
                .lineLimit(1)
                .contentTransition(.opacity)
                .accessibilityLabel(liveTranscript.isEmpty ? "Đang chờ phát âm..." : "Nhận diện giọng nói: \(liveTranscript)")
        }
    }
}

