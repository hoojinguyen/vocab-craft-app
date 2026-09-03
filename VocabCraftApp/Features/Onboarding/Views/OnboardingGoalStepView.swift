import CraftUIKit
import SwiftUI

public struct OnboardingGoalStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    private let goals: [(id: String, titleKey: LocalizedStringKey, descKey: LocalizedStringKey, icon: String)] = [
        ("deck_daily", "app.onboarding.goal.daily", "app.onboarding.goal.daily_desc", "bubble.left.and.bubble.right"),
        ("deck_business", "app.onboarding.goal.business", "app.onboarding.goal.business_desc", "briefcase"),
        ("deck_academic", "app.onboarding.goal.academic", "app.onboarding.goal.academic_desc", "graduationcap"),
        ("deck_tech", "app.onboarding.goal.tech", "app.onboarding.goal.tech_desc", "cpu")
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
