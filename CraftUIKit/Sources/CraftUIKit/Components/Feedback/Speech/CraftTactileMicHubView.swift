import SwiftUI

// MARK: - CraftTactileMicHubView

/// A circular tactile microphone control hub view featuring gradient styling, pulsing animations during active listening,
/// processing indicators, and dynamic localized status subtitles.
public struct CraftTactileMicHubView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let speechState: CraftSpeechState
    public let onTapMic: () -> Void

    @State private var isPulsing: Bool = false

    public init(speechState: CraftSpeechState, onTapMic: @escaping () -> Void) {
        self.speechState = speechState
        self.onTapMic = onTapMic
    }

    private var isListening: Bool {
        if case .listening = speechState { return true }
        return false
    }

    private var isProcessing: Bool {
        if case .processing = speechState { return true }
        return false
    }

    public var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Button(action: onTapMic) {
                ZStack {
                    if isListening && !reduceMotion {
                        Circle()
                            .stroke(theme.colors.brandPrimary.opacity(0.35), lineWidth: 4)
                            .frame(width: 104, height: 104)
                            .scaleEffect(isPulsing ? 1.25 : 1.0)
                            .opacity(isPulsing ? 0.15 : 0.8)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                    isPulsing = true
                                }
                            }
                            .onDisappear {
                                isPulsing = false
                            }
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isListening
                                    ? [theme.colors.brandPrimary, theme.colors.brandSecondary]
                                    : [theme.colors.brandPrimary, theme.colors.brandPrimary.opacity(0.88)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(
                            color: isListening ? theme.colors.brandPrimary.opacity(0.45) : theme.colors.brandPrimary.opacity(0.25),
                            radius: isListening ? 16 : 8,
                            x: 0,
                            y: isListening ? 6 : 4
                        )

                    if isProcessing {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.2)
                    } else {
                        Image(systemName: isListening ? "waveform.and.mic" : "mic.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white)
                            .symbolEffect(.bounce, value: isListening)
                    }
                }
                .frame(width: 108, height: 108)
                .contentShape(Circle())
            }
            .buttonStyle(CraftTactileButtonStyle())
            .disabled(isProcessing)
            .accessibilityLabel(isListening ? CraftLocalized.string("craft.speech.mic_stop_a11y") : CraftLocalized.string("craft.speech.mic_start_a11y"))

            Text(statusSubtitle)
                .font(theme.typography.label)
                .fontWeight(.medium)
                .foregroundColor(isListening ? theme.colors.brandPrimary : theme.colors.textSecondary)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: isListening)
    }

    private var statusSubtitle: String {
        switch speechState {
        case .idle:
            return CraftLocalized.string("craft.speech.tap_to_speak")
        case .listening:
            return CraftLocalized.string("craft.speech.listening")
        case .processing:
            return CraftLocalized.string("craft.speech.analyzing")
        case .evaluated:
            return CraftLocalized.string("craft.speech.try_again")
        }
    }
}

// MARK: - ButtonStyle

private struct CraftTactileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Tactile Mic States") {
    VStack(spacing: 32) {
        CraftTactileMicHubView(speechState: .idle, onTapMic: {})
        CraftTactileMicHubView(speechState: .listening(audioLevels: [0.3, 0.6]), onTapMic: {})
        CraftTactileMicHubView(speechState: .processing, onTapMic: {})
        CraftTactileMicHubView(speechState: .evaluated(overallScore: 85), onTapMic: {})
    }
    .padding()
}
