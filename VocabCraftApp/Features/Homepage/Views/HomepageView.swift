import SwiftUI

/// Integrated Homepage view showcasing Bento grid layout, dark mode aesthetic, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel

    @MainActor
    public init(viewModel: HomepageViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    @MainActor
    public init(ttsService: TextToSpeechProtocol? = nil) {
        self._viewModel = State(wrappedValue: HomepageViewModel(ttsService: ttsService))
    }

    @MainActor
    public init(
        userName: String = "Hooji N.",
        streakDays: Int = 14,
        dailyGoalProgress: Double = 0.75,
        dueCardsCount: Int = 24,
        totalWords: Int = 1420,
        retentionPercentage: Double = 0.85,
        unreadNotifications: Bool = true,
        ttsService: TextToSpeechProtocol? = nil
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
        self._viewModel = State(wrappedValue: HomepageViewModel(initialState: state, ttsService: ttsService))
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
                            },
                            onSpeakTap: { word in
                                viewModel.speakSuggestedWord(word)
                            }
                        )

                        SRSMemoryHeroCard(
                            totalWords: viewModel.state.totalWords,
                            retentionPercentage: viewModel.state.retentionPercentage
                        )

                        ActionCardsGrid(
                            dueCardsCount: viewModel.state.dueCardsCount,
                            onReflexTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.selectTab(.reflex)
                                }
                            },
                            onQueueTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.selectTab(.vocabulary)
                                }
                            }
                        )

                        CEFRDistributionCard(
                            onDetailTap: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.selectTab(.vocabulary)
                                }
                            }
                        )

                        Spacer(minLength: 100)
                    }
                    .padding(.top)
                }
            case .vocabulary:
                VocabularyView()
            case .search:
                SearchNewWordView()
            case .reflex:
                ReflexDrillView(onDismiss: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        viewModel.selectTab(.home)
                    }
                })
            case .settings:
                SettingsView(viewModel: viewModel.settingsViewModel)
            }

            if viewModel.selectedTab != .reflex {
                LiquidGlassTabBar(selectedTab: $viewModel.selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(viewModel.settingsViewModel.store.colorScheme)
    }
}
