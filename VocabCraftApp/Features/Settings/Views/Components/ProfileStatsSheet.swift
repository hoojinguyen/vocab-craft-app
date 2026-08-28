import CraftUIKit
import SwiftUI

/// Bottom sheet component displaying user learning statistics, CEFR Oxford mastery
/// progression, and unlocked achievements, matching the VaultWordDetailSheet architecture.
public struct ProfileStatsSheet: View {
    @Environment(\.craftTheme) private var theme

    public let wordsLearned: Int
    public let accuracyPercent: Int
    public let avgSpeedSeconds: Double
    public let streakDays: Int

    public init(
        wordsLearned: Int = 420,
        accuracyPercent: Int = 94,
        avgSpeedSeconds: Double = 1.8,
        streakDays: Int = 14
    ) {
        self.wordsLearned = wordsLearned
        self.accuracyPercent = accuracyPercent
        self.avgSpeedSeconds = avgSpeedSeconds
        self.streakDays = streakDays
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                // Header Section: Title & Subtitle
                headerSection

                // Section 1: 4-Item Bento Metrics Grid
                metricsGridSection

                // Section 2: Oxford CEFR Progression
                cefrProgressionSection

                // Section 3: Unlocked Achievements
                achievementsSection
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
        .presentationDetents([.fraction(0.78), .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
            CraftText(
                AppStrings.Profile.title,
                style: .titleLarge,
                color: theme.colors.textPrimary
            )
            .fontWeight(.bold)

            CraftText(
                AppStrings.Settings.profileTagline,
                style: .caption,
                color: theme.colors.textSecondary
            )
        }
        .padding(.top, theme.spacing.xs)
    }

    // MARK: - Bento Metrics Grid

    private var metricsGridSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: theme.spacing.md),
                GridItem(.flexible(), spacing: theme.spacing.md)
            ],
            spacing: theme.spacing.md
        ) {
            metricCard(
                iconName: "book.fill",
                iconColor: theme.colors.brandPrimary,
                value: "\(wordsLearned)",
                label: AppStrings.Profile.wordsLearned
            )

            metricCard(
                iconName: "target",
                iconColor: theme.colors.statusSuccess,
                value: "\(accuracyPercent)%",
                label: AppStrings.Profile.reflexAccuracy
            )

            metricCard(
                iconName: "bolt.fill",
                iconColor: theme.colors.statusWarning,
                value: String(format: "%.1fs", avgSpeedSeconds),
                label: AppStrings.Profile.avgSpeed
            )

            metricCard(
                iconName: "flame.fill",
                iconColor: theme.colors.accent,
                value: "\(streakDays)",
                label: AppStrings.Profile.streakDays
            )
        }
    }

    private func metricCard(
        iconName: String,
        iconColor: Color,
        value: String,
        label: LocalizedStringKey
    ) -> some View {
        CraftCard(style: .outlined) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: theme.radii.sm)
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 32, height: 32)

                        CraftIcon(iconName, size: .sm, color: iconColor)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(theme.typography.metricRounded)
                        .fontWeight(.bold)
                        .foregroundStyle(theme.colors.textPrimary)

                    Text(label)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Oxford CEFR Progression

    private var cefrProgressionSection: some View {
        CraftCard(style: .outlined) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon("chart.bar.fill", size: .sm, color: theme.colors.brandPrimary)
                    CraftText(AppStrings.Profile.cefrMastery, style: .headline, color: theme.colors.textPrimary)
                    Spacer()
                }

                VStack(spacing: theme.spacing.sm) {
                    cefrRow(level: "A1", label: "Beginner", percent: 100, count: "500/500", color: theme.colors.statusSuccess)
                    cefrRow(level: "A2", label: "Elementary", percent: 92, count: "460/500", color: theme.colors.statusSuccess)
                    cefrRow(level: "B1", label: "Intermediate", percent: 75, count: "375/500", color: theme.colors.brandPrimary)
                    cefrRow(level: "B2", label: "Upper-Int", percent: 45, count: "225/500", color: theme.colors.accent)
                    cefrRow(level: "C1", label: "Advanced", percent: 12, count: "60/500", color: theme.colors.textMuted)
                }
            }
        }
    }

    private func cefrRow(level: String, label: String, percent: Int, count: String, color: Color) -> some View {
        VStack(spacing: theme.spacing.xs / 2) {
            HStack {
                Text(level)
                    .font(theme.typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(label)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)

                Spacer()

                Text(count)
                    .font(theme.typography.caption)
                    .monospacedDigit()
                    .foregroundStyle(theme.colors.textMuted)
            }

            CraftProgressBar(
                progress: Double(percent) / 100.0,
                height: 6,
                tintColor: color
            )
        }
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        CraftCard(style: .outlined) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack(spacing: theme.spacing.xs) {
                    CraftIcon("trophy.fill", size: .sm, color: theme.colors.statusWarning)
                    CraftText(AppStrings.Profile.achievements, style: .headline, color: theme.colors.textPrimary)
                    Spacer()
                }

                HStack(spacing: theme.spacing.xs) {
                    CraftBadge(
                        AppStrings.Profile.badgeReflexMaster,
                        symbol: .practice,
                        variant: .subtle,
                        tone: .warning,
                        size: .sm
                    )

                    CraftBadge(
                        AppStrings.Profile.badgeStreakBlaze,
                        symbol: .streak,
                        variant: .subtle,
                        tone: .primary,
                        size: .sm
                    )

                    CraftBadge(
                        AppStrings.Profile.badgeOxfordPioneer,
                        symbol: .trophy,
                        variant: .subtle,
                        tone: .success,
                        size: .sm
                    )
                }
            }
        }
    }
}

#Preview("ProfileStatsSheet") {
    ProfileStatsSheet()
}
