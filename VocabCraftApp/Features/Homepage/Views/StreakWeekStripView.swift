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
        // Locale-aware weekday symbols for last 7 days ending today (trailing window)
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = calendar
        // Use veryShort or short symbols; fallback to short
        let baseSymbols = formatter.shortWeekdaySymbols ?? ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]
        // Generate 7 dates: today-6 .. today
        let today = Date()
        return (0..<7).map { idx in
            let daysAgo = 6 - idx
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                return CraftStreakDay(id: "d\(idx)", weekdaySymbol: baseSymbols[idx % baseSymbols.count], status: .upcoming, isToday: idx == 6)
            }
            let weekday = calendar.component(.weekday, from: date) // 1=Sun
            // baseSymbols is Sunday-first; index = weekday-1
            let symbol = baseSymbols[(weekday - 1) % baseSymbols.count]
            let isToday = idx == 6
            let status: CraftStreakDayStatus
            // Streak covers last `streakDays` days; today counts only if isCompletedToday
            let cappedStreak = min(7, streakDays)
            let isWithinStreak: Bool = {
                if isToday {
                    return isCompletedToday && cappedStreak > 0
                } else {
                    // For days before today, they are within streak if daysAgo < cappedStreak (+ adjust for today pending)
                    // If today pending, streak days are before today, so shift by 1
                    let effectiveStreak = isCompletedToday ? cappedStreak : min(6, cappedStreak)
                    // Count from today backwards: daysAgo 1..6
                    return daysAgo <= effectiveStreak && daysAgo > 0
                }
            }()
            // Special demo freeze: if long streak and today pending, show freeze at middle
            if isWithinStreak {
                status = .completed
            } else if isToday && !isCompletedToday {
                // Show pending for today, or frozen for demo long streak
                if streakDays >= 14 {
                    status = .frozen
                } else {
                    status = .pending
                }
            } else {
                status = .upcoming
            }
            return CraftStreakDay(
                id: "d\(idx)",
                weekdaySymbol: symbol,
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
        .accessibilityLabel(Text(String(format: String(localized: "app.home.streak.week_a11y", defaultValue: "Chuỗi %lld ngày", bundle: .module), streakDays)))
        .accessibilityValue(Text(weekDays.map { "\($0.weekdaySymbol) \(statusLabel(for: $0.status))" }.joined(separator: ", ")))
        .accessibilityHint(Text(String(localized: "app.home.streak.week_hint", defaultValue: "Nhấn để xem chi tiết chuỗi", bundle: .module)))
    }

    private func statusLabel(for status: CraftStreakDayStatus) -> String {
        switch status {
        case .completed: return CraftLocalized.string("craft.streak.day_status_completed")
        case .pending: return CraftLocalized.string("craft.streak.day_status_pending")
        case .frozen: return CraftLocalized.string("craft.streak.day_status_saved")
        case .missed: return CraftLocalized.string("craft.streak.day_status_missed")
        case .upcoming: return CraftLocalized.string("craft.streak.day_status_upcoming")
        }
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
    .background(CraftDefaultTheme().colors.canvasBackground)
}
#endif
