import CraftUIKit
import SwiftUI

/// Comprehensive modal dashboard presenting vocabulary growth, CEFR ladder distribution,
/// memory depth funnel, and pacing prediction across user progress.
public struct VocabGrowthDashboardSheet: View {
    @Environment(\.craftTheme) private var theme

    public let snapshot: VocabGrowthSnapshot
    public let dailyPace: Int
    public let onDismiss: () -> Void

    public init(
        snapshot: VocabGrowthSnapshot,
        dailyPace: Int = 10,
        onDismiss: @escaping () -> Void
    ) {
        self.snapshot = snapshot
        self.dailyPace = max(1, dailyPace)
        self.onDismiss = onDismiss
    }

    // MARK: - Computed Properties for Intelligence & Telemetry

    public var retentionHealthPercent: Int {
        Int(round(snapshot.estimatedRetentionRate * 100))
    }

    public var estimatedCompetenceLevel: String {
        guard !snapshot.cefrDistribution.isEmpty else { return "A1" }

        let masteredLevels = snapshot.cefrDistribution.filter { $0.masteryPercentage >= 0.8 }
        if let highestMastered = masteredLevels.last {
            if let highestIndex = snapshot.cefrDistribution.firstIndex(of: highestMastered) {
                let nextIndex = highestIndex + 1
                if nextIndex < snapshot.cefrDistribution.count && snapshot.cefrDistribution[nextIndex].acquiredCount > 0 {
                    return "\(highestMastered.cefrLevel)+"
                }
            }
            return highestMastered.cefrLevel
        }

        if let firstWithWords = snapshot.cefrDistribution.first(where: { $0.acquiredCount > 0 }) {
            return firstWithWords.cefrLevel
        }
        return "A1"
    }

    public var pacingTargetStat: CEFRLevelStat? {
        snapshot.cefrDistribution.first(where: { $0.masteryPercentage < 1.0 })
    }

    public var pacingRemainingWords: Int {
        guard let target = pacingTargetStat else { return 0 }
        return max(0, target.targetStandardCount - target.acquiredCount)
    }

    public var pacingTargetLevel: String {
        pacingTargetStat?.cefrLevel ?? (snapshot.cefrDistribution.last?.cefrLevel ?? "C2")
    }

    public var pacingDaysRemaining: Int {
        guard pacingRemainingWords > 0 else { return 0 }
        let pace = max(1, dailyPace)
        return Int(ceil(Double(pacingRemainingWords) / Double(pace)))
    }

    public var pacingEstimatedDate: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: pacingDaysRemaining, to: Date()) ?? Date()
    }

    public var pacingFormattedDate: String {
        pacingEstimatedDate.formatted(date: .abbreviated, time: .omitted)
    }

    public var pacingMessage: String {
        guard pacingRemainingWords > 0 else {
            return AppStrings.VocabGrowth.pacingAllCompletedText
        }
        return AppStrings.VocabGrowth.pacingPredictionText(
            pace: dailyPace,
            level: pacingTargetLevel,
            date: pacingFormattedDate
        )
    }

    // MARK: - View Body

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.spacing.lg) {
                headerView
                heroSummaryCard
                cefrLadderCard
                depthFunnelCard
                pacingCard
                dismissButton
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(AppStrings.VocabGrowth.dashboardTitle)
                    .font(theme.typography.titleLarge.weight(.bold))
                    .foregroundStyle(theme.colors.textPrimary)

                Text(AppStrings.VocabGrowth.dashboardSubtitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            Button(action: {
                CraftHaptics.shared.light()
                onDismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(theme.colors.surfaceElevated)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                        )

                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.Common.close)
        }
    }

    private var heroSummaryCard: some View {
        CraftCard(surfaceStyle: .tactile3D, cornerRadius: theme.radius.lg, padding: theme.spacing.base) {
            HStack(alignment: .center, spacing: 0) {
                heroMetricItem(
                    value: snapshot.totalWordsAcquired.formatted(),
                    label: AppStrings.VocabGrowth.totalWordsLabel,
                    icon: "character.book.closed.fill",
                    color: theme.colors.brandPrimary
                )

                Divider()
                    .frame(height: 36)
                    .background(theme.colors.borderDefault)

                heroMetricItem(
                    value: estimatedCompetenceLevel,
                    label: AppStrings.VocabGrowth.estimatedCompetenceLabel,
                    icon: "graduationcap.fill",
                    color: theme.colors.brandSecondary
                )

                Divider()
                    .frame(height: 36)
                    .background(theme.colors.borderDefault)

                heroMetricItem(
                    value: AppStrings.VocabGrowth.retentionHealthValue(percent: retentionHealthPercent),
                    label: AppStrings.VocabGrowth.retentionHealthLabel,
                    icon: "heart.fill",
                    color: theme.colors.statusSuccess
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func heroMetricItem(
        value: String,
        label: LocalizedStringKey,
        icon: String,
        color: Color
    ) -> some View {
        VStack(spacing: theme.spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(theme.typography.headline.weight(.heavy))
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var cefrLadderCard: some View {
        CraftCard(surfaceStyle: .tactile3D, cornerRadius: theme.radius.lg, padding: theme.spacing.base) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(AppStrings.VocabGrowth.cefrLadderTitle)
                        .font(theme.typography.titleMedium.weight(.bold))
                        .foregroundStyle(theme.colors.textPrimary)

                    Text(AppStrings.VocabGrowth.cefrLadderSubtitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                VStack(spacing: theme.spacing.sm) {
                    ForEach(snapshot.cefrDistribution) { stat in
                        cefrLevelRow(stat)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func cefrLevelRow(_ stat: CEFRLevelStat) -> some View {
        let percent = Int(round(stat.masteryPercentage * 100))
        let isMastered = stat.masteryPercentage >= 1.0
        let hasWords = stat.acquiredCount > 0

        return VStack(spacing: theme.spacing.xxs) {
            HStack(spacing: theme.spacing.xs) {
                CraftBadge(
                    stat.cefrLevel,
                    tone: isMastered ? .success : (hasWords ? .primary : .neutral),
                    size: .sm
                )

                Spacer()

                Text(AppStrings.VocabGrowth.cefrStatRatio(
                    acquired: stat.acquiredCount,
                    target: stat.targetStandardCount,
                    percent: percent
                ))
                .font(theme.typography.caption.monospacedDigit())
                .foregroundStyle(theme.colors.textSecondary)
            }

            CraftProgressBar(
                progress: stat.masteryPercentage,
                height: 8,
                tintColor: isMastered ? theme.colors.statusSuccess : theme.colors.brandPrimary,
                trackColor: theme.colors.borderDefault.opacity(0.5),
                cornerRadius: theme.radius.full
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var depthFunnelCard: some View {
        CraftCard(surfaceStyle: .tactile3D, cornerRadius: theme.radius.lg, padding: theme.spacing.base) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(AppStrings.VocabGrowth.depthFunnelTitle)
                        .font(theme.typography.titleMedium.weight(.bold))
                        .foregroundStyle(theme.colors.textPrimary)

                    Text(AppStrings.VocabGrowth.depthFunnelSubtitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                VStack(spacing: theme.spacing.xs) {
                    depthTierRow(
                        title: AppStrings.VocabGrowth.tierEncounteredTitle,
                        desc: AppStrings.VocabGrowth.tierEncounteredDesc,
                        count: snapshot.newWordsCount,
                        badgeColor: theme.colors.brandSecondary,
                        icon: "eye.fill"
                    )

                    depthTierRow(
                        title: AppStrings.VocabGrowth.tierConsolidatingTitle,
                        desc: AppStrings.VocabGrowth.tierConsolidatingDesc,
                        count: snapshot.consolidatingWordsCount,
                        badgeColor: theme.colors.brandPrimary,
                        icon: "arrow.triangle.2.circlepath"
                    )

                    depthTierRow(
                        title: AppStrings.VocabGrowth.tierMasteredTitle,
                        desc: AppStrings.VocabGrowth.tierMasteredDesc,
                        count: snapshot.masteredWordsCount,
                        badgeColor: theme.colors.statusSuccess,
                        icon: "bolt.shield.fill"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func depthTierRow(
        title: LocalizedStringKey,
        desc: LocalizedStringKey,
        count: Int,
        badgeColor: Color,
        icon: String
    ) -> some View {
        HStack(spacing: theme.spacing.sm) {
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(badgeColor)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                Text(title)
                    .font(theme.typography.bodyMedium.weight(.semibold))
                    .foregroundStyle(theme.colors.textPrimary)

                Text(desc)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            Text(AppStrings.VocabGrowth.wordsCount(count: count))
                .font(theme.typography.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(theme.colors.textPrimary)
                .padding(.horizontal, theme.spacing.xs)
                .padding(.vertical, theme.spacing.xxs)
                .background(theme.colors.surfaceElevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                )
        }
        .padding(.vertical, theme.spacing.xxs)
        .accessibilityElement(children: .combine)
    }

    private var pacingCard: some View {
        CraftCard(surfaceStyle: .tactile3D, cornerRadius: theme.radius.lg, padding: theme.spacing.base) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: theme.spacing.xs) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(theme.colors.brandPrimary)

                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                        Text(AppStrings.VocabGrowth.pacingTitle)
                            .font(theme.typography.titleMedium.weight(.bold))
                            .foregroundStyle(theme.colors.textPrimary)

                        Text(AppStrings.VocabGrowth.pacingSubtitle)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                HStack {
                    Text(pacingMessage)
                        .font(theme.typography.bodyMedium.weight(.medium))
                        .foregroundStyle(theme.colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(theme.spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.md)
                        .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var dismissButton: some View {
        CraftButton(
            AppStrings.Common.close,
            variant: .primary,
            size: .lg,
            isFullWidth: true,
            action: onDismiss
        )
    }
}
