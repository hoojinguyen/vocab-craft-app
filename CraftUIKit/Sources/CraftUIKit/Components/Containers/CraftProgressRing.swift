import SwiftUI

// MARK: - CraftProgressRing Component

/// A circular completion ring with stroke animations and customizable center label content.
public struct CraftProgressRing<CenterContent: View>: View {
    @Environment(\.craftTheme) private var theme

    public let progress: Double
    public let lineWidth: CGFloat
    public let size: CGFloat
    public let tintColor: Color?
    public let trackColor: Color?
    public let animated: Bool
    public let accessibilityLabel: String
    public let centerContent: CenterContent

    /// Clamped progress value guaranteed to be in the [0.0, 1.0] range.
    public var clampedProgress: Double {
        min(max(progress, 0.0), 1.0)
    }

    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 80,
        tintColor: Color? = nil,
        trackColor: Color? = nil,
        animated: Bool = true,
        accessibilityLabel: String = "Progress",
        @ViewBuilder centerContent: () -> CenterContent
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.tintColor = tintColor
        self.trackColor = trackColor
        self.animated = animated
        self.accessibilityLabel = accessibilityLabel
        self.centerContent = centerContent()
    }

    public var body: some View {
        let fill = tintColor ?? theme.colors.brandPrimary
        let track = trackColor ?? theme.colors.surfaceSubtle

        ZStack {
            // Background track circle
            Circle()
                .stroke(track, lineWidth: lineWidth)

            // Progress stroke circle
            Circle()
                .trim(from: 0.0, to: CGFloat(clampedProgress))
                .stroke(
                    fill,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(animated ? theme.animations.springSmooth : nil, value: clampedProgress)

            // Center slot content
            centerContent
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
    }
}

// MARK: - Convenience Inits

public extension CraftProgressRing where CenterContent == Text {
    /// Convenience initializer showing percentage text in the center.
    init(
        progress: Double,
        lineWidth: CGFloat = 8,
        size: CGFloat = 80,
        tintColor: Color? = nil,
        trackColor: Color? = nil,
        animated: Bool = true,
        accessibilityLabel: String = "Progress"
    ) {
        let percentage = Int((min(max(progress, 0.0), 1.0) * 100).rounded())
        self.init(
            progress: progress,
            lineWidth: lineWidth,
            size: size,
            tintColor: tintColor,
            trackColor: trackColor,
            animated: animated,
            accessibilityLabel: accessibilityLabel
        ) {
            Text("\(percentage)%")
                .font(.system(size: max(size * 0.22, 12), weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
    }
}

#Preview("CraftProgressRing") {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            CraftProgressRing(progress: 0.25)
            CraftProgressRing(progress: 0.50)
            CraftProgressRing(progress: 0.75)
        }
    }
    .padding()
}

