import CraftUIKit
import SwiftUI

// MARK: - Multiple Choice Section
public struct MixedDrillMultipleChoiceSection: View {
    @Environment(\.craftTheme) private var theme

    public let word: VaultWordItem
    public let options: [ReflexBlitzOption]
    public let onSelectOption: (ReflexBlitzOption) -> Void

    public init(
        word: VaultWordItem,
        options: [ReflexBlitzOption],
        onSelectOption: @escaping (ReflexBlitzOption) -> Void
    ) {
        self.word = word
        self.options = options
        self.onSelectOption = onSelectOption
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            MixedDrillPromptHeader(word: word)

            MixedDrillClozeSentence(word: word, isReviewed: false)

            CraftDivider()
                .padding(.horizontal, theme.spacing.xs)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: theme.spacing.sm), GridItem(.flexible(), spacing: theme.spacing.sm)], spacing: theme.spacing.sm) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    CraftChoiceCard(
                        prefix: optionLetter(for: index),
                        prefixStyle: .circle,
                        title: option.text,
                        state: .idle,
                        style: .tactile3D,
                        showsStatusIndicator: false,
                        action: {
                            onSelectOption(option)
                        }
                    )
                    .accessibilityLabel(AppStrings.ReflexBlitz.optionA11y(prefix: optionLetter(for: index), text: option.text))
                }
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

// MARK: - Speaking Section
public struct MixedDrillSpeakingSection: View {
    @Environment(\.craftTheme) private var theme

    public let word: VaultWordItem
    public let liveTranscript: String
    public let elapsedTimeMs: Int
    public let onSwitchToKeyboard: () -> Void

    public init(
        word: VaultWordItem,
        liveTranscript: String,
        elapsedTimeMs: Int,
        onSwitchToKeyboard: @escaping () -> Void
    ) {
        self.word = word
        self.liveTranscript = liveTranscript
        self.elapsedTimeMs = elapsedTimeMs
        self.onSwitchToKeyboard = onSwitchToKeyboard
    }

    private func speechWaveformHeight(for index: Int) -> CGFloat {
        let offset: Int = index * 5 + (elapsedTimeMs / 60)
        let dynamicHeight: Int = 8 + (offset % 18)
        return CGFloat(dynamicHeight)
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            MixedDrillPromptHeader(word: word)

            MixedDrillClozeSentence(word: word, isReviewed: false)

            CraftDivider()
                .padding(.horizontal, theme.spacing.xs)

            VStack(spacing: theme.spacing.sm) {
                HStack(spacing: 4) {
                    ForEach(0..<9, id: \.self) { idx in
                        Capsule()
                            .fill(theme.colors.statusSuccess)
                            .frame(width: 3.5, height: speechWaveformHeight(for: idx))
                            .animation(.easeInOut(duration: 0.1), value: elapsedTimeMs)
                    }
                }
                .frame(height: 26)
                .accessibilityHidden(true)

                if liveTranscript.isEmpty {
                    HStack(spacing: theme.spacing.xs) {
                        Image(systemName: "mic.fill")
                            .font(.caption2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(theme.colors.statusSuccess)

                        CraftText(
                            AppStrings.ReflexBlitz.speakingListeningText,
                            style: .caption,
                            color: theme.colors.textMuted
                        )
                    }
                } else {
                    CraftBadge(
                        liveTranscript,
                        iconName: "waveform",
                        variant: .subtle,
                        tone: .primary,
                        size: .md,
                        shape: .capsule
                    )
                }

                Button(action: onSwitchToKeyboard) {
                    HStack(spacing: 4) {
                        Image(systemName: "keyboard")
                            .font(.caption2)
                        Text(AppStrings.ReflexBlitz.switchToKeyboardText)
                            .font(theme.typography.caption.weight(.semibold))
                    }
                    .foregroundColor(theme.colors.textMuted)
                    .padding(.top, 4)
                    .frame(minHeight: 44)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, theme.spacing.sm)
            .frame(maxWidth: .infinity)
            .background(theme.colors.surfaceCard.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg, style: .continuous))
        }
    }
}

// MARK: - Typing Section
public struct MixedDrillTypingSection: View {
    @Environment(\.craftTheme) private var theme

    public let word: VaultWordItem
    @Binding public var typingText: String
    public let onSubmit: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    public init(
        word: VaultWordItem,
        typingText: Binding<String>,
        onSubmit: @escaping () -> Void
    ) {
        self.word = word
        self._typingText = typingText
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            MixedDrillPromptHeader(word: word)

            MixedDrillClozeSentence(word: word, isReviewed: false)

            CraftDivider()
                .padding(.horizontal, theme.spacing.xs)

            HStack(spacing: theme.spacing.sm) {
                TextField(AppStrings.ReflexBlitz.typingPlaceholderText, text: $typingText)
                    .textFieldStyle(.plain)
                    .font(theme.typography.bodyMedium)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.vertical, theme.spacing.sm)
                    .background(theme.colors.canvasBackground)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.md, style: .continuous)
                            .stroke(isTextFieldFocused ? theme.colors.brandPrimary : theme.colors.borderDefault, lineWidth: isTextFieldFocused ? 1.5 : 1)
                    )
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    .onSubmit {
                        onSubmit()
                    }

                Button(action: onSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(typingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.colors.textMuted.opacity(0.35) : theme.colors.brandPrimary)
                }
                .disabled(typingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(AppStrings.ReflexBlitz.typingSubmitA11y)
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
    }
}

// MARK: - Listening Section
public struct MixedDrillListeningSection: View {
    @Environment(\.craftTheme) private var theme

    public let options: [ReflexBlitzOption]
    public let elapsedTimeMs: Int
    public let onPlayAudio: () -> Void
    public let onSelectOption: (ReflexBlitzOption) -> Void

    public init(
        options: [ReflexBlitzOption],
        elapsedTimeMs: Int,
        onPlayAudio: @escaping () -> Void,
        onSelectOption: @escaping (ReflexBlitzOption) -> Void
    ) {
        self.options = options
        self.elapsedTimeMs = elapsedTimeMs
        self.onPlayAudio = onPlayAudio
        self.onSelectOption = onSelectOption
    }

    private func listeningWaveformHeight(for index: Int) -> CGFloat {
        let offset: Int = index * 6 + (elapsedTimeMs / 60)
        let dynamicHeight: Int = 8 + (offset % 22)
        return CGFloat(dynamicHeight)
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            VStack(spacing: theme.spacing.sm) {
                HStack(spacing: 5) {
                    ForEach(0..<11, id: \.self) { idx in
                        Capsule()
                            .fill(theme.colors.statusInfo)
                            .frame(width: 3.5, height: listeningWaveformHeight(for: idx))
                            .animation(.easeInOut(duration: 0.1), value: elapsedTimeMs)
                    }
                }
                .frame(height: 28)
                .accessibilityHidden(true)

                CraftButton(
                    AppStrings.ReflexBlitz.listeningReplayText,
                    iconName: "speaker.wave.3.fill",
                    variant: .outline,
                    size: .sm,
                    action: onPlayAudio
                )
                .accessibilityLabel(AppStrings.ReflexBlitz.listeningReplayText)

                CraftText(
                    AppStrings.ReflexBlitz.listeningInstructionText,
                    style: .caption,
                    color: theme.colors.textMuted,
                    textAlignment: .center
                )
            }
            .padding(.vertical, theme.spacing.xs)

            CraftDivider()
                .padding(.horizontal, theme.spacing.xs)

            VStack(spacing: theme.spacing.sm) {
                ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                    CraftChoiceCard(
                        prefix: optionLetter(for: index),
                        prefixStyle: .circle,
                        title: option.text,
                        state: .idle,
                        style: .tactile3D,
                        showsStatusIndicator: false,
                        action: {
                            onSelectOption(option)
                        }
                    )
                    .accessibilityLabel(AppStrings.ReflexBlitz.optionA11y(prefix: optionLetter(for: index), text: option.text))
                }
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

// MARK: - Reviewed Section
public struct MixedDrillReviewedSection: View {
    @Environment(\.craftTheme) private var theme

    public let item: MixedReflexDrillItem
    public let result: ReflexCardResult?
    public let options: [ReflexBlitzOption]
    public let onPlayAudio: () -> Void

    public init(
        item: MixedReflexDrillItem,
        result: ReflexCardResult?,
        options: [ReflexBlitzOption] = [],
        onPlayAudio: @escaping () -> Void
    ) {
        self.item = item
        self.result = result
        self.options = options
        self.onPlayAudio = onPlayAudio
    }

    private var isResultCorrect: Bool { result?.isCorrect ?? false }
    private var isResultTimeout: Bool { result?.isTimeout ?? false }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            statusHeaderBadge
            lemmaAndDefinitionSection
            CraftDivider()
                .padding(.horizontal, theme.spacing.xs)
            MixedDrillClozeSentence(word: item.word, isReviewed: true, isResultCorrect: isResultCorrect)

            if item.assignedMode == .multipleChoice && !options.isEmpty {
                CraftDivider()
                    .padding(.horizontal, theme.spacing.xs)
                reviewedOptionsGrid
            } else if item.assignedMode == .listening {
                listeningResultChip
            } else if item.assignedMode == .speaking, let spoken = result?.recognizedSpoken, !spoken.isEmpty {
                speakingResultChip(spoken: spoken)
            } else if item.assignedMode == .typing, let typed = result?.typedText, !typed.isEmpty {
                typingResultChip(typed: typed)
            }
        }
    }

    private var statusHeaderBadge: some View {
        CraftBadge(
            isResultCorrect
                ? AppStrings.ReflexBlitz.correctTitleText
                : (isResultTimeout ? AppStrings.ReflexBlitz.timeoutTitleText : AppStrings.ReflexBlitz.incorrectTitleText),
            iconName: isResultCorrect
                ? "checkmark.circle.fill"
                : (isResultTimeout ? "clock.badge.exclamationmark.fill" : "xmark.circle.fill"),
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
                    item.word.lemma,
                    style: .titleLarge,
                    color: theme.colors.textPrimary
                )

                if !item.word.pos.isEmpty {
                    CraftBadge(
                        item.word.pos.uppercased(),
                        variant: .subtle,
                        tone: .primary,
                        size: .sm,
                        shape: .capsule
                    )
                }

                CraftSpeakerButton(
                    variant: .subtle,
                    size: .sm,
                    isPlaying: false,
                    label: LocalizedStringKey("craft.audio.pronounce"),
                    action: onPlayAudio
                )
            }

            if !item.word.phonetic.isEmpty {
                CraftText(
                    item.word.phonetic,
                    style: .caption,
                    color: theme.colors.textMuted
                )
                .accessibilityLabel(AppStrings.ReflexBlitz.ipaA11y(item.word.phonetic))
            }

            CraftText(
                item.word.definitionVi,
                style: .titleMedium,
                color: theme.colors.textPrimary,
                textAlignment: .center
            )
            .padding(.top, theme.spacing.xs / 2)
        }
    }

    private var listeningResultChip: some View {
        CraftBadge(
            AppStrings.ReflexBlitz.selectedPrefix(result?.selectedOption ?? item.word.definitionVi),
            iconName: isResultCorrect ? "checkmark.circle.fill" : "xmark.circle.fill",
            variant: .subtle,
            tone: isResultCorrect ? .success : .danger,
            size: .md,
            shape: .capsule
        )
    }

    private func speakingResultChip(spoken: String) -> some View {
        CraftBadge(
            AppStrings.ReflexBlitz.spokenRecognized(spoken),
            iconName: "waveform",
            variant: .subtle,
            tone: .primary,
            size: .md,
            shape: .capsule
        )
    }

    private func typingResultChip(typed: String) -> some View {
        CraftBadge(
            AppStrings.ReflexBlitz.typedAnswer(typed),
            iconName: "keyboard",
            variant: .subtle,
            tone: isResultCorrect ? .success : .danger,
            size: .md,
            shape: .capsule
        )
    }

    @ViewBuilder
    private var reviewedOptionsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: theme.spacing.sm), GridItem(.flexible(), spacing: theme.spacing.sm)], spacing: theme.spacing.sm) {
            ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                let isSelected = (option.text == result?.selectedOption)
                let isOptionCorrect = option.isCorrect
                let choiceState: CraftChoiceState = isOptionCorrect ? .correct : (isSelected ? .wrong : .idle)

                CraftChoiceCard(
                    prefix: optionLetter(for: index),
                    prefixStyle: .circle,
                    title: option.text,
                    state: choiceState,
                    style: .tactile3D,
                    showsStatusIndicator: isOptionCorrect || isSelected,
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
}

// MARK: - Reusable Helpers
public struct MixedDrillPromptHeader: View {
    @Environment(\.craftTheme) private var theme

    public let word: VaultWordItem

    public init(word: VaultWordItem) {
        self.word = word
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            CraftText(
                word.lemma,
                style: .titleMedium,
                color: theme.colors.textPrimary
            )

            if !word.phonetic.isEmpty {
                CraftText(
                    word.phonetic,
                    style: .caption,
                    color: theme.colors.textMuted
                )
            }

            Spacer()

            if !word.pos.isEmpty {
                CraftBadge(
                    word.pos.uppercased(),
                    variant: .subtle,
                    tone: .primary,
                    size: .sm,
                    shape: .capsule
                )
            }
        }
    }
}

public struct MixedDrillClozeSentence: View {
    @Environment(\.craftTheme) private var theme

    public let word: VaultWordItem
    public let isReviewed: Bool
    public var isResultCorrect: Bool

    public init(word: VaultWordItem, isReviewed: Bool, isResultCorrect: Bool = true) {
        self.word = word
        self.isReviewed = isReviewed
        self.isResultCorrect = isResultCorrect
    }

    public var body: some View {
        if !word.exampleSentenceEn.isEmpty {
            VStack(spacing: theme.spacing.xs) {
                if isReviewed {
                    reviewedFormattedSentence
                } else {
                    activeClozeSentence
                }

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
            .padding(.horizontal, theme.spacing.xs)
            .padding(.vertical, theme.spacing.xs)
        }
    }

    @ViewBuilder
    private var reviewedFormattedSentence: some View {
        if let range = word.exampleSentenceEn.range(of: word.lemma, options: .caseInsensitive) {
            let prefix = String(word.exampleSentenceEn[..<range.lowerBound])
            let target = String(word.exampleSentenceEn[range])
            let suffix = String(word.exampleSentenceEn[range.upperBound...])
            (
                Text(prefix)
                    .font(theme.typography.titleMedium)
                    .fontDesign(.serif)
                    .foregroundColor(theme.colors.textPrimary)
                +
                Text(target)
                    .font(theme.typography.titleMedium.bold())
                    .fontDesign(.serif)
                    .foregroundColor(isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
                +
                Text(suffix)
                    .font(theme.typography.titleMedium)
                    .fontDesign(.serif)
                    .foregroundColor(theme.colors.textPrimary)
            )
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(word.exampleSentenceEn)
                .font(theme.typography.titleMedium.bold())
                .fontDesign(.serif)
                .foregroundColor(isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var activeClozeSentence: some View {
        if let range = word.exampleSentenceEn.range(of: word.lemma, options: .caseInsensitive) {
            let prefix = String(word.exampleSentenceEn[..<range.lowerBound])
            let suffix = String(word.exampleSentenceEn[range.upperBound...])
            (
                Text(prefix)
                    .font(theme.typography.titleMedium)
                    .fontDesign(.serif)
                    .foregroundColor(theme.colors.textPrimary)
                +
                Text(" [ ______ ] ")
                    .font(theme.typography.titleMedium.bold())
                    .fontDesign(.monospaced)
                    .foregroundColor(theme.colors.brandPrimary)
                +
                Text(suffix)
                    .font(theme.typography.titleMedium)
                    .fontDesign(.serif)
                    .foregroundColor(theme.colors.textPrimary)
            )
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(word.exampleSentenceEn)
                .font(theme.typography.titleMedium)
                .fontDesign(.serif)
                .foregroundColor(theme.colors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
