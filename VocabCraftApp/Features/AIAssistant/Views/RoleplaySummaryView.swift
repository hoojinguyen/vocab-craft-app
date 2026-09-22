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

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    CraftIcon(.sparkles, size: .xl, color: theme.colors.accent)
                        .padding(.top, theme.spacing.xl)

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
                                    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
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

                    CraftButton(
                        AppStrings.AIAssistant.actionDone,
                        variant: .primary,
                        size: .lg,
                        isFullWidth: true
                    ) {
                        onDismiss()
                    }
                    .padding(.horizontal, theme.spacing.base)
                    .padding(.top, theme.spacing.md)
                    .padding(.bottom, theme.spacing.xl)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .craftConfetti(isTriggered: $confettiTrigger, particleCount: 36)
    }
}
