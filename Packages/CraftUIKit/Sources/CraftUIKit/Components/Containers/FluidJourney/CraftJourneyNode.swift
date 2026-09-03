import SwiftUI

// MARK: - Journey Node Button Style

/// Button style providing spring-based mechanical depress scale feedback for journey nodes.
private struct JourneyNodeButtonStyle: ButtonStyle {
    let isLocked: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(!isLocked && configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - CraftJourneyNode Component

/// A 72pt uniform continuous squircle floating node within the fluid journey learning path.
///
/// Features:
/// - 72pt unscaled diameter across all states (`RoundedRectangle(cornerRadius: 28, style: .continuous)`)
/// - 5 surface styles: `.elevated`, `.flat`, `.outlined`, `.tactile3D`, `.glass`
/// - Preserved lesson icons on locked/upcoming nodes in a muted tone (no `lock.fill` replacement)
/// - Active breathing glow aura without mechanical scale ballooning
/// - Bottom-right checkmark badge on completed nodes
public struct CraftJourneyNode: View, Equatable {
    public let node: LessonNodeModel
    public let surfaceStyle: CraftSurfaceStyle?
    public let onTap: (@Sendable () -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var baseScale: CGFloat = 1.0

    @State private var tapTrigger: Bool = false

    // MARK: - Initializers

    public init(
        node: LessonNodeModel,
        surfaceStyle: CraftSurfaceStyle? = nil,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.node = node
        self.surfaceStyle = surfaceStyle
        self.onTap = onTap
    }

    public init(
        model: LessonNodeModel,
        surfaceStyle: CraftSurfaceStyle? = nil,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.init(node: model, surfaceStyle: surfaceStyle, onTap: onTap)
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftJourneyNode, rhs: CraftJourneyNode) -> Bool {
        lhs.node == rhs.node && lhs.surfaceStyle == rhs.surfaceStyle
    }

    // MARK: - Surface Style Resolution

    public var effectiveSurfaceStyle: CraftSurfaceStyle {
        if let surfaceStyle {
            return surfaceStyle
        }
        if environmentSurfaceStyle != .flat {
            return environmentSurfaceStyle
        }
        return theme.journeySurfaceStyle
    }

    // MARK: - Sizing Metrics

    /// Returns the standard unscaled diameter in points for a node in the given progression state.
    public static func diameter(for state: LessonNodeState) -> CGFloat {
        72
    }

    /// Dynamic scaled diameter accounting for user accessibility scale.
    public var currentDiameter: CGFloat {
        Self.diameter(for: node.state) * baseScale
    }

    /// Dynamic icon size proportional to node diameter.
    public var iconSize: CGFloat {
        let unscaled: CGFloat = switch node.state {
        case .active, .inProgress: 28
        case .completed: 26
        case .upcoming, .locked, .bonus: 24
        }
        return unscaled * baseScale
    }

    /// Preserved lesson icon name across all progression states.
    public var displayedIconName: String {
        node.iconName.isEmpty ? "book.fill" : node.iconName
    }

    // MARK: - Accessibility Helpers

    public var accessibilityLabelText: String {
        let base: String
        switch node.state {
        case .completed:
            base = CraftLocalized.format("craft.learning_path.node_completed_a11y", node.title)
        case .active:
            if let progress = node.progress {
                let percent = Int((progress * 100).rounded())
                base = CraftLocalized.format("craft.learning_path.node_current_format_a11y", node.title, percent)
            } else {
                base = CraftLocalized.format("craft.learning_path.node_current_a11y", node.title)
            }
        case .inProgress:
            if let progress = node.progress {
                let percent = Int((progress * 100).rounded())
                base = CraftLocalized.format("craft.learning_path.node_in_progress_format_a11y", node.title, percent)
            } else {
                base = CraftLocalized.format("craft.learning_path.node_in_progress_a11y", node.title)
            }
        case .upcoming:
            base = CraftLocalized.format("craft.learning_path.node_upcoming_a11y", node.title)
        case .locked:
            base = CraftLocalized.format("craft.learning_path.node_locked_a11y", node.title)
        case .bonus:
            base = CraftLocalized.format("craft.learning_path.node_bonus_a11y", node.title)
        }

        if let xp = node.xpReward {
            let rewardText = CraftLocalized.format("craft.learning_path.reward_format_a11y", xp)
            return "\(base). \(rewardText)"
        }
        return base
    }

    public var accessibilityHintText: String {
        switch node.state {
        case .completed:
            return CraftLocalized.string("craft.learning_path.tap_to_review_hint")
        case .active, .inProgress:
            return CraftLocalized.string("craft.learning_path.tap_to_continue_hint")
        case .upcoming, .bonus:
            return CraftLocalized.string("craft.learning_path.tap_to_start_hint")
        case .locked:
            return CraftLocalized.string("craft.learning_path.unlock_requirement_hint")
        }
    }

    public var accessibilityTraits: AccessibilityTraits {
        node.state == .locked ? [] : .isButton
    }

    // MARK: - Body

    public var body: some View {
        Button {
            tapTrigger.toggle()
            onTap?()
        } label: {
            VStack(spacing: theme.spacing.xs) {
                ZStack {
                    if node.state == .active || node.state == .inProgress {
                        activeGlowBackground
                    }

                    nodeFace
                }
                .frame(width: currentDiameter, height: currentDiameter)

                if node.state == .active || node.state == .inProgress {
                    activeStartTag
                }
            }
        }
        .buttonStyle(JourneyNodeButtonStyle(isLocked: node.state == .locked))
        .disabled(node.state == .locked && onTap == nil)
        .sensoryFeedback(.impact(weight: .medium), trigger: tapTrigger)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - Node Face

    @ViewBuilder
    private var nodeFace: some View {
        ZStack {
            faceBackgroundView

            Image(systemName: displayedIconName)
                .font(.system(size: iconSize, weight: (node.state == .active || node.state == .inProgress) ? .bold : .semibold))
                .foregroundStyle(iconForegroundColor)
        }
        .frame(width: currentDiameter, height: currentDiameter)
        .opacity(node.state == .locked ? 0.8 : 1.0)
        .overlay(alignment: .bottomTrailing) {
            if node.state == .completed {
                completedCheckmarkBadge
                    .offset(x: 4, y: 4)
            }
        }
    }

    // MARK: - Shape Helper

    private var squircleShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 28 * baseScale, style: .continuous)
    }

    // MARK: - Face Background View

    @ViewBuilder
    private var faceBackgroundView: some View {
        switch effectiveSurfaceStyle {
        case .glass:
            glassFace
        case .elevated:
            elevatedFace
        case .outlined:
            outlinedFace
        case .flat:
            flatFace
        case .tactile3D:
            tactile3DFace
        }
    }

    // MARK: - Surface Style Faces

    private var glassFace: some View {
        ZStack {
            squircleShape
                .fill(.ultraThinMaterial)

            switch node.state {
            case .active, .inProgress:
                squircleShape
                    .fill(theme.colors.brandPrimary.opacity(0.25))
            case .completed:
                squircleShape
                    .fill(theme.colors.statusSuccess.opacity(0.18))
            case .bonus:
                squircleShape
                    .fill(theme.colors.accent.opacity(0.20))
            case .upcoming, .locked:
                squircleShape
                    .fill(theme.colors.surfaceSubtle.opacity(theme.glass.tintOpacity))
            }

            squircleShape
                .strokeBorder(theme.glass.borderGradient, lineWidth: 1)
            squircleShape
                .strokeBorder(theme.depths.topHighlight, lineWidth: 0.8)
        }
        .craftShadow(theme.shadows.sm)
    }

    private var elevatedFace: some View {
        ZStack {
            switch node.state {
            case .active, .inProgress:
                squircleShape
                    .fill(theme.gradients.brandHero)
            case .completed:
                squircleShape
                    .fill(theme.colors.brandPrimary.opacity(0.12))
            case .bonus:
                squircleShape
                    .fill(theme.colors.accent.opacity(0.15))
            case .upcoming, .locked:
                squircleShape
                    .fill(theme.colors.surfaceElevated)
            }

            squircleShape
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .craftDynamic(light: Color.white.opacity(0.7), dark: Color.white.opacity(0.16)), location: 0.0),
                            .init(color: .craftDynamic(light: theme.colors.hairline.opacity(0.4), dark: Color.white.opacity(0.04)), location: 0.5),
                            .init(color: .clear, location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .craftShadow(node.state == .active || node.state == .inProgress ? theme.shadows.md : theme.shadows.sm)
    }

    private var outlinedFace: some View {
        ZStack {
            squircleShape
                .fill(theme.colors.surfaceCard)

            switch node.state {
            case .active, .inProgress:
                squircleShape
                    .strokeBorder(theme.colors.brandPrimary, lineWidth: 2)
            case .completed:
                squircleShape
                    .strokeBorder(theme.colors.statusSuccess, lineWidth: 1.5)
            case .bonus:
                squircleShape
                    .strokeBorder(theme.colors.accent, lineWidth: 1.5)
            case .upcoming, .locked:
                squircleShape
                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
            }
        }
    }

    private var flatFace: some View {
        ZStack {
            switch node.state {
            case .active, .inProgress:
                squircleShape
                    .fill(theme.gradients.brandHero)
            case .completed:
                squircleShape
                    .fill(theme.colors.brandPrimary.opacity(0.12))
            case .bonus:
                squircleShape
                    .fill(theme.colors.accent.opacity(0.15))
            case .upcoming, .locked:
                squircleShape
                    .fill(theme.colors.surfaceSubtle)
            }
        }
    }

    private var tactile3DFace: some View {
        ZStack {
            switch node.state {
            case .active, .inProgress:
                squircleShape
                    .fill(theme.gradients.brandHero)

                squircleShape
                    .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
            case .completed:
                squircleShape
                    .fill(theme.colors.brandPrimary.opacity(0.12))

                squircleShape
                    .strokeBorder(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)
            case .bonus:
                squircleShape
                    .fill(theme.colors.accent.opacity(0.15))

                squircleShape
                    .strokeBorder(theme.colors.accent.opacity(0.3), lineWidth: 1.5)
            case .upcoming, .locked:
                squircleShape
                    .fill(theme.colors.surfaceSubtle)

                squircleShape
                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
            }
        }
        .shadow(
            color: (node.state == .active || node.state == .inProgress)
                ? theme.colors.brandPrimary.opacity(0.40)
                : (node.state == .completed ? theme.colors.brandPrimary.opacity(0.08) : Color.clear),
            radius: (node.state == .active || node.state == .inProgress) ? 12 : 6,
            x: 0,
            y: (node.state == .active || node.state == .inProgress) ? 5 : 3
        )
    }

    // MARK: - Foreground Colors

    private var iconForegroundColor: Color {
        switch node.state {
        case .active, .inProgress:
            switch effectiveSurfaceStyle {
            case .outlined, .glass:
                return theme.colors.brandPrimary
            case .elevated, .flat, .tactile3D:
                return theme.colors.textInverse
            }
        case .completed:
            return theme.colors.brandPrimary
        case .bonus:
            return theme.colors.accent
        case .upcoming:
            return theme.colors.textMuted
        case .locked:
            return theme.colors.textMuted.opacity(0.70)
        }
    }

    // MARK: - Checkmark Badge

    private var completedCheckmarkBadge: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surfaceCard)
                .frame(width: 24, height: 24)

            Circle()
                .fill(theme.colors.statusSuccess)
                .frame(width: 20, height: 20)

            Image(systemName: "checkmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.colors.textInverse)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Active Breathing Glow

    @ViewBuilder
    private var activeGlowBackground: some View {
        let haloSize = currentDiameter + 24
        let haloGradient = RadialGradient(
            colors: [
                theme.colors.brandPrimary.opacity(0.35),
                theme.colors.brandPrimary.opacity(0.12),
                Color.clear
            ],
            center: .center,
            startRadius: currentDiameter * 0.35,
            endRadius: haloSize * 0.5
        )

        let glowCornerRadius: CGFloat = 34 * baseScale

        if reduceMotion {
            RoundedRectangle(cornerRadius: glowCornerRadius, style: .continuous)
                .fill(haloGradient)
                .frame(width: haloSize, height: haloSize)
                .opacity(0.8)

            RoundedRectangle(cornerRadius: glowCornerRadius, style: .continuous)
                .stroke(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)
                .frame(width: haloSize, height: haloSize)
        } else {
            PhaseAnimator(GlowPhase.allCases) { phase in
                ZStack {
                    RoundedRectangle(cornerRadius: glowCornerRadius, style: .continuous)
                        .fill(haloGradient)
                        .frame(width: haloSize, height: haloSize)
                        .opacity(phase == .glowing ? 1.0 : 0.65)
                        .scaleEffect(phase == .glowing ? 1.05 : 0.98)

                    RoundedRectangle(cornerRadius: glowCornerRadius, style: .continuous)
                        .stroke(
                            theme.colors.brandPrimary.opacity(phase == .glowing ? 0.38 : 0.16),
                            lineWidth: 1.5
                        )
                        .frame(width: haloSize, height: haloSize)
                        .scaleEffect(phase == .glowing ? 1.04 : 0.98)
                }
            } animation: { _ in
                .craftGlow
            }
        }
    }

    // MARK: - Start Lesson Sub-tag

    private var activeStartTag: some View {
        Text(CraftLocalized.string("craft.fluid_journey.start_lesson").uppercased())
            .font(theme.typography.caption.weight(.bold))
            .foregroundStyle(theme.colors.textInverse)
            .padding(.horizontal, theme.spacing.md)
            .padding(.vertical, theme.spacing.xs)
            .background(
                Capsule()
                    .fill(theme.gradients.brandHero)
            )
            .overlay(
                Capsule()
                    .strokeBorder(theme.colors.textInverse.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: theme.colors.brandPrimary.opacity(0.35), radius: 6, x: 0, y: 3)
            .accessibilityHidden(true)
    }
}
