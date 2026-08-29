import CraftUIKit
import SwiftUI

/// Isolated challenge mode view for Reflex Speaking modality.
/// Displays Vietnamese definition prompt, cloze sentence, active pulsing waveform visualizer,
/// live speech recognition transcript badge, and switch-to-keyboard fallback action.
public struct ReflexSpeakingModeView: View {
    @Environment(\.craftTheme) private var theme

    public let word: any ReflexDrillable
    public let liveTranscript: String
    public let elapsedTimeMs: Int
    public let showHint: Bool
    public let clozeParts: ClozeSentenceParts?
    public let displayedSentence: String?
    public let onSwitchToKeyboard: (() -> Void)?

    public init(
        word: any ReflexDrillable,
        liveTranscript: String = "",
        elapsedTimeMs: Int = 0,
        showHint: Bool = false,
        clozeParts: ClozeSentenceParts? = nil,
        displayedSentence: String? = nil,
        onSwitchToKeyboard: (() -> Void)? = nil
    ) {
        self.word = word
        self.liveTranscript = liveTranscript
        self.elapsedTimeMs = elapsedTimeMs
        self.showHint = showHint
        self.clozeParts = clozeParts
        self.displayedSentence = displayedSentence
        self.onSwitchToKeyboard = onSwitchToKeyboard
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            wordHeaderArea
            sentenceArea
            dividerLine
            livingAudioDockView
        }
    }

    // MARK: - Word Prompt Header
    @ViewBuilder
    private var wordHeaderArea: some View {
        VStack(spacing: theme.spacing.xs) {
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
        }
        .padding(.top, theme.spacing.xs / 2)
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
                .accessibilityLabel(AppStrings.ReflexBlitz.clozeSentenceA11y(word.clozeSentenceEn))
        }
    }

    @ViewBuilder
    private var sentenceView: some View {
        if let parts = clozeParts {
            activeClozeText(parts: parts)
        } else {
            Text(displayedSentence ?? word.clozeSentenceEn)
                .font(theme.typography.bodySerif.weight(.medium))
                .foregroundColor(theme.colors.textPrimary)
        }
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

    private var dividerLine: some View {
        CraftDivider()
            .padding(.horizontal, theme.spacing.xs)
    }

    // MARK: - Living Audio Visualizer Dock
    @ViewBuilder
    private var livingAudioDockView: some View {
        VStack(spacing: theme.spacing.xs) {
            CraftWaveformView(
                barCount: 16,
                spacing: theme.spacing.xs,
                minHeight: 4,
                maxHeight: 28,
                barWidth: 4,
                isRecording: true,
                activeColor: theme.colors.brandPrimary
            )
            .frame(height: 28)
            .accessibilityHidden(true)

            if liveTranscript.isEmpty {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon("mic.fill", size: .sm, color: theme.colors.textMuted)
                    CraftText(
                        AppStrings.ReflexBlitz.speakingListeningText,
                        style: .caption,
                        color: theme.colors.textMuted
                    )
                }
                .transition(.opacity)
            } else {
                CraftBadge(
                    liveTranscript,
                    iconName: "waveform",
                    variant: .solid,
                    tone: .primary,
                    size: .md,
                    shape: .capsule
                )
                .transition(.scale.combined(with: .opacity))
            }

            if let onSwitchToKeyboard {
                Button(action: onSwitchToKeyboard) {
                    HStack(spacing: theme.spacing.xs) {
                        CraftIcon("keyboard", size: .xs, color: theme.colors.textMuted)
                        Text(AppStrings.ReflexBlitz.switchToKeyboard)
                            .font(theme.typography.caption.weight(.semibold))
                    }
                    .foregroundColor(theme.colors.textMuted)
                    .padding(.top, theme.spacing.xs)
                    .frame(minHeight: 44)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(AppStrings.ReflexBlitz.switchToKeyboardText)
            }
        }
        .padding(.vertical, theme.spacing.sm)
        .padding(.horizontal, theme.spacing.base)
        .frame(maxWidth: .infinity)
        .background(theme.colors.surfaceSubtle.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: liveTranscript.isEmpty)
        .accessibilityLabel(liveTranscript.isEmpty ? AppStrings.ReflexBlitz.speechWaitingA11y : AppStrings.ReflexBlitz.speechRecognizedA11y(liveTranscript))
    }
}
