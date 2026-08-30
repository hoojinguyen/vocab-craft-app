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
                    TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
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

// MARK: - CraftSnakeDottedSegmentView

/// Renders a single vector dotted snake path segment with round caps and progressive theme coloring.
public struct CraftSnakeDottedSegmentView: View, Equatable {
    public let segment: SnakePathSegmentGeometry
    public let fromState: LessonNodeState
    public let toState: LessonNodeState
    public var dotDiameter: CGFloat?
    public var dotSpacing: CGFloat?
    public var customColor: Color?

    @Environment(\.craftTheme) private var theme

    public init(
        segment: SnakePathSegmentGeometry,
        fromState: LessonNodeState,
        toState: LessonNodeState,
        dotDiameter: CGFloat? = nil,
        dotSpacing: CGFloat? = nil,
        customColor: Color? = nil
    ) {
        self.segment = segment
        self.fromState = fromState
        self.toState = toState
        self.dotDiameter = dotDiameter
        self.dotSpacing = dotSpacing
        self.customColor = customColor
    }

    public static func == (lhs: CraftSnakeDottedSegmentView, rhs: CraftSnakeDottedSegmentView) -> Bool {
        lhs.segment == rhs.segment &&
        lhs.fromState == rhs.fromState &&
        lhs.toState == rhs.toState &&
        lhs.dotDiameter == rhs.dotDiameter &&
        lhs.dotSpacing == rhs.dotSpacing &&
        lhs.customColor == rhs.customColor
    }

    private var segmentColor: Color {
        if let customColor {
            return customColor
        }
        if fromState == .completed && toState == .completed {
            return theme.colors.pathCompleted
        } else if fromState == .completed && (toState == .active || toState == .inProgress) {
            return theme.colors.pathActive
        } else if toState == .locked || fromState == .locked {
            // Muted but still visible on ivory canvas — avoid invisible beige
            return theme.colors.textMuted.opacity(0.35)
        } else if fromState == .active || fromState == .inProgress || fromState == .upcoming {
            return theme.colors.textMuted.opacity(0.55)
        } else {
            return theme.colors.textMuted.opacity(0.30)
        }
    }

    private func strokeStyle(diameter: CGFloat, spacing: CGFloat) -> StrokeStyle {
        StrokeStyle(
            lineWidth: diameter,
            lineCap: .round,
            lineJoin: .round,
            dash: [0, diameter + spacing]
        )
    }

    public var body: some View {
        let diameter = dotDiameter ?? theme.spacing.pathDotDiameter
        let spacing = dotSpacing ?? theme.spacing.pathDotSpacing
        segment.buildPath()
            .stroke(
                segmentColor,
                style: strokeStyle(diameter: diameter, spacing: spacing)
            )
            .accessibilityHidden(true)
    }
}

// MARK: - CraftSnakeConnectorLayer

/// Container layer rendering progressive colored vector dotted snake connectors between anchored nodes.
/// Uses single Canvas draw call instead of N Path views to reduce SwiftUI view count and layout thrash.
public struct CraftSnakeConnectorLayer: View {
    public let nodes: [LessonNodeModel]
    public let preferences: NodeAnchorPreferenceKey.Value
    public let geometry: GeometryProxy
    public var turnRadius: CGFloat?
    public var edgeInset: CGFloat?
    public var dotDiameter: CGFloat?
    public var dotSpacing: CGFloat?

    @Environment(\.craftTheme) private var theme

    public init(
        nodes: [LessonNodeModel],
        preferences: NodeAnchorPreferenceKey.Value,
        geometry: GeometryProxy,
        turnRadius: CGFloat? = nil,
        edgeInset: CGFloat? = nil,
        dotDiameter: CGFloat? = nil,
        dotSpacing: CGFloat? = nil
    ) {
        self.nodes = nodes
        self.preferences = preferences
        self.geometry = geometry
        self.turnRadius = turnRadius
        self.edgeInset = edgeInset
        self.dotDiameter = dotDiameter
        self.dotSpacing = dotSpacing
    }

    private func segmentColor(from: LessonNodeState, to: LessonNodeState) -> Color {
        if from == .completed && to == .completed {
            return theme.colors.pathCompleted
        } else if from == .completed && (to == .active || to == .inProgress) {
            return theme.colors.pathActive
        } else if to == .locked || from == .locked {
            return theme.colors.textMuted.opacity(0.35)
        } else if from == .active || from == .inProgress || from == .upcoming {
            return theme.colors.textMuted.opacity(0.55)
        } else {
            return theme.colors.textMuted.opacity(0.30)
        }
    }

    public var body: some View {
        let diameter = dotDiameter ?? theme.spacing.pathDotDiameter
        let spacing = dotSpacing ?? theme.spacing.pathDotSpacing
        let radius = turnRadius ?? theme.spacing.pathTurnRadius
        let inset = edgeInset ?? theme.spacing.pathEdgeInset
        let strokeStyle = StrokeStyle(
            lineWidth: diameter,
            lineCap: .round,
            lineJoin: .round,
            dash: [0, diameter + spacing]
        )

        Canvas { context, _ in
            guard nodes.count > 1 else { return }
            for index in 0..<(nodes.count - 1) {
                let fromNode = nodes[index]
                let toNode = nodes[index + 1]
                guard let fromAnchor = preferences[fromNode.id],
                      let toAnchor = preferences[toNode.id] else { continue }
                let fromPoint = geometry[fromAnchor]
                let toPoint = geometry[toAnchor]
                let segment = SnakePathGeometry.createSegment(
                    from: fromPoint,
                    to: toPoint,
                    containerWidth: geometry.size.width,
                    turnRadius: radius,
                    edgeInset: inset
                )
                let color = segmentColor(from: fromNode.state, to: toNode.state)
                let path = segment.buildPath()
                context.stroke(path, with: .color(color), style: strokeStyle)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
