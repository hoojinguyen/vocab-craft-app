import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif
#if canImport(AppKit)
    import AppKit
#endif

// MARK: - Journey Node Button Style

/// Button style providing spring-based mechanical depress scale and tactile translation feedback for journey nodes.
private struct JourneyNodeButtonStyle: ButtonStyle {
    let isLocked: Bool
    let surfaceStyle: CraftSurfaceStyle
    let depth: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        let isDepressed = !isLocked && configuration.isPressed
        configuration.label
            .offset(y: (isDepressed && surfaceStyle == .tactile3D) ? depth : 0)
            .scaleEffect(isDepressed ? (surfaceStyle == .tactile3D ? 1.0 : 0.95) : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - CraftJourneyNode Component

/// An 88pt uniform continuous squircle floating node within the fluid journey learning path.
///
/// Features:
/// - 88pt unscaled diameter across all states (`RoundedRectangle(cornerRadius: 30, style: .continuous)`)
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
        88
    }

    /// Dynamic scaled diameter accounting for user accessibility scale.
    public var currentDiameter: CGFloat {
        Self.diameter(for: node.state) * baseScale
    }

    /// Dynamic icon size proportional to node diameter.
    public var iconSize: CGFloat {
        let unscaled: CGFloat =
            switch node.state {
            case .active, .inProgress: 34
            case .completed, .upcoming, .locked, .bonus: 32
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
                base = CraftLocalized.format(
                    "craft.learning_path.node_current_format_a11y", node.title, percent)
            } else {
                base = CraftLocalized.format("craft.learning_path.node_current_a11y", node.title)
            }
        case .inProgress:
            if let progress = node.progress {
                let percent = Int((progress * 100).rounded())
                base = CraftLocalized.format(
                    "craft.learning_path.node_in_progress_format_a11y", node.title, percent)
            } else {
                base = CraftLocalized.format(
                    "craft.learning_path.node_in_progress_a11y", node.title)
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
            nodeFaceView
                .frame(width: currentDiameter, height: currentDiameter)
        }
        .buttonStyle(
            JourneyNodeButtonStyle(
                isLocked: node.state == .locked,
                surfaceStyle: effectiveSurfaceStyle,
                depth: theme.depths.depthMd
            )
        )
        .disabled(node.state == .locked && onTap == nil)
        .sensoryFeedback(.impact(weight: .medium), trigger: tapTrigger)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - Node Face

    @ViewBuilder
    private var nodeFaceView: some View {
        if node.state == .active, !reduceMotion {
            PhaseAnimator(GlowPhase.allCases) { phase in
                nodeFace
                    .scaleEffect(1.0)
                    .shadow(
                        color: theme.colors.brandPrimary.opacity(phase == .glowing ? 0.45 : 0.20),
                        radius: phase == .glowing ? 10 : 5,
                        x: 0,
                        y: phase == .glowing ? 4 : 2
                    )
            } animation: { _ in
                .craftGlow
            }
        } else {
            nodeFace
        }
    }

    @ViewBuilder
    private var nodeFace: some View {
        ZStack {
            faceBackgroundView

            iconView
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

    private var iconFontWeight: Font.Weight {
        switch node.state {
        case .active, .inProgress, .completed:
            return .bold
        case .upcoming, .locked, .bonus:
            return .semibold
        }
    }

    /// Resolves the SF Symbol name, automatically preferring filled variants when available.
    public var resolvedIconName: String {
        let base = displayedIconName
        if base.hasSuffix(".fill") || base.contains(".fill.") {
            return base
        }
        let filled = "\(base).fill"
        #if canImport(UIKit)
            if UIImage(systemName: filled) != nil {
                return filled
            }
        #elseif canImport(AppKit)
            if NSImage(systemSymbolName: filled, accessibilityDescription: nil) != nil {
                return filled
            }
        #endif
        return base
    }

    private var iconView: some View {
        Image(systemName: resolvedIconName)
            .font(.system(size: iconSize, weight: iconFontWeight))
            .foregroundStyle(iconForegroundColor)
    }

    // MARK: - Shape Helper

    private var squircleShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 30 * baseScale, style: .continuous)
    }

    // MARK: - Face Backgrounds by Style

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
                    .fill(theme.colors.brandPrimary.opacity(0.18))

                squircleShape
                    .strokeBorder(theme.glass.borderGradient, lineWidth: 1.5)
            case .completed:
                squircleShape
                    .fill(theme.colors.brandPrimary.opacity(0.10))

                squircleShape
                    .strokeBorder(theme.colors.brandPrimary.opacity(0.3), lineWidth: 1)
            case .bonus:
                squircleShape
                    .fill(theme.colors.accent.opacity(0.15))

                squircleShape
                    .strokeBorder(theme.colors.accent.opacity(0.3), lineWidth: 1)
            case .upcoming, .locked:
                squircleShape
                    .fill(theme.colors.surfaceSubtle.opacity(0.6))

                squircleShape
                    .strokeBorder(theme.colors.borderDefault.opacity(0.5), lineWidth: 1)
            }
        }
        .craftShadow(
            node.state == .active || node.state == .inProgress ? theme.shadows.md : theme.shadows.sm
        )
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
                .strokeBorder(theme.depths.topHighlight, lineWidth: 1)
        }
        .craftShadow(
            node.state == .active || node.state == .inProgress ? theme.shadows.md : theme.shadows.sm
        )
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

    private var bottomRimShape: some View {
        squircleShape
            .fill(
                (node.state == .active || node.state == .inProgress || node.state == .completed)
                    ? theme.colors.brandPrimary.opacity(0.80)
                    : theme.colors.borderDefault
            )
            .offset(y: theme.depths.depthMd)
    }

    private var tactile3DFace: some View {
        ZStack {
            // 3D Bevel Extrusion Rim Layer
            bottomRimShape

            // Top Face Layer
            switch node.state {
            case .active, .inProgress:
                squircleShape
                    .fill(theme.gradients.brandHero)
            case .completed:
                // Opaque surfaceCard base prevents 3D rim bleedthrough
                squircleShape
                    .fill(theme.colors.surfaceCard)

                // Soft theme pastel wash matching current theme palette
                squircleShape
                    .fill(theme.colors.brandPrimary.opacity(0.08))

                squircleShape
                    .strokeBorder(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)
            case .bonus:
                squircleShape
                    .fill(theme.colors.surfaceCard)

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

            squircleShape
                .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)
        }
        .craftShadow(
            node.state == .active || node.state == .inProgress ? theme.shadows.md : theme.shadows.sm
        )
    }

    // MARK: - Foreground Colors

    private var iconForegroundColor: Color {
        switch node.state {
        case .active, .inProgress:
            return Color.white
        case .completed:
            return theme.colors.brandPrimary
        case .bonus:
            return theme.colors.accent
        case .upcoming, .locked:
            return theme.colors.textMuted
        }
    }

    // MARK: - Checkmark Badge

    private var completedCheckmarkBadge: some View {
        ZStack {
            Circle()
                .fill(theme.colors.statusSuccess)

            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .frame(width: 26, height: 26)
        .accessibilityHidden(true)
    }
}
