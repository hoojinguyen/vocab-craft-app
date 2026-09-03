import CraftUIKit
import SwiftUI

public struct OnboardingRoadmapRevealStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: theme.spacing.xl) {
            Spacer()

            if viewModel.isSynthesizing {
                VStack(spacing: theme.spacing.lg) {
                    CraftPulsingAuraRing(
                        color: theme.colors.brandPrimary,
                        size: 64,
                        lineWidth: 3.5
                    )

                    Text(LocalizedStringKey(viewModel.synthesisPhaseTextKey))
                        .font(theme.typography.titleMedium)
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                .padding(.horizontal, theme.spacing.base)
            } else if let result = viewModel.roadmapResult {
                VStack(spacing: theme.spacing.lg) {
                    CraftCard(style: .elevated) {
                        VStack(spacing: theme.spacing.base) {
                            HStack {
                                CraftBadge(
                                    viewModel.selectedCefrLevel,
                                    variant: .subtle,
                                    tone: .primary,
                                    size: .md
                                )
                                Spacer()
                                Text(result.startingStage.title)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }

                            Divider()

                            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                                Text("app.onboarding.reveal.ready")
                                    .font(theme.typography.titleLarge)
                                    .foregroundStyle(theme.colors.textPrimary)

                                let projectedWords = Int64(viewModel.selectedDailyWords * 30)
                                let projectionText = String(
                                    format: String(localized: "app.onboarding.reveal.projection_format", defaultValue: "With %lld words/day, you'll master %lld words in 30 days!", bundle: .module),
                                    Int64(viewModel.selectedDailyWords),
                                    projectedWords
                                )

                                Text(projectionText)
                                    .font(theme.typography.bodyMedium)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, theme.spacing.base)

                    if let errorMsg = viewModel.errorMessage {
                        Text(errorMsg)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.statusDanger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, theme.spacing.base)
                    }

                    CraftButton(
                        viewModel.errorMessage != nil
                            ? LocalizedStringKey("craft.common.action.retry")
                            : LocalizedStringKey("app.onboarding.reveal.cta"),
                        variant: .primary,
                        size: .lg,
                        isFullWidth: true
                    ) {
                        if viewModel.errorMessage != nil {
                            viewModel.errorMessage = nil
                            viewModel.completeOnboardingAndDismiss()
                        } else {
                            viewModel.startFirstLesson()
                        }
                    }
                    .padding(.horizontal, theme.spacing.base)
                }
                .transition(.scale.combined(with: .opacity))
            } else if let errorMsg = viewModel.errorMessage {
                VStack(spacing: theme.spacing.lg) {
                    Text(errorMsg)
                        .font(theme.typography.bodyMedium)
                        .foregroundStyle(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)

                    CraftButton(
                        "craft.common.action.retry",
                        variant: .secondary,
                        size: .md
                    ) {
                        viewModel.retrySynthesis()
                    }
                }
                .padding(.horizontal, theme.spacing.base)
            }

            Spacer()
        }
    }
}
