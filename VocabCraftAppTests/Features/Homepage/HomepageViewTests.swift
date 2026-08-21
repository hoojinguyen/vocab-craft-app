import SwiftUI
@testable import VocabCraftApp
import XCTest

@MainActor
final class HomepageViewTests: XCTestCase {
    func testTabItemProperties() {
        XCTAssertEqual(TabItem.home.title, AppStrings.Tabs.home)
        XCTAssertEqual(TabItem.home.symbol, "house.fill")
        XCTAssertEqual(TabItem.vocabulary.title, AppStrings.Tabs.vocabulary)
        XCTAssertEqual(TabItem.vocabulary.symbol, "book.fill")
        XCTAssertEqual(TabItem.reflex.title, AppStrings.Tabs.reflex)
        XCTAssertEqual(TabItem.reflex.symbol, "bolt.fill")
        XCTAssertEqual(TabItem.settings.title, AppStrings.Tabs.settings)
        XCTAssertEqual(TabItem.settings.symbol, "gearshape.fill")
        XCTAssertEqual(TabItem.search.title, AppStrings.Tabs.search)
        XCTAssertEqual(TabItem.search.symbol, "magnifyingglass")
        XCTAssertEqual(TabItem.allCases.count, 5)
    }

    func testLiquidGlassTabBarInitialization() {
        let binding = Binding.constant(TabItem.home)
        let tabBar = LiquidGlassTabBar(selectedTab: binding)
        XCTAssertNotNil(tabBar)
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

        container.appRouter.selectTab(.search)
        XCTAssertNotNil(homepage.body)

        container.appRouter.navigateToReflex()
        XCTAssertNotNil(homepage.body)

        container.appRouter.navigateToSettings()
        XCTAssertNotNil(homepage.body)
    }

    func testHomepageViewModelLoadDataIdempotence() async {
        let container = AppContainer.mock
        let viewModel = container.makeHomepageViewModel()

        // Initial load
        await viewModel.loadData()
        let initialCount = viewModel.suggestedWords.count
        XCTAssertGreaterThan(initialCount, 0)

        // Mutate state to verify second call is guarded and does not overwrite
        viewModel.suggestedWords[0].lemma = "CustomGuardedWord"
        await viewModel.loadData()
        XCTAssertEqual(viewModel.suggestedWords[0].lemma, "CustomGuardedWord")
    }
}
