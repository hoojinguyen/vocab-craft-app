import CraftUIKit
import SwiftUI

/// Challenge and reviewed view for Reflex Blitz Multiple Choice modality.
/// Features a 3D Flip Card stimulus container (front: definition + cloze prompt; back: target word, IPA, audio replay, example sentence)
/// and an interactive options list placed directly on the canvas background.
public struct ReflexBlitzMultipleChoiceCardView: View {
    @Environment(\.craftTheme) private var theme

    public let word: ReflexBlitzWordItem
    public let options: [ReflexBlitzOption]
    public let isReviewed: Bool
    public let isResultCorrect: Bool
    public let isResultTimeout: Bool
    public let showHint: Bool
    public let selectedOptionText: String?
    public let clozeParts: ClozeSentenceParts?
    public let displayedSentence: String
    public let cardBorderColor: Color
    public let onSelectOption: ((ReflexBlitzOption) -> Void)?
    public let onReplayAudio: (() -> Void)?

    public init(
        word: ReflexBlitzWordItem,
        options: [ReflexBlitzOption],
        isReviewed: Bool,
        isResultCorrect: Bool,
        isResultTimeout: Bool,
        showHint: Bool,
        selectedOptionText: String?,
        clozeParts: ClozeSentenceParts?,
        displayedSentence: String,
        cardBorderColor: Color,
        onSelectOption: ((ReflexBlitzOption) -> Void)?,
        onReplayAudio: (() -> Void)?
    ) {
        self.word = word
        self.options = options
        self.isReviewed = isReviewed
        self.isResultCorrect = isResultCorrect
        self.isResultTimeout = isResultTimeout
        self.showHint = showHint
        self.selectedOptionText = selectedOptionText
        self.clozeParts = clozeParts
        self.displayedSentence = displayedSentence
        self.cardBorderColor = cardBorderColor
        self.onSelectOption = onSelectOption
        self.onReplayAudio = onReplayAudio
    }

    public func choiceState(for option: ReflexBlitzOption) -> CraftChoiceState {
        guard isReviewed else { return .idle }
        if option.isCorrect {
            return .correct
        } else if option.text == selectedOptionText {
            return .wrong
        } else {
            return .disabled
        }
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            flipStimulusCard

            optionsListView
        }
    }

    // MARK: - 3D Flip Stimulus Card

    @ViewBuilder
    private var flipStimulusCard: some View {
        CraftFlipCard(
            isFlipped: Binding(
                get: { isReviewed },
                set: { _ in }
            ),
            axis: .horizontal,
            edgeThickness: 0,
            showSpecularGlare: true,
            showsHighlightBorder: false,
            isTapToFlipEnabled: false,
            cornerRadius: theme.radii.xl,
            perspective: 0.5,
            animation: .spring(response: 0.45, dampingFraction: 0.78)
        ) {
            frontPromptFace
        } back: {
            backResultFace
        }
    }

    private var frontPromptFace: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftText(
                word.definitionVi,
                style: .titleLarge,
                color: theme.colors.textPrimary,
                textAlignment: .center
            )
            .lineLimit(2)
            .accessibilityLabel(AppStrings.ReflexBlitz.definitionA11y(word.definitionVi))

            HStack(alignment: .center, spacing: theme.spacing.xs) {
                if !word.cleanPos.isEmpty {
                    CraftBadge(
                        word.cleanPos,
                        variant: .subtle,
                        tone: .neutral,
                        size: .sm,
                        shape: .capsule
                    )
                }

                CraftBadge(
                    word.cleanLevel,
                    variant: .subtle,
                    tone: .warning,
                    size: .sm,
                    shape: .capsule
                )

                if showHint {
                    CraftBadge(
                        AppStrings.ReflexBlitz.hintPrefix(word.cleanInitialLetterHint),
                        iconName: "lightbulb.min.fill",
                        variant: .outline,
                        tone: .warning,
                        size: .sm,
                        shape: .capsule
                    )
                    .transition(.scale.combined(with: .opacity))
                    .accessibilityLabel(AppStrings.ReflexBlitz.hintA11y(word.cleanInitialLetterHint))
                }
            }

            sentenceArea
                .padding(.top, theme.spacing.xs / 2)
        }
        .padding(theme.spacing.base)
        .frame(maxWidth: .infinity)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadows.md.color, radius: theme.shadows.md.radius, x: theme.shadows.md.x, y: theme.shadows.md.y)
    }

    private var backResultFace: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            // Row 1: Lemma (Left) and Audio Replay Speaker Button (Right)
            HStack(alignment: .center) {
                CraftText(
                    word.lemma,
                    style: .titleLargeSerif,
                    color: theme.colors.textPrimary,
                    textAlignment: .leading
                )

                Spacer(minLength: theme.spacing.sm)

                if let onReplayAudio {
                    CraftSpeakerButton(
                        variant: .subtle,
                        size: .md,
                        isPlaying: false,
                        label: nil,
                        action: onReplayAudio
                    )
                }
            }

            // Row 2: IPA Phonetic
            if !word.ipa.isEmpty {
                CraftText(
                    word.ipa,
                    style: .caption,
                    color: theme.colors.textMuted,
                    textAlignment: .leading
                )
                .accessibilityLabel(AppStrings.ReflexBlitz.ipaA11y(word.ipa))
            }

            // Row 3: Badges (Part of Speech without '.' & CEFR Level)
            HStack(spacing: theme.spacing.xs) {
                if !word.cleanPos.isEmpty {
                    CraftBadge(
                        word.cleanPos,
                        variant: .subtle,
                        tone: .neutral,
                        size: .sm,
                        shape: .capsule
                    )
                }

                CraftBadge(
                    word.cleanLevel,
                    variant: .subtle,
                    tone: .warning,
                    size: .sm,
                    shape: .capsule
                )
            }
            .padding(.vertical, 2)

            // Row 4: Meaning (Definition in Vietnamese)
            CraftText(
                word.definitionVi,
                style: .titleMedium,
                color: theme.colors.textPrimary,
                textAlignment: .leading
            )
            .padding(.top, 2)

            // Row 5: Example Sentence & Vietnamese Translation
            VStack(alignment: .leading, spacing: 4) {
                sentenceView
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if !word.exampleSentenceVi.isEmpty {
                    CraftText(
                        word.exampleSentenceVi,
                        style: .caption,
                        color: theme.colors.textMuted,
                        textAlignment: .leading
                    )
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 4)
        }
        .padding(theme.spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .stroke(
                    isResultCorrect
                        ? theme.colors.statusSuccess.opacity(0.6)
                        : (isResultTimeout ? theme.colors.statusWarning.opacity(0.6) : theme.colors.statusDanger.opacity(0.6)),
                    lineWidth: 1.5
                )
        )
        .shadow(color: theme.shadows.md.color, radius: theme.shadows.md.radius, x: theme.shadows.md.x, y: theme.shadows.md.y)
    }

    // MARK: - Sentence Area

    @ViewBuilder
    private var sentenceArea: some View {
        VStack(spacing: theme.spacing.xs) {
            sentenceView
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, theme.spacing.xs)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isResultCorrect)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isResultTimeout)
                .accessibilityLabel(
                    isReviewed
                        ? AppStrings.ReflexBlitz.completedSentenceA11y(word.completedSentenceWithTargetWord)
                        : AppStrings.ReflexBlitz.clozeSentenceA11y(word.clozeSentenceEn)
                )

            if isReviewed && !word.exampleSentenceVi.isEmpty {
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
    private var sentenceView: some View {
        if let parts = clozeParts {
            if isReviewed {
                reviewedClozeText(parts: parts)
            } else {
                activeClozeText(parts: parts)
            }
        } else {
            Text(displayedSentence)
                .font(theme.typography.bodySerif.weight(isReviewed ? .bold : .medium))
                .foregroundColor(isReviewed ? (isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger) : theme.colors.textPrimary)
        }
    }

    private func reviewedClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotColor: Color = isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
        let slotText = Text(parts.slot)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(slotColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }

    private func activeClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotText = Text(parts.slot)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(showHint ? theme.colors.statusWarning : theme.colors.brandPrimary)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }

    // MARK: - Options List (Directly on Canvas)

    @ViewBuilder
    private var optionsListView: some View {
        VStack(spacing: theme.spacing.xs) {
            ForEach(options, id: \.id) { option in
                let choiceState = choiceState(for: option)

                CraftChoiceCard(
                    prefix: nil,
                    prefixStyle: .none,
                    title: option.text,
                    textAlignment: .leading,
                    state: choiceState,
                    style: .tactile3D,
                    showsStatusIndicator: false,
                    action: {
                        guard !isReviewed else { return }
                        onSelectOption?(option)
                    }
                )
                .frame(minHeight: 48)
                .accessibilityLabel(option.text)
            }
        }
    }
}
