import XCTest
import SwiftUI
@testable import VocabCraftApp

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
        XCTAssertEqual(TabItem.allCases.count, 4)
    }

    func testLiquidGlassTabBarInitialization() {
        let binding = Binding.constant(TabItem.home)
        let tabBar = LiquidGlassTabBar(selectedTab: binding)
        XCTAssertNotNil(tabBar)
    }

    func testHomepageViewInitialization() {
        let homepage = HomepageView()
        XCTAssertNotNil(homepage)
    }

    func testHomepageViewCustomInit() {
        let homepage = HomepageView(
            userName: "Alice",
            streakDays: 7,
            dailyGoalProgress: 0.5,
            dueCardsCount: 12,
            totalWords: 500,
            retentionPercentage: 0.9
        )
        XCTAssertNotNil(homepage)
        XCTAssertEqual(homepage.userName, "Alice")
        XCTAssertEqual(homepage.streakDays, 7)
        XCTAssertEqual(homepage.dailyGoalProgress, 0.5)
        XCTAssertEqual(homepage.dueCardsCount, 12)
        XCTAssertEqual(homepage.totalWords, 500)
        XCTAssertEqual(homepage.retentionPercentage, 0.9)
    }
}
