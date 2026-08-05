import SwiftUI

/// Integrated Homepage view showcasing Bento grid layout, dark mode aesthetic, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel

    @MainActor
    public init(viewModel: HomepageViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    @MainActor
    public init() {
        self._viewModel = State(wrappedValue: HomepageViewModel())
    }

    @MainActor
    public init(
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyGoalProgress: Double = 0.75,
        dueCardsCount: Int = 24,
        totalWords: Int = 1420,
        retentionPercentage: Double = 0.85,
        unreadNotifications: Bool = true
    ) {
        let state = HomepageState(
            userName: userName,
            streakDays: streakDays,
            dailyGoalProgress: dailyGoalProgress,
            dueCardsCount: dueCardsCount,
            totalWords: totalWords,
            retentionPercentage: retentionPercentage,
            unreadNotifications: unreadNotifications
        )
        self._viewModel = State(wrappedValue: HomepageViewModel(initialState: state))
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        ZStack(alignment: .bottom) {
            Color.vocabCanvas
                .ignoresSafeArea()

            switch viewModel.selectedTab {
            case .home:
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        HeaderView(
                            userName: viewModel.state.userName,
                            streakDays: viewModel.state.streakDays,
                            dailyGoalProgress: viewModel.state.dailyGoalProgress,
                            unreadNotifications: viewModel.state.unreadNotifications
                        )

                        SuggestedWordsCardView(
                            words: viewModel.suggestedWords,
                            selectedIndex: $viewModel.currentSuggestedWordIndex,
                            onBookmarkToggle: { id in
                                viewModel.toggleBookmarkSuggestedWord(id: id)
                            }
                        )

                        SRSMemoryHeroCard(
                            totalWords: viewModel.state.totalWords,
                            retentionPercentage: viewModel.state.retentionPercentage
                        )

                        ActionCardsGrid(
                            dueCardsCount: viewModel.state.dueCardsCount,
                            onReflexTap: {},
                            onQueueTap: {}
                        )

                        CEFRDistributionCard()

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            case .vocabulary:
                VocabularyView()
            case .search:
                SearchNewWordView()
            case .reflex, .settings:
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        HeaderView(
                            userName: viewModel.state.userName,
                            streakDays: viewModel.state.streakDays,
                            dailyGoalProgress: viewModel.state.dailyGoalProgress,
                            unreadNotifications: viewModel.state.unreadNotifications
                        )

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            }

            LiquidGlassTabBar(selectedTab: $viewModel.selectedTab)
        }
    }
}
