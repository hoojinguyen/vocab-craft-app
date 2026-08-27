import SwiftUI

// MARK: - CraftPathSurgeShape

/// A custom animatable `Shape` that renders a moving light beam along any arbitrary or Bézier path.
public struct CraftPathSurgeShape: Shape {
    public var progress: CGFloat
    public var trailLength: CGFloat
    private let pathProvider: @Sendable (CGRect) -> Path

    public var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    public init(
        progress: CGFloat,
        trailLength: CGFloat = 0.2,
        pathProvider: @escaping @Sendable (CGRect) -> Path
    ) {
        self.progress = progress
        self.trailLength = trailLength
        self.pathProvider = pathProvider
    }

    public init(
        from: CGPoint,
        to: CGPoint,
        progress: CGFloat,
        trailLength: CGFloat = 0.2
    ) {
        self.progress = progress
        self.trailLength = trailLength
        self.pathProvider = { _ in
            var path = Path()
            path.move(to: from)
            let dy = to.y - from.y
            let control1 = CGPoint(x: from.x, y: from.y + dy * 0.5)
            let control2 = CGPoint(x: to.x, y: to.y - dy * 0.5)
            path.addCurve(to: to, control1: control1, control2: control2)
            return path
        }
    }

    public init(
        segment: SnakePathSegmentGeometry,
        progress: CGFloat,
        trailLength: CGFloat = 0.2
    ) {
        self.progress = progress
        self.trailLength = trailLength
        self.pathProvider = { _ in segment.buildPath() }
    }

    public init(
        path: Path,
        progress: CGFloat,
        trailLength: CGFloat = 0.2
    ) {
        self.progress = progress
        self.trailLength = trailLength
        self.pathProvider = { _ in path }
    }

    public func path(in rect: CGRect) -> Path {
        let basePath = pathProvider(rect)
        let clampedProgress = max(0.0, min(1.0, progress))
        let start = max(0.0, clampedProgress - trailLength)
        let end = clampedProgress
        guard end > 0, start < end else { return Path() }
        return basePath.trimmedPath(from: start, to: end)
    }
}

// MARK: - CraftPathUnlockSurgeView

/// A high-performance celebration effect view that renders an energetic light surge particle along Bézier connectors during node unlocks.
public struct CraftPathUnlockSurgeView: View {
    public let from: CGPoint?
    public let to: CGPoint?
    public let segment: SnakePathSegmentGeometry?
    public let customPath: Path?
    public let isTriggered: Bool
    public let explicitProgress: CGFloat?
    public let trailLength: CGFloat
    public let color: Color?
    public let glowColor: Color?
    public let lineWidth: CGFloat
    public let sparkSize: CGFloat
    public let duration: Double
    public let onComplete: (@Sendable () -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animatedProgress: CGFloat = 0.0
    @State private var isCompleted: Bool = false

    // MARK: - Initializers

    public init(
        from: CGPoint,
        to: CGPoint,
        isTriggered: Bool = true,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        trailLength: CGFloat = 0.25,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) {
        self.from = from
        self.to = to
        self.segment = nil
        self.customPath = nil
        self.isTriggered = isTriggered
        self.explicitProgress = nil
        self.trailLength = trailLength
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = duration
        self.onComplete = onComplete
    }

    public init(
        from: CGPoint,
        to: CGPoint,
        progress: CGFloat,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        trailLength: CGFloat = 0.25
    ) {
        self.from = from
        self.to = to
        self.segment = nil
        self.customPath = nil
        self.isTriggered = true
        self.explicitProgress = progress
        self.trailLength = trailLength
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = 0.65
        self.onComplete = nil
    }

    public init(
        segment: SnakePathSegmentGeometry,
        isTriggered: Bool = true,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        trailLength: CGFloat = 0.25,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) {
        self.from = segment.from
        self.to = segment.to
        self.segment = segment
        self.customPath = nil
        self.isTriggered = isTriggered
        self.explicitProgress = nil
        self.trailLength = trailLength
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = duration
        self.onComplete = onComplete
    }

    public init(
        segment: SnakePathSegmentGeometry,
        progress: CGFloat,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        trailLength: CGFloat = 0.25
    ) {
        self.from = segment.from
        self.to = segment.to
        self.segment = segment
        self.customPath = nil
        self.isTriggered = true
        self.explicitProgress = progress
        self.trailLength = trailLength
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = 0.65
        self.onComplete = nil
    }

    public init(
        path: Path,
        isTriggered: Bool = true,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        trailLength: CGFloat = 0.25,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) {
        self.from = nil
        self.to = nil
        self.segment = nil
        self.customPath = path
        self.isTriggered = isTriggered
        self.explicitProgress = nil
        self.trailLength = trailLength
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = duration
        self.onComplete = onComplete
    }

    public init(
        path: Path,
        progress: CGFloat,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        trailLength: CGFloat = 0.25
    ) {
        self.from = nil
        self.to = nil
        self.segment = nil
        self.customPath = path
        self.isTriggered = true
        self.explicitProgress = progress
        self.trailLength = trailLength
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = 0.65
        self.onComplete = nil
    }

    // MARK: - Properties

    private var currentProgress: CGFloat {
        explicitProgress ?? animatedProgress
    }

    private var basePath: Path {
        if let customPath {
            return customPath
        } else if let segment {
            return segment.buildPath()
        } else if let from, let to {
            var path = Path()
            path.move(to: from)
            let dy = to.y - from.y
            let control1 = CGPoint(x: from.x, y: from.y + dy * 0.5)
            let control2 = CGPoint(x: to.x, y: to.y - dy * 0.5)
            path.addCurve(to: to, control1: control1, control2: control2)
            return path
        } else {
            return Path()
        }
    }

    // MARK: - Body

    public var body: some View {
        let progress = currentProgress
        let effectiveColor = color ?? theme.colors.brandPrimary
        let effectiveGlowColor = glowColor ?? theme.colors.statusWarning

        ZStack {
            if progress > 0 {
                // Wide ambient glow
                CraftPathSurgeShape(
                    path: basePath,
                    progress: progress,
                    trailLength: trailLength
                )
                .stroke(
                    LinearGradient(
                        colors: [effectiveGlowColor.opacity(0.1), effectiveColor.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: lineWidth * 2.4, lineCap: .round, lineJoin: .round)
                )
                .blur(radius: 4)

                // Sharp core beam
                CraftPathSurgeShape(
                    path: basePath,
                    progress: progress,
                    trailLength: trailLength
                )
                .stroke(
                    LinearGradient(
                        colors: [effectiveColor.opacity(0.3), effectiveGlowColor],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )

                // Bright highlight core
                CraftPathSurgeShape(
                    path: basePath,
                    progress: progress,
                    trailLength: trailLength * 0.4
                )
                .stroke(
                    Color.white.opacity(0.9),
                    style: StrokeStyle(lineWidth: max(1.5, lineWidth * 0.35), lineCap: .round, lineJoin: .round)
                )

                // Spark particle at head
                if let leadPoint = basePath.trimmedPath(from: 0, to: progress).currentPoint {
                    sparkHead(at: leadPoint, glowColor: effectiveGlowColor, primaryColor: effectiveColor)
                }
            }
        }
        .accessibilityHidden(true)
        .onAppear {
            triggerSurgeIfNeeded()
        }
        .onChange(of: isTriggered) { _, newValue in
            if newValue {
                triggerSurgeIfNeeded()
            }
        }
    }

    @ViewBuilder
    private func sparkHead(at point: CGPoint, glowColor: Color, primaryColor: Color) -> some View {
        ZStack {
            // Ambient glow halo
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(0.9),
                            primaryColor.opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: sparkSize * 1.4
                    )
                )
                .frame(width: sparkSize * 2.8, height: sparkSize * 2.8)

            // Sharp glow
            Circle()
                .fill(glowColor)
                .frame(width: sparkSize * 0.8, height: sparkSize * 0.8)
                .blur(radius: 1.0)

            // Inner white core
            Circle()
                .fill(Color.white)
                .frame(width: sparkSize * 0.45, height: sparkSize * 0.45)
        }
        .position(point)
    }

    private func triggerSurgeIfNeeded() {
        guard explicitProgress == nil else { return }
        guard isTriggered else { return }

        if reduceMotion {
            animatedProgress = 1.0
            onComplete?()
        } else {
            animatedProgress = 0.0
            withAnimation(theme.animations.springGentle) {
                animatedProgress = 1.0
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                if !isCompleted {
                    isCompleted = true
                    onComplete?()
                }
            }
        }
    }
}

// MARK: - Type Alias

/// Alias for `CraftPathUnlockSurgeView`.
public typealias CraftPathUnlockSurge = CraftPathUnlockSurgeView

// MARK: - View Modifiers

public struct CraftPathUnlockSurgeModifier: ViewModifier {
    @Binding public var isTriggered: Bool
    public let from: CGPoint?
    public let to: CGPoint?
    public let segment: SnakePathSegmentGeometry?
    public let customPath: Path?
    public let color: Color?
    public let glowColor: Color?
    public let lineWidth: CGFloat
    public let sparkSize: CGFloat
    public let duration: Double
    public let onComplete: (@Sendable () -> Void)?

    public init(
        isTriggered: Binding<Bool>,
        from: CGPoint,
        to: CGPoint,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) {
        self._isTriggered = isTriggered
        self.from = from
        self.to = to
        self.segment = nil
        self.customPath = nil
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = duration
        self.onComplete = onComplete
    }

    public init(
        isTriggered: Binding<Bool>,
        segment: SnakePathSegmentGeometry,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) {
        self._isTriggered = isTriggered
        self.from = segment.from
        self.to = segment.to
        self.segment = segment
        self.customPath = nil
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = duration
        self.onComplete = onComplete
    }

    public init(
        isTriggered: Binding<Bool>,
        path: Path,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) {
        self._isTriggered = isTriggered
        self.from = nil
        self.to = nil
        self.segment = nil
        self.customPath = path
        self.color = color
        self.glowColor = glowColor
        self.lineWidth = lineWidth
        self.sparkSize = sparkSize
        self.duration = duration
        self.onComplete = onComplete
    }

    public func body(content: Content) -> some View {
        content.overlay {
            if isTriggered {
                if let segment {
                    CraftPathUnlockSurgeView(
                        segment: segment,
                        isTriggered: isTriggered,
                        color: color,
                        glowColor: glowColor,
                        lineWidth: lineWidth,
                        sparkSize: sparkSize,
                        duration: duration,
                        onComplete: onComplete
                    )
                } else if let customPath {
                    CraftPathUnlockSurgeView(
                        path: customPath,
                        isTriggered: isTriggered,
                        color: color,
                        glowColor: glowColor,
                        lineWidth: lineWidth,
                        sparkSize: sparkSize,
                        duration: duration,
                        onComplete: onComplete
                    )
                } else if let from, let to {
                    CraftPathUnlockSurgeView(
                        from: from,
                        to: to,
                        isTriggered: isTriggered,
                        color: color,
                        glowColor: glowColor,
                        lineWidth: lineWidth,
                        sparkSize: sparkSize,
                        duration: duration,
                        onComplete: onComplete
                    )
                }
            }
        }
    }
}

public extension View {
    /// Overlays an energetic light surge particle along a Bézier S-curve connector during node unlock.
    func craftPathUnlockSurge(
        isTriggered: Binding<Bool>,
        from: CGPoint,
        to: CGPoint,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) -> some View {
        modifier(
            CraftPathUnlockSurgeModifier(
                isTriggered: isTriggered,
                from: from,
                to: to,
                color: color,
                glowColor: glowColor,
                lineWidth: lineWidth,
                sparkSize: sparkSize,
                duration: duration,
                onComplete: onComplete
            )
        )
    }

    /// Overlays an energetic light surge particle along a serpentine snake segment during node unlock.
    func craftPathUnlockSurge(
        isTriggered: Binding<Bool>,
        segment: SnakePathSegmentGeometry,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) -> some View {
        modifier(
            CraftPathUnlockSurgeModifier(
                isTriggered: isTriggered,
                segment: segment,
                color: color,
                glowColor: glowColor,
                lineWidth: lineWidth,
                sparkSize: sparkSize,
                duration: duration,
                onComplete: onComplete
            )
        )
    }

    /// Overlays an energetic light surge particle along an arbitrary path during node unlock.
    func craftPathUnlockSurge(
        isTriggered: Binding<Bool>,
        path: Path,
        color: Color? = nil,
        glowColor: Color? = nil,
        lineWidth: CGFloat = 4.0,
        sparkSize: CGFloat = 12.0,
        duration: Double = 0.65,
        onComplete: (@Sendable () -> Void)? = nil
    ) -> some View {
        modifier(
            CraftPathUnlockSurgeModifier(
                isTriggered: isTriggered,
                path: path,
                color: color,
                glowColor: glowColor,
                lineWidth: lineWidth,
                sparkSize: sparkSize,
                duration: duration,
                onComplete: onComplete
            )
        )
    }
}
