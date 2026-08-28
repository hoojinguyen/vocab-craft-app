import CraftUIKit
import SwiftUI

/// Reviewed consolidation view for Reflex Blitz drill card displaying correct answers, IPA, translations, and feedback.
public struct ReflexBlitzCardReviewedView: View {
    @Environment(\.craftTheme) private var theme

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
        VStack(spacing: theme.spacing.md) {
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
        CraftBadge(
            isResultCorrect ? "Chính xác!" : (isResultTimeout ? "Hết thời gian!" : "Chưa chính xác"),
            iconName: isResultCorrect ? "checkmark.circle.fill" : (isResultTimeout ? "clock.badge.exclamationmark.fill" : "xmark.circle.fill"),
            variant: .subtle,
            tone: isResultCorrect ? .success : .danger,
            size: .md,
            shape: .capsule
        )
    }

    private var lemmaAndDefinitionSection: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack(alignment: .center, spacing: theme.spacing.sm) {
                CraftText(
                    word.lemma,
                    style: .titleLarge,
                    color: theme.colors.textPrimary
                )

                if !word.pos.isEmpty {
                    CraftBadge(
                        word.pos.uppercased(),
                        variant: .subtle,
                        tone: .primary,
                        size: .sm,
                        shape: .capsule
                    )
                }

                if let onReplayAudio = onReplayAudio {
                    CraftSpeakerButton(
                        variant: .subtle,
                        size: .sm,
                        isPlaying: false,
                        label: LocalizedStringKey("craft.audio.pronounce"),
                        action: onReplayAudio
                    )
                }
            }

            if !word.ipa.isEmpty {
                CraftText(
                    word.ipa,
                    style: .caption,
                    color: theme.colors.textMuted
                )
                .accessibilityLabel("Phiên âm IPA: \(word.ipa)")
            }

            CraftText(
                word.definitionVi,
                style: .titleMedium,
                color: theme.colors.textPrimary,
                textAlignment: .center
            )
            .padding(.top, theme.spacing.xs / 2)
        }
    }

    private var sentenceSection: some View {
        VStack(spacing: theme.spacing.xs) {
            reviewedSentenceView
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, theme.spacing.xs)
                .fixedSize(horizontal: false, vertical: true)

            if !word.exampleSentenceVi.isEmpty {
                CraftText(
                    word.exampleSentenceVi,
                    style: .caption,
                    color: theme.colors.textMuted,
                    textAlignment: .center
                )
                .padding(.horizontal, theme.spacing.xs)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var reviewedSentenceView: some View {
        if let parts = clozeParts {
            Text(parts.prefix)
                .font(theme.typography.titleMedium)
                .fontDesign(.serif)
                .foregroundColor(theme.colors.textPrimary)
            +
            Text(parts.slot)
                .font(theme.typography.titleMedium.bold())
                .fontDesign(.serif)
                .foregroundColor(isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
            +
            Text(parts.suffix)
                .font(theme.typography.titleMedium)
                .fontDesign(.serif)
                .foregroundColor(theme.colors.textPrimary)
        } else {
            Text(displayedSentence)
                .font(theme.typography.titleMedium.bold())
                .fontDesign(.serif)
                .foregroundColor(isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
        }
    }

    private var listeningResultChip: some View {
        CraftBadge(
            "Đã chọn: \(selectedOptionText ?? word.definitionVi)",
            iconName: isResultCorrect ? "checkmark.circle.fill" : "xmark.circle.fill",
            variant: .subtle,
            tone: isResultCorrect ? .success : .danger,
            size: .md,
            shape: .capsule
        )
    }

    private func speakingResultChip(spoken: String) -> some View {
        CraftBadge(
            "Nhận diện: \(spoken)",
            iconName: "waveform",
            variant: .subtle,
            tone: .primary,
            size: .md,
            shape: .capsule
        )
    }

    private func typingResultChip(typed: String) -> some View {
        CraftBadge(
            "Đã nhập: \(typed)",
            iconName: "keyboard",
            variant: .subtle,
            tone: isResultCorrect ? .success : .danger,
            size: .md,
            shape: .capsule
        )
    }

    @ViewBuilder
    private var reviewedOptionsGrid: some View {
        let isMultipleChoice = mode == .multipleChoice
        let gridColumns = isMultipleChoice
            ? [GridItem(.flexible(), spacing: theme.spacing.sm), GridItem(.flexible(), spacing: theme.spacing.sm)]
            : [GridItem(.flexible())]

        LazyVGrid(columns: gridColumns, spacing: theme.spacing.sm) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let isSelected = (option.text == selectedOptionText)
                let isCorrect = option.isCorrect
                let choiceState: CraftChoiceState = isCorrect ? .correct : (isSelected ? .wrong : .idle)

                CraftChoiceCard(
                    prefix: optionLetter(for: index),
                    prefixStyle: .circle,
                    title: option.text,
                    state: choiceState,
                    style: .tactile3D,
                    showsStatusIndicator: isCorrect || isSelected,
                    action: {}
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
        CraftDivider()
            .padding(.horizontal, theme.spacing.xs)
    }
}
