import XCTest
import SwiftUI
@testable import VocabCraftApp

@MainActor
final class HomepageViewTests: XCTestCase {
    func testTabItemProperties() {
        XCTAssertEqual(TabItem.home.title, "Trang chủ")
        XCTAssertEqual(TabItem.home.symbol, "house.fill")
        XCTAssertEqual(TabItem.vocabulary.title, "Từ vựng")
        XCTAssertEqual(TabItem.vocabulary.symbol, "book.fill")
        XCTAssertEqual(TabItem.reflex.title, "Phản xạ")
        XCTAssertEqual(TabItem.reflex.symbol, "bolt.fill")
        XCTAssertEqual(TabItem.settings.title, "Cài đặt")
        XCTAssertEqual(TabItem.settings.symbol, "gearshape.fill")
        XCTAssertEqual(TabItem.search.title, "Tra từ")
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

