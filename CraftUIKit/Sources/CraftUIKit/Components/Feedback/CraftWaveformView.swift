import SwiftUI

// MARK: - CraftWaveformView

/// An audio visualizer component displaying animated frequency bars with normalization,
/// dynamic spacing, smooth spring height transitions, and breathing pulse glow during recording.
public struct CraftWaveformView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let audioLevels: [CGFloat]
    public let barCount: Int
    public let spacing: CGFloat
    public let minHeight: CGFloat
    public let maxHeight: CGFloat
    public let barWidth: CGFloat
    public let isRecording: Bool
    public let activeColor: Color?
    public let inactiveColor: Color?

    @State private var pulseGlow: Bool = false

    public init(
        audioLevels: [CGFloat] = [],
        barCount: Int = 16,
        spacing: CGFloat = 4,
        minHeight: CGFloat = 4,
        maxHeight: CGFloat = 40,
        barWidth: CGFloat = 4,
        isRecording: Bool = false,
        activeColor: Color? = nil,
        inactiveColor: Color? = nil
    ) {
        self.audioLevels = audioLevels
        self.barCount = max(1, barCount)
        self.spacing = spacing
        self.minHeight = max(1, minHeight)
        self.maxHeight = max(minHeight, maxHeight)
        self.barWidth = barWidth
        self.isRecording = isRecording
        self.activeColor = activeColor
        self.inactiveColor = inactiveColor
    }

    /// Normalized audio levels clamped to [0.0, 1.0] and padded/truncated to `barCount`.
    public var normalizedLevels: [CGFloat] {
        var levels = audioLevels.map { min(max($0, 0.0), 1.0) }
        if levels.count < barCount {
            levels.append(contentsOf: Array(repeating: 0.0, count: barCount - levels.count))
        } else if levels.count > barCount {
            levels = Array(levels.prefix(barCount))
        }
        return levels
    }

    /// Computes the visual height for a given normalized level.
    public func barHeight(for level: CGFloat) -> CGFloat {
        let clamped = min(max(level, 0.0), 1.0)
        return minHeight + (maxHeight - minHeight) * clamped
    }

    private var averageLevelPercentage: Int {
        let sum: CGFloat = normalizedLevels.reduce(CGFloat(0), +)
        let count = CGFloat(max(1, barCount))
        return Int((sum / count) * 100)
    }

    public var body: some View {
        let currentLevels = normalizedLevels
        let resolvedActiveColor = activeColor ?? (isRecording ? theme.colors.statusDanger : theme.colors.brandPrimary)
        let resolvedInactiveColor = inactiveColor ?? theme.colors.borderDefault

        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                let level = currentLevels[index]
                let height = barHeight(for: level)
                let isActiveBar = isRecording || level > 0.0

                Capsule()
                    .fill(isActiveBar ? resolvedActiveColor : resolvedInactiveColor)
                    .frame(width: barWidth, height: height)
                    .animation(reduceMotion ? .none : theme.animations.springSnappy, value: height)
            }
        }
        .frame(height: maxHeight)
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xs / 2)
        .background(
            Capsule()
                .fill(isRecording ? resolvedActiveColor.opacity(pulseGlow ? 0.15 : 0.05) : Color.clear)
                .blur(radius: isRecording ? (pulseGlow ? 8 : 4) : 0)
        )
        .onAppear {
            if isRecording && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            } else {
                pulseGlow = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isRecording ? "Audio waveform recording active" : "Audio waveform visualizer")
        .accessibilityValue("\(averageLevelPercentage) percent average audio level")
    }
}

// MARK: - Previews

#Preview("Waveform - Idle") {
    CraftWaveformView(
        audioLevels: [0.1, 0.2, 0.4, 0.7, 0.9, 0.6, 0.3, 0.1],
        barCount: 16
    )
    .padding()
}

#Preview("Waveform - Recording") {
    CraftWaveformView(
        audioLevels: [0.2, 0.5, 0.8, 1.0, 0.7, 0.4, 0.6, 0.9, 0.3],
        barCount: 16,
        isRecording: true
    )
    .padding()
}
