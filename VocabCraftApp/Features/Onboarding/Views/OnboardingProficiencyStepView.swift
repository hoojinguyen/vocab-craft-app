import CraftUIKit
import SwiftUI

public struct OnboardingProficiencyStepView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.craftTheme) private var theme

    private struct ProficiencyLevelItem: Identifiable {
        let id: String
        let titleKey: LocalizedStringKey
        let descKey: LocalizedStringKey
    }

    private let levels: [ProficiencyLevelItem] = [
        ProficiencyLevelItem(id: "A1", titleKey: "app.onboarding.level.a1", descKey: "app.onboarding.level.a1_desc"),
        ProficiencyLevelItem(id: "A2", titleKey: "app.onboarding.level.a2", descKey: "app.onboarding.level.a2_desc"),
        ProficiencyLevelItem(id: "B1", titleKey: "app.onboarding.level.b1_b2", descKey: "app.onboarding.level.b1_b2_desc"),
        ProficiencyLevelItem(id: "C1", titleKey: "app.onboarding.level.c1", descKey: "app.onboarding.level.c1_desc")
    ]

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.lg) {
            VStack(alignment: .leading, spacing: theme.spacing.xs) {
                Text("app.onboarding.level.title")
                    .font(theme.typography.titleLarge)
                    .foregroundStyle(theme.colors.textPrimary)

                Text("app.onboarding.level.subtitle")
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(.horizontal, theme.spacing.base)

            ScrollView(showsIndicators: false) {
                VStack(spacing: theme.spacing.md) {
                    ForEach(levels, id: \.id) { level in
                        CraftChoiceCard(
                            prefix: LocalizedStringKey(level.id),
                            prefixStyle: .roundedSquare,
                            title: level.titleKey,
                            subtitle: level.descKey,
                            state: viewModel.selectedCefrLevel == level.id ? .selected : .idle,
                            showsStatusIndicator: false,
                            action: {
                                CraftHaptics.shared.selection()
                                viewModel.selectedCefrLevel = level.id
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
