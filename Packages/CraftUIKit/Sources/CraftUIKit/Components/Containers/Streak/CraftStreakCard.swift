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

#if canImport(PreviewsMacros)
#Preview("CraftStreakCard - All 6 Surface Styles (Light)") {
    let mockDays: [CraftStreakDay] = [
        .init(id: "1", weekdaySymbol: "T2", status: .completed),
        .init(id: "2", weekdaySymbol: "T3", status: .completed),
        .init(id: "3", weekdaySymbol: "T4", status: .frozen),
        .init(id: "4", weekdaySymbol: "T5", status: .pending, isToday: true),
        .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
        .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
        .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
    ]

    let starterData = CraftStreakData(
        currentStreak: 3,
        bestStreak: 7,
        freezeTokens: 1,
        maxFreezeTokens: 2,
        nextMilestoneDays: 7,
        isCompletedToday: false,
        weekDays: mockDays
    )

    let blazeData = CraftStreakData(
        currentStreak: 14,
        bestStreak: 30,
        freezeTokens: 2,
        maxFreezeTokens: 3,
        nextMilestoneDays: 21,
        isCompletedToday: false,
        weekDays: mockDays
    )

    let legendaryData = CraftStreakData(
        currentStreak: 45,
        bestStreak: 60,
        freezeTokens: 3,
        maxFreezeTokens: 3,
        nextMilestoneDays: 50,
        isCompletedToday: true,
        weekDays: mockDays
    )

    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            // 1. Flat
            VStack(alignment: .leading, spacing: 8) {
                Text("1. Flat Style (.flat)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                CraftStreakCard(
                    data: starterData,
                    cardStyle: .flat,
                    onTap: { print("Flat card tapped") },
                    onFreezeTap: { print("Freeze tapped") },
                    onMilestoneTap: { print("Milestone tapped") },
                    onDayTap: { day in print("Day tapped: \(day.weekdaySymbol)") }
                )
            }

            // 2. Elevated
            VStack(alignment: .leading, spacing: 8) {
                Text("2. Elevated Style (.elevated)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                CraftStreakCard(
                    data: blazeData,
                    cardStyle: .elevated,
                    onTap: { print("Elevated card tapped") },
                    onFreezeTap: { print("Freeze tapped") },
                    onMilestoneTap: { print("Milestone tapped") },
                    onDayTap: { day in print("Day tapped: \(day.weekdaySymbol)") }
                )
            }

            // 3. Outlined
            VStack(alignment: .leading, spacing: 8) {
                Text("3. Outlined Style (.outlined)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                CraftStreakCard(
                    data: starterData,
                    cardStyle: .outlined,
                    onTap: { print("Outlined card tapped") },
                    onFreezeTap: { print("Freeze tapped") },
                    onMilestoneTap: { print("Milestone tapped") },
                    onDayTap: { day in print("Day tapped: \(day.weekdaySymbol)") }
                )
            }

            // 4. Gradient
            VStack(alignment: .leading, spacing: 8) {
                Text("4. Gradient Style (.gradient)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                CraftStreakCard(
                    data: legendaryData,
                    cardStyle: .gradient,
                    onTap: { print("Gradient card tapped") },
                    onFreezeTap: { print("Freeze tapped") },
                    onMilestoneTap: { print("Milestone tapped") },
                    onDayTap: { day in print("Day tapped: \(day.weekdaySymbol)") }
                )
            }

            // 5. Tactile 3D
            VStack(alignment: .leading, spacing: 8) {
                Text("5. Tactile 3D Style (.tactile3D)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                CraftStreakCard(
                    data: blazeData,
                    cardStyle: .tactile3D,
                    onTap: { print("Tactile 3D card tapped") },
                    onFreezeTap: { print("Freeze tapped") },
                    onMilestoneTap: { print("Milestone tapped") },
                    onDayTap: { day in print("Day tapped: \(day.weekdaySymbol)") }
                )
            }

            // 6. Liquid Glass
            VStack(alignment: .leading, spacing: 8) {
                Text("6. Liquid Glass Style (.glass)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
                CraftStreakCard(
                    data: legendaryData,
                    cardStyle: .glass,
                    onTap: { print("Glass card tapped") },
                    onFreezeTap: { print("Freeze tapped") },
                    onMilestoneTap: { print("Milestone tapped") },
                    onDayTap: { day in print("Day tapped: \(day.weekdaySymbol)") }
                )
            }
        }
        .padding()
    }
}
#endif

#if canImport(PreviewsMacros)
#Preview("CraftStreakCard - All 6 Surface Styles (Dark)") {
    let mockDays: [CraftStreakDay] = [
        .init(id: "1", weekdaySymbol: "T2", status: .completed),
        .init(id: "2", weekdaySymbol: "T3", status: .completed),
        .init(id: "3", weekdaySymbol: "T4", status: .frozen),
        .init(id: "4", weekdaySymbol: "T5", status: .pending, isToday: true),
        .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
        .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
        .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
    ]

    let blazeData = CraftStreakData(
        currentStreak: 14,
        bestStreak: 30,
        freezeTokens: 2,
        maxFreezeTokens: 3,
        nextMilestoneDays: 21,
        isCompletedToday: false,
        weekDays: mockDays
    )

    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(CraftCardStyle.allCases, id: \.self) { style in
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(style.rawValue.capitalized) Style (.\(style.rawValue))")
                        .font(.system(.caption, design: .rounded, weight: .bold))
                        .foregroundStyle(.secondary)
                    CraftStreakCard(
                        data: blazeData,
                        cardStyle: style,
                        onTap: { print("\(style) tapped") },
                        onFreezeTap: { print("Freeze tapped") },
                        onMilestoneTap: { print("Milestone tapped") },
                        onDayTap: { day in print("Day: \(day.weekdaySymbol)") }
                    )
                }
            }
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
#endif

