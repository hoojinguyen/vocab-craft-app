import SwiftUI

/// Integrated Homepage view showcasing Bento grid layout, dark mode aesthetic, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel
    @Environment(\.appContainer) private var appContainer

    @MainActor
    public init(viewModel: HomepageViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
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
                .task {
                    await viewModel.loadData()
                }

            case .vocabulary:
                if let appContainer = appContainer {
                    VocabularyView(viewModel: appContainer.makeVocabularyViewModel())
                } else {
                    VocabularyView()
                }
            case .search:
                SearchNewWordView()
            case .reflex:
                if let appContainer = appContainer {
                    ReflexDrillView(viewModel: appContainer.makeReflexDrillViewModel(), onDismiss: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            viewModel.selectTab(.home)
                        }
                    })
                } else {
                    Text("AppContainer is missing")
                }
            case .settings:
                if let appContainer = appContainer {
                    SettingsView(viewModel: appContainer.makeSettingsViewModel())
                } else {
                    Text("AppContainer is missing")
                }
            }

            if viewModel.selectedTab != .reflex {
                LiquidGlassTabBar(selectedTab: $viewModel.selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .preferredColorScheme(appContainer?.userSettingsStore.colorScheme)
        .environment(\.locale, appContainer?.userSettingsStore.appLocale ?? .autoupdatingCurrent)
    }
}
