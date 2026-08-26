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

    private func averageLevelPercentage(for levels: [CGFloat]) -> Int {
        let sum: CGFloat = levels.reduce(CGFloat(0), +)
        let count = CGFloat(max(1, barCount))
        return Int((sum / count) * 100)
    }

    public var body: some View {
        let resolvedActiveColor = activeColor ?? theme.colors.brandPrimary
        let resolvedInactiveColor = inactiveColor ?? theme.colors.borderDefault

        Group {
            if isRecording && !reduceMotion {
                TimelineView(.animation) { timeline in
                    renderBars(
                        time: timeline.date.timeIntervalSinceReferenceDate,
                        activeColor: resolvedActiveColor,
                        inactiveColor: resolvedInactiveColor
                    )
                }
            } else {
                renderStaticBars(
                    levels: normalizedLevels,
                    activeColor: resolvedActiveColor,
                    inactiveColor: resolvedInactiveColor
                )
            }
        }
        .frame(height: maxHeight)
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.xs / 2)
        .background(
            Capsule()
                .fill(isRecording ? resolvedActiveColor.opacity(pulseGlow ? 0.18 : 0.06) : Color.clear)
                .blur(radius: isRecording ? (pulseGlow ? 8 : 4) : 0)
        )
        .onAppear {
            if isRecording && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseGlow = true
                }
            }
        }
        .onDisappear {
            pulseGlow = false
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
        .accessibilityLabel(isRecording ? CraftLocalized.string("craft.waveform.recording_active_a11y") : CraftLocalized.string("craft.waveform.visualizer_a11y"))
        .accessibilityValue(CraftLocalized.format("craft.waveform.audio_level_format", averageLevelPercentage(for: normalizedLevels)))
    }

    private func dynamicLevel(for index: Int, time: TimeInterval, baseLevels: [CGFloat]) -> CGFloat {
        let normalizedPos = Double(index) / Double(max(1, barCount - 1))
        let centerBell = sin(normalizedPos * .pi)

        let wave1 = sin(time * 7.0 + Double(index) * 0.6)
        let wave2 = cos(time * 11.0 - Double(index) * 0.9)
        let oscillation = (wave1 * 0.6 + wave2 * 0.4 + 1.0) / 2.0

        let inputLevel = index < baseLevels.count ? baseLevels[index] : 0
        if inputLevel > 0.05 {
            return inputLevel * CGFloat(0.45 + 0.55 * oscillation)
        } else {
            return CGFloat(centerBell * (0.25 + 0.75 * oscillation))
        }
    }

    @ViewBuilder
    private func renderBars(time: TimeInterval, activeColor: Color, inactiveColor: Color) -> some View {
        let baseLevels = normalizedLevels
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { (index: Int) in
                let level = dynamicLevel(for: index, time: time, baseLevels: baseLevels)
                let height = barHeight(for: level)

                Capsule()
                    .fill(activeColor)
                    .frame(width: barWidth, height: height)
            }
        }
    }

    @ViewBuilder
    private func renderStaticBars(levels: [CGFloat], activeColor: Color, inactiveColor: Color) -> some View {
        HStack(alignment: .center, spacing: spacing) {
            ForEach(0..<barCount, id: \.self) { index in
                let level = levels[index]
                let height = barHeight(for: level)
                let isActiveBar = isRecording || level > 0.0

                Capsule()
                    .fill(isActiveBar ? activeColor : inactiveColor)
                    .frame(width: barWidth, height: height)
                    .animation(reduceMotion ? .none : theme.animations.springSnappy, value: height)
            }
        }
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
