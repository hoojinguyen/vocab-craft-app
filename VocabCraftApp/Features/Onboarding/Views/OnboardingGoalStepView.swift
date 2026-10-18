import CraftUIKit
import SwiftUI

public struct OnboardingGoalStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme
    @Environment(\.locale) private var locale

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text(AppStrings.Onboarding.goalTitle)
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(AppStrings.Onboarding.goalSubtitle)
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.base)

            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacing.md) {
                    ForEach(viewModel.learningPaths) { path in
                        CraftChoiceCard(
                            prefix: nil as String?,
                            prefixStyle: .none,
                            title: localizedTitle(for: path),
                            subtitle: localizedDescription(for: path),
                            state: isSelected(path) ? .selected : .idle,
                            showsStatusIndicator: false,
                            action: {
                                CraftHaptics.shared.selection()
                                viewModel.selectedPathId = path.code
                            }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }

            Spacer()

            CraftButton(
                AppStrings.Onboarding.continue,
                variant: .primary,
                size: .lg,
                isFullWidth: true
            ) {
                viewModel.nextStep()
            }
            .disabled(!viewModel.canContinue)
            .padding(.horizontal, theme.spacing.base)
            .padding(.bottom, theme.spacing.base)
        }
        .task {
            await viewModel.loadLearningPaths()
        }
    }

    // MARK: - Helpers

    private func isSelected(_ path: LearningPathDTO) -> Bool {
        viewModel.selectedPathId == path.code || viewModel.selectedPathId == path.id
    }

    private func localizedTitle(for path: LearningPathDTO) -> String {
        let isVietnamese = locale.identifier.hasPrefix("vi")
        if isVietnamese {
            return path.titleVi.isEmpty ? path.titleEn : path.titleVi
        } else {
            return path.titleEn.isEmpty ? path.titleVi : path.titleEn
        }
    }

    private func localizedDescription(for path: LearningPathDTO) -> String? {
        let isVietnamese = locale.identifier.hasPrefix("vi")
        if isVietnamese {
            return path.descriptionVi ?? path.descriptionEn
        } else {
            return path.descriptionEn ?? path.descriptionVi
        }
    }
}
