import CraftUIKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum HomepageTabBarPresentationPolicy {
    static func presentation(
        for tab: TabItem,
        current: CraftTabBarPresentation
    ) -> CraftTabBarPresentation {
        tab == .home ? current : .expanded
    }
}

/// Integrated Homepage view showcasing in-scroll HomeTopHeaderView, CraftFluidJourney gamified journey, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel
    @State private var vaultVM: PersonalVaultViewModel?
    @State private var settingsVM: SettingsViewModel?
    @State private var reflexBlitzVM: ReflexBlitzViewModel?
    @State private var speakingHubVM: SpeakingHubViewModel?
    @State private var activeLessonLearningVM: LessonLearningViewModel?
    @State private var activeTreasureClaimNode: LessonNodeModel?
    @State private var lessonLaunchTask: Task<Void, Never>?
    @State private var isLaunchingLesson: Bool = false
    @State private var isHandlingLessonFinished: Bool = false
    @State private var tabBarPresentation: CraftTabBarPresentation = .expanded
    @State private var scrollToActiveNonce: Int = 0
    @State private var homeConfettiTrigger: Bool = false
    @State private var completionToastData: CraftToastData?
    @State private var isLearningPathSwitchPresented: Bool = false
    @State private var fastTrackAttemptDeckId: String?
    @Environment(\.appContainer) private var appContainer
    @Environment(\.appRouter) private var appRouter
    @Environment(\.craftTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var isReducedMotion

    @MainActor
    public init(viewModel: HomepageViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        @Bindable var router = appRouter

        ZStack(alignment: .bottom) {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            switch router.selectedTab {
            case .home:
                VStack(spacing: 0) {
                    HomeTopHeaderView(
                        userName: viewModel.userName,
                        streakDays: viewModel.streakDays,
                        dailyWordsLearned: viewModel.dailyWordsLearned,
                        dailyWordsGoal: viewModel.dailyWordsGoal,
                        totalWordsAcquired: viewModel.totalWordsAcquired,
                        currentCEFRLevel: viewModel.currentCEFRLevel,
                        onAvatarTap: {
                            CraftHaptics.shared.light()
                            appRouter.navigateToSettings()
                        },
                        onProgressTap: { scrollToActiveNonce += 1 },
                        onLexicalPillTap: { viewModel.presentVocabGrowthDashboard() }
                    )
                    .background(theme.colors.canvasBackground)

                    Group {
                        if (viewModel.isLoading && viewModel.sections.isEmpty) || ProcessInfo.processInfo.arguments.contains("-test-home-skeleton") {
                             HomeSkeletonView()
                        } else if let error = viewModel.errorMessage, viewModel.sections.isEmpty {
                            ContentUnavailableView {
                                Label(String(localized: "app.home.load_error_title", defaultValue: "Failed to load learning path", bundle: .module), systemImage: "wifi.exclamationmark")
                            } description: {
                                Text(error)
                                    .multilineTextAlignment(.center)
                            } actions: {
                                CraftButton(AppStrings.Common.retry, variant: .primary, size: .md) {
                                    Task { await viewModel.loadLearningPath() }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(theme.colors.canvasBackground)
                        } else {
                            CraftFluidJourney(
                                sections: viewModel.sections,
                                surfaceStyle: .tactile3D,
                                isSuspended: activeLessonLearningVM != nil || activeTreasureClaimNode != nil,
                                deckTitle: viewModel.currentDeckTitle,
                                deckSubtitle: viewModel.currentDeckSubtitle,
                                onNodeTap: { node in
                                    MainActor.assumeIsolated { viewModel.handleNodeTap(node) }
                                },
                                onStartLesson: { node in
                                    MainActor.assumeIsolated { startLesson(for: node) }
                                },
                                onTabBarPresentationChange: { presentation in
                                    MainActor.assumeIsolated {
                                        if tabBarPresentation != presentation {
                                            if isReducedMotion {
                                                tabBarPresentation = presentation
                                            } else {
                                                withAnimation(.smooth(duration: 0.2)) {
                                                    tabBarPresentation = presentation
                                                }
                                            }
                                        }
                                    }
                                },
                                onAdjustPlan: {
                                    MainActor.assumeIsolated { isLearningPathSwitchPresented = true }
                                },
                                scrollToActive: true,
                                externalScrollTrigger: scrollToActiveNonce,
                                detailSheetBuilder: { node, onStart, onDismiss in
                                    if node.kind == .treasureChest {
                                        let deckId = viewModel.resolvedDeckId(for: node)
                                        return AnyView(
                                            TreasureClaimSheet(
                                                node: node,
                                                deckId: deckId,
                                                onClaim: {
                                                    try await viewModel.claimTreasure(node: node)
                                                },
                                                onClaimSuccess: { result in
                                                    handleTreasureClaimSuccess(result)
                                                },
                                                onDismiss: onDismiss
                                            )
                                            .craftSurfaceStyle(.tactile3D)
                                            .presentationDetents([.fraction(0.52), .medium])
                                        )
                                    } else {
                                        return AnyView(
                                            CraftLessonDetailSheet(
                                                node: node,
                                                surfaceStyle: .tactile3D,
                                                onStart: onStart,
                                                onDismiss: {
                                                    fastTrackAttemptDeckId = nil
                                                    onDismiss()
                                                },
                                                onFastTrack: { checkpointNode in
                                                    let deckId = viewModel.resolvedDeckId(for: checkpointNode)
                                                    fastTrackAttemptDeckId = deckId
                                                    onDismiss()
                                                    startLesson(for: checkpointNode, isFastTrack: true)
                                                }
                                            )
                                            .craftSurfaceStyle(.tactile3D)
                                            .presentationDetents([.fraction(0.70), .large])
                                        )
                                    }
                                }
                            )
                            .refreshable {
                                await viewModel.loadLearningPath()
                            }
                        }
                    }
                    .task {
                        if viewModel.sections.isEmpty && !ProcessInfo.processInfo.arguments.contains("-test-home-skeleton") {
                            await viewModel.loadLearningPath()
                        }
                    }
                }

            case .vocabulary:
                VocabularyView(vaultViewModel: vaultVM ?? appContainer.makePersonalVaultViewModel())
            case .aiAssistant:
                SpeakingHubView(
                    viewModel: speakingHubVM ?? appContainer.makeSpeakingHubViewModel(),
                    appContainer: appContainer
                )
            case .reflex:
                ReflexBlitzView(
                    viewModel: reflexBlitzVM ?? appContainer.makeReflexBlitzViewModel(),
                    onDismiss: {
                        handleReflexDismiss()
                    },
                    onFinishSession: { _ in
                        handleReflexSessionFinished()
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
        .craftConfetti(isTriggered: $homeConfettiTrigger, particleCount: 36)
        .craftToast(item: $completionToastData, position: .top)
        .onAppear {
            viewModel.refreshDailyProgress()
            if vaultVM == nil {
                vaultVM = appContainer.makePersonalVaultViewModel()
            }
            if settingsVM == nil {
                settingsVM = appContainer.makeSettingsViewModel()
            }
            if appRouter.selectedTab == .aiAssistant, speakingHubVM == nil {
                speakingHubVM = appContainer.makeSpeakingHubViewModel()
            }

            if let config = appRouter.pendingReflexBlitzConfig {
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
                appRouter.pendingReflexBlitzConfig = nil
            } else if appRouter.selectedTab == .reflex && reflexBlitzVM == nil {
                let vm = appContainer.makeReflexBlitzViewModel()
                self.reflexBlitzVM = vm
            }
            handleTestLaunchArguments()
        }
        #if canImport(UIKit)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            viewModel.refreshDailyProgress()
        }
        #endif
        .onOpenURL { url in
            appRouter.handleDeepLink(url: url)
        }
        .onChange(of: appRouter.pendingReflexBlitzConfig) { _, newConfig in
            if let config = newConfig {
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
                appRouter.pendingReflexBlitzConfig = nil
            }
        }
        .onChange(of: appRouter.selectedTab) { _, newTab in
            if newTab == .home {
                viewModel.refreshDailyProgress()
                if let selectedId = appContainer.userSettingsStore.selectedLearningPathId,
                   selectedId != viewModel.activeLearningPath?.id {
                    Task { await viewModel.loadLearningPath() }
                }
            }
            if newTab != .home {
                lessonLaunchTask?.cancel()
            }
            if newTab == .reflex && reflexBlitzVM == nil {
                self.reflexBlitzVM = appContainer.makeReflexBlitzViewModel()
            }
            tabBarPresentation = HomepageTabBarPresentationPolicy.presentation(
                for: newTab,
                current: tabBarPresentation
            )
        }
        .environment(\.locale, appContainer.userSettingsStore.appLocale ?? .autoupdatingCurrent)
        #if os(iOS)
        .fullScreenCover(item: $activeLessonLearningVM, onDismiss: {
            activeLessonLearningVM = nil
            fastTrackAttemptDeckId = nil
        }) { vm in
            LessonLearningView(
                viewModel: vm,
                onDismiss: {
                    activeLessonLearningVM = nil
                    fastTrackAttemptDeckId = nil
                },
                onFinished: { summary in
                    handleLessonFinished(vm: vm, summary: summary)
                }
            )
        }
        #else
        .sheet(item: $activeLessonLearningVM, onDismiss: {
            activeLessonLearningVM = nil
            fastTrackAttemptDeckId = nil
        }) { vm in
            LessonLearningView(
                viewModel: vm,
                onDismiss: {
                    activeLessonLearningVM = nil
                    fastTrackAttemptDeckId = nil
                },
                onFinished: { summary in
                    handleLessonFinished(vm: vm, summary: summary)
                }
            )
        }
        #endif
        .sheet(item: $activeTreasureClaimNode) { node in
            TreasureClaimSheet(
                node: node,
                deckId: viewModel.resolvedDeckId(for: node),
                onClaim: {
                    try await viewModel.claimTreasure(node: node)
                },
                onClaimSuccess: { result in
                    handleTreasureClaimSuccess(result)
                },
                onDismiss: { activeTreasureClaimNode = nil }
            )
            .craftSurfaceStyle(.tactile3D)
            .presentationDetents([.fraction(0.52), .medium])
        }
        .sheet(isPresented: $isLearningPathSwitchPresented) {
            LearningPathSwitchSheet(activePathId: viewModel.activeLearningPath?.id) { selectedPath in
                Task { await viewModel.switchLearningPath(to: selectedPath.id) }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $viewModel.activeMilestoneDelta) { delta in
            MilestoneLexicalDeltaSheet(delta: delta, onContinue: {
                viewModel.dismissMilestoneDelta()
                scrollToActiveNonce += 1
            }, onOpenVault: {
                viewModel.dismissMilestoneDelta()
                appRouter.selectedTab = .vocabulary
            })
            .craftSurfaceStyle(.tactile3D)
            .presentationDetents([.fraction(0.65), .large])
        }
        .sheet(isPresented: $viewModel.isVocabGrowthDashboardPresented) {
            VocabGrowthDashboardSheet(
                snapshot: viewModel.currentVocabGrowthSnapshot,
                dailyPace: viewModel.dailyWordsGoal > 0 ? viewModel.dailyWordsGoal : 10,
                onDismiss: { viewModel.dismissVocabGrowthDashboard() }
            )
            .craftSurfaceStyle(.tactile3D)
            .presentationDetents([.large])
        }
    }
}

// MARK: - Lesson & Reflex Orchestration Extension

private extension HomepageView {
    func handleTestLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-test-path-switch") {
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                if viewModel.sections.isEmpty {
                    await viewModel.loadLearningPath()
                }
                await MainActor.run {
                    self.isLearningPathSwitchPresented = true
                }
            }
            return
        }

        if args.contains("-test-milestone-delta") {
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                await MainActor.run {
                    viewModel.activeMilestoneDelta = MilestoneLexicalDelta(
                        unitId: "deck_daily",
                        unitTitle: "Everyday Travel",
                        cefrLevel: "A1",
                        newWordsAdded: 15,
                        wordsMastered: 8,
                        avgResponseTimeMs: 1200,
                        accuracyRate: 0.94,
                        acquiredWords: ["Passport", "Ticket", "Airport", "Luggage"]
                    )
                }
            }
            return
        }

        if args.contains("-test-treasure-claim") {
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                if viewModel.sections.isEmpty {
                    await viewModel.loadLearningPath()
                }
                let treasureNode = viewModel.sections.flatMap(\.nodes).first(where: { $0.kind == .treasureChest })
                    ?? LessonNodeModel(
                        id: "treasure_deck_0",
                        title: AppStrings.Treasure.congratsTitleText,
                        iconName: "gift.fill",
                        state: .bonus,
                        kind: .treasureChest,
                        xpReward: LessonEconomyPolicy.treasureXP
                    )
                await MainActor.run {
                    self.activeTreasureClaimNode = treasureNode
                }
            }
            return
        }

        if args.contains("-test-lesson-discovery") {
            handleLessonDiscoveryLaunchArguments()
            return
        }

        handleLessonFeedbackLaunchArguments(args: args)
    }

    func handleLessonDiscoveryLaunchArguments() {
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            let decks = (try? await appContainer.vocabularyDataSource.fetchTopicDecks()) ?? []
            let firstDeck = decks.first?.id ?? "deck_daily"
            let stages = (try? await appContainer.vocabularyDataSource.fetchSubTopicStages(deckId: firstDeck)) ?? []
            let firstStage = stages.first?.id ?? "stage_daily_1"
            let words = (try? await appContainer.vocabularyDataSource.fetchWordsForStage(stageId: firstStage)) ?? []
            guard !words.isEmpty else { return }
            let vm = appContainer.makeLessonLearningViewModel(
                stageId: firstStage,
                deckId: firstDeck,
                words: words
            )
            await MainActor.run {
                self.activeLessonLearningVM = vm
            }
        }
    }

    func handleLessonFeedbackLaunchArguments(args: [String]) {
        guard args.contains("-test-lesson-feedback-incorrect") || args.contains("-test-lesson-feedback-correct") else { return }
        let isCorrect = args.contains("-test-lesson-feedback-correct")
        Task {
            try? await Task.sleep(for: .milliseconds(150))
            let words = (try? await appContainer.vocabularyDataSource.fetchWordsForStage(stageId: "stage_daily_1")) ?? []
            guard !words.isEmpty else { return }
            let vm = appContainer.makeLessonLearningViewModel(
                stageId: "stage_daily_1",
                deckId: "deck_daily",
                words: words
            )
            if let firstExIndex = vm.steps.firstIndex(where: { step in
                if case .exercise = step { return true }
                return false
            }) {
                for _ in 0..<firstExIndex {
                    vm.advanceStep()
                }
            }
            vm.isFeedbackPresented = true
            vm.lastAttemptCorrect = isCorrect
            await MainActor.run {
                self.activeLessonLearningVM = vm
            }
        }
    }

    func startLesson(for node: LessonNodeModel, isFastTrack: Bool = false) {
        if !isFastTrack {
            fastTrackAttemptDeckId = nil
        }

        if node.kind == .treasureChest {
            activeTreasureClaimNode = node
            return
        }

        guard !isLaunchingLesson && activeLessonLearningVM == nil else {
            if !isFastTrack {
                fastTrackAttemptDeckId = nil
            }
            return
        }

        let resolvedDeckId = viewModel.resolvedDeckId(for: node)
        guard !resolvedDeckId.isEmpty else {
            fastTrackAttemptDeckId = nil
            completionToastData = CraftToastData(
                title: AppStrings.Common.errorText,
                message: AppStrings.Lesson.loadErrorText,
                iconName: "exclamationmark.triangle.fill",
                style: .danger,
                surfaceStyle: .glass,
                duration: 3.0
            )
            return
        }

        isLaunchingLesson = true
        lessonLaunchTask?.cancel()
        lessonLaunchTask = Task {
            defer {
                Task { @MainActor in
                    isLaunchingLesson = false
                }
            }

            let deckId: String = resolvedDeckId
            let words = await fetchLessonWords(for: node, deckId: deckId)

            guard !Task.isCancelled else {
                await MainActor.run {
                    fastTrackAttemptDeckId = nil
                }
                return
            }

            guard !words.isEmpty else {
                await MainActor.run {
                    fastTrackAttemptDeckId = nil
                    guard !Task.isCancelled else { return }
                    completionToastData = CraftToastData(
                        title: AppStrings.Common.errorText,
                        message: AppStrings.Lesson.loadErrorText,
                        iconName: "exclamationmark.triangle.fill",
                        style: .danger,
                        surfaceStyle: .glass,
                        duration: 3.0
                    )
                }
                return
            }

            let vm = appContainer.makeLessonLearningViewModel(
                stageId: node.id,
                deckId: deckId,
                words: words,
                isFastTrack: isFastTrack || (fastTrackAttemptDeckId == deckId)
            )
            // Allow CoreAnimation buffer recovery (~150ms) after sheet dismissal before presenting cover
            try? await Task.sleep(for: .milliseconds(150))
            await MainActor.run {
                guard !Task.isCancelled, appRouter.selectedTab == .home else {
                    fastTrackAttemptDeckId = nil
                    return
                }
                self.activeLessonLearningVM = vm
            }
        }
    }

    private func fetchLessonWords(for node: LessonNodeModel, deckId: String) async -> [TopicWordDTO] {
        if node.id.hasPrefix("checkpoint_") {
            let stages = (try? await appContainer.vocabularyDataSource.fetchSubTopicStages(deckId: deckId)) ?? []
            let wordsByStage: [String: [TopicWordDTO]] = await withTaskGroup(of: (String, [TopicWordDTO]).self) { group in
                for stage in stages {
                    group.addTask {
                        let stageWords = (try? await appContainer.vocabularyDataSource.fetchWordsForStage(stageId: stage.id)) ?? []
                        return (stage.id, stageWords)
                    }
                }
                var mapped: [String: [TopicWordDTO]] = [:]
                mapped.reserveCapacity(stages.count)
                for await (stageId, stageWords) in group {
                    mapped[stageId] = stageWords
                }
                return mapped
            }
            let weakWords = (try? await appContainer.reviewWeakWordsUseCase.fetchWeakWords()) ?? []
            let weakWordIds = Set(weakWords.map(\.id))
            let sampler = SmartCheckpointWordSampler()
            return sampler.sample(
                stages: stages,
                wordsByStage: wordsByStage,
                weakWordIds: weakWordIds,
                targetCount: 10
            )
        } else {
            return (try? await appContainer.vocabularyDataSource.fetchWordsForStage(stageId: node.id)) ?? []
        }
    }

    private func handleLessonFinished(vm: LessonLearningViewModel, summary: LessonSummaryModel) {
        guard !isHandlingLessonFinished else { return }
        isHandlingLessonFinished = true

        Task {
            defer {
                Task { @MainActor in
                    isHandlingLessonFinished = false
                }
            }

            // Await persistence completion before dismissing and reloading learning path
            do {
                _ = try await vm.awaitCompletion()
            } catch {
                await MainActor.run {
                    completionToastData = CraftToastData(
                        title: AppStrings.Common.errorText,
                        message: error.localizedDescription,
                        iconName: "exclamationmark.triangle.fill",
                        style: .danger,
                        surfaceStyle: .glass,
                        duration: 3.0
                    )
                }
                return
            }

            let isFastTrackAttempt = vm.isFastTrack || (fastTrackAttemptDeckId == summary.deckId)
            fastTrackAttemptDeckId = nil

            if isFastTrackAttempt {
                let fastTrackResult = try? await viewModel.fastTrackUnit(
                    deckId: summary.deckId,
                    score: summary.accuracyFraction
                )
                if let fastTrackResult, fastTrackResult.isSuccess {
                    await MainActor.run {
                        activeLessonLearningVM = nil
                        CraftHaptics.shared.success()
                        homeConfettiTrigger = true
                        completionToastData = CraftToastData(
                            title: AppStrings.Home.fastTrackSuccessText,
                            message: "+\(summary.xpEarned) XP • \(AppStrings.Home.fastTrackCTAText)",
                            iconName: "bolt.fill",
                            style: .success,
                            surfaceStyle: .glass,
                            duration: 3.5
                        )
                    }
                    return
                } else {
                    await MainActor.run {
                        activeLessonLearningVM = nil
                        CraftHaptics.shared.warning()
                        completionToastData = CraftToastData(
                            title: AppStrings.Home.fastTrackCTAText,
                            message: AppStrings.Home.fastTrackFailedText,
                            iconName: "xmark.circle.fill",
                            style: .warning,
                            surfaceStyle: .glass,
                            duration: 3.5
                        )
                    }
                    return
                }
            }

            await MainActor.run {
                activeLessonLearningVM = nil
                viewModel.applyCompletedLesson(stageId: summary.stageId)
            }
            if summary.isUnitCheckpoint {
                Task {
                    // Buffer recovery (~150ms) after full-screen cover dismissal before presenting milestone sheet
                    try? await Task.sleep(for: .milliseconds(150))
                    await MainActor.run { viewModel.triggerMilestoneDelta(for: summary.deckId, summary: summary) }
                }
            }
            await MainActor.run {
                let starIcons = String(repeating: "★", count: summary.stars)
                CraftHaptics.shared.success()
                homeConfettiTrigger = true
                completionToastData = CraftToastData(
                    title: AppStrings.Home.completedTitleText,
                    message: "+\(summary.xpEarned) XP • \(starIcons)\(AppStrings.Home.starsSuffixText)",
                    iconName: "star.fill",
                    style: .success,
                    surfaceStyle: .glass,
                    duration: 3.0
                )
            }
        }
    }

    private func handleTreasureClaimSuccess(_ result: TreasureRewardResult) {
        CraftHaptics.shared.success()
        homeConfettiTrigger = true
        let title = result.isAlreadyClaimed ? AppStrings.Treasure.alreadyClaimedText : AppStrings.Home.completedTitleText
        let message = result.isAlreadyClaimed ? AppStrings.Treasure.congratsTitleText : "+\(result.xpEarned) XP • \(AppStrings.Treasure.congratsTitleText)"
        let icon = result.isAlreadyClaimed ? "checkmark.seal.fill" : "gift.fill"
        let style: CraftToastStyle = result.isAlreadyClaimed ? .info : .success
        completionToastData = CraftToastData(title: title, message: message, iconName: icon, style: style, surfaceStyle: .glass, duration: 3.0)
        if !result.isAlreadyClaimed {
            Task {
                // Allow treasure claim sheet dismissal (~350ms) before presenting milestone delta sheet
                try? await Task.sleep(for: .milliseconds(350))
                await MainActor.run { viewModel.triggerMilestoneDelta(for: result.deckId) }
            }
        }
    }

    private func handleReflexSessionFinished() {
        reflexBlitzVM = appContainer.makeReflexBlitzViewModel()
    }

    private func handleReflexDismiss() {
        reflexBlitzVM = nil
        appRouter.navigateToHome()
    }
}
