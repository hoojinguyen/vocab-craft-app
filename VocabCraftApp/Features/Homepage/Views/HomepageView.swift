import SwiftUI

/// Integrated Homepage view showcasing Bento grid layout, dark mode aesthetic, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel
    @State private var vocabularyVM: VocabularyViewModel?
    @State private var settingsVM: SettingsViewModel?
    @State private var reflexBlitzVM: ReflexBlitzViewModel?
    @Environment(\.appContainer) private var appContainer
    @Environment(\.appRouter) private var appRouter

    private var reflexBlitzViewId: String {
        guard let vm = reflexBlitzVM else { return "default" }
        return "\(vm.selectedMode.rawValue)-\(vm.phase)-\(vm.cardPhase)"
    }

    @MainActor
    public init(viewModel: HomepageViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var router = appRouter

        ZStack(alignment: .bottom) {
            Color.vocabCanvas
                .ignoresSafeArea()

            switch router.selectedTab {
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
                                router.navigateToReflex()
                            },
                            onQueueTap: {
                                router.navigateToVocabulary()
                            }
                        )

                        CEFRDistributionCard(
                            onDetailTap: {
                                router.navigateToVocabulary()
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
                ReflexBlitzView(viewModel: reflexBlitzVM ?? appContainer.makeReflexBlitzViewModel(), onDismiss: {
                    reflexBlitzVM = nil
                    router.navigateToHome()
                })
                .id(reflexBlitzViewId)
            case .settings:
                SettingsView(viewModel: settingsVM ?? appContainer.makeSettingsViewModel())
            }

            if router.selectedTab != .reflex {
                LiquidGlassTabBar(selectedTab: $router.selectedTab)
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

            if let config = appRouter.pendingReflexBlitzConfig {
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
            } else if appRouter.selectedTab == .reflex && reflexBlitzVM == nil {
                let vm = appContainer.makeReflexBlitzViewModel()
                self.reflexBlitzVM = vm
            }
        }
        .onOpenURL { url in
            appRouter.handleDeepLink(url: url)
            if let config = appRouter.pendingReflexBlitzConfig {
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
            }
        }
        .onChange(of: appRouter.pendingReflexBlitzConfig) { _, newConfig in
            if let config = newConfig {
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
            }
        }
        .preferredColorScheme(appContainer.userSettingsStore.colorScheme)
        .environment(\.locale, appContainer.userSettingsStore.appLocale ?? .autoupdatingCurrent)
    }
}

