import CraftUIKit
import SwiftUI

/// Reviewed consolidation view for Reflex drill modes (Speaking, Typing, Listening)
/// displaying correct answers, phonetic IPA, translations, and modality-specific feedback.
public struct ReflexReviewedConsolidationView: View {
    @Environment(\.craftTheme) private var theme

    public let word: any ReflexDrillable
    public let mode: ReflexMode
    public let reviewResult: ReflexCardResult?
    public let displayedSentence: String
    public let onReplayAudio: (() -> Void)?

    public init(
        word: any ReflexDrillable,
        mode: ReflexMode,
        reviewResult: ReflexCardResult?,
        displayedSentence: String,
        onReplayAudio: (() -> Void)? = nil
    ) {
        self.word = word
        self.mode = mode
        self.reviewResult = reviewResult
        self.displayedSentence = displayedSentence
        self.onReplayAudio = onReplayAudio
    }

    public var isResultCorrect: Bool {
        reviewResult?.isCorrect ?? false
    }

    public var isResultTimeout: Bool {
        reviewResult?.isTimeout ?? false
    }

    public var clozeParts: ClozeSentenceParts? {
        ReflexClozeFormatter.extractTemplateParts(from: word.clozeSentenceEn)
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            lemmaAndDefinitionSection
            dividerLine
            sentenceSection

            if mode == .listening {
                listeningResultChip
            } else if mode == .speaking, let spoken = reviewResult?.recognizedSpoken, !spoken.isEmpty {
                speakingResultChip(spoken: spoken)
            } else if mode == .typing, let typed = reviewResult?.typedText, !typed.isEmpty {
                typingResultChip(typed: typed)
            }
        }
    }
}

// MARK: - Subviews

private extension ReflexReviewedConsolidationView {
    var lemmaAndDefinitionSection: some View {
        VStack(spacing: theme.spacing.xs) {
            HStack(alignment: .center, spacing: theme.spacing.sm) {
                CraftText(
                    word.lemma,
                    style: .titleLargeSerif,
                    color: theme.colors.textPrimary
                )

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

            if !word.ipa.isEmpty {
                CraftText(
                    word.ipa,
                    style: .caption,
                    color: theme.colors.textMuted
                )
                .accessibilityLabel(AppStrings.ReflexBlitz.ipaA11y(word.ipa))
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

    var sentenceSection: some View {
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
    var reviewedSentenceView: some View {
        if let parts = clozeParts {
            Text(parts.prefix)
                .font(theme.typography.bodySerif)
                .foregroundColor(theme.colors.textPrimary)
            +
            Text(parts.slot.replacingOccurrences(of: "[ _________ ]", with: word.lemma))
                .font(theme.typography.bodySerif.bold())
                .foregroundColor(isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
            +
            Text(parts.suffix)
                .font(theme.typography.bodySerif)
                .foregroundColor(theme.colors.textPrimary)
        } else {
            Text(displayedSentence)
                .font(theme.typography.bodySerif.bold())
                .foregroundColor(isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
        }
    }

    var listeningResultChip: some View {
        CraftBadge(
            AppStrings.ReflexBlitz.selectedPrefix(reviewResult?.selectedOption ?? word.definitionVi),
            iconName: isResultCorrect ? "checkmark.circle.fill" : "xmark.circle.fill",
            variant: .subtle,
            tone: isResultCorrect ? .success : .danger,
            size: .md,
            shape: .capsule
        )
    }

    func speakingResultChip(spoken: String) -> some View {
        CraftBadge(
            AppStrings.ReflexBlitz.spokenRecognized(spoken),
            iconName: "waveform",
            variant: .subtle,
            tone: .primary,
            size: .md,
            shape: .capsule
        )
    }

    func typingResultChip(typed: String) -> some View {
        CraftBadge(
            AppStrings.ReflexBlitz.typedAnswer(typed),
            iconName: "keyboard",
            variant: .subtle,
            tone: isResultCorrect ? .success : .danger,
            size: .md,
            shape: .capsule
        )
    }

    var dividerLine: some View {
        CraftDivider()
            .padding(.horizontal, theme.spacing.xs)
    }
}
