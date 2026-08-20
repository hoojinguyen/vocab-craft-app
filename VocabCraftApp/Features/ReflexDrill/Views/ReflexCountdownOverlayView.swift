import SwiftUI

/// Apple Fitness+ style full-screen countdown overlay before starting a Reflex Blitz drill.
public struct ReflexCountdownOverlayView: View {
    public let count: Int
    public let mode: ReflexBlitzMode

    public init(count: Int, mode: ReflexBlitzMode = .speaking) {
        self.count = count
        self.mode = mode
    }

    private var modePromptText: String {
        switch mode {
        case .speaking:
            return "Chuẩn bị phát âm to & rõ ràng"
        case .typing:
            return "Đặt tay lên phím & sẵn sàng gõ nhanh"
        case .multipleChoice:
            return "Quan sát nhanh & chọn đáp án đúng"
        case .listening:
            return "Tập trung lắng nghe phát âm"
        }
    }

    private var modeIconName: String {
        switch mode {
        case .speaking:
            return "waveform.and.mic"
        case .typing:
            return "keyboard"
        case .multipleChoice:
            return "sparkles.rectangle.stack"
        case .listening:
            return "headphones"
        }
    }

    public var body: some View {
        ZStack {
            // Apple-grade dynamic blur backdrop
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(Color.black.opacity(0.6))
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Modality Icon with hierarchical rendering & pulse
                Image(systemName: modeIconName)
                    .font(.system(size: 38, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.vocabPeach)
                    .symbolEffect(.pulse, options: .repeating, isActive: count > 0)
                    .padding(.bottom, 8)

                // Large Fitness-style Countdown Number
                Text(count > 0 ? "\(count)" : "GO!")
                    .font(.system(size: 88, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: count > 0 ? [Color.vocabPeach, Color.vocabPeach.opacity(0.85)] : [Color.vocabMint, Color.vocabMint.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(count > 0 ? 1.0 : 1.25)
                    .animation(.spring(response: 0.35, dampingFraction: 0.55), value: count)
                    .accessibilityLabel(count > 0 ? "Đếm ngược \(count)" : "Bắt đầu!")

                // Contextual Modality Instruction Text
                Text(modePromptText)
                    .font(.headline.weight(.medium))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .accessibilityElement(children: .combine)
        }
        .sensoryFeedback(.impact(weight: count > 0 ? .medium : .heavy), trigger: count)
    }
}

