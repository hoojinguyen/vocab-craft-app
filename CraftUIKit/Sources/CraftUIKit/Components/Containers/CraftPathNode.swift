import SwiftUI

// MARK: - CraftPathNode Atom View

/// A universal atom view representing an individual journey path node.
///
/// Supports:
/// - 6 progression states (`completed`, `active`, `inProgress`, `upcoming`, `locked`, `bonus`)
/// - 5 shapes (`circle`, `hexagon`, `diamond`, `squircle`, `star`)
/// - 5 surface styles (`tactile3D`, `glass`, `elevated`, `outlined`, `flat`)
/// - Active pulsating glow halo and bobbing speech bubble callout
/// - Mechanical depress physics, monospaced badges, 3D star rating, and progress trim arcs
public struct CraftPathNode<CustomPayload: Sendable>: View {
    public let model: CraftPathNodeModel<CustomPayload>
    public let calloutText: String?
    public let onTap: (@Sendable (CraftPathNodeModel<CustomPayload>) -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var baseScale: CGFloat = 1.0

    @State private var tapTrigger: Bool = false
    @State private var completionTrigger: Bool = false
    @State private var lockedAttemptTrigger: Bool = false

    // MARK: - Initializers

    public init(
        model: CraftPathNodeModel<CustomPayload>,
        calloutText: String? = nil,
        onTap: (@Sendable (CraftPathNodeModel<CustomPayload>) -> Void)? = nil
    ) {
        self.model = model
        self.calloutText = calloutText
        self.onTap = onTap
    }

    public init(
        model: CraftPathNodeModel<CustomPayload>,
        calloutText: String? = nil,
        onTapSimple: @escaping @Sendable () -> Void
    ) {
        self.model = model
        self.calloutText = calloutText
        self.onTap = { _ in onTapSimple() }
    }

    // MARK: - Computed Properties & Sizing

    public var effectiveSurfaceStyle: CraftSurfaceStyle {
        model.surfaceStyle
    }

    public var nodeDiameter: CGFloat {
        let unscaled: CGFloat = switch model.state {
        case .completed: 52
        case .active: 64
        case .inProgress: 56
        case .upcoming, .locked: 48
        case .bonus: 56
        }
        return unscaled * baseScale
    }

    public var iconSize: CGFloat {
        let unscaled: CGFloat = switch model.state {
        case .active: 26
        case .inProgress, .bonus: 22
        case .completed: 20
        case .upcoming, .locked: 18
        }
        return unscaled * baseScale
    }

    public var resolvedCalloutText: String {
        if let calloutText, !calloutText.isEmpty {
            return calloutText
        }
        return CraftLocalized.string("craft.journey.continueCallout")
    }

    // MARK: - Accessibility Helpers

    public var accessibilityLabelText: String {
        let base: String
        switch model.state {
        case .completed:
            base = "Lesson: \(model.title), Completed"
        case .active:
            if let progress = model.progress {
                let percent = Int((progress * 100).rounded())
                base = "Lesson: \(model.title), Current lesson. \(percent)% complete"
            } else {
                base = "Lesson: \(model.title), Current lesson"
            }
        case .inProgress:
            if let progress = model.progress {
                let percent = Int((progress * 100).rounded())
                base = "Lesson: \(model.title), In progress. \(percent)% complete"
            } else {
                base = "Lesson: \(model.title), In progress"
            }
        case .upcoming:
            base = "Lesson: \(model.title), Upcoming lesson"
        case .locked:
            base = "Lesson: \(model.title), Locked"
        case .bonus:
            base = "Bonus Lesson: \(model.title)"
        }

        if let metric = model.metricText, !metric.isEmpty {
            return "\(base). \(metric)"
        }
        return base
    }

    public var accessibilityHintText: String {
        switch model.state {
        case .completed:
            return "Double tap to review"
        case .active, .inProgress:
            return "Double tap to continue"
        case .upcoming, .bonus:
            return "Double tap to start"
        case .locked:
            return "Complete previous lessons to unlock"
        }
    }

    public var accessibilityTraits: AccessibilityTraits {
        model.state == .locked ? .notEnabled : .isButton
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            if model.state == .active {
                ActiveCalloutBubble(text: resolvedCalloutText)
                    .padding(.bottom, 6)
            }

            nodeAtom
                .anchorPreference(key: NodeAnchorPreferenceKey.self, value: .center) { anchor in
                    [model.id: anchor]
                }

            nodeLabels
                .padding(.top, 6)
        }
        .sensoryFeedback(.impact(weight: .medium), trigger: tapTrigger)
        .sensoryFeedback(.success, trigger: completionTrigger)
        .sensoryFeedback(.error, trigger: lockedAttemptTrigger)
        .sensoryFeedback(.selection, trigger: model.badgeCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - Node Atom

    private var nodeAtom: some View {
        ZStack {
            // Active glow halo ring
            if model.state == .active {
                activeGlowHalo
            }

            // Node button stack
            if effectiveSurfaceStyle == .tactile3D {
                tactileStack
            } else {
                standardButton
            }
        }
        .frame(minWidth: 44, minHeight: 44)
    }

    // MARK: - Tactile 3D Stack

    private var tactileStack: some View {
        ZStack {
            // Extruded bottom rim
            bottomRimShape
                .offset(y: model.state == .locked ? 0 : theme.depths.depthMd)

            // Top Face Button
            Button {
                handleTap()
            } label: {
                topFaceView
            }
            .buttonStyle(TactileNodeButtonStyle(isLocked: model.state == .locked, depth: theme.depths.depthMd))
        }
        .frame(width: nodeDiameter, height: nodeDiameter + (model.state == .locked ? 0 : theme.depths.depthMd))
    }

    // MARK: - Standard Button

    private var standardButton: some View {
        Button {
            handleTap()
        } label: {
            topFaceView
        }
        .buttonStyle(.craftPress(scale: model.state == .locked ? 1.0 : 0.94))
        .disabled(model.state == .locked)
        .frame(width: nodeDiameter, height: nodeDiameter)
    }

    // MARK: - Top Face View

    private var topFaceView: some View {
        ZStack {
            // Face Background Fill & Stroke
            faceBackgroundView

            // Specular / Highlight Overlay
            faceHighlightOverlay

            // Progress arc
            if model.state == .inProgress {
                progressArcView
            }

            // Center Icon
            nodeIconView
        }
        .frame(width: nodeDiameter, height: nodeDiameter)
        .opacity(model.state == .locked ? 0.6 : 1.0)
        .overlay(alignment: .topTrailing) {
            badgeOverlayView
        }
    }

    // MARK: - Bottom Rim Shape

    @ViewBuilder
    private var bottomRimShape: some View {
        switch model.shape {
        case .circle:
            Circle()
                .fill(rimColor)
                .frame(width: nodeDiameter, height: nodeDiameter)
        case .hexagon:
            HexagonShape()
                .fill(rimColor)
                .frame(width: nodeDiameter, height: nodeDiameter)
        case .diamond:
            DiamondShape()
                .fill(rimColor)
                .frame(width: nodeDiameter, height: nodeDiameter)
        case .squircle:
            SquircleShape(cornerRadius: nodeDiameter * 0.28)
                .fill(rimColor)
                .frame(width: nodeDiameter, height: nodeDiameter)
        case .star:
            StarShape()
                .fill(rimColor)
                .frame(width: nodeDiameter, height: nodeDiameter)
        }
    }

    // MARK: - Face Background View

    @ViewBuilder
    private var faceBackgroundView: some View {
        switch model.shape {
        case .circle:
            shapeSurface(shape: Circle())
        case .hexagon:
            shapeSurface(shape: HexagonShape())
        case .diamond:
            shapeSurface(shape: DiamondShape())
        case .squircle:
            shapeSurface(shape: SquircleShape(cornerRadius: nodeDiameter * 0.28))
        case .star:
            shapeSurface(shape: StarShape())
        }
    }

    @ViewBuilder
    private func shapeSurface<S: Shape>(shape: S) -> some View {
        switch effectiveSurfaceStyle {
        case .glass:
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(glassTintFill)
                shape.stroke(theme.glass.borderGradient, lineWidth: 1)
            }
        case .elevated:
            ZStack {
                shape.fill(stateFillColor)
                shape.stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.6), location: 0.0),
                            .init(color: theme.colors.hairline.opacity(0.3), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .craftShadow(theme.shadows.md)
        case .outlined:
            ZStack {
                shape.fill(theme.colors.surfaceCard)
                shape.stroke(theme.colors.borderDefault, lineWidth: 1.5)
            }
        case .flat:
            shape.fill(theme.colors.surfaceSubtle)
        case .tactile3D:
            ZStack {
                stateFillView(shape: shape)

                if model.state == .upcoming || model.state == .locked {
                    shape.stroke(theme.colors.borderDefault, lineWidth: 1.5)
                }
            }
        }
    }

    @ViewBuilder
    private func stateFillView<S: Shape>(shape: S) -> some View {
        switch model.state {
        case .completed:
            shape.fill(theme.colors.statusSuccess)
        case .active:
            shape.fill(theme.gradients.brandHero)
        case .inProgress:
            shape.fill(theme.colors.surfaceElevated)
        case .upcoming, .locked:
            shape.fill(theme.colors.surfaceSubtle)
        case .bonus:
            shape.fill(theme.gradients.accentShine)
                .craftShimmer(isActive: !reduceMotion)
        }
    }

    private var stateFillColor: Color {
        switch model.state {
        case .completed:
            return theme.colors.statusSuccess
        case .active:
            return theme.colors.brandPrimary
        case .inProgress:
            return theme.colors.surfaceElevated
        case .upcoming, .locked:
            return theme.colors.surfaceSubtle
        case .bonus:
            return theme.colors.accent
        }
    }

    private var glassTintFill: Color {
        switch model.state {
        case .completed:
            return theme.colors.statusSuccess.opacity(0.20)
        case .active:
            return theme.colors.brandPrimary.opacity(0.25)
        case .inProgress:
            return theme.colors.brandPrimary.opacity(0.12)
        case .bonus:
            return theme.colors.accent.opacity(0.25)
        case .upcoming, .locked:
            return theme.colors.surfaceCard.opacity(0.15)
        }
    }

    // MARK: - Face Highlight Overlay

    @ViewBuilder
    private var faceHighlightOverlay: some View {
        if effectiveSurfaceStyle == .tactile3D {
            switch model.shape {
            case .circle:
                Circle().stroke(theme.depths.topHighlight, lineWidth: 1.5)
            case .hexagon:
                HexagonShape().stroke(theme.depths.topHighlight, lineWidth: 1.5)
            case .diamond:
                DiamondShape().stroke(theme.depths.topHighlight, lineWidth: 1.5)
            case .squircle:
                SquircleShape(cornerRadius: nodeDiameter * 0.28).stroke(theme.depths.topHighlight, lineWidth: 1.5)
            case .star:
                StarShape().stroke(theme.depths.topHighlight, lineWidth: 1.5)
            }
        }
    }

    // MARK: - Progress Arc View

    @ViewBuilder
    private var progressArcView: some View {
        let clampedProgress = min(max(model.progress ?? 0.0, 0.0), 1.0)
        switch model.shape {
        case .circle:
            ZStack {
                Circle()
                    .stroke(theme.colors.borderDefault, lineWidth: 3)

                Circle()
                    .trim(from: 0.0, to: CGFloat(clampedProgress))
                    .stroke(
                        theme.colors.brandPrimary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        case .hexagon:
            HexagonShape()
                .trim(from: 0.0, to: CGFloat(clampedProgress))
                .stroke(
                    theme.colors.brandPrimary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
        case .diamond:
            DiamondShape()
                .trim(from: 0.0, to: CGFloat(clampedProgress))
                .stroke(
                    theme.colors.brandPrimary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
        case .squircle:
            SquircleShape(cornerRadius: nodeDiameter * 0.28)
                .trim(from: 0.0, to: CGFloat(clampedProgress))
                .stroke(
                    theme.colors.brandPrimary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
        case .star:
            StarShape()
                .trim(from: 0.0, to: CGFloat(clampedProgress))
                .stroke(
                    theme.colors.brandPrimary,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
        }
    }

    // MARK: - Rim Color

    private var rimColor: Color {
        switch model.state {
        case .completed:
            return theme.colors.statusSuccess.opacity(0.85)
        case .active:
            return theme.colors.brandPrimary.opacity(0.85)
        case .inProgress, .upcoming:
            return theme.colors.borderDefault
        case .locked:
            return theme.colors.surfaceSubtle
        case .bonus:
            return theme.colors.accent.opacity(0.85)
        }
    }

    // MARK: - Active Glow Halo

    @ViewBuilder
    private var activeGlowHalo: some View {
        let haloSize = nodeDiameter + 24
        if reduceMotion {
            haloShapeView(size: haloSize, opacity: 1.0, scale: 1.0)
        } else {
            PhaseAnimator(GlowPhase.allCases) { phase in
                haloShapeView(
                    size: haloSize,
                    opacity: phase == .glowing ? 1.0 : 0.75,
                    scale: phase == .glowing ? 1.04 : 0.98
                )
            } animation: { _ in
                .craftGlow
            }
        }
    }

    @ViewBuilder
    private func haloShapeView(size: CGFloat, opacity: Double, scale: CGFloat) -> some View {
        switch model.shape {
        case .circle:
            Circle()
                .fill(theme.colors.pathHaloGlow.opacity(opacity))
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .overlay(
                    Circle()
                        .stroke(theme.colors.brandPrimary.opacity(opacity * 0.35), lineWidth: 1.5)
                        .scaleEffect(scale)
                )
        case .hexagon:
            HexagonShape()
                .fill(theme.colors.pathHaloGlow.opacity(opacity))
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .overlay(
                    HexagonShape()
                        .stroke(theme.colors.brandPrimary.opacity(opacity * 0.35), lineWidth: 1.5)
                        .scaleEffect(scale)
                )
        case .diamond:
            DiamondShape()
                .fill(theme.colors.pathHaloGlow.opacity(opacity))
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .overlay(
                    DiamondShape()
                        .stroke(theme.colors.brandPrimary.opacity(opacity * 0.35), lineWidth: 1.5)
                        .scaleEffect(scale)
                )
        case .squircle:
            SquircleShape(cornerRadius: size * 0.28)
                .fill(theme.colors.pathHaloGlow.opacity(opacity))
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .overlay(
                    SquircleShape(cornerRadius: size * 0.28)
                        .stroke(theme.colors.brandPrimary.opacity(opacity * 0.35), lineWidth: 1.5)
                        .scaleEffect(scale)
                )
        case .star:
            StarShape()
                .fill(theme.colors.pathHaloGlow.opacity(opacity))
                .frame(width: size, height: size)
                .scaleEffect(scale)
                .overlay(
                    StarShape()
                        .stroke(theme.colors.brandPrimary.opacity(opacity * 0.35), lineWidth: 1.5)
                        .scaleEffect(scale)
                )
        }
    }

    // MARK: - Node Icon View

    private var effectiveIconName: String {
        switch model.state {
        case .completed:
            return "checkmark"
        case .locked:
            return "lock.fill"
        case .bonus:
            return model.icon.name.isEmpty ? "star.fill" : model.icon.name
        case .active, .inProgress, .upcoming:
            return model.icon.name.isEmpty ? "book.fill" : model.icon.name
        }
    }

    private var iconColor: Color {
        switch model.state {
        case .completed, .active, .bonus:
            return .white
        case .inProgress:
            return theme.colors.brandPrimary
        case .upcoming, .locked:
            return theme.colors.textMuted
        }
    }

    @ViewBuilder
    private var nodeIconView: some View {
        if model.icon.isSystem {
            Image(systemName: effectiveIconName)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(iconColor)
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(.pulse.byLayer, isActive: model.state == .active && !reduceMotion)
                .symbolEffect(.bounce, value: model.state == .completed)
                .symbolEffectsRemoved(reduceMotion)
        } else {
            Image(effectiveIconName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(iconColor)
        }
    }

    // MARK: - Node Labels

    private var nodeLabels: some View {
        VStack(spacing: 2) {
            Text(model.title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundStyle(model.state == .locked ? theme.colors.textMuted : theme.colors.textPrimary)

            if let subtitle = model.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            } else if let metric = model.metricText, !metric.isEmpty {
                Text(metric)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            }

            if model.state == .completed, let starCount = model.stars, starCount > 0 {
                starRatingView(count: starCount)
            }
        }
        .frame(maxWidth: 120)
    }

    // MARK: - 3D Star Rating

    private func starRatingView(count: Int) -> some View {
        let clampedStars = min(max(count, 0), 3)
        return HStack(spacing: 3) {
            ForEach(0..<clampedStars, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.gradients.accentShine)
                    .shadow(color: theme.colors.accent.opacity(0.5), radius: 0, x: 0, y: 1.2)
                    .overlay {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(theme.depths.topHighlight)
                    }
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Badge Overlay

    @ViewBuilder
    private var badgeOverlayView: some View {
        if let count = model.badgeCount, count > 0 {
            badgeView(text: "\(count)", bounceValue: count)
                .offset(x: 4, y: -4)
        } else if let text = model.badgeText, !text.isEmpty {
            badgeView(text: text, bounceValue: nil)
                .offset(x: 4, y: -4)
        }
    }

    private func badgeView(text: String, bounceValue: Int?) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(theme.colors.textInverse)
            .padding(.horizontal, text.count > 1 ? 5 : 0)
            .frame(minWidth: 18, minHeight: 18)
            .background(
                Capsule()
                    .fill(theme.colors.statusDanger)
            )
            .overlay(
                Capsule()
                    .stroke(theme.colors.surfaceCard, lineWidth: 1.5)
            )
            .contentTransition(.numericText())
            .symbolEffect(.bounce, value: bounceValue ?? 0)
    }

    // MARK: - Tap Handling

    private func handleTap() {
        if model.state == .locked {
            lockedAttemptTrigger.toggle()
        } else if model.state == .completed {
            completionTrigger.toggle()
        } else {
            tapTrigger.toggle()
        }
        onTap?(model)
    }
}

extension CraftPathNode: Equatable where CustomPayload: Equatable {
    public static func == (lhs: CraftPathNode<CustomPayload>, rhs: CraftPathNode<CustomPayload>) -> Bool {
        lhs.model == rhs.model && lhs.calloutText == rhs.calloutText
    }
}
