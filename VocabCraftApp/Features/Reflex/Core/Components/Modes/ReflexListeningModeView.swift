import CraftUIKit
import SwiftUI

/// Isolated challenge mode view for Reflex Listening modality.
/// Lemma and cloze prompt remain hidden during active countdown; learners listen to audio
/// stimulus and select the matching definition among 4 choices on the canvas.
public struct ReflexListeningModeView: View {
    @Environment(\.craftTheme) private var theme

    public let word: (any ReflexDrillable)?
    public let options: [ReflexBlitzOption]
    public let elapsedTimeMs: Int
    public let isReviewed: Bool
    public let selectedOptionText: String?
    public let hintStage: Int
    public let eliminatedOptionId: String?
    public let onPlayAudio: (() -> Void)?
    public let onSelectOption: ((ReflexBlitzOption) -> Void)?

    public init(
        word: (any ReflexDrillable)? = nil,
        options: [ReflexBlitzOption],
        elapsedTimeMs: Int = 0,
        isReviewed: Bool = false,
        selectedOptionText: String? = nil,
        hintStage: Int = 0,
        eliminatedOptionId: String? = nil,
        onPlayAudio: (() -> Void)? = nil,
        onSelectOption: ((ReflexBlitzOption) -> Void)? = nil
    ) {
        self.word = word
        self.options = options
        self.elapsedTimeMs = elapsedTimeMs
        self.isReviewed = isReviewed
        self.selectedOptionText = selectedOptionText
        self.hintStage = hintStage
        self.eliminatedOptionId = eliminatedOptionId
        self.onPlayAudio = onPlayAudio
        self.onSelectOption = onSelectOption
    }

    public func choiceState(for option: ReflexBlitzOption) -> CraftChoiceState {
        guard isReviewed else {
            if hintStage >= 3 && option.id == eliminatedOptionId {
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
            audioHeroArea
            dividerLine
            listeningOptionsListView
        }
    }

    // MARK: - Audio Hero Stimulus Area
    @ViewBuilder
    private var audioHeroArea: some View {
        VStack(spacing: theme.spacing.md) {
            CraftWaveformView(
                barCount: 16,
                spacing: theme.spacing.xs,
                minHeight: 6,
                maxHeight: 36,
                barWidth: 4,
                isRecording: true,
                activeColor: theme.colors.accent
            )
            .frame(height: 36)
            .accessibilityHidden(true)

            if let onPlayAudio {
                CraftSpeakerButton(
                    variant: .subtle,
                    size: .lg,
                    isPlaying: false,
                    label: AppStrings.ReflexBlitz.listeningReplay,
                    action: onPlayAudio
                )
            }

            CraftText(
                AppStrings.ReflexBlitz.listeningInstructionText,
                style: .caption,
                color: theme.colors.textMuted,
                textAlignment: .center
            )
        }
        .padding(.vertical, theme.spacing.xs)
    }

    private var dividerLine: some View {
        CraftDivider()
            .padding(.horizontal, theme.spacing.xs)
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
