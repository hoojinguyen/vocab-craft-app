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
                                isSuspended: activeLessonLearningVM != nil,
                                deckTitle: viewModel.currentDeckTitle,
                                deckSubtitle: viewModel.currentDeckSubtitle,
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
                                scrollToActive: true,
                                externalScrollTrigger: scrollToActiveNonce
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
                AIAssistantPlaceholderView()
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

            if let config = appRouter.pendingReflexBlitzConfig {
                let vm = appContainer.makeReflexBlitzViewModel()
                vm.applyReviewConfig(config)
                self.reflexBlitzVM = vm
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
            if newTab == .home {
                viewModel.refreshDailyProgress()
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
}

// MARK: - Lesson & Reflex Orchestration Extension

private extension HomepageView {
    func handleTestLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
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

    func startLesson(for node: LessonNodeModel) {
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
            // Allow CoreAnimation buffer recovery (~150ms) after sheet dismissal before presenting cover
            try? await Task.sleep(for: .milliseconds(150))
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
                viewModel.applyCompletedLesson(stageId: summary.stageId)
            }
            await MainActor.run {
                let starIcons = String(repeating: "★", count: summary.stars)
                CraftHaptics.shared.success()
                homeConfettiTrigger = true
                completionToastData = CraftToastData(
                    title: String(localized: "app.home.toast.completed_title", defaultValue: "Completed!", bundle: .module),
                    message: "+\(summary.xpEarned) XP • \(starIcons)\(String(localized: "app.home.toast.stars_suffix", defaultValue: " • Amazing!", bundle: .module))",
                    iconName: "star.fill",
                    style: .success,
                    surfaceStyle: .glass,
                    duration: 3.0
                )
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
