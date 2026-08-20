import SwiftUI

/// Integrated Homepage view showcasing Bento grid layout, dark mode aesthetic, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel
    @State private var vocabularyVM: VocabularyViewModel?
    @State private var settingsVM: SettingsViewModel?
    @Environment(\.appContainer) private var appContainer
    @Environment(\.appRouter) private var appRouter
    @State private var fallbackRouter = AppRouter()

    private var currentRouter: AppRouter {
        appRouter ?? appContainer.appRouter
    }

    @MainActor
    public init(viewModel: HomepageViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.vocabCanvas
                .ignoresSafeArea()

            switch currentRouter.selectedTab {
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
                                currentRouter.navigateToReflex()
                            },
                            onQueueTap: {
                                currentRouter.navigateToVocabulary()
                            }
                        )

                        CEFRDistributionCard(
                            onDetailTap: {
                                currentRouter.navigateToVocabulary()
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
                VocabularyView(viewModel: vocabularyVM ?? appContainer.makeVocabularyViewModel())
            case .search:
                SearchNewWordView()
            case .reflex:
                ReflexBlitzView(viewModel: appContainer.makeReflexBlitzViewModel(), onDismiss: {
                    currentRouter.navigateToHome()
                })
            case .settings:
                SettingsView(viewModel: settingsVM ?? appContainer.makeSettingsViewModel())
            }

            if currentRouter.selectedTab != .reflex {
                LiquidGlassTabBar(selectedTab: Binding(
                    get: { currentRouter.selectedTab },
                    set: { currentRouter.selectTab($0) }
                ))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if vocabularyVM == nil {
                vocabularyVM = appContainer.makeVocabularyViewModel()
            }
            if settingsVM == nil {
                settingsVM = appContainer.makeSettingsViewModel()
            }
        }
        .preferredColorScheme(appContainer.userSettingsStore.colorScheme)
        .environment(\.locale, appContainer.userSettingsStore.appLocale ?? .autoupdatingCurrent)
    }
}
