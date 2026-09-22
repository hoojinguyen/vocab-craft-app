import CraftUIKit
import SwiftUI

public struct AIAssistantHubView: View {
    @State private var viewModel: AIAssistantHubViewModel
    @State private var activeScenario: RoleplayScenario?
    @Environment(\.appContainer) private var appContainer
    @Environment(\.craftTheme) private var theme

    public init(viewModel: AIAssistantHubViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    CraftPageHeader(
                        AppStrings.AIAssistant.hubTitle,
                        alignment: .leading,
                        enableScrollFade: false
                    )

                    if let daily = viewModel.dailyScenario {
                        heroDailyCard(for: daily)
                    }

                    topicFilterBar

                    scenarioListSection

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.xs)
            }
        }
        .task {
            if viewModel.scenarios.isEmpty {
                await viewModel.loadScenarios()
            }
        }
        #if os(iOS)
        .fullScreenCover(item: $activeScenario) { scenario in
            RoleplayRoomView(
                viewModel: appContainer.makeRoleplayRoomViewModel(for: scenario),
                onDismiss: { activeScenario = nil }
            )
        }
        #else
        .sheet(item: $activeScenario) { scenario in
            RoleplayRoomView(
                viewModel: appContainer.makeRoleplayRoomViewModel(for: scenario),
                onDismiss: { activeScenario = nil }
            )
        }
        #endif
    }

    private func heroDailyCard(for scenario: RoleplayScenario) -> some View {
        CraftCard(
            style: .outlined,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.lg
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack {
                    CraftBadge(
                        AppStrings.AIAssistant.dailyMissionBadge,
                        symbol: .sparkles,
                        variant: .subtle,
                        tone: .primary,
                        size: .sm,
                        customTint: theme.colors.accent
                    )
                    Spacer()
                }

                Text(LocalizedStringKey(scenario.titleKey))
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(LocalizedStringKey(scenario.descriptionKey))
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)

                HStack(spacing: theme.spacing.xs) {
                    ForEach(scenario.targetWordIds, id: \.self) { word in
                        CraftBadge(
                            LocalizedStringKey(word),
                            variant: .subtle,
                            tone: .neutral,
                            size: .sm
                        )
                    }
                }

                CraftButton(
                    AppStrings.AIAssistant.actionStartRoleplay,
                    variant: .primary,
                    size: .md,
                    isFullWidth: true
                ) {
                    activeScenario = scenario
                }
                .padding(.top, theme.spacing.xs)
            }
        }
    }

    private var topicFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                topicPill(
                    title: AppStrings.AIAssistant.topicAll,
                    isSelected: viewModel.selectedTopic == nil
                ) {
                    viewModel.selectedTopic = nil
                }

                ForEach(ScenarioTopic.allCases, id: \.self) { topic in
                    topicPill(
                        title: localizedTopicTitle(for: topic),
                        isSelected: viewModel.selectedTopic == topic
                    ) {
                        viewModel.selectedTopic = topic
                    }
                }
            }
            .padding(.vertical, theme.spacing.xxs)
        }
    }

    private func localizedTopicTitle(for topic: ScenarioTopic) -> LocalizedStringKey {
        switch topic {
        case .dining: return AppStrings.AIAssistant.topicDining
        case .travel: return AppStrings.AIAssistant.topicTravel
        case .workplace: return AppStrings.AIAssistant.topicWorkplace
        case .dailyLife: return AppStrings.AIAssistant.topicDailyLife
        case .interview: return AppStrings.AIAssistant.topicInterview
        }
    }

    private func topicPill(
        title: LocalizedStringKey,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            CraftBadge(
                title,
                variant: isSelected ? .solid : .subtle,
                tone: isSelected ? .primary : .neutral,
                size: .md
            )
        }
        .buttonStyle(.plain)
    }

    private var scenarioListSection: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(viewModel.filteredScenarios.filter { $0.id != viewModel.dailyScenario?.id }) { scenario in
                CraftCard(
                    style: .outlined,
                    cornerRadius: theme.radii.lg,
                    padding: theme.spacing.md
                ) {
                    HStack(spacing: theme.spacing.md) {
                        CraftIcon(
                            scenario.iconSymbol,
                            size: .lg,
                            color: theme.colors.brandPrimary
                        )
                        .frame(width: 44, height: 44)
                        .background(theme.colors.brandPrimary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))

                        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                            Text(LocalizedStringKey(scenario.titleKey))
                                .font(theme.typography.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.textPrimary)

                            Text(LocalizedStringKey(scenario.descriptionKey))
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.textSecondary)
                        }

                        Spacer()

                        CraftButton(
                            AppStrings.AIAssistant.actionStartRoleplay,
                            variant: .secondary,
                            size: .sm
                        ) {
                            activeScenario = scenario
                        }
                    }
                }
            }
        }
    }
}
