import SwiftUI

// MARK: - CraftStreakCard Component

/// A 7-day Bento dashboard widget displaying the user's streak flame, current tier,
/// weekly cycle track, freeze shield counter, and milestone progress.
public struct CraftStreakCard: View {
    public let data: CraftStreakData
    public let cardStyle: CraftCardStyle
    public let surfaceStyle: CraftSurfaceStyle?
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onTap: (() -> Void)?
    public let onFreezeTap: (() -> Void)?
    public let onMilestoneTap: (() -> Void)?
    public let onDayTap: ((CraftStreakDay) -> Void)?

    public init(
        data: CraftStreakData,
        cardStyle: CraftCardStyle = .outlined,
        surfaceStyle: CraftSurfaceStyle? = nil,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onTap: (() -> Void)? = nil,
        onFreezeTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftStreakDay) -> Void)? = nil
    ) {
        self.data = data
        self.surfaceStyle = surfaceStyle
        if let surfaceStyle {
            self.cardStyle = CraftCardStyle(surfaceStyle: surfaceStyle)
        } else {
            self.cardStyle = cardStyle
        }
        self.customAccessibilityLabel = accessibilityLabel
        self.customAccessibilityHint = accessibilityHint
        self.onTap = onTap
        self.onFreezeTap = onFreezeTap
        self.onMilestoneTap = onMilestoneTap
        self.onDayTap = onDayTap
    }

    public init(
        data: CraftStreakData,
        surfaceStyle: CraftSurfaceStyle,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onTap: (() -> Void)? = nil,
        onFreezeTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftStreakDay) -> Void)? = nil
    ) {
        self.init(
            data: data,
            cardStyle: CraftCardStyle(surfaceStyle: surfaceStyle),
            surfaceStyle: surfaceStyle,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            onTap: onTap,
            onFreezeTap: onFreezeTap,
            onMilestoneTap: onMilestoneTap,
            onDayTap: onDayTap
        )
    }

    public var body: some View {
        CraftActivityTrackerCard(
            data: data.asActivityTrackerData,
            cardStyle: cardStyle,
            surfaceStyle: surfaceStyle,
            icon: .system(CraftSymbol.streak.rawValue),
            accessibilityLabel: customAccessibilityLabel,
            accessibilityHint: customAccessibilityHint,
            onCardTap: onTap,
            onShieldTap: onFreezeTap,
            onMilestoneTap: onMilestoneTap,
            onDayTap: onDayTap.map { callback in
                { (activityDay: CraftActivityDay) in
                    if let streakDay = data.weekDays.first(where: { $0.id == activityDay.id }) {
                        callback(streakDay)
                    } else {
                        let streakStatus: CraftStreakDayStatus
                        switch activityDay.status {
                        case .completed: streakStatus = .completed
                        case .pending: streakStatus = .pending
                        case .saved: streakStatus = .frozen
                        case .missed: streakStatus = .missed
                        case .upcoming: streakStatus = .upcoming
                        }
                        let fallbackDay = CraftStreakDay(
                            id: activityDay.id,
                            weekdaySymbol: activityDay.weekdaySymbol,
                            status: streakStatus,
                            isToday: activityDay.isToday
                        )
                        callback(fallbackDay)
                    }
                }
            }
        )
    }
}

// MARK: - Previews

#Preview("CraftStreakCard") {
    let mockDays: [CraftStreakDay] = [
        .init(id: "1", weekdaySymbol: "T2", status: .completed),
        .init(id: "2", weekdaySymbol: "T3", status: .completed),
        .init(id: "3", weekdaySymbol: "T4", status: .frozen),
        .init(id: "4", weekdaySymbol: "T5", status: .pending, isToday: true),
        .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
        .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
        .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
    ]

    ScrollView {
        VStack(spacing: 24) {
            CraftStreakCard(
                data: CraftStreakData(
                    currentStreak: 14,
                    bestStreak: 30,
                    freezeTokens: 2,
                    maxFreezeTokens: 3,
                    nextMilestoneDays: 21,
                    isCompletedToday: false,
                    weekDays: mockDays
                ),
                onFreezeTap: {},
                onMilestoneTap: {}
            )
        }
        .padding()
    }
}
