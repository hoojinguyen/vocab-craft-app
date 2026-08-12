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
}
