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

/// Integrated Homepage view showcasing in-scroll HomeTopHeaderView, CraftFluidJourney gamified journey, and liquid glass navigation.
public struct HomepageView: View {
    @State private var viewModel: HomepageViewModel
    @State private var vaultVM: PersonalVaultViewModel?
    @State private var settingsVM: SettingsViewModel?
    @State private var reflexBlitzVM: ReflexBlitzViewModel?
    @State private var activeLessonNode: LessonNodeModel?
    @State private var activeLessonLearningVM: LessonLearningViewModel?
    @State private var lessonLaunchTask: Task<Void, Never>?
    @State private var isLaunchingLesson: Bool = false
    @State private var isHandlingLessonFinished: Bool = false
    @State private var tabBarPresentation: CraftTabBarPresentation = .expanded
    @State private var scrollToActiveNonce: Int = 0
    @State private var homeConfettiTrigger: Bool = false
    @State private var completionToastData: CraftToastData?
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
                        onAvatarTap: {
                            CraftHaptics.shared.light()
                            appRouter.navigateToSettings()
                        },
                        onProgressTap: {
                            scrollToActiveNonce += 1
                        }
                    )
                    .background(theme.colors.canvasBackground)

                    Group {
                        if viewModel.isLoading && viewModel.sections.isEmpty {
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
                                externalScrollTrigger: scrollToActiveNonce
                            )
                            .refreshable {
                                await viewModel.loadLearningPath()
                            }
                        }
                    }
                    .task {
                        if viewModel.sections.isEmpty {
                            await viewModel.loadLearningPath()
                        }
                    }
                }

            case .vocabulary:
                VocabularyView(vaultViewModel: vaultVM ?? appContainer.makePersonalVaultViewModel())
            case .aiAssistant:
                AIAssistantPlaceholderView()
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
        .craftConfetti(isTriggered: $homeConfettiTrigger, particleCount: 36)
        .craftToast(item: $completionToastData, position: .top)
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
        }) { vm in
            LessonLearningView(
                viewModel: vm,
                onDismiss: {
                    activeLessonLearningVM = nil
                },
                onFinished: { summary in
                    handleLessonFinished(vm: vm, summary: summary)
                }
            )
        }
        #else
        .sheet(item: $activeLessonLearningVM, onDismiss: {
            activeLessonLearningVM = nil
        }) { vm in
            LessonLearningView(
                viewModel: vm,
                onDismiss: {
                    activeLessonLearningVM = nil
                },
                onFinished: { summary in
                    handleLessonFinished(vm: vm, summary: summary)
                }
            )
        }
        #endif
    }

    private func startLesson(for node: LessonNodeModel) {
        guard !isLaunchingLesson && activeLessonLearningVM == nil else { return }

        let resolvedDeckId: String
        if node.id.hasPrefix("checkpoint_") {
            resolvedDeckId = String(node.id.dropFirst("checkpoint_".count))
        } else {
            resolvedDeckId = viewModel.sections.first(where: { sec in sec.nodes.contains(where: { $0.id == node.id }) })?.id ?? ""
        }

        guard !resolvedDeckId.isEmpty else {
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

            let words: [TopicWordDTO]
            let deckId: String = resolvedDeckId
            if node.id.hasPrefix("checkpoint_") {
                let stages = (try? await appContainer.vocabularyDataSource.fetchSubTopicStages(deckId: deckId)) ?? []
                let deckWords: [TopicWordDTO] = await withTaskGroup(of: [TopicWordDTO].self) { group in
                    for stage in stages {
                        group.addTask {
                            (try? await appContainer.vocabularyDataSource.fetchWordsForStage(stageId: stage.id)) ?? []
                        }
                    }
                    var combined: [TopicWordDTO] = []
                    combined.reserveCapacity(stages.count * 8)
                    for await words in group {
                        combined.append(contentsOf: words)
                    }
                    return combined
                }
                words = deckWords
            } else {
                words = (try? await appContainer.vocabularyDataSource.fetchWordsForStage(stageId: node.id)) ?? []
            }

            guard !Task.isCancelled else { return }

            guard !words.isEmpty else {
                await MainActor.run {
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
                words: words
            )
            await MainActor.run {
                guard !Task.isCancelled, appRouter.selectedTab == .home else { return }
                self.activeLessonLearningVM = vm
            }
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

            await MainActor.run {
                activeLessonLearningVM = nil
            }
            await viewModel.loadLearningPath()
            await MainActor.run {
                let starIcons = String(repeating: "★", count: summary.stars)
                CraftHaptics.shared.success()
                homeConfettiTrigger = true
                completionToastData = CraftToastData(
                    title: String(localized: "app.home.toast.completed_title", defaultValue: "Completed!", bundle: .module),
                    message: "+\(summary.xpEarned) XP • \(starIcons) \(String(localized: "app.home.toast.stars_suffix", defaultValue: " • Great Job!", bundle: .module))",
                    iconName: "star.fill",
                    style: .success,
                    surfaceStyle: .glass,
                    duration: 3.0
                )
            }
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

                do {
                    let result = try await appContainer.completeLessonUseCase.execute(
                        stageId: node.id,
                        deckId: deckId,
                        stars: stars,
                        weakWordIds: weakWordIds,
                        progressFraction: 1.0
                    )
                    await viewModel.loadLearningPath()
                    // Reward feedback: confetti + toast only on success — show fixed policy reward, not stars * xp
                    await MainActor.run {
                        let earnedXP = result.xpEarned
                        let starIcons = String(repeating: "★", count: stars)
                        CraftHaptics.shared.success()
                        homeConfettiTrigger = true
                        completionToastData = CraftToastData(
                            title: String(localized: "app.home.toast.completed_title", defaultValue: "Completed!", bundle: .module),
                            message: "+\(earnedXP) XP • \(starIcons) \(String(localized: "app.home.toast.stars_suffix", defaultValue: " • Great Job!", bundle: .module))",
                            iconName: "star.fill",
                            style: .success,
                            surfaceStyle: .glass,
                            duration: 3.0
                        )
                    }
                } catch {
                    await MainActor.run {
                        completionToastData = CraftToastData(
                            title: String(localized: "common.error", defaultValue: "Error", bundle: .module),
                            message: error.localizedDescription,
                            iconName: "exclamationmark.triangle.fill",
                            style: .danger,
                            surfaceStyle: .glass,
                            duration: 3.0
                        )
                    }
                }
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
