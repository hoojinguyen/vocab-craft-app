import CraftUIKit
import SwiftUI

/// Compact 7-day streak strip for homepage — shows weekday dots, not full Bento card.
/// Designed for 1-glance “mai mất streak” urgency.
public struct StreakWeekStripView: View {
    public let streakDays: Int
    public let isCompletedToday: Bool

    @Environment(\.craftTheme) private var theme

    public init(streakDays: Int, isCompletedToday: Bool) {
        self.streakDays = streakDays
        self.isCompletedToday = isCompletedToday
    }

    private var weekDays: [CraftStreakDay] {
        // Vietnamese weekday symbols Mon-Sun
        let symbols = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
        // Determine how many of last 7 days are considered completed.
        // For demo: streakDays % 7 gives completed in current week; if completedToday true, last dot is completed.
        let completedInWeek = min(7, streakDays % 7 + (isCompletedToday ? 1 : 0))
        // Edge: if streak >=7, show 6 completed + today pending/completed
        let effectiveCompleted = streakDays >= 7 ? (isCompletedToday ? 7 : 6) : completedInWeek
        return (0..<7).map { idx in
            let isToday = idx == 6
            let status: CraftStreakDayStatus
            if idx < effectiveCompleted {
                status = .completed
            } else if isToday && !isCompletedToday {
                status = .pending
            } else if idx == 3 && streakDays >= 14 && !isCompletedToday {
                // Demo freeze example for long streaks
                status = .frozen
            } else {
                status = .upcoming
            }
            return CraftStreakDay(
                id: "d\(idx)",
                weekdaySymbol: symbols[idx],
                status: status,
                isToday: isToday
            )
        }
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDays) { day in
                VStack(spacing: 4) {
                    Text(day.weekdaySymbol)
                        .font(.system(size: 10, weight: day.isToday ? .bold : .medium))
                        .foregroundStyle(day.isToday ? theme.colors.textPrimary : theme.colors.textMuted)

                    dayNode(for: day)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.lg)
                .fill(theme.colors.surfaceCard.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radii.lg)
                        .strokeBorder(theme.colors.hairline, lineWidth: 1)
                )
        )
        .craftShadow(theme.shadows.sm)
        .padding(.horizontal, theme.spacing.base)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(String(localized: "app.home.streak.week_a11y", defaultValue: "Chuỗi \(streakDays) ngày", bundle: .module)))
    }

    @ViewBuilder
    private func dayNode(for day: CraftStreakDay) -> some View {
        let size: CGFloat = 28
        switch day.status {
        case .completed:
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: size, height: size)
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(
                Circle()
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
            )
        case .frozen:
            ZStack {
                Circle()
                    .fill(theme.colors.streakFreeze.opacity(0.18))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.streakFreeze.opacity(0.3), lineWidth: 1)
                    )
                Image(systemName: "snowflake")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.colors.streakFreeze)
            }
        case .pending:
            Circle()
                .strokeBorder(theme.colors.brandPrimary, style: StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(theme.colors.brandPrimary.opacity(0.12))
                        .frame(width: size - 4, height: size - 4)
                )
                .overlay(
                    Image(systemName: "exclamationmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(theme.colors.brandPrimary)
                )
        case .upcoming:
            Circle()
                .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                .frame(width: size, height: size)
        case .missed:
            Circle()
                .fill(theme.colors.surfaceSubtle)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .fill(theme.colors.textMuted.opacity(0.4))
                        .frame(width: 4, height: 4)
                )
        }
    }
}

#if canImport(PreviewsMacros)
#Preview("StreakWeekStrip") {
    VStack(spacing: 16) {
        StreakWeekStripView(streakDays: 14, isCompletedToday: false)
        StreakWeekStripView(streakDays: 3, isCompletedToday: true)
        StreakWeekStripView(streakDays: 45, isCompletedToday: false)
    }
    .padding()
    .background(Color.vocabCanvas)
}
#endif
