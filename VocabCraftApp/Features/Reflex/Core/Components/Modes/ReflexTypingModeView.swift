import CraftUIKit
import SwiftUI

/// Isolated challenge mode view for Reflex Typing modality.
/// Displays Vietnamese definition prompt, cloze sentence, auto-focused `CraftTextField`,
/// tactile submit button, and enter-key submission support.
public struct ReflexTypingModeView: View {
    @Environment(\.craftTheme) private var theme

    public let word: any ReflexDrillable
    @Binding public var typingText: String
    public let showHint: Bool
    public let hintStage: Int
    public let clozeStages: ReflexClozeStageSet?
    public let clozeParts: ClozeSentenceParts?
    public let displayedSentence: String?
    public let hintBadgeText: String?
    public let onSubmit: (() -> Void)?

    @FocusState private var isTextFieldFocused: Bool

    public init(
        word: any ReflexDrillable,
        typingText: Binding<String>,
        showHint: Bool = false,
        hintStage: Int = 0,
        clozeStages: ReflexClozeStageSet? = nil,
        clozeParts: ClozeSentenceParts? = nil,
        displayedSentence: String? = nil,
        hintBadgeText: String? = nil,
        onSubmit: (() -> Void)? = nil
    ) {
        self.word = word
        self._typingText = typingText
        self.showHint = showHint
        self.hintStage = hintStage
        self.clozeStages = clozeStages
        self.clozeParts = clozeParts
        self.displayedSentence = displayedSentence
        self.hintBadgeText = hintBadgeText
        self.onSubmit = onSubmit
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
            wordHeaderArea
            sentenceArea
            dividerLine
            typingInputDockView
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

                if showHint || hintStage > 0 {
                    let badgeText = (hintBadgeText?.isEmpty == false)
                        ? hintBadgeText!
                        : AppStrings.ReflexBlitz.hintPrefix(word.cleanInitialLetterHint)
                    CraftBadge(
                        badgeText,
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
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: hintStage)
                .accessibilityLabel(AppStrings.ReflexBlitz.clozeSentenceA11y(word.clozeSentenceEn))
        }
    }

    @ViewBuilder
    private var sentenceView: some View {
        if let parts = activeClozeParts ?? clozeParts {
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
            .foregroundColor((showHint || hintStage >= 2) ? theme.colors.statusWarning : theme.colors.brandPrimary)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
    }

    private var dividerLine: some View {
        CraftDivider()
            .padding(.horizontal, theme.spacing.xs)
    }

    // MARK: - Typing Input Dock
    @ViewBuilder
    private var typingInputDockView: some View {
        let isInputEmpty = typingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        HStack(spacing: theme.spacing.sm) {
            CraftTextField(
                placeholder: AppStrings.ReflexBlitz.typingPlaceholderText,
                text: $typingText,
                leadingIcon: "keyboard",
                style: .standard
            )
            .focused($isTextFieldFocused)
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .onSubmit {
                onSubmit?()
            }
            .accessibilityLabel(AppStrings.ReflexBlitz.typingInputA11y)

            CraftIconButton(
                iconName: "arrow.up.circle.fill",
                size: .lg,
                shape: .circle,
                variant: isInputEmpty ? .subtle : .filled,
                accessibilityLabel: AppStrings.ReflexBlitz.typingSubmitA11y,
                action: {
                    onSubmit?()
                }
            )
            .disabled(isInputEmpty)
        }
        .padding(.horizontal, theme.spacing.xs / 2)
        .onAppear {
            isTextFieldFocused = true
        }
    }
}
