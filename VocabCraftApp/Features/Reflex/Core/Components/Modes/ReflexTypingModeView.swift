import CraftUIKit
import SwiftUI

/// Challenge and reviewed view for Reflex Blitz Typing modality.
/// Features a 3D Flip Card stimulus container (front: definition + cloze prompt; back: target word, IPA, user input subtitle, audio replay, example sentence)
/// and a floating keyboard-docked input bar with auto-focus and return key validation.
public struct ReflexTypingModeView: View {
    @Environment(\.craftTheme) private var theme

    public let word: any ReflexDrillable
    public let isReviewed: Bool
    public let isResultCorrect: Bool
    public let isResultTimeout: Bool
    public let showHint: Bool
    public let hintStage: Int
    @Binding public var typingText: String
    public let userSubmittedText: String?
    public let clozeStages: ReflexClozeStageSet?
    public let clozeParts: ClozeSentenceParts?
    public let displayedSentence: String
    public let hintBadgeText: String?
    public let onSubmit: (() -> Void)?
    public let onReplayAudio: (() -> Void)?

    @FocusState private var isTextFieldFocused: Bool

    public init(
        word: any ReflexDrillable,
        isReviewed: Bool = false,
        isResultCorrect: Bool = false,
        isResultTimeout: Bool = false,
        showHint: Bool = false,
        hintStage: Int = 0,
        typingText: Binding<String>,
        userSubmittedText: String? = nil,
        clozeStages: ReflexClozeStageSet? = nil,
        clozeParts: ClozeSentenceParts? = nil,
        displayedSentence: String = "",
        hintBadgeText: String? = nil,
        onSubmit: (() -> Void)? = nil,
        onReplayAudio: (() -> Void)? = nil
    ) {
        self.word = word
        self.isReviewed = isReviewed
        self.isResultCorrect = isResultCorrect
        self.isResultTimeout = isResultTimeout
        self.showHint = showHint
        self.hintStage = hintStage
        self._typingText = typingText
        self.userSubmittedText = userSubmittedText
        self.clozeStages = clozeStages
        self.clozeParts = clozeParts
        self.displayedSentence = displayedSentence.isEmpty ? word.clozeSentenceEn : displayedSentence
        self.hintBadgeText = hintBadgeText
        self.onSubmit = onSubmit
        self.onReplayAudio = onReplayAudio
    }

    public init(
        word: any ReflexDrillable,
        typingText: Binding<String>,
        showHint: Bool = false,
        hintStage: Int = 0,
        clozeStages: ReflexClozeStageSet? = nil,
        clozeParts: ClozeSentenceParts? = nil,
        displayedSentence: String = "",
        hintBadgeText: String? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.init(
            word: word,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: showHint,
            hintStage: hintStage,
            typingText: typingText,
            userSubmittedText: nil,
            clozeStages: clozeStages,
            clozeParts: clozeParts,
            displayedSentence: displayedSentence,
            hintBadgeText: hintBadgeText,
            onSubmit: onSubmit,
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
        VStack(spacing: theme.spacing.md) {
            flipStimulusCard

            if isReviewed {
                externalTypedBadge
            } else {
                floatingInputBar
            }
        }
        .onAppear {
            requestDelayedFocus()
        }
        .onChange(of: isReviewed) { _, reviewed in
            if reviewed {
                isTextFieldFocused = false
            } else {
                requestDelayedFocus()
            }
        }
    }

    private func requestDelayedFocus() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            guard !isReviewed else { return }
            isTextFieldFocused = true
        }
    }

    // MARK: - 3D Flip Stimulus Card

    @ViewBuilder
    private var flipStimulusCard: some View {
        let statusGlow: Color? = isReviewed
            ? (isResultCorrect ? theme.colors.statusSuccess.opacity(0.2) : theme.colors.statusDanger.opacity(0.2))
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

    // MARK: - Front Face

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

            sentenceArea
                .padding(.top, theme.spacing.xs / 2)
        }
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .center)
    }

    // MARK: - Back Face

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

            // Row 3: Badges (POS capsule, Level capsule)
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
                backSentenceView
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
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .center)
    }

    // MARK: - External Typed Answer Badge

    @ViewBuilder
    private var externalTypedBadge: some View {
        if isReviewed,
           let submitted = userSubmittedText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !submitted.isEmpty {
            CraftBadge(
                isResultCorrect
                    ? AppStrings.ReflexBlitz.typingEnteredPrefix(submitted)
                    : AppStrings.ReflexBlitz.typingYouTypedPrefix(submitted),
                variant: .subtle,
                tone: isResultCorrect ? .success : .danger,
                size: .md,
                shape: .capsule
            )
            .padding(.top, theme.spacing.sm)
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Sentence Area

    @ViewBuilder
    private var sentenceArea: some View {
        VStack(spacing: theme.spacing.xs) {
            frontSentenceView
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, theme.spacing.xs)
                .fixedSize(horizontal: false, vertical: true)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: hintStage)
                .accessibilityLabel(
                    isReviewed
                        ? AppStrings.ReflexBlitz.completedSentenceA11y(word.completedSentenceWithTargetWord)
                        : AppStrings.ReflexBlitz.clozeSentenceA11y(word.clozeSentenceEn)
                )
        }
    }

    @ViewBuilder
    private var frontSentenceView: some View {
        if let parts = activeClozeParts ?? clozeParts {
            activeClozeText(parts: parts)
        } else {
            Text(displayedSentence.isEmpty ? word.clozeSentenceEn : displayedSentence)
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
        let sentence = word.exampleSentenceEn.isEmpty ? word.clozeSentenceEn : word.exampleSentenceEn
        return ReflexClozeFormatter.extractClozeOrLemmaParts(sentenceEn: sentence, lemma: word.lemma)
    }

    @ViewBuilder
    private var backSentenceView: some View {
        if let parts = effectiveClozeParts {
            reviewedClozeText(parts: parts)
        } else {
            Text(displayedSentence.isEmpty ? word.completedSentenceWithTargetWord : displayedSentence)
                .font(theme.typography.bodySerif.weight(.medium))
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    private func reviewedClozeText(parts: ClozeSentenceParts) -> Text {
        let prefixText = Text(parts.prefix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        let slotColor: Color = isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
        let slotWord = parts.slot.contains("_") ? word.lemma : parts.slot
        let slotText = Text(slotWord)
            .font(theme.typography.bodySerif.bold())
            .foregroundColor(slotColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }

    // MARK: - Floating Input Dock

    @ViewBuilder
    private var floatingInputBar: some View {
        HStack(spacing: theme.spacing.sm) {
            Image(systemName: "keyboard")
                .foregroundColor(theme.colors.textMuted)
                .font(theme.typography.bodyMedium)

            TextField(
                AppStrings.ReflexBlitz.typingPlaceholderText,
                text: $typingText
            )
            .font(theme.typography.bodyMedium)
            .foregroundColor(theme.colors.textPrimary)
            .focused($isTextFieldFocused)
            .submitLabel(.go)
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .onSubmit {
                handleSubmission()
            }
            .accessibilityLabel(AppStrings.ReflexBlitz.typingInputA11y)
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.surfaceElevated)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(theme.colors.hairline, lineWidth: 1)
        )
        .shadow(
            color: theme.shadows.sm.color,
            radius: theme.shadows.sm.radius,
            x: theme.shadows.sm.x,
            y: theme.shadows.sm.y
        )
        .padding(.horizontal, theme.spacing.base)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func handleSubmission() {
        let trimmed = typingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit?()
    }
}
