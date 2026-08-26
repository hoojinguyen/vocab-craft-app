import SwiftUI

// MARK: - CraftActivityTrackerCard Component

/// A universal 7-day Bento dashboard widget displaying activity/streak progress, tier flame/icon,
/// weekly cycle track, shield counter, and milestone progress.
public struct CraftActivityTrackerCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let data: CraftActivityTrackerData
    public let cardStyle: CraftCardStyle
    public let surfaceStyle: CraftSurfaceStyle?
    public let icon: CraftNodeIcon
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onShieldTap: (() -> Void)?
    public let onMilestoneTap: (() -> Void)?
    public let onDayTap: ((CraftActivityDay) -> Void)?

    @State private var isPulsing = false

    public init(
        data: CraftActivityTrackerData,
        cardStyle: CraftCardStyle = .outlined,
        surfaceStyle: CraftSurfaceStyle? = nil,
        icon: CraftNodeIcon = .system(CraftSymbol.streak.rawValue),
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onShieldTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftActivityDay) -> Void)? = nil
    ) {
        self.data = data
        self.surfaceStyle = surfaceStyle
        if let surfaceStyle {
            self.cardStyle = CraftCardStyle(surfaceStyle: surfaceStyle)
        } else {
            self.cardStyle = cardStyle
        }
        self.icon = icon
        self.customAccessibilityLabel = accessibilityLabel
        self.customAccessibilityHint = accessibilityHint
        self.onShieldTap = onShieldTap
        self.onMilestoneTap = onMilestoneTap
        self.onDayTap = onDayTap
    }

    public init(
        data: CraftActivityTrackerData,
        surfaceStyle: CraftSurfaceStyle,
        icon: CraftNodeIcon = .system(CraftSymbol.streak.rawValue),
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onShieldTap: (() -> Void)? = nil,
        onMilestoneTap: (() -> Void)? = nil,
        onDayTap: ((CraftActivityDay) -> Void)? = nil
    ) {
        self.init(
            data: data,
            cardStyle: CraftCardStyle(surfaceStyle: surfaceStyle),
            surfaceStyle: surfaceStyle,
            icon: icon,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            onShieldTap: onShieldTap,
            onMilestoneTap: onMilestoneTap,
            onDayTap: onDayTap
        )
    }

    public var body: some View {
        CraftCard(style: effectiveCardStyle) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                headerRow
                weekTrackRow
                footerRow
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelString)
        .accessibilityHint(accessibilityHintString)
        .accessibilityActionIf(onShieldTap != nil, named: CraftLocalized.string("craft.streak.viewShieldAction")) {
            onShieldTap?()
        }
        .accessibilityActionIf(onMilestoneTap != nil, named: CraftLocalized.string("craft.streak.viewMilestoneAction")) {
            onMilestoneTap?()
        }
        .onAppear {
            updatePulseAnimation()
        }
        .onDisappear {
            isPulsing = false
        }
        .onChange(of: reduceMotion) { _, _ in
            updatePulseAnimation()
        }
        .onChange(of: data.isCompletedToday) { _, _ in
            updatePulseAnimation()
        }
    }

    private var effectiveCardStyle: CraftCardStyle {
        if let surfaceStyle {
            return CraftCardStyle(surfaceStyle: surfaceStyle)
        }
        if environmentSurfaceStyle != .flat {
            return CraftCardStyle(surfaceStyle: environmentSurfaceStyle)
        }
        return cardStyle
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(alignment: .center, spacing: theme.spacing.xs) {
            // Hero Icon colored by Tier Gradient
            heroIconView
                .frame(width: 32, height: 32)

            // Value & Tier Subtitle
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(data.currentValue)")
                        .font(theme.typography.metricRounded)
                        .monospacedDigit()
                        .foregroundStyle(theme.colors.textPrimary)

                    Text(resolvedUnit)
                        .font(theme.typography.label)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                Text(tierTitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textMuted)
            }

            Spacer(minLength: theme.spacing.xs)

            // Best Record Trophy Badge
            if data.bestRecord > 0 {
                CraftBadge(
                    CraftLocalized.format("craft.streak.bestRecord", data.bestRecord),
                    symbol: .trophy,
                    variant: .subtle,
                    tone: .neutral,
                    size: .sm,
                    customTint: Color(hex: "F59E0B") // Warm Amber Gold
                )
            }
        }
    }

    @ViewBuilder
    private var heroIconView: some View {
        if icon.isSystem {
            Image(systemName: icon.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(tierGradient)
        } else {
            Image(icon.name)
                .resizable()
                .scaledToFit()
        }
    }

    // MARK: - 7-Day Cycle Track Row

    private var weekTrackRow: some View {
        HStack(spacing: theme.spacing.xs) {
            ForEach(data.cycleDays) { day in
                VStack(spacing: theme.spacing.xs) {
                    Text(day.weekdaySymbol)
                        .font(theme.typography.caption)
                        .fontWeight(day.isToday ? .bold : .medium)
                        .foregroundStyle(day.isToday ? theme.colors.textPrimary : theme.colors.textMuted)

                    dayNodeView(for: day)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.surfaceSubtle.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    }

    @ViewBuilder
    private func dayNodeView(for day: CraftActivityDay) -> some View {
        if let onDayTap {
            Button {
                #if os(iOS)
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.prepare()
                generator.impactOccurred()
                #endif
                onDayTap(day)
            } label: {
                dayStatusNode(for: day)
            }
            .buttonStyle(.craftPress(scale: 0.94))
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel("\(day.weekdaySymbol), \(accessibilityDayStatusDescription(for: day.status))")
            .accessibilityHint("Chạm hai lần để xem chi tiết ngày này.")
        } else {
            dayStatusNode(for: day)
                .frame(minWidth: 44, minHeight: 44)
        }
    }

    @ViewBuilder
    private func dayStatusNode(for day: CraftActivityDay) -> some View {
        let nodeSize: CGFloat = 36
        let depth = theme.depths.depthSm

        ZStack {
            switch day.status {
            case .completed:
                ZStack {
                    // Bottom 3D Rim
                    Circle()
                        .fill(tierRimColor)
                        .frame(width: nodeSize, height: nodeSize)
                        .offset(y: depth)

                    // Top Face
                    Circle()
                        .fill(tierGradient)
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(
                            Circle()
                                .stroke(theme.depths.topHighlight, lineWidth: 1.0)
                        )
                        .overlay(
                            nodeFaceIcon
                        )
                }
                .frame(width: nodeSize, height: nodeSize + depth)
                .craftShadow(theme.shadows.sm)

            case .pending:
                Circle()
                    .fill(day.isToday ? tierBaseColor.opacity(0.12) : theme.colors.surfaceSubtle.opacity(0.5))
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay(
                        Circle()
                            .stroke(
                                day.isToday ? tierBaseColor : theme.colors.borderDefault,
                                style: StrokeStyle(lineWidth: 1.5, dash: day.isToday ? [4, 3] : [3, 3])
                            )
                    )
                    .overlay {
                        if day.isToday && !reduceMotion {
                            Circle()
                                .stroke(tierBaseColor.opacity(isPulsing ? 0.6 : 0.0), lineWidth: 2.5)
                                .scaleEffect(isPulsing ? 1.25 : 1.0)
                                .opacity(isPulsing ? 0.0 : 1.0)
                        }
                    }

            case .saved:
                ZStack {
                    // Bottom 3D Shield Rim
                    Circle()
                        .fill(theme.colors.streakFreeze.opacity(0.35))
                        .frame(width: nodeSize, height: nodeSize)
                        .offset(y: depth)

                    // Top Face
                    Circle()
                        .fill(theme.colors.streakFreeze.opacity(0.14))
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(
                            Circle()
                                .stroke(theme.depths.topHighlight, lineWidth: 1.0)
                        )
                        .overlay(
                            Circle()
                                .stroke(theme.colors.streakFreeze.opacity(0.35), lineWidth: 1.0)
                        )
                        .overlay(
                            Image(systemName: "snowflake")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(theme.colors.streakFreeze)
                        )
                }
                .frame(width: nodeSize, height: nodeSize + depth)

            case .missed:
                Circle()
                    .fill(theme.colors.surfaceSubtle)
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay(
                        Circle()
                            .stroke(theme.colors.borderDefault.opacity(0.4), lineWidth: 0.5)
                    )
                    .overlay(
                        Circle()
                            .fill(theme.colors.textMuted.opacity(0.35))
                            .frame(width: 6, height: 6)
                    )

            case .upcoming:
                Circle()
                    .stroke(theme.colors.borderDefault.opacity(0.7), lineWidth: 1.0)
                    .frame(width: nodeSize, height: nodeSize)
                    .background(Circle().fill(theme.colors.surfaceSubtle.opacity(0.25)))
            }
        }
        .frame(width: nodeSize, height: nodeSize + depth)
    }

    @ViewBuilder
    private var nodeFaceIcon: some View {
        if icon.isSystem {
            Image(systemName: icon.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        } else {
            Image(icon.name)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
        }
    }

    // MARK: - Footer Row

    private var footerRow: some View {
        VStack(spacing: theme.spacing.xs) {
            Divider()
                .overlay(theme.colors.borderDefault.opacity(0.5))

            HStack(alignment: .center, spacing: theme.spacing.sm) {
                // Shield Counter
                if let onShieldTap {
                    Button(action: onShieldTap) {
                        shieldBadge
                    }
                    .buttonStyle(.craftPress(scale: 0.96))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(.isButton)
                } else {
                    shieldBadge
                        .frame(minHeight: 44)
                }

                Spacer(minLength: theme.spacing.xs)

                // Milestone Progress & Text
                if data.nextMilestone > 0 {
                    if let onMilestoneTap {
                        Button(action: onMilestoneTap) {
                            milestoneProgressSection
                        }
                        .buttonStyle(.craftPress(scale: 0.98))
                        .frame(minWidth: 44, minHeight: 44)
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

    private var shieldBadge: some View {
        CraftBadge(
            CraftLocalized.format("craft.streak.freezeShield", data.shieldTokens, data.maxShieldTokens),
            iconName: "snowflake",
            variant: .subtle,
            tone: data.shieldTokens > 0 ? .primary : .neutral,
            size: .sm
        )
        .fixedSize(horizontal: true, vertical: false)
    }

    private var milestoneProgressSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(milestoneDescriptionText)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            CraftProgressBar(
                progress: data.milestoneProgress,
                height: 6,
                tintColor: tierBaseColor
            )
            .frame(minWidth: 60, maxWidth: 140)
        }
    }

    // MARK: - Visual & Text Helpers

    private var resolvedUnit: String {
        if let unitKey = data.unitKey {
            return CraftLocalized.string(unitKey)
        }
        return data.unit
    }

    private var tierTitle: String {
        switch data.tier {
        case .starter:
            return CraftLocalized.string("craft.streak.tierStarter")
        case .blaze:
            return CraftLocalized.string("craft.streak.tierBlaze")
        case .legendary:
            return CraftLocalized.string("craft.streak.tierLegendary")
        }
    }

    private var tierRimColor: Color {
        switch data.tier {
        case .starter:
            return theme.colors.brandPrimary.opacity(0.85)
        case .blaze:
            return theme.colors.accent.opacity(0.85)
        case .legendary:
            return Color.purple.opacity(0.85)
        }
    }

    private var milestoneDescriptionText: String {
        if let subtitle = data.subtitle, !subtitle.isEmpty {
            return subtitle
        }
        let remaining = max(0, data.nextMilestone - data.currentValue)
        let percent = Int(round(data.milestoneProgress * 100.0))
        if remaining == 0 {
            return CraftLocalized.format("craft.streak.milestoneReachedPercent", data.nextMilestone)
        } else {
            return CraftLocalized.format("craft.streak.milestoneProgressPercent", data.nextMilestone, percent)
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
            return theme.colors.statusDanger
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
        let statusDescription = data.isCompletedToday ? CraftLocalized.string("craft.streak.todayCompleted") : CraftLocalized.string("craft.streak.todayPending")
        let bestDescription = data.bestRecord > 0 ? "\(CraftLocalized.format("craft.streak.bestRecord", data.bestRecord)). " : ""
        let freezeDescription = CraftLocalized.format("craft.streak.freezeShield", data.shieldTokens, data.maxShieldTokens)
        return "\(data.currentValue) \(resolvedUnit), \(tierTitle). \(statusDescription). \(bestDescription)\(freezeDescription)"
    }

    private var accessibilityHintString: String {
        if let customAccessibilityHint {
            return customAccessibilityHint
        }
        var actions: [String] = []
        if onShieldTap != nil {
            actions.append("'\(CraftLocalized.string("craft.streak.viewShieldAction"))'")
        }
        if onMilestoneTap != nil {
            actions.append("'\(CraftLocalized.string("craft.streak.viewMilestoneAction"))'")
        }
        if !actions.isEmpty {
            let actionsJoined = actions.joined(separator: ", ")
            return CraftLocalized.format("craft.streak.cardA11yActionsFormat", actionsJoined)
        }
        return CraftLocalized.string("craft.streak.cardA11yHintOverview")
    }

    private func accessibilityDayStatusDescription(for status: CraftActivityDayStatus) -> String {
        switch status {
        case .completed:
            return CraftLocalized.string("craft.streak.dayStatusCompleted")
        case .pending:
            return CraftLocalized.string("craft.streak.dayStatusPending")
        case .saved:
            return CraftLocalized.string("craft.streak.dayStatusSaved")
        case .missed:
            return CraftLocalized.string("craft.streak.dayStatusMissed")
        case .upcoming:
            return CraftLocalized.string("craft.streak.dayStatusUpcoming")
        }
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
