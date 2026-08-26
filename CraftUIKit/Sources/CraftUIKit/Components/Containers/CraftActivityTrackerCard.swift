import SwiftUI

// MARK: - CraftActivityTrackerCard Component

/// A universal 7-day Bento dashboard widget displaying activity/streak progress, tier flame/icon,
/// weekly cycle track, shield counter, and milestone progress.
public struct CraftActivityTrackerCard: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle

    public let data: CraftActivityTrackerData
    public let cardStyle: CraftCardStyle
    public let surfaceStyle: CraftSurfaceStyle?
    public let icon: CraftNodeIcon
    public let customAccessibilityLabel: String?
    public let customAccessibilityHint: String?
    public let onCardTap: (() -> Void)?
    public let onShieldTap: (() -> Void)?
    public let onMilestoneTap: (() -> Void)?
    public let onDayTap: ((CraftActivityDay) -> Void)?

    public init(
        data: CraftActivityTrackerData,
        cardStyle: CraftCardStyle = .outlined,
        surfaceStyle: CraftSurfaceStyle? = nil,
        icon: CraftNodeIcon = .system(CraftSymbol.streak.rawValue),
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        onCardTap: (() -> Void)? = nil,
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
        self.onCardTap = onCardTap
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
        onCardTap: (() -> Void)? = nil,
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
            onCardTap: onCardTap,
            onShieldTap: onShieldTap,
            onMilestoneTap: onMilestoneTap,
            onDayTap: onDayTap
        )
    }

    public var body: some View {
        CraftCard(
            style: effectiveCardStyle,
            customGradient: isGradientCard ? tierGradient : nil,
            action: onCardTap
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.base) {
                headerRow
                weekTrackRow
                footerRow
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabelString)
        .accessibilityHint(accessibilityHintString)
        .accessibilityActionIf(onShieldTap != nil, named: CraftLocalized.string("craft.streak.view_shield_action")) {
            onShieldTap?()
        }
        .accessibilityActionIf(onMilestoneTap != nil, named: CraftLocalized.string("craft.streak.view_milestone_action")) {
            onMilestoneTap?()
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

    private var isGradientCard: Bool {
        effectiveCardStyle == .gradient
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
                        .foregroundStyle(isGradientCard ? Color.white : theme.colors.textPrimary)

                    Text(resolvedUnit)
                        .font(theme.typography.label)
                        .foregroundStyle(isGradientCard ? Color.white.opacity(0.85) : theme.colors.textSecondary)
                }

                Text(tierTitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(isGradientCard ? Color.white.opacity(0.75) : theme.colors.textMuted)
            }

            Spacer(minLength: theme.spacing.xs)

            // Best Record Trophy Badge
            if data.bestRecord > 0 {
                CraftBadge(
                    CraftLocalized.format("craft.streak.best_record_format", data.bestRecord),
                    symbol: .trophy,
                    variant: isGradientCard ? .solid : .subtle,
                    tone: .neutral,
                    size: .sm,
                    customTint: isGradientCard ? Color.white.opacity(0.25) : theme.colors.accent
                )
                .overlay(
                    isGradientCard
                        ? Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.8)
                        : nil
                )
            }
        }
    }

    @ViewBuilder
    private var heroIconView: some View {
        if icon.isSystem {
            if isGradientCard {
                Image(systemName: icon.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.white)
                    .shadow(color: Color.black.opacity(0.20), radius: 2, y: 1)
            } else {
                Image(systemName: icon.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(tierGradient)
            }
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
                        .foregroundStyle(
                            isGradientCard
                                ? (day.isToday ? Color.white : Color.white.opacity(0.70))
                                : (day.isToday ? theme.colors.textPrimary : theme.colors.textMuted)
                        )

                    dayNodeView(for: day)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .padding(.horizontal, theme.spacing.xs)
        .padding(.vertical, theme.spacing.sm)
        .background(
            isGradientCard
                ? Color.black.opacity(0.16)
                : theme.colors.surfaceSubtle.opacity(0.35)
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
        .overlay(
            isGradientCard
                ? RoundedRectangle(cornerRadius: theme.radii.md)
                    .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                : nil
        )
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
            .accessibilityHint(CraftLocalized.string("craft.streak.day_inspect_hint"))
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
                        .fill(isGradientCard ? Color.black.opacity(0.30) : tierRimColor)
                        .frame(width: nodeSize, height: nodeSize)
                        .offset(y: depth)

                    // Top Face
                    Circle()
                        .fill(isGradientCard ? AnyShapeStyle(Color.white) : AnyShapeStyle(tierGradient))
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(
                            Circle()
                                .stroke(isGradientCard ? AnyShapeStyle(Color.white) : AnyShapeStyle(theme.depths.topHighlight), lineWidth: 1.0)
                        )
                        .overlay(
                            nodeFaceIcon
                        )
                }
                .frame(width: nodeSize, height: nodeSize + depth)
                .craftShadow(theme.shadows.sm)

            case .pending:
                Circle()
                    .fill(
                        isGradientCard
                            ? (day.isToday ? Color.white.opacity(0.22) : Color.white.opacity(0.08))
                            : (day.isToday ? tierBaseColor.opacity(0.12) : theme.colors.surfaceSubtle.opacity(0.5))
                    )
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay(
                        Circle()
                            .stroke(
                                isGradientCard
                                    ? (day.isToday ? Color.white : Color.white.opacity(0.35))
                                    : (day.isToday ? tierBaseColor : theme.colors.borderDefault),
                                style: StrokeStyle(lineWidth: 1.5, dash: day.isToday ? [4, 3] : [3, 3])
                            )
                    )
                    .overlay {
                        if day.isToday {
                            CraftPulsingAuraRing(
                                color: isGradientCard ? Color.white : tierBaseColor,
                                size: nodeSize,
                                lineWidth: 2.5
                            )
                        }
                    }

            case .saved:
                ZStack {
                    // Bottom 3D Shield Rim
                    Circle()
                        .fill(isGradientCard ? Color.black.opacity(0.25) : theme.colors.streakFreeze.opacity(0.35))
                        .frame(width: nodeSize, height: nodeSize)
                        .offset(y: depth)

                    // Top Face
                    Circle()
                        .fill(isGradientCard ? Color.white.opacity(0.25) : theme.colors.streakFreeze.opacity(0.14))
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(
                            Circle()
                                .stroke(isGradientCard ? AnyShapeStyle(Color.white.opacity(0.40)) : AnyShapeStyle(theme.depths.topHighlight), lineWidth: 1.0)
                        )
                        .overlay(
                            Circle()
                                .stroke(isGradientCard ? Color.white.opacity(0.60) : theme.colors.streakFreeze.opacity(0.35), lineWidth: 1.0)
                        )
                        .overlay(
                            Image(systemName: "snowflake")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(isGradientCard ? Color(hex: "E0F2FE") : theme.colors.streakFreeze)
                        )
                }
                .frame(width: nodeSize, height: nodeSize + depth)

            case .missed:
                Circle()
                    .fill(isGradientCard ? Color.white.opacity(0.12) : theme.colors.surfaceSubtle)
                    .frame(width: nodeSize, height: nodeSize)
                    .overlay(
                        Circle()
                            .stroke(isGradientCard ? Color.white.opacity(0.25) : theme.colors.borderDefault.opacity(0.4), lineWidth: 0.5)
                    )
                    .overlay(
                        Circle()
                            .fill(isGradientCard ? Color.white.opacity(0.60) : theme.colors.textMuted.opacity(0.35))
                            .frame(width: 6, height: 6)
                    )

            case .upcoming:
                Circle()
                    .stroke(isGradientCard ? Color.white.opacity(0.35) : theme.colors.borderDefault.opacity(0.7), lineWidth: 1.0)
                    .frame(width: nodeSize, height: nodeSize)
                    .background(
                        Circle().fill(isGradientCard ? Color.white.opacity(0.08) : theme.colors.surfaceSubtle.opacity(0.25))
                    )
            }
        }
        .frame(width: nodeSize, height: nodeSize + depth)
    }

    @ViewBuilder
    private var nodeFaceIcon: some View {
        if icon.isSystem {
            Image(systemName: icon.name)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isGradientCard ? tierBaseColor : Color.white)
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
                .overlay(isGradientCard ? Color.white.opacity(0.22) : theme.colors.borderDefault.opacity(0.5))

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
            CraftLocalized.format("craft.streak.freeze_shield_format", data.shieldTokens, data.maxShieldTokens),
            iconName: "snowflake",
            variant: isGradientCard ? .solid : .subtle,
            tone: isGradientCard ? .neutral : (data.shieldTokens > 0 ? .primary : .neutral),
            size: .sm,
            customTint: isGradientCard ? Color.white.opacity(0.25) : nil
        )
        .overlay(
            isGradientCard
                ? Capsule().strokeBorder(Color.white.opacity(0.4), lineWidth: 0.8)
                : nil
        )
        .fixedSize(horizontal: true, vertical: false)
    }

    private var milestoneProgressSection: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(milestoneDescriptionText)
                .font(theme.typography.caption)
                .foregroundStyle(isGradientCard ? Color.white.opacity(0.90) : theme.colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            CraftProgressBar(
                progress: data.milestoneProgress,
                height: 6,
                tintColor: isGradientCard ? Color.white : tierBaseColor,
                trackColor: isGradientCard ? Color.white.opacity(0.25) : nil
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
            return CraftLocalized.string("craft.streak.tier_starter")
        case .blaze:
            return CraftLocalized.string("craft.streak.tier_blaze")
        case .legendary:
            return CraftLocalized.string("craft.streak.tier_legendary")
        }
    }

    private var tierRimColor: Color {
        switch data.tier {
        case .starter:
            return theme.colors.streakStarter.opacity(0.85)
        case .blaze:
            return theme.colors.streakBlaze.opacity(0.85)
        case .legendary:
            return theme.colors.streakLegendary.opacity(0.85)
        }
    }

    private var milestoneDescriptionText: String {
        if let subtitle = data.subtitle, !subtitle.isEmpty {
            return subtitle
        }
        return CraftLocalized.format("craft.streak.milestone_title_format", data.nextMilestone)
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
            return theme.colors.streakStarter
        case .blaze:
            return theme.colors.streakBlaze
        case .legendary:
            return theme.colors.streakLegendary
        }
    }

    // MARK: - Accessibility Strings

    private var accessibilityLabelString: String {
        if let customAccessibilityLabel {
            return customAccessibilityLabel
        }
        let statusDescription = data.isCompletedToday ? CraftLocalized.string("craft.streak.today_completed") : CraftLocalized.string("craft.streak.today_pending")
        let bestDescription = data.bestRecord > 0 ? "\(CraftLocalized.format("craft.streak.best_record_format", data.bestRecord)). " : ""
        let freezeDescription = CraftLocalized.format("craft.streak.freeze_shield_format", data.shieldTokens, data.maxShieldTokens)
        return "\(data.currentValue) \(resolvedUnit), \(tierTitle). \(statusDescription). \(bestDescription)\(freezeDescription)"
    }

    private var accessibilityHintString: String {
        if let customAccessibilityHint {
            return customAccessibilityHint
        }
        return CraftLocalized.string("craft.streak.card_a11y_overview")
    }

    private func accessibilityDayStatusDescription(for status: CraftActivityDayStatus) -> String {
        switch status {
        case .completed:
            return CraftLocalized.string("craft.streak.day_status_completed")
        case .pending:
            return CraftLocalized.string("craft.streak.day_status_pending")
        case .saved:
            return CraftLocalized.string("craft.streak.day_status_saved")
        case .missed:
            return CraftLocalized.string("craft.streak.day_status_missed")
        case .upcoming:
            return CraftLocalized.string("craft.streak.day_status_upcoming")
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
