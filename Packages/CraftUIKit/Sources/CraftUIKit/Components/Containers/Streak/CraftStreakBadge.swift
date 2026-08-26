import SwiftUI

// MARK: - Badge Size Enum

/// Size options for `CraftStreakBadge`.
public enum CraftStreakBadgeSize: String, Sendable, CaseIterable, Equatable {
    case sm
    case md

    /// Badge height in points.
    public var height: CGFloat {
        switch self {
        case .sm: return 32
        case .md: return 40
        }
    }

    /// Icon point size for the streak flame.
    public var iconSize: CGFloat {
        switch self {
        case .sm: return 13
        case .md: return 16
        }
    }

    /// Horizontal padding in points.
    public var horizontalPadding: CGFloat {
        switch self {
        case .sm: return 10
        case .md: return 14
        }
    }

    /// Font token for the streak counter.
    public var font: Font {
        switch self {
        case .sm:
            return .system(.caption, design: .rounded, weight: .bold)
        case .md:
            return .system(.callout, design: .rounded, weight: .bold)
        }
    }
}

// MARK: - CraftStreakBadge Component

/// A compact, HIG-compliant flame streak badge used in navigation bars and header views.
public struct CraftStreakBadge: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public let count: Int
    public let tier: CraftStreakTier
    public let isCompletedToday: Bool
    public let size: CraftStreakBadgeSize
    public let style: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onTap: (() -> Void)?

    public init(
        count: Int,
        tier: CraftStreakTier? = nil,
        isCompletedToday: Bool = false,
        size: CraftStreakBadgeSize = .md,
        style: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.count = count
        self.tier = tier ?? CraftStreakTier.tier(for: count)
        self.isCompletedToday = isCompletedToday
        self.size = size
        self.style = style
        self.customAccessibilityLabel = accessibilityLabel
        self.customAccessibilityHint = accessibilityHint
        self.onTap = onTap
    }

    public var body: some View {
        if let onTap {
            Button(action: onTap) {
                badgePill
            }
            .buttonStyle(.craftPress(scale: 0.96))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(accessibilityLabelString)
            .accessibilityHint(accessibilityHintString)
        } else {
            badgePill
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabelString)
                .accessibilityHint(accessibilityHintString)
        }
    }

    // MARK: - Badge Pill Content

    private var badgePill: some View {
        let content = HStack(spacing: 4) {
            // Flame Icon colored by Tier Gradient with SF Symbol Pulse Effect
            Image(systemName: CraftSymbol.streak.rawValue)
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundStyle(tierGradient)
                .symbolEffect(.pulse.byLayer, options: .repeating, isActive: !isCompletedToday && !reduceMotion)

            // Monospaced Digit Counter
            Text(verbatim: "\(count)")
                .font(size.font)
                .monospacedDigit()
                .foregroundStyle(theme.colors.textPrimary)
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size == .sm ? 4 : 6)
        .frame(minHeight: size.height)

        return surfaceDecorated(content)
    }

    // MARK: - Surface Decoration

    @ViewBuilder
    private func surfaceDecorated<V: View>(_ content: V) -> some View {
        if let resolvedStyle {
            content.craftSurface(
                style: resolvedStyle,
                shape: Capsule(),
                customTint: surfaceTint(for: resolvedStyle),
                depth: theme.depths.depthSm
            )
        } else {
            content
                .background(pillBackground)
                .clipShape(Capsule())
                .overlay(pillBorder)
                .overlay(
                    Capsule()
                        .strokeBorder(theme.depths.topHighlight, lineWidth: 1.0)
                )
                .craftShadow(isCompletedToday ? theme.shadows.sm : CraftShadow(color: .clear, radius: 0))
        }
    }

    private var resolvedStyle: CraftSurfaceStyle? {
        if let style {
            return style
        }
        if environmentSurfaceStyle != .flat {
            return environmentSurfaceStyle
        }
        return nil
    }

    private func surfaceTint(for style: CraftSurfaceStyle) -> Color? {
        switch style {
        case .glass:
            return tierBaseColor
        case .flat:
            return isCompletedToday ? tierBaseColor.opacity(0.12) : theme.colors.surfaceSubtle.opacity(0.60)
        case .elevated:
            return isCompletedToday ? tierBaseColor.opacity(0.08) : nil
        case .outlined:
            return isCompletedToday ? tierBaseColor.opacity(0.08) : nil
        case .tactile3D:
            return isCompletedToday ? tierBaseColor.opacity(0.12) : theme.colors.surfaceSubtle.opacity(0.50)
        }
    }

    // MARK: - Background & Border Views

    @ViewBuilder
    private var pillBackground: some View {
        if isCompletedToday {
            tierBaseColor.opacity(0.12)
        } else {
            theme.colors.surfaceSubtle.opacity(0.60)
        }
    }

    @ViewBuilder
    private var pillBorder: some View {
        if isCompletedToday {
            Capsule()
                .strokeBorder(tierBaseColor.opacity(0.24), lineWidth: 1.0)
        } else {
            Capsule()
                .strokeBorder(
                    theme.colors.streakPending.opacity(0.45),
                    style: StrokeStyle(lineWidth: 1.0, dash: [4, 3])
                )
        }
    }

    // MARK: - Visual Helpers

    private var tierGradient: LinearGradient {
        switch tier {
        case .starter:
            return theme.gradients.streakStarter
        case .blaze:
            return theme.gradients.streakBlaze
        case .legendary:
            return theme.gradients.streakLegendary
        }
    }

    private var tierBaseColor: Color {
        switch tier {
        case .starter:
            return theme.colors.brandPrimary
        case .blaze:
            return theme.colors.accent
        case .legendary:
            return theme.colors.statusDanger
        }
    }

    // MARK: - Accessibility Strings

    private var accessibilityLabelString: String {
        if let customAccessibilityLabel {
            return customAccessibilityLabel
        }
        let statusDescription = isCompletedToday
            ? CraftLocalized.string("craft.streak.today_completed")
            : CraftLocalized.string("craft.streak.today_pending")
        let tierKey: String
        switch tier {
        case .starter:
            tierKey = "craft.streak.tier_starter"
        case .blaze:
            tierKey = "craft.streak.tier_blaze"
        case .legendary:
            tierKey = "craft.streak.tier_legendary"
        }
        let tierName = CraftLocalized.string(tierKey)
        return CraftLocalized.format("craft.streak.badge_a11y_format", count, tierName, statusDescription)
    }

    private var accessibilityHintString: String {
        if let customAccessibilityHint {
            return customAccessibilityHint
        }
        return onTap != nil ? CraftLocalized.string("craft.streak.badge_a11y_hint") : ""
    }
}

#Preview("CraftStreakBadge") {
    VStack(spacing: 24) {
        HStack(spacing: 16) {
            CraftStreakBadge(count: 3, isCompletedToday: false, size: .sm)
            CraftStreakBadge(count: 7, isCompletedToday: true, size: .sm)
            CraftStreakBadge(count: 30, isCompletedToday: true, size: .sm)
        }

        HStack(spacing: 16) {
            CraftStreakBadge(count: 3, isCompletedToday: false, size: .md)
            CraftStreakBadge(count: 14, isCompletedToday: true, size: .md)
            CraftStreakBadge(count: 100, isCompletedToday: true, size: .md)
        }

        HStack(spacing: 16) {
            CraftStreakBadge(count: 7, isCompletedToday: true, size: .md, style: .glass)
            CraftStreakBadge(count: 14, isCompletedToday: true, size: .md, style: .elevated)
            CraftStreakBadge(count: 30, isCompletedToday: true, size: .md, style: .tactile3D)
        }
    }
    .padding()
}
