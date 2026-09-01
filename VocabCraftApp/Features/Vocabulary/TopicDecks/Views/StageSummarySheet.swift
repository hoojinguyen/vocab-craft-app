import CraftUIKit
import SwiftUI

/// Step 3 of the Stage Learning Flow: Stage completion summary displaying XP earned, correct count, accuracy, weak words flagged for review, and unlock next stage CTA.
public struct StageSummarySheet: View {
    @Environment(\.craftTheme) private var theme

    public let summary: StageCompletionSummary
    public let onFinish: () -> Void
    public let onRestart: () -> Void

    @State private var triggerHaptic: Bool = false

    public init(
        summary: StageCompletionSummary,
        onFinish: @escaping () -> Void,
        onRestart: @escaping () -> Void
    ) {
        self.summary = summary
        self.onFinish = onFinish
        self.onRestart = onRestart
    }

    private var accuracyPercentage: Int {
        guard summary.totalQuestions > 0 else { return 100 }
        return Int((Double(summary.correctCount) / Double(summary.totalQuestions)) * 100)
    }

    private var isPassed: Bool {
        accuracyPercentage >= 70
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground.ignoresSafeArea()

            #if canImport(UIKit)
            if isPassed {
                ConfettiParticleView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            #endif

            VStack(spacing: 24) {
                Spacer()

                // Celebration Icon
                celebrationBadge

                // Headline & Subtitle
                VStack(spacing: 6) {
                    Text(isPassed ? AppStrings.TopicDecks.StageSummary.passedTitle : AppStrings.TopicDecks.StageSummary.failedTitle)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(theme.colors.textPrimary)

                    Text(isPassed ? AppStrings.TopicDecks.StageSummary.passedSubtitle : AppStrings.TopicDecks.StageSummary.failedSubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                // Stats Dashboard Grid
                statsDashboardGrid
                    .padding(.horizontal, 20)

                // Weak Words Callout (if any)
                if !summary.weakWordIds.isEmpty {
                    weakWordsCallout
                        .padding(.horizontal, 20)
                }

                Spacer()

                // Action Buttons
                actionButtons
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            triggerHaptic = true
        }
        .sensoryFeedback(isPassed ? .success : .warning, trigger: triggerHaptic)
    }

    // MARK: - Celebration Badge
    private var celebrationBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isPassed
                            ? [theme.colors.accent.opacity(0.2), theme.colors.accent.opacity(0.1)]
                            : [theme.colors.statusDanger.opacity(0.2), theme.colors.statusDanger.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 96, height: 96)

            Image(systemName: isPassed ? "trophy.fill" : "arrow.counterclockwise.circle.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(isPassed ? theme.colors.accent : theme.colors.statusDanger)
                .symbolEffect(.bounce, value: triggerHaptic)
        }
    }

    // MARK: - Stats Dashboard Grid
    private var statsDashboardGrid: some View {
        HStack(spacing: 12) {
            statMetricCard(
                title: "+\(max(0, summary.xpEarned)) XP",
                label: AppStrings.TopicDecks.StageSummary.xpEarnedText,
                color: theme.colors.statusSuccess
            )

            statMetricCard(
                title: "\(summary.correctCount)/\(summary.totalQuestions)",
                label: AppStrings.TopicDecks.StageSummary.correctText,
                color: theme.colors.textPrimary
            )

            statMetricCard(
                title: "\(accuracyPercentage)%",
                label: AppStrings.TopicDecks.StageSummary.accuracyText,
                color: isPassed ? theme.colors.statusSuccess : theme.colors.statusDanger
            )
        }
    }

    private func statMetricCard(title: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(theme.colors.surfaceCard)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.colors.hairline, lineWidth: 1)
        )
    }

    // MARK: - Weak Words Callout
    private var weakWordsCallout: some View {
        HStack(spacing: 10) {
            Image(systemName: "flag.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(theme.colors.statusDanger)

            VStack(alignment: .leading, spacing: 2) {
                Text(AppStrings.TopicDecks.StageSummary.weakWordsCount(summary.weakWordIds.count))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(theme.colors.textPrimary)

                Text(AppStrings.TopicDecks.StageSummary.weakWordsDesc)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.colors.textSecondary)
            }

            Spacer()
        }
        .padding(12)
        .background(theme.colors.statusDanger.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.colors.statusDanger.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary Finish / Next CTA
            Button(action: onFinish) {
                HStack(spacing: 8) {
                    Text(isPassed ? AppStrings.TopicDecks.StageSummary.finishContinue : AppStrings.TopicDecks.StageSummary.continuePath)
                        .font(.system(size: 15, weight: .bold))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: isPassed
                            ? [theme.colors.statusSuccess, theme.colors.statusSuccess.opacity(0.85)]
                            : [theme.colors.brandPrimary, theme.colors.brandPrimary.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: (isPassed ? theme.colors.statusSuccess : theme.colors.brandPrimary).opacity(0.35), radius: 8, x: 0, y: 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(BentoCardButtonStyle())

            // Secondary Restart CTA
            Button(action: onRestart) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text(AppStrings.TopicDecks.StageSummary.restartStage)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(theme.colors.textSecondary)
                .padding(.vertical, 8)
            }
        }
    }
}
