import SwiftUI

// MARK: - CraftNodeConnector Shape

/// A custom Bézier S-curve connecting two points in a learning path.
public struct CraftNodeConnector: Shape {
    public var from: CGPoint
    public var to: CGPoint

    public init(from: CGPoint, to: CGPoint) {
        self.from = from
        self.to = to
    }

    public var animatableData: AnimatablePair<CGPoint.AnimatableData, CGPoint.AnimatableData> {
        get {
            AnimatablePair(from.animatableData, to.animatableData)
        }
        set {
            from.animatableData = newValue.first
            to.animatableData = newValue.second
        }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        let midY = (from.y + to.y) / 2
        let control1 = CGPoint(x: from.x, y: midY)
        let control2 = CGPoint(x: to.x, y: midY)
        path.addCurve(to: to, control1: control1, control2: control2)
        return path
    }
}

// MARK: - BreathingConnectorView

/// Connector view displaying the signature "Breathing Path" pulse between the active node and the next lesson.
public struct BreathingConnectorView: View {
    public let from: CGPoint
    public let to: CGPoint
    public var color: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.craftTheme) private var theme

    public init(from: CGPoint, to: CGPoint, color: Color? = nil) {
        self.from = from
        self.to = to
        self.color = color
    }

    public var body: some View {
        let strokeColor = color ?? theme.colors.brandPrimary

        Group {
            if reduceMotion {
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        strokeColor.opacity(0.4),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
            } else {
                PhaseAnimator(BreathingPhase.allCases) { phase in
                    CraftNodeConnector(from: from, to: to)
                        .stroke(
                            strokeColor.opacity(phase == .inhale ? 0.6 : 0.35),
                            style: StrokeStyle(
                                lineWidth: phase == .inhale ? 3.0 : 2.0,
                                lineCap: .round
                            )
                        )
                } animation: { _ in
                    .craftBreathing
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - CraftStyledConnector

/// Renders a Bézier curve connector supporting dashed, solid, gradient, and animated styles.
public struct CraftStyledConnector: View {
    public let from: CGPoint
    public let to: CGPoint
    public let style: ConnectorStyle
    public var color: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.craftTheme) private var theme

    public init(
        from: CGPoint,
        to: CGPoint,
        style: ConnectorStyle = .dashed,
        color: Color? = nil
    ) {
        self.from = from
        self.to = to
        self.style = style
        self.color = color
    }

    private var effectiveColor: Color {
        if let color {
            return color
        }
        switch style {
        case .dashed, .solid:
            return theme.colors.borderDefault
        case .gradient:
            return theme.colors.borderDefault
        case .animated:
            return theme.colors.brandPrimary
        }
    }

    public var body: some View {
        Group {
            switch style {
            case .dashed:
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        effectiveColor,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
                    )

            case .solid:
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        effectiveColor,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )

            case .gradient(let startColor, let endColor):
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        LinearGradient(
                            colors: [startColor, endColor],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )

            case .animated:
                if reduceMotion {
                    CraftNodeConnector(from: from, to: to)
                        .stroke(
                            effectiveColor,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [4, 4])
                        )
                } else {
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let phase = CGFloat(time.truncatingRemainder(dividingBy: 2.0) * 12)
                        CraftNodeConnector(from: from, to: to)
                            .stroke(
                                effectiveColor,
                                style: StrokeStyle(
                                    lineWidth: 2.5,
                                    lineCap: .round,
                                    dash: [6, 6],
                                    dashPhase: phase
                                )
                            )
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}
