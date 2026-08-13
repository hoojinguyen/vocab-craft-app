import SwiftUI

/// Shared speech visualizer component showing animated sound equalizer bars
/// and live recognized speech text display across voice features.
public struct VocabSpeechVisualizerView: View {
    public let isListening: Bool
    public let recognizedText: String
    public let placeholderText: String

    @State private var barHeights: [CGFloat] = [12, 24, 18, 30, 16, 26, 14]

    public init(
        isListening: Bool,
        recognizedText: String,
        placeholderText: String = "Nhấn micro bên dưới và nói đáp án tiếng Anh..."
    ) {
        self.isListening = isListening
        self.recognizedText = recognizedText
        self.placeholderText = placeholderText
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header Label
            HStack {
                Label(
                    isListening ? AppStrings.Reflex.listening : AppStrings.Reflex.spokenAnswer,
                    systemImage: isListening ? "waveform" : "mic.fill"
                )
                .font(.caption2.bold().smallCaps())
                .foregroundColor(isListening ? .vocabCoral : .vocabMuted)

                Spacer()
            }

            // Equalizer Sound Bar Visualizer
            if isListening {
                HStack(spacing: 5) {
                    ForEach(0..<barHeights.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color.vocabCoral, Color.vocabPeach],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 4, height: barHeights[index])
                            .animation(.easeInOut(duration: 0.12), value: barHeights[index])
                    }
                }
                .frame(height: 32)
                .task(id: isListening) {
                    guard isListening else { return }
                    while !Task.isCancelled && isListening {
                        try? await Task.sleep(for: .milliseconds(120))
                        for i in 0..<barHeights.count {
                            barHeights[i] = CGFloat.random(in: 8...30)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Recognized Speech Text Display
            Text(displayText)
                .font(.system(size: 19, weight: recognizedText.isEmpty ? .medium : .semibold, design: .rounded))
                .foregroundColor(recognizedText.isEmpty ? .vocabMuted.opacity(0.6) : .vocabInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color.vocabSurfaceCard

                if isListening {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.vocabCoral.opacity(0.6), Color.vocabPeach.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                }
            }
        )
        .cornerRadius(24)
        .shadow(
            color: isListening ? Color.vocabCoral.opacity(0.12) : Color.black.opacity(0.03),
            radius: isListening ? 12 : 6,
            x: 0,
            y: isListening ? 6 : 3
        )
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isListening)
    }

    private var displayText: String {
        if !recognizedText.isEmpty {
            return recognizedText
        }
        if isListening {
            return "Đang lắng nghe câu nói của bạn..."
        }
        return placeholderText
    }
}
