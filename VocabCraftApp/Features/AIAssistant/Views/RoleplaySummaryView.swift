import CraftUIKit
import SwiftUI

public struct RoleplaySummaryView: View {
    public let summary: RoleplaySessionSummary
    public let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme
    @State private var confettiTrigger = true

    public init(summary: RoleplaySessionSummary, onDismiss: @escaping () -> Void) {
        self.summary = summary
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.lg) {
                Spacer()

                CraftIcon(.sparkles, size: .xl, color: theme.colors.accent)

                Text(AppStrings.AIAssistant.summaryCongratulations)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)

                CraftCard(style: .outlined, cornerRadius: theme.radii.xl, padding: theme.spacing.lg) {
                    VStack(spacing: theme.spacing.md) {
                        HStack {
                            Text(AppStrings.AIAssistant.summaryFluencyScore)
                                .font(theme.typography.bodyLarge)
                                .foregroundStyle(theme.colors.textSecondary)
                            Spacer()
                            Text("\(summary.fluencyScore)%")
                                .font(theme.typography.titleLarge)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.statusSuccess)
                        }

                        Divider()

                        HStack {
                            Text(AppStrings.AIAssistant.summaryMasteredWords)
                                .font(theme.typography.bodyLarge)
                                .foregroundStyle(theme.colors.textSecondary)
                            Spacer()
                            Text("\(summary.targetWordsMastered.count) / \(summary.targetWordsAttempted.count)")
                                .font(theme.typography.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.brandPrimary)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.base)

                if !summary.refinements.isEmpty {
                    CraftCard(style: .outlined, cornerRadius: theme.radii.xl, padding: theme.spacing.md) {
                        VStack(alignment: .leading, spacing: theme.spacing.xs) {
                            Text(AppStrings.AIAssistant.summaryTakeawaysTitle)
                                .font(theme.typography.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.textPrimary)

                            ForEach(summary.refinements) { refinement in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(refinement.originalUserSentence)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.textMuted)
                                    Text(refinement.refinedNativeSentence)
                                        .font(theme.typography.bodyMedium)
                                        .foregroundStyle(theme.colors.brandPrimary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, theme.spacing.base)
                }

                Spacer()

                CraftButton(
                    AppStrings.AIAssistant.actionDone,
                    variant: .primary,
                    size: .lg,
                    isFullWidth: true
                ) {
                    onDismiss()
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .craftConfetti(isTriggered: $confettiTrigger, particleCount: 36)
    }
}
