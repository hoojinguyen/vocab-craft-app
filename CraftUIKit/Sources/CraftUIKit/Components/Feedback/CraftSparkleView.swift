import SwiftUI

// MARK: - Sparkle Style

/// The visual style of the celebratory particle burst.
public enum CraftSparkleStyle: String, CaseIterable, Sendable {
    case sparkles
    case confetti
}

// MARK: - Particle Internal Model

private struct FXParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var gravity: CGFloat
    var drag: CGFloat
    var scale: CGFloat
    var rotation: CGFloat
    var rotationSpeed: CGFloat
    var flipSpeed: CGFloat
    var flipProgress: CGFloat
    var opacity: Double
    var color: Color
    var shape: ParticleShape
    var size: CGSize

    enum ParticleShape {
        case star
        case diamond
        case circle
        case rectangle
    }
}

// MARK: - CraftSparkleView

/// A celebratory particle overlay rendering sparkle bursts or confetti physics
/// with automatic lifecycle management and Reduce Motion accessibility support.
public struct CraftSparkleView: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding public var isTriggered: Bool
    public let style: CraftSparkleStyle
    public let particleCount: Int

    @State private var particles: [FXParticle] = []
    @State private var animationStartDate: Date?
    @State private var isRunning: Bool = false
    @State private var staticOpacity: Double = 0.0
    @State private var containerSize: CGSize = CGSize(width: 300, height: 300)

    public init(
        isTriggered: Binding<Bool>,
        style: CraftSparkleStyle = .sparkles,
        particleCount: Int = 20
    ) {
        self._isTriggered = isTriggered
        self.style = style
        self.particleCount = max(1, particleCount)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if reduceMotion {
                    reduceMotionFallback
                } else if isRunning {
                    TimelineView(.animation(paused: !isRunning)) { timeline in
                        Canvas { context, size in
                            guard let start = animationStartDate else { return }
                            let elapsed = timeline.date.timeIntervalSince(start)
                            drawParticles(context: context, size: size, elapsed: elapsed)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .onAppear {
                if geometry.size.width > 0 && geometry.size.height > 0 {
                    containerSize = geometry.size
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                if newSize.width > 0 && newSize.height > 0 {
                    containerSize = newSize
                }
            }
        }
        .task(id: isTriggered) {
            guard isTriggered else {
                isRunning = false
                particles.removeAll()
                animationStartDate = nil
                staticOpacity = 0.0
                return
            }

            if reduceMotion {
                isRunning = true
                withAnimation(.easeIn(duration: 0.2)) {
                    staticOpacity = 1.0
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.3)) {
                    staticOpacity = 0.0
                }
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                isRunning = false
                isTriggered = false
            } else {
                particles = generateParticles(in: containerSize)
                animationStartDate = Date()
                isRunning = true

                let duration: Double = style == .sparkles ? 1.4 : 2.2
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                guard !Task.isCancelled else { return }
                isRunning = false
                particles.removeAll()
                animationStartDate = nil
                isTriggered = false
            }
        }
    }

    // MARK: - Particle Generation

    private func generateParticles(in size: CGSize) -> [FXParticle] {
        let center = CGPoint(
            x: size.width > 0 ? size.width / 2 : 150,
            y: size.height > 0 ? size.height / 2 : 150
        )
        let colors = palette(for: style)

        return (0..<particleCount).map { i in
            let color = colors[i % colors.count]
            switch style {
            case .sparkles:
                let angle = Double.random(in: 0...(2 * .pi))
                let speed = CGFloat.random(in: 80...260)
                let shape: FXParticle.ParticleShape = i % 3 == 0 ? .star : (i % 3 == 1 ? .diamond : .circle)
                let pSize = CGFloat.random(in: 10...22)

                return FXParticle(
                    id: i,
                    x: center.x + CGFloat.random(in: -20...20),
                    y: center.y + CGFloat.random(in: -20...20),
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    gravity: 20,
                    drag: 0.94,
                    scale: CGFloat.random(in: 0.7...1.3),
                    rotation: CGFloat.random(in: 0...(2 * .pi)),
                    rotationSpeed: CGFloat.random(in: -4...4),
                    flipSpeed: 0,
                    flipProgress: 0,
                    opacity: 1.0,
                    color: color,
                    shape: shape,
                    size: CGSize(width: pSize, height: pSize)
                )

            case .confetti:
                let startX = center.x + CGFloat.random(in: -60...60)
                let startY = center.y + CGFloat.random(in: -20...40)
                let angle = Double.random(in: (-.pi * 0.85)...(-.pi * 0.15))
                let speed = CGFloat.random(in: 250...520)
                let shape: FXParticle.ParticleShape = i % 2 == 0 ? .rectangle : .circle
                let w = CGFloat.random(in: 8...14)
                let h = shape == .rectangle ? CGFloat.random(in: 12...22) : w

                return FXParticle(
                    id: i,
                    x: startX,
                    y: startY,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    gravity: 340,
                    drag: 0.985,
                    scale: CGFloat.random(in: 0.8...1.2),
                    rotation: CGFloat.random(in: 0...(2 * .pi)),
                    rotationSpeed: CGFloat.random(in: -5...5),
                    flipSpeed: CGFloat.random(in: 3...8),
                    flipProgress: Double.random(in: 0...(.pi * 2)),
                    opacity: 1.0,
                    color: color,
                    shape: shape,
                    size: CGSize(width: w, height: h)
                )
            }
        }
    }

    private func palette(for style: CraftSparkleStyle) -> [Color] {
        switch style {
        case .sparkles:
            return [
                theme.colors.accent,           // Gold
                theme.colors.accent.opacity(0.7), // Light Gold
                theme.colors.brandPrimary,      // Brand
                theme.colors.statusSuccess,     // Green
                theme.colors.brandSecondary,    // Amber
                Color.white
            ]
        case .confetti:
            return [
                theme.colors.statusDanger,      // Red
                theme.colors.accent,            // Amber
                theme.colors.statusSuccess,     // Green
                theme.colors.statusInfo,        // Blue
                theme.colors.brandPrimary,      // Brand
                theme.colors.brandSecondary,    // Secondary
            ]
        }
    }

    // MARK: - Canvas Rendering

    private func drawParticles(context: GraphicsContext, size: CGSize, elapsed: Double) {
        let maxDuration: Double = style == .sparkles ? 1.4 : 2.2
        let progress = min(elapsed / maxDuration, 1.0)
        let fadeThreshold = 0.65
        let fadeFactor = progress > fadeThreshold ? max(0.0, 1.0 - (progress - fadeThreshold) / (1.0 - fadeThreshold)) : 1.0

        for particle in particles {
            let t = CGFloat(elapsed)
            // Monotonic outward displacement under continuous drag decay:
            // \int_0^t e^{-k \tau} d\tau = (1 - drag^{60t}) / (-ln(drag) * 60)
            let decayRate = -log(particle.drag) * 60
            let integratedTime: CGFloat
            if decayRate > 0.0001 {
                integratedTime = (1.0 - pow(particle.drag, t * 60)) / decayRate
            } else {
                integratedTime = t
            }

            let currentX = particle.x + particle.vx * integratedTime
            let currentY = particle.y + particle.vy * integratedTime + (0.5 * particle.gravity * t * t)

            let currentRotation = particle.rotation + particle.rotationSpeed * t
            let flipScale = style == .confetti ? abs(cos(CGFloat(particle.flipProgress) + particle.flipSpeed * t)) : 1.0
            let currentScale = style == .sparkles ? max(0, particle.scale * (1.0 - CGFloat(progress * 0.7))) : particle.scale
            let currentOpacity = particle.opacity * fadeFactor

            guard currentOpacity > 0.01 else { continue }

            var pContext = context
            pContext.translateBy(x: currentX, y: currentY)
            pContext.rotate(by: Angle(radians: Double(currentRotation)))
            pContext.scaleBy(x: currentScale * flipScale, y: currentScale)

            let color = particle.color.opacity(currentOpacity)
            let w = particle.size.width
            let h = particle.size.height

            switch particle.shape {
            case .circle:
                let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
                pContext.fill(Path(ellipseIn: rect), with: .color(color))

            case .rectangle:
                let rect = CGRect(x: -w/2, y: -h/2, width: w, height: h)
                pContext.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(color))

            case .diamond:
                var path = Path()
                path.move(to: CGPoint(x: 0, y: -h/2))
                path.addLine(to: CGPoint(x: w/2, y: 0))
                path.addLine(to: CGPoint(x: 0, y: h/2))
                path.addLine(to: CGPoint(x: -w/2, y: 0))
                path.closeSubpath()
                pContext.fill(path, with: .color(color))

            case .star:
                let path = starPath(width: w, height: h)
                pContext.fill(path, with: .color(color))
            }
        }
    }

    private func starPath(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        let cx = CGFloat(0)
        let cy = CGFloat(0)
        let outerR = max(width, height) / 2
        let innerR = outerR * 0.35

        let points = 4
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? outerR : innerR
            let angle = (Double(i) * .pi / Double(points)) - (.pi / 2)
            let x = cx + CGFloat(cos(angle)) * r
            let y = cy + CGFloat(sin(angle)) * r
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }

    // MARK: - Reduce Motion Fallback

    private var reduceMotionFallback: some View {
        HStack(spacing: theme.spacing.xs) {
            CraftIcon(
                style == .sparkles ? CraftSymbol.sparkles.rawValue : CraftSymbol.partyPopper.rawValue,
                size: .lg,
                color: theme.colors.accent,
                weight: .bold
            )
            Text(style == .sparkles ? "Sparkle!" : "Celebration!")
                .font(theme.typography.headline)
                .foregroundColor(theme.colors.textPrimary)
        }
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .background(
            Capsule()
                .fill(theme.colors.surfaceElevated)
                .craftShadow(theme.shadows.md)
        )
        .opacity(staticOpacity)
    }
}

// MARK: - Sparkle & Confetti View Modifier

public struct CraftSparkleOverlayModifier: ViewModifier {
    @Binding public var isTriggered: Bool
    public let style: CraftSparkleStyle
    public let particleCount: Int

    public init(
        isTriggered: Binding<Bool>,
        style: CraftSparkleStyle,
        particleCount: Int
    ) {
        self._isTriggered = isTriggered
        self.style = style
        self.particleCount = particleCount
    }

    public func body(content: Content) -> some View {
        content
            .overlay {
                CraftSparkleView(
                    isTriggered: $isTriggered,
                    style: style,
                    particleCount: particleCount
                )
            }
    }
}

// MARK: - View Modifiers Extension

public extension View {
    /// Overlays celebratory sparkle particles when triggered.
    ///
    /// - Parameters:
    ///   - isTriggered: Binding controlling the particle burst activation. Automatically resets to false on completion.
    ///   - particleCount: Number of sparkle particles generated (default: 20).
    /// - Returns: A view modified with the sparkle burst overlay.
    func craftSparkle(isTriggered: Binding<Bool>, particleCount: Int = 20) -> some View {
        modifier(CraftSparkleOverlayModifier(isTriggered: isTriggered, style: .sparkles, particleCount: particleCount))
    }

    /// Overlays celebratory confetti physics burst when triggered.
    ///
    /// - Parameters:
    ///   - isTriggered: Binding controlling the confetti burst activation. Automatically resets to false on completion.
    ///   - particleCount: Number of confetti particles generated (default: 30).
    /// - Returns: A view modified with the confetti burst overlay.
    func craftConfetti(isTriggered: Binding<Bool>, particleCount: Int = 30) -> some View {
        modifier(CraftSparkleOverlayModifier(isTriggered: isTriggered, style: .confetti, particleCount: particleCount))
    }
}

// MARK: - Previews

#Preview("Sparkle Burst") {
    CraftSparkleView(
        isTriggered: .constant(true),
        style: .sparkles,
        particleCount: 30
    )
    .frame(width: 300, height: 300)
    .background(Color.black.opacity(0.8))
}

#Preview("Confetti Burst") {
    CraftConfettiPreview()
}

private struct CraftConfettiPreview: View {
    @State private var triggered: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            Button("Trigger Confetti") {
                triggered = true
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .craftConfetti(isTriggered: $triggered, particleCount: 40)
    }
}
