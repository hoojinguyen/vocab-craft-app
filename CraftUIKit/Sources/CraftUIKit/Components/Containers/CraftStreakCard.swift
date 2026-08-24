import SwiftUI

// MARK: - CraftStreakCard Component

/// A 7-day Bento dashboard widget displaying the user's streak flame, current tier,
/// weekly cycle track, freeze shield counter, and milestone progress.
public struct CraftStreakCard: View {
    public let data: CraftStreakData
    public let cardStyle: CraftCardStyle
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onFreezeTap: (() -> Void)?
    public let onMilestoneTap: (() -> Void)?

    public init(
        data: CraftStreakData,
        cardStyle: CraftCardStyle = .outlined,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onFreezeTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil
    ) {
        self.data = data
        self.cardStyle = cardStyle
        self.customAccessibilityLabel = accessibilityLabel
        self.customAccessibilityHint = accessibilityHint
        self.onFreezeTap = onFreezeTap
        self.onMilestoneTap = onMilestoneTap
    }

    public var body: some View {
        CraftActivityTrackerCard(
            data: data.asActivityTrackerData,
            cardStyle: cardStyle,
            icon: .system(CraftSymbol.streak.rawValue),
            accessibilityLabel: customAccessibilityLabel,
            accessibilityHint: customAccessibilityHint,
            onShieldTap: onFreezeTap,
            onMilestoneTap: onMilestoneTap
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
