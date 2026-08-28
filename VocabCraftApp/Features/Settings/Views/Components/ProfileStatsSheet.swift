import CraftUIKit
import SwiftUI

/// An interactive, CraftLessonDetailSheet-aligned modal sheet displaying detailed user learning
/// statistics, Oxford CEFR mastery breakdown, and unlocked achievements.
public struct ProfileStatsSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    public let userLevel: String
    public let wordsLearned: Int
    public let accuracyPercent: Int
    public let avgSpeedSeconds: Double
    public let streakDays: Int

    public init(
        userLevel: String = "B2 Intermediate",
        wordsLearned: Int = 420,
        accuracyPercent: Int = 94,
        avgSpeedSeconds: Double = 1.8,
        streakDays: Int = 14
    ) {
        self.userLevel = userLevel
        self.wordsLearned = wordsLearned
        self.accuracyPercent = accuracyPercent
        self.avgSpeedSeconds = avgSpeedSeconds
        self.streakDays = streakDays
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator Handle
            Capsule()
                .fill(theme.colors.borderDefault)
                .frame(width: 36, height: 4)
                .padding(.top, theme.spacing.md)
                .padding(.bottom, theme.spacing.sm)
                .accessibilityHidden(true)

            ScrollView {
                VStack(spacing: theme.spacing.base) {
                    // Header Section: Tactile 3D Icon, Title, Level Badge
                    headerSection

                    // Metrics Chips Row
                    metricsRow

                    // Oxford CEFR Mastery Card
                    cefrProgressionCard

                    // Badges & Achievements Card
                    achievementsCard
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.sm)
            }

            // Bottom Primary Action Button
            CraftButton(
                AppStrings.Common.done,
                variant: .primary,
                size: .lg,
                isFullWidth: true
            ) {
                dismiss()
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.xs)
            .padding(.bottom, theme.spacing.base)
        }
        .background(theme.colors.surfaceCard)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: theme.radii.xl,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: theme.radii.xl
            )
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: theme.spacing.xs) {
            // Tactile 3D Trophy Icon
            tactile3DHeroIcon
                .padding(.bottom, theme.spacing.xs)

            // Centered Title
            Text(AppStrings.Profile.title)
                .font(theme.typography.titleLarge.bold())
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            // User Level Badge
            CraftBadge(
                userLevel,
                symbol: .star,
                variant: .subtle,
                tone: .primary,
                size: .md
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tactile 3D Hero Icon

    private var tactile3DHeroIcon: some View {
        ZStack {
            // Bottom 3D Bevel Rim
            Circle()
                .fill(theme.colors.accent.opacity(0.85))
                .frame(width: 56, height: 56)
                .offset(y: 4)

            // Top Face
            ZStack {
                Circle()
                    .fill(theme.gradients.brandHero)

                // Top highlight
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )

                Image(systemName: "trophy.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: 56, height: 56)
        }
        .frame(width: 56, height: 60)
        .accessibilityHidden(true)
    }

    // MARK: - Metrics Chips Row

    private var metricsRow: some View {
        HStack(spacing: theme.spacing.xs) {
            // Words Learned Chip
            metricChip(
                icon: "book.fill",
                title: "\(wordsLearned) \(AppStrings.Common.wordUnitText)",
                tintColor: theme.colors.brandPrimary,
                backgroundColor: theme.colors.brandPrimary.opacity(0.12)
            )

            // Accuracy Chip
            metricChip(
                icon: "target",
                title: "\(accuracyPercent)%",
                tintColor: theme.colors.statusSuccess,
                backgroundColor: theme.colors.statusSuccess.opacity(0.12)
            )

            // Speed Chip
            metricChip(
                icon: "bolt.fill",
                title: String(format: "%.1fs", avgSpeedSeconds),
                tintColor: theme.colors.accent,
                backgroundColor: theme.colors.accent.opacity(0.12)
            )

            // Streak Chip
            metricChip(
                icon: "flame.fill",
                title: "\(streakDays)d",
                tintColor: theme.colors.statusWarning,
                backgroundColor: theme.colors.statusWarning.opacity(0.12)
            )
        }
        .frame(maxWidth: .infinity)
    }

    private func metricChip(
        icon: String,
        title: String,
        tintColor: Color,
        backgroundColor: Color
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(tintColor)

            Text(title)
                .font(theme.typography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.md)
                .stroke(theme.colors.borderDefault.opacity(0.5), lineWidth: 1)
        )
    }

    // MARK: - Oxford CEFR Progression Card

    private var cefrProgressionCard: some View {
        CraftCard(style: .outlined) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.colors.brandPrimary)

                    Text(AppStrings.Profile.cefrMastery)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
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

    // MARK: - Achievements Card

    private var achievementsCard: some View {
        CraftCard(style: .outlined) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(theme.colors.statusWarning)

                    Text(AppStrings.Profile.achievements)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
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
