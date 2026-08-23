import SwiftUI

// MARK: - CraftStreakCard Component

/// A 7-day Bento dashboard widget displaying the user's streak flame, current tier,
/// weekly cycle track, freeze shield counter, and milestone progress.
public struct CraftStreakCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let data: CraftStreakData
    public let cardStyle: CraftCardStyle
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onFreezeTap: (() -> Void)?
    public let onMilestoneTap: (() -> Void)?

    @State private var isPulsing = false

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
        CraftCard(style: cardStyle) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                headerRow
                weekTrackRow
                footerRow
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelString)
        .accessibilityHint(accessibilityHintString)
        .accessibilityActionIf(onFreezeTap != nil, named: "Xem khiên bảo vệ") {
            onFreezeTap?()
        }
        .accessibilityActionIf(onMilestoneTap != nil, named: "Xem mốc thưởng") {
            onMilestoneTap?()
        }
        .onAppear {
            updatePulseAnimation()
        }
        .onChange(of: reduceMotion) { _, _ in
            updatePulseAnimation()
        }
        .onChange(of: data.isCompletedToday) { _, _ in
            updatePulseAnimation()
        }
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center, spacing: theme.spacing.xs) {
            // Flame Icon colored by Tier Gradient
            Image(systemName: CraftSymbol.streak.rawValue)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(tierGradient)
                .frame(width: 32, height: 32)

            // Streak Count & Tier Subtitle
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(data.currentStreak)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(theme.colors.textPrimary)

                    Text("ngày")
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                Text(tierTitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textMuted)
            }

            Spacer(minLength: theme.spacing.xs)

            // Best Streak Trophy Badge
            if data.bestStreak > 0 {
                CraftBadge(
                    "Kỷ lục: \(data.bestStreak) ngày",
                    symbol: .trophy,
                    variant: .subtle,
                    tone: .warning,
                    size: .sm
                )
            }
        }
    }

    // MARK: - 7-Day Week Track Row

    private var weekTrackRow: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(data.weekDays) { day in
                VStack(spacing: theme.spacing.xs) {
                    Text(day.weekdaySymbol)
                        .font(.caption2)
                        .fontWeight(day.isToday ? .bold : .medium)
                        .foregroundStyle(day.isToday ? theme.colors.textPrimary : theme.colors.textMuted)

                    dayStatusNode(for: day)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func dayStatusNode(for day: CraftStreakDay) -> some View {
        let nodeSize: CGFloat = 36

        ZStack {
            switch day.status {
            case .completed:
                Circle()
                    .fill(tierGradient)
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay(
                        Image(systemName: CraftSymbol.streak.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .craftShadow(theme.shadows.sm)

            case .pending:
                Circle()
                    .fill(day.isToday ? tierBaseColor.opacity(0.08) : theme.colors.surfaceSubtle.opacity(0.5))
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                day.isToday ? theme.colors.streakPending : theme.colors.borderDefault,
                                style: StrokeStyle(lineWidth: 1.5, dash: day.isToday ? [4, 3] : [3, 3])
                            )
                    )
                    .scaleEffect(!reduceMotion && day.isToday && isPulsing ? 1.06 : 1.0)
                    .opacity(!reduceMotion && day.isToday && isPulsing ? 0.90 : 1.0)

            case .frozen:
                Circle()
                    .fill(theme.colors.streakFreeze.opacity(0.14))
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.streakFreeze.opacity(0.35), lineWidth: 1.0)
                    )
                    .overlay(
                        Image(systemName: "snowflake")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.colors.streakFreeze)
                    )

            case .missed:
                Circle()
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay(
                        Circle()
                            .fill(theme.colors.textMuted.opacity(0.35))
                            .frame(width: 6, height: 6)
                    )

            case .upcoming:
                Circle()
                    .strokeBorder(theme.colors.borderDefault.opacity(0.7), lineWidth: 1.0)
                    .frame(width: nodeSize, height: nodeSize)
                    .background(Circle().fill(theme.colors.surfaceSubtle.opacity(0.25)))
            }
        }
        .frame(width: nodeSize, height: nodeSize)
    }

    // MARK: - Footer Row

    private var footerRow: some View {
        VStack(spacing: theme.spacing.xs) {
            Divider()
                .overlay(theme.colors.borderDefault.opacity(0.5))

            HStack(alignment: .center, spacing: theme.spacing.sm) {
                // Freeze Shield Counter
                if let onFreezeTap {
                    Button(action: onFreezeTap) {
                        freezeBadge
                    }
                    .buttonStyle(.craftPress(scale: 0.96))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(.isButton)
                } else {
                    freezeBadge
                        .frame(minHeight: 44)
                }

                Spacer(minLength: theme.spacing.xs)

                // Milestone Progress & Text
                if data.nextMilestoneDays > 0 {
                    if let onMilestoneTap {
                        Button(action: onMilestoneTap) {
                            milestoneProgressSection
                        }
                        .buttonStyle(.craftPress(scale: 0.98))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityAddTraits(.isButton)
                    } else {
                        milestoneProgressSection
                            .frame(minHeight: 44)
                    }
                }
            }
        }
    }

    private var freezeBadge: some View {
        CraftBadge(
            "\(data.freezeTokens)/\(data.maxFreezeTokens) Khiên",
            iconName: "snowflake",
            variant: .subtle,
            tone: data.freezeTokens > 0 ? .primary : .neutral,
            size: .sm
        )
    }

    private var milestoneProgressSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(milestoneDescriptionText)
                .font(.caption2)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)

            CraftProgressBar(
                progress: data.milestoneProgress,
                height: 6,
                tintColor: tierBaseColor
            )
            .frame(maxWidth: 130)
        }
    }

    // MARK: - Visual & Text Helpers

    private var tierTitle: String {
        switch data.tier {
        case .starter:
            return "Chuỗi khởi đầu"
        case .blaze:
            return "Chuỗi rực lửa"
        case .legendary:
            return "Chuỗi huyền thoại"
        }
    }

    private var milestoneDescriptionText: String {
        if let subtitle = data.subtitle, !subtitle.isEmpty {
            return subtitle
        }
        let remaining = max(0, data.nextMilestoneDays - data.currentStreak)
        if remaining == 0 {
            return "Đạt mốc \(data.nextMilestoneDays) ngày!"
        } else {
            return "Còn \(remaining) ngày đến mốc \(data.nextMilestoneDays)"
        }
    }

    private var tierGradient: LinearGradient {
        switch data.tier {
        case .starter:
            return theme.gradients.streakStarter
        case .blaze:
            return theme.gradients.streakBlaze
        case .legendary:
            return theme.gradients.streakLegendary
        }
    }

    private var tierBaseColor: Color {
        switch data.tier {
        case .starter:
            return theme.colors.brandPrimary
        case .blaze:
            return theme.colors.accent
        case .legendary:
            return Color(hex: 0x8B5CF6)
        }
    }

    private func updatePulseAnimation() {
        if !reduceMotion && !data.isCompletedToday {
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
        let statusDescription = data.isCompletedToday ? "Hôm nay đã hoàn thành" : "Hôm nay chưa hoàn thành"
        let bestDescription = data.bestStreak > 0 ? "Kỷ lục \(data.bestStreak) ngày." : ""
        let freezeDescription = "\(data.freezeTokens) trên \(data.maxFreezeTokens) khiên bảo vệ."
        return "Chuỗi \(data.currentStreak) ngày học liên tiếp, Cấp độ \(data.tier.rawValue). \(statusDescription). \(bestDescription) \(freezeDescription)"
    }

    private var accessibilityHintString: String {
        if let customAccessibilityHint {
            return customAccessibilityHint
        }
        var actions: [String] = []
        if onFreezeTap != nil {
            actions.append("'Xem khiên bảo vệ'")
        }
        if onMilestoneTap != nil {
            actions.append("'Xem mốc thưởng'")
        }
        if !actions.isEmpty {
            return "Vuốt lên hoặc xuống để chọn tác vụ \(actions.joined(separator: " hoặc "))."
        }
        return "Hiển thị tổng quan chuỗi ngày học trong tuần."
    }
}

// MARK: - Accessibility Helper

private extension View {
    @ViewBuilder
    func accessibilityActionIf(
        _ condition: Bool,
        named name: String,
        action: @escaping () -> Void
    ) -> some View {
        if condition {
            self.accessibilityAction(named: Text(name), action)
        } else {
            self
        }
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

            CraftStreakCard(
                data: CraftStreakData(
                    currentStreak: 35,
                    bestStreak: 35,
                    freezeTokens: 3,
                    maxFreezeTokens: 3,
                    nextMilestoneDays: 50,
                    isCompletedToday: true,
                    weekDays: [
                        .init(id: "1", weekdaySymbol: "T2", status: .completed),
                        .init(id: "2", weekdaySymbol: "T3", status: .completed),
                        .init(id: "3", weekdaySymbol: "T4", status: .completed),
                        .init(id: "4", weekdaySymbol: "T5", status: .completed, isToday: true),
                        .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
                        .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
                        .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
                    ]
                )
            )

            CraftStreakCard(
                data: CraftStreakData(
                    currentStreak: 3,
                    bestStreak: 7,
                    freezeTokens: 1,
                    maxFreezeTokens: 3,
                    nextMilestoneDays: 7,
                    isCompletedToday: false,
                    weekDays: [
                        .init(id: "1", weekdaySymbol: "T2", status: .completed),
                        .init(id: "2", weekdaySymbol: "T3", status: .completed),
                        .init(id: "3", weekdaySymbol: "T4", status: .missed),
                        .init(id: "4", weekdaySymbol: "T5", status: .pending, isToday: true),
                        .init(id: "5", weekdaySymbol: "T6", status: .upcoming),
                        .init(id: "6", weekdaySymbol: "T7", status: .upcoming),
                        .init(id: "7", weekdaySymbol: "CN", status: .upcoming)
                    ]
                )
            )
        }
        .padding()
    }
}
