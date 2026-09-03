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

/// A 3D tactile floating node within the fluid journey learning path.
///
/// Features 3 primary visual states:
/// - `.completed`: 68pt translucent mint disc with a checkmark badge (`✓`)
/// - `.active`: 82pt saturated hero orb with breathing glow (`PhaseAnimator`) and "START LESSON" sub-tag
/// - `.upcoming` / `.locked`: 60pt muted surface disc
public struct CraftJourneyNode: View, Equatable {
    public let node: LessonNodeModel
    public let onTap: (@Sendable () -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var baseScale: CGFloat = 1.0

    @State private var tapTrigger: Bool = false

    // MARK: - Initializer

    public init(node: LessonNodeModel, onTap: (@Sendable () -> Void)? = nil) {
        self.node = node
        self.onTap = onTap
    }

    public init(model: LessonNodeModel, onTap: (@Sendable () -> Void)? = nil) {
        self.init(node: model, onTap: onTap)
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftJourneyNode, rhs: CraftJourneyNode) -> Bool {
        lhs.node == rhs.node
    }

    // MARK: - Sizing Metrics

    /// Returns the standard unscaled diameter in points for a node in the given progression state.
    public static func diameter(for state: LessonNodeState) -> CGFloat {
        switch state {
        case .active, .inProgress:
            return 82
        case .completed:
            return 68
        case .upcoming, .locked, .bonus:
            return 60
        }
    }

    /// Dynamic scaled diameter accounting for user accessibility scale.
    public var currentDiameter: CGFloat {
        Self.diameter(for: node.state) * baseScale
    }

    /// Dynamic icon size proportional to node diameter.
    public var iconSize: CGFloat {
        let unscaled: CGFloat = switch node.state {
        case .active, .inProgress: 32
        case .completed: 26
        case .upcoming, .locked, .bonus: 22
        }
        return unscaled * baseScale
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

                    orbBody
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

    // MARK: - Orb Body

    @ViewBuilder
    private var orbBody: some View {
        ZStack {
            switch node.state {
            case .completed:
                completedOrb
            case .active, .inProgress:
                activeOrb
            case .upcoming, .locked, .bonus:
                mutedOrb
            }
        }
        .frame(width: currentDiameter, height: currentDiameter)
        .overlay(alignment: .bottomTrailing) {
            if node.state == .completed {
                completedCheckmarkBadge
                    .offset(x: theme.spacing.xxs, y: theme.spacing.xxs)
            }
        }
    }

    // MARK: - Completed Orb

    private var completedOrb: some View {
        ZStack {
            Circle()
                .fill(theme.colors.brandPrimary.opacity(0.12))

            Circle()
                .strokeBorder(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)

            Image(systemName: displayedIconName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(theme.colors.brandPrimary)
        }
        .shadow(color: theme.colors.brandPrimary.opacity(0.08), radius: 6, x: 0, y: 3)
    }

    // MARK: - Active Hero Orb

    private var activeOrb: some View {
        ZStack {
            Circle()
                .fill(theme.gradients.brandHero)

            Circle()
                .strokeBorder(theme.depths.topHighlight, lineWidth: 1.5)

            Image(systemName: displayedIconName)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(theme.colors.textInverse)
        }
        .shadow(color: theme.colors.brandPrimary.opacity(0.40), radius: 14, x: 0, y: 6)
    }

    // MARK: - Muted Upcoming / Locked Orb

    private var mutedOrb: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surfaceSubtle)

            Circle()
                .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)

            Image(systemName: displayedIconName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(theme.colors.textMuted)
        }
        .opacity(node.state == .locked ? 0.6 : 0.85)
    }

    // MARK: - Checkmark Badge

    private var completedCheckmarkBadge: some View {
        ZStack {
            Circle()
                .fill(theme.colors.surfaceCard)
                .frame(width: 24, height: 24)

            Circle()
                .fill(theme.colors.statusSuccess)
                .frame(width: 22, height: 22)

            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(theme.colors.textInverse)
        }
        .accessibilityHidden(true)
    }

    // MARK: - Active Breathing Glow

    @ViewBuilder
    private var activeGlowBackground: some View {
        let haloSize = currentDiameter + 28
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

        if reduceMotion {
            Circle()
                .fill(haloGradient)
                .frame(width: haloSize, height: haloSize)
                .opacity(0.8)

            Circle()
                .stroke(theme.colors.brandPrimary.opacity(0.25), lineWidth: 1.5)
                .frame(width: haloSize, height: haloSize)
        } else {
            PhaseAnimator(GlowPhase.allCases) { phase in
                ZStack {
                    Circle()
                        .fill(haloGradient)
                        .frame(width: haloSize, height: haloSize)
                        .opacity(phase == .glowing ? 1.0 : 0.65)
                        .scaleEffect(phase == .glowing ? 1.06 : 0.96)

                    Circle()
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

    // MARK: - Helpers

    private var displayedIconName: String {
        if node.state == .locked {
            return "lock.fill"
        }
        return node.iconName.isEmpty ? "book.fill" : node.iconName
    }
}
