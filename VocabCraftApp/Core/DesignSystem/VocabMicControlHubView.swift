import SwiftUI

/// Shared microphone control hub component providing tap-to-toggle voice recording
/// with dynamic pulsing ring animation, sensory feedback, and clear UX instructions.
public struct VocabMicControlHubView: View {
    public let isListening: Bool
    public let idleSubtitleText: String
    public let listeningSubtitleText: String
    public let onTapMic: () -> Void

    @State private var isMicPulsing = false

    public init(
        isListening: Bool,
        idleSubtitleText: String = "Chạm vào Micro để bắt đầu nói",
        listeningSubtitleText: String = "Chạm để hoàn thành bài nói",
        onTapMic: @escaping () -> Void
    ) {
        self.isListening = isListening
        self.idleSubtitleText = idleSubtitleText
        self.listeningSubtitleText = listeningSubtitleText
        self.onTapMic = onTapMic
    }

    public var body: some View {
        VStack(spacing: 12) {
            Button(action: onTapMic) {
                ZStack {
                    if isListening {
                        Circle()
                            .stroke(Color.vocabCoral.opacity(0.35), lineWidth: 4)
                            .frame(width: 108, height: 108)
                            .scaleEffect(isMicPulsing ? 1.2 : 1.0)
                            .opacity(isMicPulsing ? 0.2 : 0.8)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                    isMicPulsing = true
                                }
                            }
                            .onDisappear {
                                isMicPulsing = false
                            }
                    }

                    Circle()
                        .fill(
                            isListening
                            ? LinearGradient(
                                colors: [Color.vocabCoral, Color.vocabCoral.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            : LinearGradient(
                                colors: [Color.vocabHeroAccent, Color.vocabHeroAccent.opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 84, height: 84)
                        .shadow(
                            color: isListening ? Color.vocabCoral.opacity(0.4) : Color.vocabHeroAccent.opacity(0.35),
                            radius: 14,
                            x: 0,
                            y: 6
                        )

                    Image(systemName: isListening ? "waveform.and.mic" : "mic.fill")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: isListening)
                }
                .frame(width: 112, height: 112)
                .contentShape(Circle())
            }
            .buttonStyle(VocabBentoCardButtonStyle())
            .accessibilityLabel(isListening ? "Dừng ghi âm và chấm điểm" : "Bắt đầu nói đáp án tiếng Anh")

            Text(isListening ? listeningSubtitleText : idleSubtitleText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isListening ? .vocabCoral : .vocabMuted)
        }
        .padding(.vertical, 6)
        .sensoryFeedback(.impact(weight: .medium), trigger: isListening)
    }
}

private struct VocabBentoCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
