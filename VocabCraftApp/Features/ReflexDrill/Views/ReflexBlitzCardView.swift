import CraftUIKit
import SwiftUI

/// Structural breakdown of a cloze sentence for inline styled reveal.
public struct ClozeSentenceParts: Equatable, Sendable {
    public let prefix: String
    public let slot: String
    public let suffix: String

    public init(prefix: String, slot: String, suffix: String) {
        self.prefix = prefix
        self.slot = slot
        self.suffix = suffix
    }
}

/// Challenge card view for Reflex Blitz drill supporting 4 modalities (Speaking, Typing, Multiple Choice, Listening)
/// and a paused review consolidation state.
public struct ReflexBlitzCardView: View {
    @Environment(\.craftTheme) private var theme

    public let word: ReflexBlitzWordItem
    public let mode: ReflexBlitzMode
    public let cardPhase: ReflexCardPhase
    public let options: [ReflexBlitzOption]
    public let fractionRemaining: Double
    public let timerStage: ReflexBlitzTimerStage
    public let showHint: Bool
    public let isCorrect: Bool
    public let isTimeout: Bool
    public let liveTranscript: String
    public let elapsedTimeMs: Int
    public let isKeyboardFallbackActive: Bool
    @Binding public var keyboardInputText: String
    public let onSelectOption: ((ReflexBlitzOption) -> Void)?
    public let onSubmitKeyboard: (() -> Void)?
    public let onReplayAudio: (() -> Void)?

    @FocusState private var isTextFieldFocused: Bool
    @State private var shakeOffset: CGFloat = 0

    public init(
        word: ReflexBlitzWordItem,
        mode: ReflexBlitzMode = .speaking,
        cardPhase: ReflexCardPhase = .activeCountdown,
        options: [ReflexBlitzOption] = [],
        fractionRemaining: Double = 1.0,
        timerStage: ReflexBlitzTimerStage = .steady,
        showHint: Bool = false,
        isCorrect: Bool = false,
        isTimeout: Bool = false,
        liveTranscript: String = "",
        elapsedTimeMs: Int = 0,
        isKeyboardFallbackActive: Bool = false,
        keyboardInputText: Binding<String> = .constant(""),
        onSelectOption: ((ReflexBlitzOption) -> Void)? = nil,
        onSubmitKeyboard: (() -> Void)? = nil,
        onReplayAudio: (() -> Void)? = nil
    ) {
        self.word = word
        self.mode = mode
        self.cardPhase = cardPhase
        self.options = options
        self.fractionRemaining = fractionRemaining
        self.timerStage = timerStage
        self.showHint = showHint
        self.isCorrect = isCorrect
        self.isTimeout = isTimeout
        self.liveTranscript = liveTranscript
        self.elapsedTimeMs = elapsedTimeMs
        self.isKeyboardFallbackActive = isKeyboardFallbackActive
        self._keyboardInputText = keyboardInputText
        self.onSelectOption = onSelectOption
        self.onSubmitKeyboard = onSubmitKeyboard
        self.onReplayAudio = onReplayAudio
    }

    public var isReviewed: Bool {
        if case .reviewed = cardPhase {
            return true
        }
        return isCorrect || isTimeout
    }

    public var reviewResult: ReflexCardResult? {
        if case .reviewed(let result) = cardPhase {
            return result
        }
        if isCorrect || isTimeout {
            return ReflexCardResult(
                isCorrect: isCorrect,
                responseTimeMs: elapsedTimeMs,
                isTimeout: isTimeout
            )
        }
        return nil
    }

    public var isResultCorrect: Bool {
        if let result = reviewResult {
            return result.isCorrect
        }
        return isCorrect
    }

    public var isResultTimeout: Bool {
        if let result = reviewResult {
            return result.isTimeout
        }
        return isTimeout
    }

    public var selectedOptionText: String? {
        reviewResult?.selectedOption
    }

    public var displayedSentence: String {
        if isReviewed {
            return word.completedSentenceWithTargetWord
        } else {
            return word.clozeSentenceEn
        }
    }

    public var cardBorderColor: Color {
        theme.colors.hairline.opacity(0.4)
    }

    public var timerStrokeColor: Color {
        if isResultCorrect {
            return theme.colors.statusSuccess
        } else if isResultTimeout {
            return theme.colors.statusDanger
        } else {
            switch timerStage {
            case .steady:
                return theme.colors.brandPrimary
            case .warning:
                return theme.colors.statusWarning
            case .urgent:
                return theme.colors.statusDanger
            }
        }
    }

    public var slotRepresentation: String {
        if isReviewed {
            return word.lemma
        } else if showHint {
            let initial = String(word.lemma.prefix(1)).lowercased()
            return "[ \(initial) • • ]"
        } else {
            return "[ • • • ]"
        }
    }

    public var clozeParts: ClozeSentenceParts? {
        guard word.hasClozeSlot else { return nil }
        let slot = isReviewed ? word.lemma : slotRepresentation
        return ClozeSentenceParts(prefix: word.clozePrefix, slot: slot, suffix: word.clozeSuffix)
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

    public func showsStatusIndicator(for option: ReflexBlitzOption) -> Bool {
        guard isReviewed else { return false }
        return option.isCorrect || (option.text == selectedOptionText)
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            if isReviewed && mode != .multipleChoice {
                ReflexBlitzCardReviewedView(
                    word: word,
                    mode: mode,
                    isReviewed: isReviewed,
                    isResultCorrect: isResultCorrect,
                    isResultTimeout: isResultTimeout,
                    options: options,
                    reviewResult: reviewResult,
                    selectedOptionText: selectedOptionText,
                    clozeParts: clozeParts,
                    displayedSentence: displayedSentence,
                    onReplayAudio: onReplayAudio
                )
            } else {
                activeCountdownContentView
            }
        }
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadows.lg.color, radius: theme.shadows.lg.radius, x: theme.shadows.lg.x, y: theme.shadows.lg.y)
        .offset(x: shakeOffset)
        .padding(.horizontal, theme.spacing.base)
        .onChange(of: isReviewed) { _, reviewed in
            if reviewed && !isResultCorrect {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.2, blendDuration: 0.15)) {
                    shakeOffset = 6
                }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(150))
                    shakeOffset = 0
                }
            }
        }
    }
}

// MARK: - Active Countdown Subviews

extension ReflexBlitzCardView {
    @ViewBuilder
    private var activeCountdownContentView: some View {
        switch mode {
        case .speaking:
            activeSpeakingContent
        case .typing:
            activeTypingContent
        case .multipleChoice:
            activeMultipleChoiceContent
        case .listening:
            activeListeningContent
        }
    }

    @ViewBuilder
    private var activeSpeakingContent: some View {
        triggerArea
        sentenceArea
        scaffoldingArea
        dividerLine
        livingAudioDockView
    }

    @ViewBuilder
    private var activeTypingContent: some View {
        triggerArea
        sentenceArea
        scaffoldingArea
        dividerLine
        typingInputDockView
    }

    @ViewBuilder
    private var activeMultipleChoiceContent: some View {
        triggerArea
        sentenceArea
        scaffoldingArea
        dividerLine
        optionsListView
    }

    @ViewBuilder
    private var activeListeningContent: some View {
        // Listening mode stimulus: Hero Audio Player Widget + Replay cue (Lemma & Cloze hidden!)
        VStack(spacing: theme.spacing.md) {
            // Pulsing Waveform Audio Visualizer
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

            if let onReplayAudio = onReplayAudio {
                CraftSpeakerButton(
                    variant: .subtle,
                    size: .lg,
                    isPlaying: false,
                    label: AppStrings.ReflexBlitz.listeningReplay,
                    action: onReplayAudio
                )
            }

            CraftText(
                AppStrings.ReflexBlitz.listeningInstruction,
                style: .caption,
                color: theme.colors.textMuted,
                textAlignment: .center
            )
        }
        .padding(.vertical, theme.spacing.xs)

        dividerLine

        optionsListView
    }

    // MARK: - Subviews & Areas

    @ViewBuilder
    private var triggerArea: some View {
        VStack(spacing: theme.spacing.xs) {
            if !word.pos.isEmpty {
                CraftBadge(
                    word.pos.uppercased(),
                    variant: .subtle,
                    tone: .primary,
                    size: .sm,
                    shape: .capsule
                )
            }

            CraftText(
                word.definitionVi,
                style: .titleLarge,
                color: theme.colors.textPrimary,
                textAlignment: .center
            )
            .lineLimit(2)
            .accessibilityLabel(AppStrings.ReflexBlitz.definitionA11y(word.definitionVi))
        }
        .padding(.top, theme.spacing.xs / 2)
    }

    @ViewBuilder
    private var sentenceArea: some View {
        sentenceView
            .multilineTextAlignment(.center)
            .lineSpacing(6)
            .padding(.horizontal, theme.spacing.xs)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isResultCorrect)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isResultTimeout)
            .accessibilityLabel(
                isReviewed
                    ? AppStrings.ReflexBlitz.completedSentenceA11y(word.completedSentenceWithTargetWord)
                    : AppStrings.ReflexBlitz.clozeSentenceA11y(word.clozeSentenceEn)
            )
    }

    @ViewBuilder
    private var scaffoldingArea: some View {
        if isReviewed && !word.ipa.isEmpty {
            CraftBadge(
                word.ipa,
                iconName: "waveform",
                variant: .subtle,
                tone: isResultCorrect ? .success : .danger,
                size: .md,
                shape: .capsule
            )
            .transition(.scale.combined(with: .opacity))
            .accessibilityLabel(AppStrings.ReflexBlitz.ipaA11y(word.ipa))
        } else if showHint && !isReviewed {
            CraftBadge(
                AppStrings.ReflexBlitz.hintPrefix(word.initialLetterHint),
                iconName: "lightbulb.min.fill",
                variant: .outline,
                tone: .warning,
                size: .sm,
                shape: .capsule
            )
            .transition(.scale.combined(with: .opacity))
            .accessibilityLabel(AppStrings.ReflexBlitz.hintA11y(word.initialLetterHint))
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
            .foregroundColor(slotTextColor)
        let suffixText = Text(parts.suffix)
            .font(theme.typography.bodySerif)
            .foregroundColor(theme.colors.textPrimary)
        return prefixText + slotText + suffixText
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

    private var slotTextColor: Color {
        if isReviewed {
            return isResultCorrect ? theme.colors.statusSuccess : theme.colors.statusDanger
        } else if showHint {
            return theme.colors.statusWarning
        } else {
            return theme.colors.brandPrimary
        }
    }

    private var dividerLine: some View {
        CraftDivider()
            .padding(.horizontal, theme.spacing.xs)
    }

    @ViewBuilder
    private var optionsListView: some View {
        VStack(spacing: theme.spacing.sm) {
            ForEach(options, id: \.id) { option in
                let choiceState = choiceState(for: option)
                let showIndicator = showsStatusIndicator(for: option)

                CraftChoiceCard(
                    prefix: nil,
                    prefixStyle: .none,
                    title: option.text,
                    textAlignment: .leading,
                    state: choiceState,
                    style: .tactile3D,
                    showsStatusIndicator: showIndicator,
                    action: {
                        guard !isReviewed else { return }
                        onSelectOption?(option)
                    }
                )
                .frame(minHeight: 52)
                .accessibilityLabel(option.text)
            }
        }
    }

    @ViewBuilder
    private var typingInputDockView: some View {
        HStack(spacing: theme.spacing.sm) {
            CraftTextField(
                placeholder: AppStrings.ReflexBlitz.typingPlaceholderText,
                text: $keyboardInputText,
                leadingIcon: "keyboard",
                style: .standard
            )
            .focused($isTextFieldFocused)
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .onSubmit {
                onSubmitKeyboard?()
            }
            .accessibilityLabel(AppStrings.ReflexBlitz.typingInputA11y)

            CraftIconButton(
                iconName: "arrow.up.circle.fill",
                size: .lg,
                shape: .circle,
                variant: keyboardInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .subtle : .filled,
                accessibilityLabel: AppStrings.ReflexBlitz.typingSubmitA11y,
                action: {
                    onSubmitKeyboard?()
                }
            )
            .disabled(keyboardInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, theme.spacing.xxs)
        .onAppear {
            if !isReviewed {
                isTextFieldFocused = true
            }
        }
    }

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
                activeColor: timerStrokeColor
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

private extension CraftSpacingTokens {
    var xxs: CGFloat { xs / 2 }
}
