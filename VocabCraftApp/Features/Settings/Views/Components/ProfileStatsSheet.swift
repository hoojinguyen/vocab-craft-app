import CraftUIKit
import SwiftUI

/// A comprehensive, theme-driven bottom sheet displaying user learning statistics,
/// CEFR Oxford mastery progression, and unlocked achievements.
public struct ProfileStatsSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    public let userName: String
    public let userLevel: String
    public let wordsLearned: Int
    public let accuracyPercent: Int
    public let avgSpeedSeconds: Double
    public let streakDays: Int

    public init(
        userName: String = "Hooji N.",
        userLevel: String = "B2 Intermediate",
        wordsLearned: Int = 420,
        accuracyPercent: Int = 94,
        avgSpeedSeconds: Double = 1.8,
        streakDays: Int = 14
    ) {
        self.userName = userName
        self.userLevel = userLevel
        self.wordsLearned = wordsLearned
        self.accuracyPercent = accuracyPercent
        self.avgSpeedSeconds = avgSpeedSeconds
        self.streakDays = streakDays
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: theme.spacing.lg) {
                    // Profile Summary Header
                    profileSummaryHeader

                    // 4-Item Bento Metrics Grid
                    bentoMetricsGrid

                    // Oxford CEFR Progression
                    cefrProgressionSection

                    // Unlocked Achievements
                    achievementsSection

                    // Dismiss Button
                    CraftButton(
                        AppStrings.Common.done,
                        variant: .primary,
                        size: .lg
                    ) {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, theme.spacing.sm)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.md)
                .padding(.bottom, theme.spacing.xl)
            }
            .background(theme.colors.canvasBackground.ignoresSafeArea())
            .navigationTitle(AppStrings.Profile.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        CraftIcon("xmark.circle.fill", size: .md, color: theme.colors.textMuted)
                    }
                    .accessibilityLabel(AppStrings.Common.close)
                }
            }
        }
    }

    // MARK: - Profile Summary Header

    private var profileSummaryHeader: some View {
        HStack(spacing: theme.spacing.md) {
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .strokeBorder(theme.colors.borderDefault, lineWidth: 1.5)
                    )

                Text(userName.prefix(1))
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textInverse)
            }

            VStack(alignment: .leading, spacing: theme.spacing.xs / 2) {
                CraftText(userName, style: .titleMedium, color: theme.colors.textPrimary)
                    .fontWeight(.bold)

                CraftBadge(
                    userLevel,
                    symbol: .star,
                    variant: .subtle,
                    tone: .primary,
                    size: .sm
                )
            }

            Spacer()
        }
        .padding(.vertical, theme.spacing.xs)
    }

    // MARK: - Bento Metrics Grid

    private var bentoMetricsGrid: some View {
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
                HStack {
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
                HStack {
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
