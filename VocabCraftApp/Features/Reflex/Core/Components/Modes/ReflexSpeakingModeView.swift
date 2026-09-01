import CraftUIKit
import SwiftUI

/// Redesigned Speaking Mode view with Dual-Zone 3D Flip Card architecture.
/// Zone 1 (Top): CraftFlipCard (.tactile3D) — front: Vietnamese definition + cloze prompt; back: consolidation.
/// Zone 2 (Bottom): CraftTactileMicHubView on canvas + live transcript CraftBadge.
public struct ReflexSpeakingModeView: View {
    @Environment(\.craftTheme) private var theme

    // MARK: - Word & Challenge Data
    public let word: any ReflexDrillable
    public let isReviewed: Bool
    public let isResultCorrect: Bool
    public let isResultTimeout: Bool
    public let showHint: Bool
    public let hintStage: Int
    public let clozeStages: ReflexClozeStageSet?
    public let clozeParts: ClozeSentenceParts?
    public let displayedSentence: String
    public let hintBadgeText: String?

    // MARK: - Mic & Transcript
    public let speechState: CraftSpeechState
    public let liveTranscript: String
    public let onCantSpeakNow: (() -> Void)?
    public let onReplayAudio: (() -> Void)?

    public init(
        word: any ReflexDrillable,
        isReviewed: Bool = false,
        isResultCorrect: Bool = false,
        isResultTimeout: Bool = false,
        showHint: Bool = false,
        hintStage: Int = 0,
        clozeStages: ReflexClozeStageSet? = nil,
        clozeParts: ClozeSentenceParts? = nil,
        displayedSentence: String = "",
        hintBadgeText: String? = nil,
        speechState: CraftSpeechState = .listening(),
        liveTranscript: String = "",
        onCantSpeakNow: (() -> Void)? = nil,
        onReplayAudio: (() -> Void)? = nil
    ) {
        self.word = word
        self.isReviewed = isReviewed
        self.isResultCorrect = isResultCorrect
        self.isResultTimeout = isResultTimeout
        self.showHint = showHint
        self.hintStage = hintStage
        self.clozeStages = clozeStages
        self.clozeParts = clozeParts
        self.displayedSentence = displayedSentence.isEmpty ? word.clozeSentenceEn : displayedSentence
        self.hintBadgeText = hintBadgeText
        self.speechState = speechState
        self.liveTranscript = liveTranscript
        self.onCantSpeakNow = onCantSpeakNow
        self.onReplayAudio = onReplayAudio
    }

    public init(
        word: any ReflexDrillable,
        liveTranscript: String = "",
        elapsedTimeMs: Int = 0,
        showHint: Bool = false,
        hintStage: Int = 0,
        clozeStages: ReflexClozeStageSet? = nil,
        clozeParts: ClozeSentenceParts? = nil,
        displayedSentence: String = "",
        hintBadgeText: String? = nil,
        onCantSpeakNow: (() -> Void)? = nil
    ) {
        self.init(
            word: word,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: showHint,
            hintStage: hintStage,
            clozeStages: clozeStages,
            clozeParts: clozeParts,
            displayedSentence: displayedSentence,
            hintBadgeText: hintBadgeText,
            speechState: .listening(),
            liveTranscript: liveTranscript,
            onCantSpeakNow: onCantSpeakNow,
            onReplayAudio: nil
        )
    }

    public var activeClozeParts: ClozeSentenceParts? {
        guard let stages = clozeStages else { return clozeParts }
        switch hintStage {
        case 0: return stages.initialParts
        case 1: return stages.lengthMaskedParts
        default: return stages.patternRevealedParts
        }
    }

    public var body: some View {
        VStack(spacing: theme.spacing.lg) {
            // Zone 1: 3D Flip Card
            flipStimulusCard

            // Zone 2: Mic Hub + Transcript (on canvas, no card wrapper)
            micHubArea
        }
    }

    // MARK: - Zone 1: 3D Flip Stimulus Card

    @ViewBuilder
    private var flipStimulusCard: some View {
        let statusGlow: Color? = isReviewed
            ? (isResultCorrect
                ? theme.colors.statusSuccess.opacity(0.2)
                : theme.colors.statusDanger.opacity(0.2))
            : nil

        CraftFlipCard(
            isFlipped: Binding(
                get: { isReviewed },
                set: { _ in }
            ),
            style: .tactile3D,
            axis: .horizontal,
            showSpecularGlare: true,
            showsHighlightBorder: false,
            highlightShadowColor: statusGlow,
            isTapToFlipEnabled: false,
            isSensoryFeedbackEnabled: false,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.base,
            perspective: 0.5,
            animation: .spring(response: 0.45, dampingFraction: 0.78)
        ) {
            frontPromptFace
        } back: {
            backResultFace
        }
    }

    // MARK: - Front Face (Active Challenge)

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
            }
            .opacity(hintStage >= 1 ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: hintStage)

            frontSentenceArea
                .padding(.top, theme.spacing.xxs)
        }
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .center)
    }

    // MARK: - Back Face (Reviewed Consolidation)

    private var backResultFace: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
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

            if !word.ipa.isEmpty {
                CraftText(
                    word.ipa,
                    style: .caption,
                    color: theme.colors.textMuted,
                    textAlignment: .leading
                )
                .accessibilityLabel(AppStrings.ReflexBlitz.ipaA11y(word.ipa))
            }

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
            .padding(.vertical, theme.spacing.xxs)

            CraftText(
                word.definitionVi,
                style: .titleMedium,
                color: theme.colors.textPrimary,
                textAlignment: .leading
            )
            .padding(.top, theme.spacing.xxs)

            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                backSentenceView
                    .multilineTextAlignment(.leading)
                    .lineSpacing(theme.spacing.xs)
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
            .padding(.top, theme.spacing.xs)
        }
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .center)
    }

    // MARK: - Zone 2: Mic Hub + Transcript Badge

    @ViewBuilder
    private var micHubArea: some View {
        VStack(spacing: theme.spacing.base) {
            CraftTactileMicHubView(
                speechState: isReviewed
                    ? .evaluated(overallScore: isResultCorrect ? 100 : 0)
                    : speechState,
                customSubtitle: isReviewed ? "" : nil,
                onTapMic: {}  // Auto continuous listening
            )
            .disabled(true)

            ReflexSpeakingLiveBadge(
                liveTranscript: liveTranscript,
                isReviewed: isReviewed,
                isResultCorrect: isResultCorrect
            )
            .equatable()
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: !liveTranscript.isEmpty)

            if !isReviewed, let onCantSpeakNow {
                CraftButton(
                    AppStrings.Practice.cantSpeakNowCTA,
                    iconName: "waveform.slash",
                    variant: .ghost,
                    size: .sm,
                    action: onCantSpeakNow
                )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isReviewed)
    }

    // MARK: - Sentence Helpers

    @ViewBuilder
    private var frontSentenceArea: some View {
        VStack(spacing: theme.spacing.xs) {
            frontSentenceView
                .multilineTextAlignment(.center)
                .lineSpacing(theme.spacing.sm)
                .padding(.horizontal, theme.spacing.xs)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: hintStage)
                .accessibilityLabel(
                    AppStrings.ReflexBlitz.clozeSentenceA11y(word.clozeSentenceEn)
                )
        }
    }

    @ViewBuilder
    private var frontSentenceView: some View {
        if let parts = activeClozeParts ?? clozeParts {
            activeClozeText(parts: parts)
        } else {
            Text(displayedSentence)
                .font(theme.typography.bodySerif.weight(.medium))
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    private func activeClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotColor = (hintStage >= 2) ? theme.colors.statusWarning : theme.colors.brandPrimary
        let slotText = Text(parts.slot)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(slotColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }

    private var effectiveClozeParts: ClozeSentenceParts? {
        if let parts = clozeStages?.initialParts ?? clozeParts {
            return parts
        }
        let formatted = ReflexClozeFormatter.formatCloze(sentenceEn: word.exampleSentenceEn, lemma: word.lemma)
        return ReflexClozeFormatter.extractTemplateParts(from: formatted)
    }

    @ViewBuilder
    private var backSentenceView: some View {
        if let parts = effectiveClozeParts {
            reviewedClozeText(parts: parts)
        } else {
            Text(word.completedSentenceWithTargetWord)
                .font(theme.typography.bodySerif.weight(.medium))
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    private func reviewedClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotColor: Color = isResultCorrect
            ? theme.colors.statusSuccess
            : theme.colors.statusDanger
        let slotWord = parts.slot.contains("_") ? word.lemma : parts.slot
        let slotText = Text(slotWord)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(slotColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }
}

// MARK: - Subviews

private struct ReflexSpeakingLiveBadge: View, Equatable {
    let liveTranscript: String
    let isReviewed: Bool
    let isResultCorrect: Bool
    @Environment(\.craftTheme) private var theme

    private var renderedToken: String {
        liveTranscript
            .split(separator: " ")
            .last
            .map(String.init) ?? liveTranscript
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.renderedToken == rhs.renderedToken &&
        lhs.isReviewed == rhs.isReviewed &&
        lhs.isResultCorrect == rhs.isResultCorrect
    }

    var body: some View {
        if !liveTranscript.isEmpty {
            CraftBadge(
                renderedToken,
                iconName: "waveform",
                variant: isReviewed ? .subtle : .solid,
                tone: isReviewed
                    ? (isResultCorrect ? .success : .danger)
                    : .primary,
                size: .md,
                shape: .capsule
            )
            .transition(.scale.combined(with: .opacity))
        }
    }
}
