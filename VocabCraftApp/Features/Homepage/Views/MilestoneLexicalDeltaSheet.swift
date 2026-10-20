import CraftUIKit
import SwiftUI

/// Data transfer object holding milestone metrics for lexical expansion at the end of a unit.
public struct MilestoneLexicalDelta: Identifiable, Sendable, Equatable {
    public var id: String { unitId }
    public let unitId: String
    public let unitTitle: String
    public let cefrLevel: String
    public let newWordsAdded: Int
    public let wordsMastered: Int
    public let avgResponseTimeMs: Double
    public let accuracyRate: Double
    public let acquiredWords: [String]
    public let cefrProgressCurrent: Int
    public let cefrProgressTarget: Int

    public init(
        unitId: String,
        unitTitle: String,
        cefrLevel: String,
        newWordsAdded: Int,
        wordsMastered: Int = 0,
        avgResponseTimeMs: Double = 0,
        accuracyRate: Double = 0,
        acquiredWords: [String] = [],
        cefrProgressCurrent: Int = 0,
        cefrProgressTarget: Int = 500
    ) {
        self.unitId = unitId
        self.unitTitle = unitTitle
        self.cefrLevel = cefrLevel
        self.newWordsAdded = newWordsAdded
        self.wordsMastered = wordsMastered
        self.avgResponseTimeMs = avgResponseTimeMs
        self.accuracyRate = accuracyRate
        self.acquiredWords = acquiredWords
        self.cefrProgressCurrent = cefrProgressCurrent
        self.cefrProgressTarget = cefrProgressTarget
    }
}

/// Interactive milestone bottom sheet celebrating lexical expansion upon completing a Unit Checkpoint or opening a Treasure Chest.
public struct MilestoneLexicalDeltaSheet: View {
    @Environment(\.craftTheme) private var theme
    @Environment(\.ttsService) private var ttsService

    public let delta: MilestoneLexicalDelta
    public let onContinue: () -> Void
    public let onOpenVault: () -> Void

    public init(
        delta: MilestoneLexicalDelta,
        onContinue: @escaping () -> Void,
        onOpenVault: @escaping () -> Void
    ) {
        self.delta = delta
        self.onContinue = onContinue
        self.onOpenVault = onOpenVault
    }

    private var targetStandardCount: Int {
        delta.cefrProgressTarget > 0 ? delta.cefrProgressTarget : 500
    }

    private var progressFraction: Double {
        guard targetStandardCount > 0 else { return 0 }
        return min(1.0, Double(delta.cefrProgressCurrent) / Double(targetStandardCount))
    }

    private var progressPercent: Int {
        Int(round(progressFraction * 100))
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: theme.spacing.lg) {
                celebrationHeader
                lexicalDeltaCard
                telemetryCard
                cefrProgressCard
                actionButtons
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.top, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xl)
        }
        .background(theme.colors.canvasBackground.ignoresSafeArea())
    }

    // MARK: - Subviews

    private var celebrationHeader: some View {
        VStack(spacing: theme.spacing.xs) {
            ZStack {
                Circle()
                    .fill(theme.colors.brandPrimary.opacity(0.12))
                    .frame(width: 64, height: 64)

                Image(systemName: "sparkles")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(theme.colors.brandPrimary)
            }
            .padding(.bottom, theme.spacing.xxs)

            Text(AppStrings.MilestoneReport.celebrationTitle)
                .font(theme.typography.titleLarge.weight(.bold))
                .foregroundStyle(theme.colors.textPrimary)
                .multilineTextAlignment(.center)

            HStack(spacing: theme.spacing.xs) {
                Text(delta.unitTitle)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)

                CraftBadge(delta.cefrLevel, tone: .primary, size: .sm)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var lexicalDeltaCard: some View {
        CraftCard(surfaceStyle: .tactile3D, cornerRadius: theme.radius.lg, padding: theme.spacing.base) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                    Text(AppStrings.MilestoneReport.wordsAdded(count: delta.newWordsAdded))
                        .font(theme.typography.displayLarge.weight(.heavy))
                        .foregroundStyle(theme.colors.brandPrimary)

                    Text(AppStrings.MilestoneReport.wordsAddedSubtitle)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }

                if !delta.acquiredWords.isEmpty {
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(AppStrings.MilestoneReport.acquiredWordsTitle)
                            .font(theme.typography.caption.weight(.semibold))
                            .foregroundStyle(theme.colors.textSecondary)

                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 95, maximum: 160), spacing: theme.spacing.xs)],
                            spacing: theme.spacing.xs
                        ) {
                            ForEach(delta.acquiredWords, id: \.self) { word in
                                wordChip(word)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func wordChip(_ word: String) -> some View {
        Button {
            CraftHaptics.shared.light()
            ttsService?.speak(text: word)
        } label: {
            HStack(spacing: theme.spacing.xxs) {
                Text(word)
                    .font(theme.typography.bodyMedium.weight(.medium))
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)

                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(theme.colors.brandPrimary)
            }
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(theme.colors.surfaceElevated)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(theme.colors.borderDefault, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(word)
        .accessibilityHint(AppStrings.MilestoneReport.listenPronunciationA11y)
    }

    private var telemetryCard: some View {
        CraftCard(surfaceStyle: .tactile3D, cornerRadius: theme.radius.lg, padding: theme.spacing.base) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                Text(AppStrings.MilestoneReport.telemetryTitle)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)

                HStack(alignment: .top, spacing: theme.spacing.xs) {
                    telemetryMetric(
                        label: AppStrings.MilestoneReport.latencyLabel,
                        value: AppStrings.MilestoneReport.latencyValue(
                            seconds: delta.avgResponseTimeMs > 0 ? (delta.avgResponseTimeMs / 1000.0) : 1.2
                        )
                    )

                    Spacer(minLength: theme.spacing.xs)

                    telemetryMetric(
                        label: AppStrings.MilestoneReport.retentionLabel,
                        value: AppStrings.MilestoneReport.retentionValue(
                            percent: Int(round(delta.accuracyRate * 100))
                        )
                    )

                    Spacer(minLength: theme.spacing.xs)

                    telemetryMetric(
                        label: AppStrings.MilestoneReport.wordsMasteredLabel,
                        value: AppStrings.MilestoneReport.wordsMasteredValue(count: delta.wordsMastered)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func telemetryMetric(label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
            Text(value)
                .font(theme.typography.metricRounded)
                .foregroundStyle(theme.colors.textPrimary)

            Text(label)
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var cefrProgressCard: some View {
        CraftCard(surfaceStyle: .tactile3D, cornerRadius: theme.radius.lg, padding: theme.spacing.base) {
            VStack(alignment: .leading, spacing: theme.spacing.sm) {
                HStack {
                    Text(AppStrings.MilestoneReport.cefrProgressTitle(level: delta.cefrLevel))
                        .font(theme.typography.titleMedium.weight(.semibold))
                        .foregroundStyle(theme.colors.textPrimary)

                    Spacer()

                    Text(AppStrings.MilestoneReport.cefrProgressDetail(
                        current: delta.cefrProgressCurrent,
                        target: targetStandardCount,
                        percent: progressPercent
                    ))
                    .font(theme.typography.caption.monospacedDigit())
                    .foregroundStyle(theme.colors.textSecondary)
                }

                CraftProgressBar(
                    progress: progressFraction,
                    height: 10,
                    tintColor: theme.colors.brandPrimary,
                    trackColor: theme.colors.borderDefault,
                    cornerRadius: theme.radius.full
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: theme.spacing.sm) {
            CraftButton(
                AppStrings.MilestoneReport.continueCta,
                variant: .primary,
                size: .lg,
                isFullWidth: true,
                action: onContinue
            )

            CraftButton(
                AppStrings.MilestoneReport.viewVaultCta,
                variant: .subtle,
                size: .md,
                isFullWidth: true,
                action: onOpenVault
            )
        }
    }
}
