import CraftUIKit
import Foundation
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class HomepageViewTests: XCTestCase {
    func testTabBarPresentationPolicyPreservesHomePresentation() {
        XCTAssertEqual(
            HomepageTabBarPresentationPolicy.presentation(
                for: .home,
                current: .compact
            ),
            .compact
        )
    }

    func testTabBarPresentationPolicyResetsOutsideHome() {
        XCTAssertEqual(
            HomepageTabBarPresentationPolicy.presentation(
                for: .vocabulary,
                current: .compact
            ),
            .expanded
        )
    }

    func testCraftFloatingTabBarInitializationSupportsCompactPresentation() {
        let tabBar = CraftFloatingTabBar(
            selectedItem: .constant(TabItem.home),
            items: TabItem.navigationTabs,
            style: .glass,
            presentation: .compact,
            centerPosition: .floating,
            centerAction: {},
            centerSymbol: CraftSymbol.practice.rawValue,
            centerTitleKey: AppStrings.Tabs.reflex
        )

        XCTAssertEqual(tabBar.presentation, .compact)
        XCTAssertNotNil(tabBar.body)
    }

    func testTabItemCraftProtocolConformance() {
        XCTAssertEqual(TabItem.home.titleKey, AppStrings.Tabs.home)
        XCTAssertEqual(TabItem.home.symbol, CraftSymbol.homeFill.rawValue)
        XCTAssertEqual(TabItem.vocabulary.titleKey, AppStrings.Tabs.vocabulary)
        XCTAssertEqual(TabItem.vocabulary.symbol, CraftSymbol.booksFill.rawValue)
        XCTAssertEqual(TabItem.aiAssistant.titleKey, AppStrings.Tabs.aiAssistant)
        XCTAssertEqual(TabItem.aiAssistant.symbol, CraftSymbol.sparkles.rawValue)
        XCTAssertEqual(TabItem.reflex.titleKey, AppStrings.Tabs.reflex)
        XCTAssertEqual(TabItem.reflex.symbol, CraftSymbol.practice.rawValue)
        XCTAssertEqual(TabItem.settings.titleKey, AppStrings.Tabs.settings)
        XCTAssertEqual(TabItem.settings.symbol, CraftSymbol.settingsFill.rawValue)
        XCTAssertEqual(TabItem.navigationTabs, [.home, .vocabulary, .aiAssistant, .settings])
        XCTAssertEqual(TabItem.allCases.count, 5)
        XCTAssertNil(TabItem.home.badgeCount)
        XCTAssertFalse(TabItem.home.showsTitle)
        XCTAssertTrue(TabItem.home.showsSymbol)
    }

    func testCraftFloatingTabBarInitialization() {
        let binding = Binding.constant(TabItem.home)
        let tabBar = CraftFloatingTabBar(
            selectedItem: binding,
            items: TabItem.navigationTabs,
            style: .glass,
            centerPosition: .floating,
            centerAction: {},
            centerSymbol: CraftSymbol.practice.rawValue,
            centerTitleKey: AppStrings.Tabs.reflex
        )
        XCTAssertNotNil(tabBar)
        XCTAssertEqual(tabBar.items.count, 4)
        XCTAssertEqual(tabBar.style, .glass)
        XCTAssertEqual(tabBar.centerPosition, .floating)
        XCTAssertEqual(tabBar.centerSymbol, CraftSymbol.practice.rawValue)
    }

    func testHomepageViewInitialization() {
        let viewModel = HomepageViewModel()
        let homepage = HomepageView(viewModel: viewModel)
        XCTAssertNotNil(homepage)
    }

    func testHomepageViewBodyEvaluationAcrossTabSwitching() {
        let container = AppContainer.mock
        let viewModel = container.makeHomepageViewModel()
        let homepage = HomepageView(viewModel: viewModel)

        for tab in TabItem.allCases {
            container.appRouter.selectedTab = tab
            XCTAssertNotNil(homepage.body)
        }
    }

    func testHomepageViewBodyForIndividualTabs() {
        let container = AppContainer.mock
        let viewModel = container.makeHomepageViewModel()
        let homepage = HomepageView(viewModel: viewModel)

        container.appRouter.navigateToHome()
        XCTAssertNotNil(homepage.body)

        container.appRouter.navigateToVocabulary()
        XCTAssertNotNil(homepage.body)

        container.appRouter.selectTab(.aiAssistant)
        XCTAssertNotNil(homepage.body)

        container.appRouter.navigateToReflex()
        XCTAssertNotNil(homepage.body)

        container.appRouter.navigateToSettings()
        XCTAssertNotNil(homepage.body)
    }

    func testHomepageViewBodyWithLoadedLearningPath() async {
        let container = AppContainer.mock
        let viewModel = container.makeHomepageViewModel()
        await viewModel.loadLearningPath()
        XCTAssertFalse(viewModel.sections.isEmpty)

        let homepage = HomepageView(viewModel: viewModel)
        XCTAssertNotNil(homepage.body)
    }

    func testHomepageViewModelLoadLearningPath() async {
        let container = AppContainer.mock
        let viewModel = container.makeHomepageViewModel()

        await viewModel.loadLearningPath()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.sections.isEmpty)
        XCTAssertEqual(viewModel.sections.count, 4)
    }

    func testHomepageViewModelNodeTapHandling() {
        let viewModel = HomepageViewModel()
        let unlockedNode = LessonNodeModel(
            id: "stage_1",
            title: "Greetings",
            subtitle: "10 words • 3 min",
            iconName: "hand.wave.fill",
            state: .active
        )
        let lockedNode = LessonNodeModel(
            id: "stage_2",
            title: "Numbers",
            subtitle: "12 words • 4 min",
            iconName: "number",
            state: .locked
        )

        viewModel.handleNodeTap(lockedNode)
        XCTAssertNil(viewModel.selectedNode)
        XCTAssertFalse(viewModel.isDetailSheetPresented)

        viewModel.handleNodeTap(unlockedNode)
        XCTAssertEqual(viewModel.selectedNode?.id, "stage_1")
        XCTAssertTrue(viewModel.isDetailSheetPresented)

        viewModel.dismissDetailSheet()
        XCTAssertNil(viewModel.selectedNode)
        XCTAssertFalse(viewModel.isDetailSheetPresented)
    }

    func testReflexBlitzWordItemFromTopicWordDTO() {
        let dto = TopicWordDTO(
            id: 101,
            stageId: "deck_daily_stage_1",
            lemma: "eloquent",
            phonetic: "/ˈel.ə.kwənt/",
            pos: "adj.",
            cefrLevel: "C1",
            definitionVi: "Hùng biện, lưu loát",
            definitionEn: "Fluent or persuasive in speaking or writing",
            exampleEn: "She gave an eloquent speech.",
            exampleVi: "Cô ấy đã có một bài phát biểu hùng biện."
        )

        let blitzItem = ReflexBlitzWordItem(from: dto)
        XCTAssertEqual(blitzItem.id, 101)
        XCTAssertEqual(blitzItem.lemma, "eloquent")
        XCTAssertEqual(blitzItem.ipa, "/ˈel.ə.kwənt/")
        XCTAssertEqual(blitzItem.definitionVi, "Hùng biện, lưu loát")
        XCTAssertEqual(blitzItem.exampleSentenceEn, "She gave an eloquent speech.")
        XCTAssertEqual(blitzItem.exampleSentenceVi, "Cô ấy đã có một bài phát biểu hùng biện.")
    }

    func testLessonStartAndCompleteUseCaseFlow() async throws {
        let container = AppContainer.mock
        let decks = try await container.vocabularyDataSource.fetchTopicDecks()
        XCTAssertFalse(decks.isEmpty)
        let firstDeck = decks[0]

        let stages = try await container.vocabularyDataSource.fetchSubTopicStages(deckId: firstDeck.id)
        XCTAssertFalse(stages.isEmpty)

        let firstStage = stages[0]
        let words = try await container.vocabularyDataSource.fetchWordsForStage(stageId: firstStage.id)
        XCTAssertFalse(words.isEmpty)

        let blitzWords = words.map { ReflexBlitzWordItem(from: $0) }
        let reflexVM = container.makeReflexBlitzViewModel(words: blitzWords)
        XCTAssertEqual(reflexVM.words.count, words.count)

        let result = try await container.completeLessonUseCase.execute(
            stageId: firstStage.id,
            deckId: firstDeck.id,
            stars: 3,
            weakWordIds: [],
            progressFraction: 1.0
        )
        XCTAssertEqual(result.stageId, firstStage.id)
        XCTAssertEqual(result.deckId, firstDeck.id)
        XCTAssertEqual(result.score, 3)
        XCTAssertEqual(result.xpEarned, 25)
        XCTAssertFalse(result.isUnitCheckpoint)
    }

    func testCheckpointLessonCompletionFlow() async throws {
        let container = AppContainer.mock
        let result = try await container.completeLessonUseCase.execute(
            stageId: "checkpoint_deck_daily",
            deckId: "deck_daily",
            stars: 3,
            weakWordIds: [],
            progressFraction: 1.0
        )
        XCTAssertEqual(result.stageId, "checkpoint_deck_daily")
        XCTAssertEqual(result.deckId, "deck_daily")
        XCTAssertEqual(result.score, 3)
        XCTAssertEqual(result.xpEarned, 80)
        XCTAssertTrue(result.isUnitCheckpoint)
    }

    func testHomepageViewIntegratesHomeTopHeaderViewInScrollFlow() async {
        let container = AppContainer.mock
        let viewModel = container.makeHomepageViewModel()
        await viewModel.loadLearningPath()

        let homepage = HomepageView(viewModel: viewModel)
        XCTAssertNotNil(homepage.body)
        XCTAssertEqual(viewModel.userName, "Hooji N.")
        XCTAssertEqual(viewModel.streakDays, 14)
        XCTAssertEqual(viewModel.dailyWordsLearned, 8)
        XCTAssertEqual(viewModel.dailyWordsGoal, 10)
    }

    func testLearningPathStickyHUDUnitDockingConfig() {
        let section = LessonSection(
            id: "sec_unit_1",
            title: "Everyday Phrases",
            level: "UNIT 1",
            progressText: "4/8",
            nodes: [
                LessonNodeModel(id: "node_1", title: "Intro", state: .active)
            ]
        )

        var tappedSectionID: String?
        let path = CraftLearningPath(
            section: section,
            pinSectionHeaders: true,
            topHeaderBuilder: {
                AnyView(
                    HomeTopHeaderView(
                        userName: "Hooji N.",
                        streakDays: 7,
                        dailyWordsLearned: 5,
                        dailyWordsGoal: 10
                    )
                )
            },
            stickyHUDBuilder: { sec in
                tappedSectionID = sec.id
                return AnyView(Text(sec.title))
            }
        )

        XCTAssertTrue(path.pinSectionHeaders)
        XCTAssertNotNil(path.topHeaderBuilder)
        XCTAssertNotNil(path.stickyHUDBuilder)
        _ = path.stickyHUDBuilder?(section)
        XCTAssertEqual(tappedSectionID, "sec_unit_1")
        XCTAssertNotNil(path.body)
    }

    func testHomeTopHeaderAvatarTapNavigatesToSettings() {
        let router = AppRouter(initialTab: .home)
        var avatarTapped = false

        let header = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 7,
            dailyWordsLearned: 5,
            dailyWordsGoal: 10,
            onAvatarTap: {
                avatarTapped = true
                router.navigateToSettings()
            }
        )

        XCTAssertNotNil(header.body)
        header.onAvatarTap?()
        XCTAssertTrue(avatarTapped)
        XCTAssertEqual(router.selectedTab, .settings)
    }
}
