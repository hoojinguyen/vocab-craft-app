import CraftUIKit
import SwiftUI

/// Challenge and reviewed view for Reflex Blitz and standalone Listening modality.
/// Features a 3D Flip Card stimulus container (front: dynamic waveform visualizer + POS hint; back: target word, speaker button, IPA, badges, Vietnamese definition, full example sentence)
/// and an interactive options list placed directly on the canvas background.
public struct ReflexListeningModeView: View {
    @Environment(\.craftTheme) private var theme

    public let word: any ReflexDrillable
    public let options: [ReflexBlitzOption]
    public let elapsedTimeMs: Int
    public let isReviewed: Bool
    public let isResultCorrect: Bool
    public let isResultTimeout: Bool
    public let showHint: Bool
    public let hintStage: Int
    public let selectedOptionText: String?
    public let cardBorderColor: Color
    public let eliminatedOptionId: String?
    public let onSelectOption: ((ReflexBlitzOption) -> Void)?
    public let onPlayAudio: (() -> Void)?
    public let onReplayAudio: (() -> Void)?

    @State private var isAudioPlaying: Bool = false
    @State private var audioTimerTask: Task<Void, Never>?

    public init(
        word: any ReflexDrillable,
        options: [ReflexBlitzOption],
        elapsedTimeMs: Int = 0,
        isReviewed: Bool = false,
        isResultCorrect: Bool = false,
        isResultTimeout: Bool = false,
        showHint: Bool = false,
        hintStage: Int = 0,
        selectedOptionText: String? = nil,
        cardBorderColor: Color = .clear,
        eliminatedOptionId: String? = nil,
        onSelectOption: ((ReflexBlitzOption) -> Void)? = nil,
        onPlayAudio: (() -> Void)? = nil,
        onReplayAudio: (() -> Void)? = nil
    ) {
        self.word = word
        self.options = options
        self.elapsedTimeMs = elapsedTimeMs
        self.isReviewed = isReviewed
        self.isResultCorrect = isResultCorrect
        self.isResultTimeout = isResultTimeout
        self.showHint = showHint
        self.hintStage = hintStage
        self.selectedOptionText = selectedOptionText
        self.cardBorderColor = cardBorderColor
        self.eliminatedOptionId = eliminatedOptionId
        self.onSelectOption = onSelectOption
        self.onPlayAudio = onPlayAudio
        self.onReplayAudio = onReplayAudio
    }

    public func choiceState(for option: ReflexBlitzOption) -> CraftChoiceState {
        guard isReviewed else {
            if hintStage >= 2 && option.id == eliminatedOptionId {
                return .disabled
            }
            return .idle
        }
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

            listeningOptionsListView
        }
        .onAppear {
            if !isReviewed {
                triggerAudioPlayback()
            }
        }
        .onDisappear {
            audioTimerTask?.cancel()
        }
        .onChange(of: hintStage) { _, newStage in
            if !isReviewed && newStage > 0 {
                triggerAudioPlayback()
            }
        }
    }

    // MARK: - Audio Playback

    private func triggerAudioPlayback() {
        onPlayAudio?()
        isAudioPlaying = true
        audioTimerTask?.cancel()
        audioTimerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if !Task.isCancelled {
                isAudioPlaying = false
            }
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

    // MARK: - Front Prompt Face

    private var frontPromptFace: some View {
        VStack(spacing: theme.spacing.md) {
            CraftWaveformView(
                barCount: 16,
                spacing: theme.spacing.xs,
                minHeight: 6,
                maxHeight: 40,
                barWidth: 4,
                isRecording: isAudioPlaying,
                activeColor: theme.colors.brandPrimary
            )
            .frame(height: 40)
            .accessibilityHidden(true)

            if hintStage >= 1 && !word.cleanPos.isEmpty {
                CraftBadge(
                    word.cleanPos,
                    variant: .subtle,
                    tone: .neutral,
                    size: .sm,
                    shape: .capsule
                )
                .transition(.scale.combined(with: .opacity))
            }

            CraftText(
                AppStrings.ReflexBlitz.listeningInstructionText,
                style: .caption,
                color: theme.colors.textMuted,
                textAlignment: .center
            )
        }
        .frame(maxWidth: .infinity, minHeight: 195, alignment: .center)
        .padding(.vertical, theme.spacing.xs)
    }

    // MARK: - Back Result Face

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

            // Row 3: Badges (Part of Speech & CEFR Level)
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

            // Row 5: Completed Sentence & Vietnamese Translation
            VStack(alignment: .leading, spacing: 4) {
                CraftText(
                    word.completedSentenceWithTargetWord,
                    style: .bodySerif,
                    color: theme.colors.textPrimary,
                    textAlignment: .leading
                )
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

    // MARK: - Options List (Directly on Canvas)

    @ViewBuilder
    private var listeningOptionsListView: some View {
        VStack(spacing: theme.spacing.sm) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let choiceState = choiceState(for: option)

                CraftChoiceCard(
                    prefix: optionLetter(for: index),
                    prefixStyle: .circle,
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
                .frame(minHeight: 52)
                .accessibilityLabel(AppStrings.ReflexBlitz.optionA11y(prefix: optionLetter(for: index), text: option.text))
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
}
