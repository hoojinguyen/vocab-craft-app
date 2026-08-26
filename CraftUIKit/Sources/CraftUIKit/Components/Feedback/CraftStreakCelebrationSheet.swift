import SwiftUI

// MARK: - CraftStreakCelebrationSheet Component

/// A celebratory modal sheet presented when the user extends or hits a milestone streak.
/// Features a pop-in hero flame icon, particle effects (sparkles/confetti), count-up animation,
/// mini 7-day progress track, motivational badge/messages, and a primary action button.
public struct CraftStreakCelebrationSheet: View {
    public let currentStreak: Int
    public let previousStreak: Int
    public let weekDays: [CraftStreakDay]
    public let surfaceStyle: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onContinue: () -> Void

    /// Visual tier derived from the current streak count.
    public var tier: CraftStreakTier {
        CraftStreakTier.tier(for: currentStreak)
    }

    /// Indicates whether this streak increment represents a significant milestone.
    public var isMilestone: Bool {
        let milestoneDays: Set<Int> = [7, 14, 21, 30, 50, 60, 90, 100, 180, 365]
        let tierChanged = CraftStreakTier.tier(for: currentStreak) != CraftStreakTier.tier(for: previousStreak)
        return milestoneDays.contains(currentStreak) || (currentStreak > 0 && currentStreak % 50 == 0) || tierChanged
    }

    public init(
        currentStreak: Int,
        previousStreak: Int,
        weekDays: [CraftStreakDay] = [],
        surfaceStyle: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.currentStreak = currentStreak
        self.previousStreak = previousStreak
        self.weekDays = weekDays
        self.surfaceStyle = surfaceStyle
        self.customAccessibilityLabel = accessibilityLabel
        self.customAccessibilityHint = accessibilityHint
        self.onContinue = onContinue
    }

    public var body: some View {
        CraftCelebrationSheet(
            currentValue: currentStreak,
            previousValue: previousStreak,
            unitKey: "craft.streak.daysUnit",
            unit: "ngày",
            cycleDays: weekDays.map(\.asActivityDay),
            icon: .system(CraftSymbol.streak.rawValue),
            surfaceStyle: surfaceStyle,
            accessibilityLabel: customAccessibilityLabel,
            accessibilityHint: customAccessibilityHint,
            onContinue: onContinue
        )
    }
}

// MARK: - Previews

#Preview("Celebration Sheet - Milestone 7") {
    let mockDays: [CraftStreakDay] = [
        .init(id: "1", weekdaySymbol: "T2", status: .completed),
        .init(id: "2", weekdaySymbol: "T3", status: .completed),
        .init(id: "3", weekdaySymbol: "T4", status: .completed),
        .init(id: "4", weekdaySymbol: "T5", status: .completed),
        .init(id: "5", weekdaySymbol: "T6", status: .completed),
        .init(id: "6", weekdaySymbol: "T7", status: .completed),
        .init(id: "7", weekdaySymbol: "CN", status: .completed, isToday: true)
    ]

    CraftStreakCelebrationSheet(
        currentStreak: 7,
        previousStreak: 6,
        weekDays: mockDays,
        onContinue: {}
    )
    .padding()
}
