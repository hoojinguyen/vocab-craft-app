import SwiftUI

// MARK: - CraftVoiceMatchCard

/// A master container view for voice evaluation and pronunciation matching tasks.
/// Assembles instruction/subtitles, score pill badge, word flow layout with token status chips,
/// live waveform visualizer, real-time transcript feedback, and a tactile mic hub.
public struct CraftVoiceMatchCard: View {
    @Environment(\.craftTheme) private var theme

    public let originText: String
    public let actualText: String?
    public let explicitTokens: [CraftSpeechWordToken]?
    public let subtitle: String?
    public let speechState: CraftSpeechState
    public let customInstruction: String?
    public let onTapMic: () -> Void
    public let onReset: (() -> Void)?

    public init(
        originText: String,
        actualText: String? = nil,
        explicitTokens: [CraftSpeechWordToken]? = nil,
        subtitle: String? = nil,
        speechState: CraftSpeechState = .idle,
        customInstruction: String? = nil,
        onTapMic: @escaping () -> Void,
        onReset: (() -> Void)? = nil
    ) {
        self.originText = originText
        self.actualText = actualText
        self.explicitTokens = explicitTokens
        self.subtitle = subtitle
        self.speechState = speechState
        self.customInstruction = customInstruction
        self.onTapMic = onTapMic
        self.onReset = onReset
    }

    private var activeTokens: [CraftSpeechWordToken] {
        if let explicitTokens {
            return explicitTokens
        }
        let isFinal: Bool
        if case .evaluated = speechState {
            isFinal = true
        } else {
            isFinal = false
        }
        return CraftTextMatchEngine.match(originText: originText, actualText: actualText, isFinal: isFinal)
    }

    private var isListening: Bool {
        if case .listening = speechState { return true }
        return false
    }

    private var audioLevels: [CGFloat] {
        if case let .listening(levels) = speechState { return levels }
        return []
    }

    public var body: some View {
        VStack(spacing: theme.spacing.md) {
            // Header / Instruction & Score
            if customInstruction != nil || isEvaluated {
                HStack(alignment: .center) {
                    if let customInstruction {
                        Text(customInstruction)
                            .font(theme.typography.label)
                            .foregroundColor(theme.colors.textSecondary)
                    }

                    Spacer()

                    if case let .evaluated(score) = speechState {
                        HStack(spacing: theme.spacing.xs) {
                            Image(systemName: "bolt.fill")
                                .font(.caption2)
                            Text(CraftLocalized.format("craft.speech.score_format", Int(score)))
                                .font(theme.typography.label)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, theme.spacing.sm)
                        .padding(.vertical, theme.spacing.xs / 2)
                        .background(score >= 80 ? theme.colors.statusSuccess.opacity(0.12) : theme.colors.statusWarning.opacity(0.12))
                        .foregroundColor(score >= 80 ? theme.colors.statusSuccess : theme.colors.statusWarning)
                        .clipShape(Capsule())
                    }
                }
            }

            // Word Tokens Flow & Centered Subtitle
            VStack(spacing: theme.spacing.sm) {
                CraftSpeechWordFlowLayout(spacing: theme.spacing.xs, lineSpacing: theme.spacing.xs, alignment: .center) {
                    ForEach(activeTokens) { token in
                        CraftSpeechWordTokenView(token: token)
                    }
                }
                .frame(maxWidth: .infinity)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(theme.typography.bodyMedium)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, theme.spacing.sm)
                }
            }
            .padding(.vertical, theme.spacing.xs)

            // Waveform & Transcript feedback
            if isListening {
                VStack(spacing: theme.spacing.xs) {
                    CraftWaveformView(
                        audioLevels: audioLevels,
                        barCount: 16,
                        isRecording: true,
                        activeColor: theme.colors.brandPrimary
                    )

                    if let actualText, !actualText.isEmpty {
                        Text(actualText)
                            .font(theme.typography.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(theme.colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, theme.spacing.xs)
                .transition(.scale.combined(with: .opacity))
            }

            // Tactile Mic Hub
            CraftTactileMicHubView(
                speechState: speechState,
                onTapMic: onTapMic
            )
        }
        .padding(theme.spacing.lg)
        .background(theme.colors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.xl, style: .continuous)
                .stroke(isListening ? theme.colors.brandPrimary.opacity(0.4) : theme.colors.borderDefault, lineWidth: 1.5)
        )
        .shadow(
            color: Color.black.opacity(0.04),
            radius: 12,
            x: 0,
            y: 4
        )
        .animation(theme.animations.springSnappy, value: speechState)
    }

    private var isEvaluated: Bool {
        if case .evaluated = speechState { return true }
        return false
    }
}

// MARK: - Previews

#Preview("CraftVoiceMatchCard - Idle") {
    CraftVoiceMatchCard(
        originText: "It was a good job.",
        subtitle: "Đó là một công việc tốt.",
        speechState: .idle,
        onTapMic: {}
    )
    .padding()
}

#Preview("CraftVoiceMatchCard - Listening") {
    CraftVoiceMatchCard(
        originText: "It was a good job.",
        actualText: "It was",
        subtitle: "Đó là một công việc tốt.",
        speechState: .listening(audioLevels: [0.2, 0.5, 0.8, 0.4]),
        onTapMic: {}
    )
    .padding()
}

#Preview("CraftVoiceMatchCard - Evaluated") {
    CraftVoiceMatchCard(
        originText: "It was a good job.",
        actualText: "It was a good job",
        subtitle: "Đó là một công việc tốt.",
        speechState: .evaluated(overallScore: 95),
        onTapMic: {}
    )
    .padding()
}
