import SwiftUI

/// Reviewed consolidation view for Reflex Blitz drill card displaying correct answers, IPA, translations, and feedback.
public struct ReflexBlitzCardReviewedView: View {
    public let word: ReflexBlitzWordItem
    public let mode: ReflexBlitzMode
    public let isReviewed: Bool
    public let isResultCorrect: Bool
    public let isResultTimeout: Bool
    public let options: [ReflexBlitzOption]
    public let reviewResult: ReflexCardResult?
    public let selectedOptionText: String?
    public let clozeParts: ClozeSentenceParts?
    public let displayedSentence: String
    public let onReplayAudio: (() -> Void)?

    public init(
        word: ReflexBlitzWordItem,
        mode: ReflexBlitzMode,
        isReviewed: Bool,
        isResultCorrect: Bool,
        isResultTimeout: Bool,
        options: [ReflexBlitzOption],
        reviewResult: ReflexCardResult?,
        selectedOptionText: String?,
        clozeParts: ClozeSentenceParts?,
        displayedSentence: String,
        onReplayAudio: (() -> Void)?
    ) {
        self.word = word
        self.mode = mode
        self.isReviewed = isReviewed
        self.isResultCorrect = isResultCorrect
        self.isResultTimeout = isResultTimeout
        self.options = options
        self.reviewResult = reviewResult
        self.selectedOptionText = selectedOptionText
        self.clozeParts = clozeParts
        self.displayedSentence = displayedSentence
        self.onReplayAudio = onReplayAudio
    }

    public var body: some View {
        VStack(spacing: 14) {
            statusHeaderBadge
            lemmaAndDefinitionSection
            dividerLine
            sentenceSection

            if mode == .multipleChoice && !options.isEmpty {
                dividerLine
                reviewedOptionsGrid
            } else if mode == .listening {
                listeningResultChip
            } else if mode == .speaking, let spoken = reviewResult?.recognizedSpoken, !spoken.isEmpty {
                speakingResultChip(spoken: spoken)
            } else if mode == .typing, let typed = reviewResult?.typedText, !typed.isEmpty {
                typingResultChip(typed: typed)
            }
        }
    }
}

// MARK: - ReflexBlitzCardReviewedView Subviews

extension ReflexBlitzCardReviewedView {
    private var statusHeaderBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: isResultCorrect ? "checkmark.circle.fill" : (isResultTimeout ? "clock.badge.exclamationmark.fill" : "xmark.circle.fill"))
                .font(.subheadline.bold())
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.bounce, value: isReviewed)

            Text(isResultCorrect ? "Chính xác!" : (isResultTimeout ? "Hết thời gian!" : "Chưa chính xác"))
                .font(.subheadline.bold())
                .fontDesign(.rounded)
        }
        .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background((isResultCorrect ? Color.vocabMint : Color.vocabCoral).opacity(0.12))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke((isResultCorrect ? Color.vocabMint : Color.vocabCoral).opacity(0.25), lineWidth: 0.8)
        )
    }

    private var lemmaAndDefinitionSection: some View {
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
                            .font(.system(size: 15, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.vocabHeroAccent)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.vocabHeroAccent.opacity(0.2), lineWidth: 0.8)
                            )
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
    }

    private var sentenceSection: some View {
        VStack(spacing: 6) {
            reviewedSentenceView
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 8)
                .fixedSize(horizontal: false, vertical: true)

            if !word.exampleSentenceVi.isEmpty {
                Text(word.exampleSentenceVi)
                    .font(.subheadline)
                    .foregroundColor(.vocabMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var reviewedSentenceView: some View {
        if let parts = clozeParts {
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
            Text(displayedSentence)
                .font(.title3.weight(.bold))
                .fontDesign(.serif)
                .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
        }
    }

    private var listeningResultChip: some View {
        HStack(spacing: 6) {
            Image(systemName: isResultCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .symbolRenderingMode(.hierarchical)
            Text("Đã chọn: \(selectedOptionText ?? word.definitionVi)")
                .font(.caption.bold())
        }
        .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background((isResultCorrect ? Color.vocabMint : Color.vocabCoral).opacity(0.12))
        .clipShape(Capsule())
    }

    private func speakingResultChip(spoken: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "waveform")
                .font(.caption)
                .symbolRenderingMode(.hierarchical)
            Text("Nhận diện: \(spoken)")
                .font(.caption.bold())
        }
        .foregroundColor(.vocabMint)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.vocabMint.opacity(0.12))
        .clipShape(Capsule())
    }

    private func typingResultChip(typed: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "keyboard")
                .font(.caption)
                .symbolRenderingMode(.hierarchical)
            Text("Đã nhập: \(typed)")
                .font(.caption.bold())
        }
        .foregroundColor(isResultCorrect ? .vocabMint : .vocabCoral)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background((isResultCorrect ? Color.vocabMint : Color.vocabCoral).opacity(0.12))
        .clipShape(Capsule())
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
                        .fontDesign(.rounded)
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
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(isCorrect ? .vocabMint : .vocabCoral)
                            .font(.subheadline)
                    } else if isCorrect {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
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

    private func optionLetter(for index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        if index >= 0 && index < letters.count {
            return letters[index]
        }
        return "\(index + 1)"
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
}
