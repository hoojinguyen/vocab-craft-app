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
        let dy = to.y - from.y
        let control1 = CGPoint(x: from.x, y: from.y + dy * 0.5)
        let control2 = CGPoint(x: to.x, y: to.y - dy * 0.5)
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

    private var connectorGradient: LinearGradient {
        LinearGradient(
            colors: [
                color ?? theme.colors.statusSuccess,
                color ?? theme.colors.brandPrimary
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    public var body: some View {
        Group {
            if reduceMotion {
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        connectorGradient,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
            } else {
                PhaseAnimator(BreathingPhase.allCases) { phase in
                    CraftNodeConnector(from: from, to: to)
                        .stroke(
                            connectorGradient,
                            style: StrokeStyle(
                                lineWidth: phase == .inhale ? 4.0 : 3.0,
                                lineCap: .round
                            )
                        )
                        .opacity(phase == .inhale ? 0.95 : 0.6)
                } animation: { _ in
                    .craftBreathing
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - CraftSmartConnector

/// Renders a dynamic learning path connector matching the state relationship between two nodes.
public struct CraftSmartConnector: View, Equatable {
    public let from: CGPoint
    public let to: CGPoint
    public let style: SmartConnectorStyle
    public var customColor: Color?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.craftTheme) private var theme

    public init(
        from: CGPoint,
        to: CGPoint,
        style: SmartConnectorStyle,
        customColor: Color? = nil
    ) {
        self.from = from
        self.to = to
        self.style = style
        self.customColor = customColor
    }

    public static func == (lhs: CraftSmartConnector, rhs: CraftSmartConnector) -> Bool {
        lhs.from == rhs.from &&
        lhs.to == rhs.to &&
        lhs.style == rhs.style &&
        lhs.customColor == rhs.customColor
    }

    public var body: some View {
        Group {
            switch style {
            case .solid:
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        customColor ?? theme.colors.statusSuccess,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
            case .breathing:
                BreathingConnectorView(
                    from: from,
                    to: to,
                    color: customColor ?? theme.colors.brandPrimary
                )
            case .dashed:
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        customColor ?? theme.colors.brandPrimary.opacity(0.6),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [6, 6])
                    )
            case .muted:
                CraftNodeConnector(from: from, to: to)
                    .stroke(
                        customColor ?? theme.colors.borderDefault,
                        style: StrokeStyle(lineWidth: 2.0, lineCap: .round, dash: [4, 4])
                    )
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
