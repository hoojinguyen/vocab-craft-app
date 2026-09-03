import CraftUIKit
import SwiftUI

public struct OnboardingGoalStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    private struct GoalOptionItem: Identifiable {
        let id: String
        let titleKey: LocalizedStringKey
        let descKey: LocalizedStringKey
    }

    private let goals: [GoalOptionItem] = [
        GoalOptionItem(id: "deck_daily", titleKey: "app.onboarding.goal.daily", descKey: "app.onboarding.goal.daily_desc"),
        GoalOptionItem(id: "deck_business", titleKey: "app.onboarding.goal.business", descKey: "app.onboarding.goal.business_desc"),
        GoalOptionItem(id: "deck_academic", titleKey: "app.onboarding.goal.academic", descKey: "app.onboarding.goal.academic_desc"),
        GoalOptionItem(id: "deck_tech", titleKey: "app.onboarding.goal.tech", descKey: "app.onboarding.goal.tech_desc")
    ]

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("app.onboarding.goal.title")
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("app.onboarding.goal.subtitle")
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.base)

            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacing.md) {
                    ForEach(goals, id: \.id) { goal in
                        CraftChoiceCard(
                            prefix: nil as LocalizedStringKey?,
                            prefixStyle: .none,
                            title: goal.titleKey,
                            subtitle: goal.descKey,
                            state: viewModel.selectedDeckId == goal.id ? .selected : .idle,
                            showsStatusIndicator: false,
                            action: {
                                CraftHaptics.shared.selection()
                                viewModel.selectedDeckId = goal.id
                            }
                        )
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }

            Spacer()

            CraftButton(
                "app.onboarding.common.continue",
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
    }
}
