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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let count: Int
    public let tier: CraftStreakTier
    public let isCompletedToday: Bool
    public let size: CraftStreakBadgeSize
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onTap: (() -> Void)?

    @State private var isPulsing = false

    public init(
        count: Int,
        tier: CraftStreakTier? = nil,
        isCompletedToday: Bool = false,
        size: CraftStreakBadgeSize = .md,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.count = count
        self.tier = tier ?? CraftStreakTier.tier(for: count)
        self.isCompletedToday = isCompletedToday
        self.size = size
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
        HStack(spacing: 4) {
            // Flame Icon colored by Tier Gradient
            Image(systemName: CraftSymbol.streak.rawValue)
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundStyle(tierGradient)

            // Monospaced Digit Counter
            Text("\(count)")
                .font(size.font)
                .monospacedDigit()
                .foregroundStyle(theme.colors.textPrimary)
        }
        .padding(.horizontal, size.horizontalPadding)
        .frame(height: size.height)
        .background(pillBackground)
        .clipShape(Capsule())
        .overlay(pillBorder)
        .scaleEffect(!reduceMotion && !isCompletedToday && isPulsing ? 1.04 : 1.0)
        .opacity(!reduceMotion && !isCompletedToday && isPulsing ? 0.90 : 1.0)
        .onAppear {
            updatePulseAnimation()
        }
        .onChange(of: isCompletedToday) { _, _ in
            updatePulseAnimation()
        }
        .onChange(of: reduceMotion) { _, _ in
            updatePulseAnimation()
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
            return Color(hex: 0x8B5CF6)
        }
    }

    private func updatePulseAnimation() {
        if !reduceMotion && !isCompletedToday {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        } else {
            withAnimation(.easeOut(duration: 0.2)) {
                isPulsing = false
            }
        }
    }

    // MARK: - Accessibility Strings

    private var accessibilityLabelString: String {
        if let customAccessibilityLabel {
            return customAccessibilityLabel
        }
        let statusDescription = isCompletedToday ? "Hôm nay đã hoàn thành" : "Hôm nay chưa hoàn thành"
        return "Chuỗi \(count) ngày học liên tiếp, Cấp độ \(tier.rawValue). \(statusDescription)."
    }

    private var accessibilityHintString: String {
        if let customAccessibilityHint {
            return customAccessibilityHint
        }
        return onTap != nil ? "Chạm hai lần để xem chi tiết chuỗi ngày." : ""
    }
}

// MARK: - Previews

#Preview("CraftStreakBadge") {
    ScrollView {
        VStack(spacing: 28) {
            Text("Completed Today")
                .font(.headline)

            HStack(spacing: 16) {
                CraftStreakBadge(count: 3, tier: .starter, isCompletedToday: true, size: .sm)
                CraftStreakBadge(count: 14, tier: .blaze, isCompletedToday: true, size: .sm)
                CraftStreakBadge(count: 45, tier: .legendary, isCompletedToday: true, size: .sm)
            }

            HStack(spacing: 16) {
                CraftStreakBadge(count: 3, tier: .starter, isCompletedToday: true, size: .md)
                CraftStreakBadge(count: 14, tier: .blaze, isCompletedToday: true, size: .md)
                CraftStreakBadge(count: 45, tier: .legendary, isCompletedToday: true, size: .md)
            }

            Divider()

            Text("Pending Today (Breathing & Dashed)")
                .font(.headline)

            HStack(spacing: 16) {
                CraftStreakBadge(count: 3, tier: .starter, isCompletedToday: false, size: .sm)
                CraftStreakBadge(count: 14, tier: .blaze, isCompletedToday: false, size: .sm)
                CraftStreakBadge(count: 45, tier: .legendary, isCompletedToday: false, size: .sm)
            }

            HStack(spacing: 16) {
                CraftStreakBadge(count: 3, tier: .starter, isCompletedToday: false, size: .md)
                CraftStreakBadge(count: 14, tier: .blaze, isCompletedToday: false, size: .md)
                CraftStreakBadge(count: 45, tier: .legendary, isCompletedToday: false, size: .md)
            }
        }
        .padding()
    }
}
