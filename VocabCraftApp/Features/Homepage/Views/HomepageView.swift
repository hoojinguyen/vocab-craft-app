import SwiftUI

/// Integrated Homepage view showcasing Bento grid layout, dark mode aesthetic, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel
    @State private var vocabularyVM: VocabularyViewModel?
    @State private var settingsVM: SettingsViewModel?
    @State private var reflexBlitzVM: ReflexBlitzViewModel?
    @State private var selectedTab: TabItem
    @Environment(\.appContainer) private var appContainer
    @Environment(\.appRouter) private var appRouter

    private var reflexBlitzViewId: String {
        guard let vm = reflexBlitzVM else { return "default" }
        return "\(vm.selectedMode.rawValue)-\(vm.phase)-\(vm.cardPhase)"
    }

    @MainActor
    public init(viewModel: HomepageViewModel, initialTab: TabItem = .home) {
        let args = ProcessInfo.processInfo.arguments
        let resolvedTab: TabItem
        if args.contains("-tab-reflex") || args.contains("-reflex-mode") || args.contains("-reflex-phase") {
            resolvedTab = .reflex
        } else if args.contains("-tab-vocabulary") {
            resolvedTab = .vocabulary
        } else if args.contains("-tab-settings") {
            resolvedTab = .settings
        } else {
            resolvedTab = initialTab
        }

        var vmState = viewModel.state
        vmState.selectedTab = resolvedTab
        self._viewModel = State(initialValue: HomepageViewModel(
            initialState: vmState,
            fetchVocabularyUseCase: viewModel.fetchVocabularyUseCase,
            ttsService: viewModel.ttsService
        ))
        self._selectedTab = State(initialValue: resolvedTab)

        if let modeIdx = args.firstIndex(of: "-reflex-mode"), modeIdx + 1 < args.count {
            let modeStr = args[modeIdx + 1]
            let mode = ReflexBlitzMode(rawValue: modeStr) ?? .speaking
            let phaseStr = args.firstIndex(of: "-reflex-phase").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
            let stateStr = args.firstIndex(of: "-reflex-state").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
            let hint = args.contains("-reflex-hint")
            let combo = args.firstIndex(of: "-reflex-combo").flatMap { $0 + 1 < args.count ? Int(args[$0 + 1]) : nil } ?? 0
            let phase: ReflexBlitzPhase = (phaseStr == "summary") ? .summary : ((phaseStr == "modeSelection") ? .modeSelection : .drilling)

            let config = ReflexBlitzDeepLinkConfig(mode: mode, phase: phase, state: stateStr, showHint: hint, combo: combo)
            let vm = AppContainer.mock.makeReflexBlitzViewModel()
            vm.applyReviewConfig(config)
            self._reflexBlitzVM = State(initialValue: vm)
        } else if let phaseIdx = args.firstIndex(of: "-reflex-phase"), phaseIdx + 1 < args.count {
            let phaseStr = args[phaseIdx + 1]
            if phaseStr == "summary" {
                let config = ReflexBlitzDeepLinkConfig(mode: .speaking, phase: .summary, state: nil, showHint: false, combo: 4)
                let vm = AppContainer.mock.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self._reflexBlitzVM = State(initialValue: vm)
            }
        }
    }



    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.vocabCanvas
                .ignoresSafeArea()

            switch selectedTab {
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
                                selectedTab = .reflex
                            },
                            onQueueTap: {
                                selectedTab = .vocabulary
                            }
                        )

                        CEFRDistributionCard(
                            onDetailTap: {
                                selectedTab = .vocabulary
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
                    selectedTab = .home
                })
                .id(reflexBlitzViewId)
            case .settings:
                SettingsView(viewModel: settingsVM ?? appContainer.makeSettingsViewModel())
            }

            if selectedTab != .reflex {
                LiquidGlassTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            print(">>> [HomepageView.onAppear] ARGS: \(args)")
            if vocabularyVM == nil {
                vocabularyVM = appContainer.makeVocabularyViewModel()
            }
            if settingsVM == nil {
                settingsVM = appContainer.makeSettingsViewModel()
            }

            if let modeIdx = args.firstIndex(of: "-reflex-mode"), modeIdx + 1 < args.count {
                let modeStr = args[modeIdx + 1]
                let mode = ReflexBlitzMode(rawValue: modeStr) ?? .speaking
                let phaseStr = args.firstIndex(of: "-reflex-phase").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
                let stateStr = args.firstIndex(of: "-reflex-state").flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil }
                let hint = args.contains("-reflex-hint")
                let combo = args.firstIndex(of: "-reflex-combo").flatMap { $0 + 1 < args.count ? Int(args[$0 + 1]) : nil } ?? 0
                let phase: ReflexBlitzPhase = (phaseStr == "summary") ? .summary : ((phaseStr == "modeSelection") ? .modeSelection : .drilling)

                let config = ReflexBlitzDeepLinkConfig(mode: mode, phase: phase, state: stateStr, showHint: hint, combo: combo)
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
                self.selectedTab = .reflex
                print(">>> [HomepageView] Switched to .reflex with mode=\(mode), phase=\(phase)")
            } else if let phaseIdx = args.firstIndex(of: "-reflex-phase"), phaseIdx + 1 < args.count {
                let phaseStr = args[phaseIdx + 1]
                if phaseStr == "summary" {
                    let config = ReflexBlitzDeepLinkConfig(mode: .speaking, phase: .summary, state: nil, showHint: false, combo: 4)
                    let vm = appContainer.makeReflexBlitzViewModel()
                    vm.applyReviewConfig(config)
                    self.reflexBlitzVM = vm
                    self.selectedTab = .reflex
                }
            } else if selectedTab == .reflex && reflexBlitzVM == nil {
                let vm = appContainer.makeReflexBlitzViewModel()
                self.reflexBlitzVM = vm
            }
        }
        .onOpenURL { url in
            appContainer.appRouter.handleDeepLink(url: url)
            if let config = appContainer.appRouter.pendingReflexBlitzConfig {
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
                self.selectedTab = .reflex
            }
        }
        .onChange(of: appContainer.appRouter.pendingReflexBlitzConfig) { _, newConfig in
            if let config = newConfig {
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
                self.selectedTab = .reflex
            }
        }
        .preferredColorScheme(appContainer.userSettingsStore.colorScheme)
        .environment(\.locale, appContainer.userSettingsStore.appLocale ?? .autoupdatingCurrent)
    }
}




