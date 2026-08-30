import SwiftUI

// MARK: - CraftSpinner Component

/// A smooth activity spinner indicator styled with brand theme colors, standardized sizing,
/// customizable stroke width, and accessibility reduce motion support.
public struct CraftSpinner: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let size: CraftIconSize
    public let color: Color?
    public let lineWidth: CGFloat

    public init(
        size: CraftIconSize = .md,
        color: Color? = nil,
        lineWidth: CGFloat? = nil
    ) {
        self.size = size
        self.color = color
        if let lineWidth {
            self.lineWidth = lineWidth
        } else {
            switch size {
            case .sm: self.lineWidth = 2.0
            case .md: self.lineWidth = 2.5
            case .lg: self.lineWidth = 3.0
            case .xl: self.lineWidth = 4.0
            }
        }
    }

    public var body: some View {
        Group {
            if reduceMotion {
                spinnerCircle
            } else {
                TimelineView(.animation) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    let angle = (time.truncatingRemainder(dividingBy: 0.8) / 0.8) * 360.0

                    spinnerCircle
                        .rotationEffect(.degrees(angle))
                }
            }
        }
        .accessibilityRepresentation {
            ProgressView()
        }
    }

    private var spinnerCircle: some View {
        Circle()
            .trim(from: 0.15, to: 0.85)
            .stroke(
                color ?? theme.colors.brandPrimary,
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .frame(width: size.pointSize, height: size.pointSize)
    }
}

#if canImport(PreviewsMacros)
#Preview("CraftSpinner") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            CraftSpinner(size: .sm)
            CraftSpinner(size: .md)
            CraftSpinner(size: .lg)
            CraftSpinner(size: .xl)
        }
        HStack(spacing: 16) {
            CraftSpinner(size: .md, color: .orange, lineWidth: 4)
            CraftSpinner(size: .lg, color: .purple, lineWidth: 1.5)
        }
    }
    .padding()
}
#endif

