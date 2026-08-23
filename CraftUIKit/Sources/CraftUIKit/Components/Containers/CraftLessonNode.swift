import SwiftUI

// MARK: - Accessibility Traits Extension

extension AccessibilityTraits {
    /// Inactive element representation with no interactive button traits.
    static let notEnabled: AccessibilityTraits = []
}

// MARK: - CraftLessonNode Component

/// An atom view representing an individual circular lesson node within a learning journey path.
///
/// Supports 6 distinct progression states (`completed`, `active`, `inProgress`, `upcoming`, `locked`, `bonus`)
/// with PhaseAnimator glow pulsing, SF Symbol transitions, badge counters, sensory haptic feedback,
/// and full HIG / VoiceOver accessibility compliance.
public struct CraftLessonNode: View, Equatable {
    public let model: LessonNodeModel
    public let onTap: (@Sendable () -> Void)?

    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var baseScale: CGFloat = 1.0

    @State private var tapTrigger: Bool = false
    @State private var completionTrigger: Bool = false
    @State private var lockedAttemptTrigger: Bool = false

    // MARK: - Initializer

    public init(
        model: LessonNodeModel,
        onTap: (@Sendable () -> Void)? = nil
    ) {
        self.model = model
        self.onTap = onTap
    }

    // MARK: - Equatable Conformance

    public static func == (lhs: CraftLessonNode, rhs: CraftLessonNode) -> Bool {
        lhs.model == rhs.model
    }

    // MARK: - Computed Sizing

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

    // MARK: - Accessibility Helpers

    public var accessibilityLabelText: String {
        switch model.state {
        case .completed:
            return "Lesson: \(model.title), Completed"
        case .active:
            if let progress = model.progress {
                let percent = Int((progress * 100).rounded())
                return "Lesson: \(model.title), Current lesson. \(percent)% complete"
            }
            return "Lesson: \(model.title), Current lesson"
        case .inProgress:
            if let progress = model.progress {
                let percent = Int((progress * 100).rounded())
                return "Lesson: \(model.title), In progress. \(percent)% complete"
            }
            return "Lesson: \(model.title), In progress"
        case .upcoming:
            return "Lesson: \(model.title), Upcoming lesson"
        case .locked:
            return "Lesson: \(model.title), Locked"
        case .bonus:
            return "Bonus Lesson: \(model.title)"
        }
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
        Group {
            if let onTap {
                Button {
                    handleTap()
                    onTap()
                } label: {
                    nodeLayout
                }
                .buttonStyle(.craftPress(scale: 0.94))
            } else {
                nodeLayout
                    .onTapGesture {
                        handleTap()
                    }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: tapTrigger)
        .sensoryFeedback(.success, trigger: completionTrigger)
        .sensoryFeedback(.error, trigger: lockedAttemptTrigger)
        .sensoryFeedback(.selection, trigger: model.badgeCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(accessibilityTraits)
    }

    // MARK: - Node Layout

    private var nodeLayout: some View {
        ZStack {
            // Active outer glow ring via PhaseAnimator
            if model.state == .active {
                activeGlowRing
            }

            // Main node circle
            mainNodeCircle
        }
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Circle())
    }

    // MARK: - Main Node Circle

    private var mainNodeCircle: some View {
        ZStack {
            // Background fill & border styling
            nodeBackground

            // State-specific overlays (e.g. progress arc)
            if model.state == .inProgress {
                progressArc
            }

            // Icon content
            nodeIcon
        }
        .frame(width: nodeDiameter, height: nodeDiameter)
        .opacity(model.state == .locked ? 0.6 : 1.0)
        .overlay(alignment: .topTrailing) {
            badgeOverlay
        }
    }

    // MARK: - Node Background

    @ViewBuilder
    private var nodeBackground: some View {
        switch model.state {
        case .completed:
            Circle()
                .fill(theme.colors.statusSuccess)
                .craftShadow(theme.shadows.md)

        case .active:
            Circle()
                .fill(theme.gradients.brandHero)
                .shadow(color: theme.colors.brandPrimary.opacity(0.25), radius: 12, x: 0, y: 4)

        case .inProgress:
            Circle()
                .fill(theme.colors.surfaceElevated)
                .craftShadow(theme.shadows.sm)

        case .upcoming:
            Circle()
                .fill(theme.colors.surfaceSubtle)
                .overlay(
                    Circle()
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                )

        case .locked:
            Circle()
                .fill(theme.colors.surfaceSubtle)
                .overlay(
                    Circle()
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                )

        case .bonus:
            Circle()
                .fill(theme.gradients.accentShine)
                .craftShimmer(isActive: !reduceMotion)
                .shadow(color: theme.colors.accent.opacity(0.35), radius: 8, x: 0, y: 2)
        }
    }

    // MARK: - Active Glow Ring

    @ViewBuilder
    private var activeGlowRing: some View {
        if reduceMotion {
            Circle()
                .stroke(theme.colors.brandPrimary.opacity(0.35), lineWidth: 3)
                .frame(width: nodeDiameter + 10, height: nodeDiameter + 10)
        } else {
            PhaseAnimator(GlowPhase.allCases) { phase in
                Circle()
                    .stroke(
                        theme.colors.brandPrimary.opacity(phase == .glowing ? 0.45 : 0.2),
                        lineWidth: 3
                    )
                    .frame(width: nodeDiameter + 12, height: nodeDiameter + 12)
                    .scaleEffect(phase == .glowing ? 1.08 : 1.0)
            } animation: { _ in
                .craftGlow
            }
        }
    }

    // MARK: - Progress Arc

    private var progressArc: some View {
        let clampedProgress = min(max(model.progress ?? 0.0, 0.0), 1.0)
        return ZStack {
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
    }

    // MARK: - Icon

    private var effectiveIconName: String {
        switch model.state {
        case .completed:
            return "checkmark"
        case .locked:
            return "lock.fill"
        case .bonus:
            return model.iconName.isEmpty ? "star.fill" : model.iconName
        case .active, .inProgress, .upcoming:
            return model.iconName.isEmpty ? "book.fill" : model.iconName
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

    private var nodeIcon: some View {
        Image(systemName: effectiveIconName)
            .font(.system(size: iconSize, weight: .bold))
            .foregroundStyle(iconColor)
            .contentTransition(.symbolEffect(.replace))
            .symbolEffect(.pulse.byLayer, isActive: model.state == .active && !reduceMotion)
            .symbolEffect(.bounce, value: model.state == .completed)
            .symbolEffectsRemoved(reduceMotion)
    }

    // MARK: - Badge Overlay

    @ViewBuilder
    private var badgeOverlay: some View {
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
    }
}

// MARK: - Preview

#Preview("CraftLessonNode States") {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            CraftLessonNode(
                model: LessonNodeModel(
                    id: "1",
                    title: "Basics 1",
                    iconName: "book.fill",
                    state: .completed
                )
            )

            CraftLessonNode(
                model: LessonNodeModel(
                    id: "2",
                    title: "Basics 2",
                    iconName: "flame.fill",
                    state: .active,
                    progress: 0.6,
                    badgeCount: 3
                )
            )

            CraftLessonNode(
                model: LessonNodeModel(
                    id: "3",
                    title: "Phrases",
                    iconName: "quote.bubble.fill",
                    state: .inProgress,
                    progress: 0.4
                )
            )
        }

        HStack(spacing: 24) {
            CraftLessonNode(
                model: LessonNodeModel(
                    id: "4",
                    title: "Grammar",
                    iconName: "pencil",
                    state: .upcoming
                )
            )

            CraftLessonNode(
                model: LessonNodeModel(
                    id: "5",
                    title: "Advanced",
                    iconName: "lock",
                    state: .locked
                )
            )

            CraftLessonNode(
                model: LessonNodeModel(
                    id: "6",
                    title: "Bonus Challenge",
                    iconName: "crown.fill",
                    state: .bonus,
                    badgeText: "HOT"
                )
            )
        }
    }
    .padding()
}
