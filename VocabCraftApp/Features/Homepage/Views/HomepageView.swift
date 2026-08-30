import CraftUIKit
import SwiftUI

enum HomepageTabBarPresentationPolicy {
    static func presentation(
        for tab: TabItem,
        current: CraftTabBarPresentation
    ) -> CraftTabBarPresentation {
        tab == .home ? current : .expanded
    }
}

/// Integrated Homepage view showcasing in-scroll HomeTopHeaderView, CraftLearningPath gamified journey, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel
    @State private var vaultVM: PersonalVaultViewModel?
    @State private var settingsVM: SettingsViewModel?
    @State private var reflexBlitzVM: ReflexBlitzViewModel?
    @State private var activeLessonNode: LessonNodeModel?
    @State private var tabBarPresentation: CraftTabBarPresentation = .expanded
    @Environment(\.appContainer) private var appContainer
    @Environment(\.appRouter) private var appRouter

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
                CraftLearningPath(
                    sections: viewModel.sections,
                    winding: .standard,
                    rowPattern: .standard,
                    onNodeTap: { node in
                        MainActor.assumeIsolated {
                            viewModel.handleNodeTap(node)
                        }
                    },
                    onStartLesson: { node in
                        MainActor.assumeIsolated {
                            startLesson(for: node)
                        }
                    },
                    showDetailModal: true,
                    scrollToActive: true,
                    showCelebration: false,
                    pinSectionHeaders: true,
                    topHeaderBuilder: {
                        AnyView(
                            HomeTopHeaderView(
                                userName: viewModel.userName,
                                streakDays: viewModel.streakDays,
                                dailyWordsLearned: viewModel.dailyWordsLearned,
                                dailyWordsGoal: viewModel.dailyWordsGoal,
                                onAvatarTap: {
                                    appRouter.navigateToSettings()
                                }
                            )
                        )
                    },
                    onTabBarPresentationChange: { presentation in
                        MainActor.assumeIsolated {
                            tabBarPresentation = presentation
                        }
                    }
                )
                .task {
                    if viewModel.sections.isEmpty {
                        await viewModel.loadLearningPath()
                    }
                }

            case .vocabulary:
                VocabularyView(vaultViewModel: vaultVM ?? appContainer.makePersonalVaultViewModel())
            case .search:
                SearchNewWordView()
            case .reflex:
                ReflexBlitzView(
                    viewModel: reflexBlitzVM ?? appContainer.makeReflexBlitzViewModel(),
                    onDismiss: {
                        handleReflexDismiss()
                    },
                    onFinishSession: { summary in
                        handleReflexSessionFinished(summary: summary)
                    }
                )
                .ignoresSafeArea(edges: .bottom)
            case .settings:
                SettingsView(viewModel: settingsVM ?? appContainer.makeSettingsViewModel())
            }

            if router.selectedTab != .reflex {
                CraftFloatingTabBar(
                    selectedItem: $router.selectedTab,
                    items: TabItem.navigationTabs,
                    style: .glass,
                    size: .md,
                    presentation: tabBarPresentation,
                    centerPosition: .floating,
                    centerAction: {
                        router.navigateToReflex()
                    },
                    centerSymbol: CraftSymbol.practice.rawValue,
                    centerTitleKey: AppStrings.Tabs.reflex
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            if vaultVM == nil {
                vaultVM = appContainer.makePersonalVaultViewModel()
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
        .onChange(of: appRouter.selectedTab) { _, newTab in
            if newTab == .reflex && reflexBlitzVM == nil {
                self.reflexBlitzVM = appContainer.makeReflexBlitzViewModel()
            }
            tabBarPresentation = HomepageTabBarPresentationPolicy.presentation(
                for: newTab,
                current: tabBarPresentation
            )
        }
        .environment(\.locale, appContainer.userSettingsStore.appLocale ?? .autoupdatingCurrent)
    }

    private func startLesson(for node: LessonNodeModel) {
        Task {
            let words: [TopicWordDTO]
            if node.id.hasPrefix("checkpoint_") {
                let deckId = String(node.id.dropFirst("checkpoint_".count))
                let stages = (try? await appContainer.vocabularyDataSource.fetchSubTopicStages(deckId: deckId)) ?? []
                var deckWords: [TopicWordDTO] = []
                for stage in stages {
                    if let stageWords = try? await appContainer.vocabularyDataSource.fetchWordsForStage(stageId: stage.id) {
                        deckWords.append(contentsOf: stageWords)
                    }
                }
                words = deckWords
            } else {
                words = (try? await appContainer.vocabularyDataSource.fetchWordsForStage(stageId: node.id)) ?? []
            }

            let blitzWords = words.map { ReflexBlitzWordItem(from: $0) }
            let vm = appContainer.makeReflexBlitzViewModel(words: blitzWords.isEmpty ? ReflexBlitzWordItem.defaultStarterWords : blitzWords)
            self.activeLessonNode = node
            self.reflexBlitzVM = vm
            self.appRouter.navigateToReflex()
        }
    }

    private func handleReflexSessionFinished(summary: ReflexBlitzSessionSummary) {
        let node = activeLessonNode
        reflexBlitzVM = nil
        activeLessonNode = nil

        if let node {
            appRouter.navigateToHome()
            Task {
                let accuracy = summary.totalWords > 0 ? Double(summary.correctWords) / Double(summary.totalWords) : 1.0
                let stars = accuracy >= 0.95 ? 3 : (accuracy >= 0.80 ? 2 : 1)
                let weakWordIds = summary.weakWordAttempts.map { Int64($0.wordId) }
                let deckId = node.id.hasPrefix("checkpoint_")
                    ? String(node.id.dropFirst("checkpoint_".count))
                    : (viewModel.sections.first(where: { sec in sec.nodes.contains(where: { $0.id == node.id }) })?.id ?? "")

                _ = try? await appContainer.completeLessonUseCase.execute(
                    stageId: node.id,
                    deckId: deckId,
                    stars: stars,
                    weakWordIds: weakWordIds,
                    progressFraction: 1.0
                )
                await viewModel.loadLearningPath()
            }
        } else {
            let vm = appContainer.makeReflexBlitzViewModel()
            self.reflexBlitzVM = vm
        }
    }

    private func handleReflexDismiss() {
        reflexBlitzVM = nil
        activeLessonNode = nil
        appRouter.navigateToHome()
    }
}
