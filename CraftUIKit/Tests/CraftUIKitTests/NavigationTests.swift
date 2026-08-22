import XCTest
import SwiftUI
@testable import CraftUIKit

struct SampleTab: CraftTabItemProtocol {
    let id: Int
    let title: String
    let symbol: String
}

struct CustomStringTab: CraftTabItemProtocol {
    let id: String
    let title: String
    let symbol: String
}

final class NavigationTests: XCTestCase {

    func testFloatingTabBarItemSelection() {
        let tabs = [
            SampleTab(id: 0, title: "Home", symbol: "house.fill"),
            SampleTab(id: 1, title: "Settings", symbol: "gear.fill")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let bar = CraftFloatingTabBar(selectedItem: binding, items: tabs)
        XCTAssertEqual(bar.selectedItem.id, 0)
        XCTAssertEqual(bar.items.count, 2)
        XCTAssertNil(bar.centerAction)
        XCTAssertEqual(bar.centerSymbol, "plus")
        XCTAssertNil(bar.centerTitle)

        // Mutate binding
        binding.wrappedValue = tabs[1]
        XCTAssertEqual(selected.id, 1)
    }

    func testFloatingTabBarWithCenterAction() {
        let tabs = [
            SampleTab(id: 0, title: "Learn", symbol: "book.fill"),
            SampleTab(id: 1, title: "Review", symbol: "arrow.clockwise"),
            SampleTab(id: 2, title: "Stats", symbol: "chart.bar.fill"),
            SampleTab(id: 3, title: "Profile", symbol: "person.fill")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })
        var centerActionExecuted = false

        let bar = CraftFloatingTabBar(
            selectedItem: binding,
            items: tabs,
            centerAction: {
                centerActionExecuted = true
            },
            centerSymbol: "plus.circle.fill",
            centerTitle: "Add Word"
        )

        XCTAssertNotNil(bar.centerAction)
        XCTAssertEqual(bar.centerSymbol, "plus.circle.fill")
        XCTAssertEqual(bar.centerTitle, "Add Word")

        bar.centerAction?()
        XCTAssertTrue(centerActionExecuted)
    }

    func testFloatingTabBarBodyRendering() {
        let tabs = [
            CustomStringTab(id: "home", title: "Home", symbol: "house.fill"),
            CustomStringTab(id: "search", title: "Search", symbol: "magnifyingglass"),
            CustomStringTab(id: "profile", title: "Profile", symbol: "person.fill")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })

        // Standard bar
        let standardBar = CraftFloatingTabBar(selectedItem: binding, items: tabs)
        XCTAssertNotNil(standardBar.body)

        // Elevated center FAB bar
        let fabBar = CraftFloatingTabBar(
            selectedItem: binding,
            items: tabs,
            centerAction: {},
            centerSymbol: "plus",
            centerTitle: "Create"
        )
        XCTAssertNotNil(fabBar.body)
    }

    func testFloatingTabBarWithBadge() {
        struct BadgeTab: CraftTabItemProtocol {
            let id: String
            let title: String
            let symbol: String
            var badgeCount: Int? = 3
        }

        var selected = BadgeTab(id: "library", title: "Library", symbol: "books.vertical", badgeCount: 5)
        let items = [
            BadgeTab(id: "home", title: "Home", symbol: "house", badgeCount: nil),
            selected
        ]
        let bar = CraftFloatingTabBar(selectedItem: Binding(get: { selected }, set: { selected = $0 }), items: items)
        XCTAssertEqual(bar.items[0].badgeCount, nil)
        XCTAssertEqual(bar.items[1].badgeCount, 5)
        XCTAssertNotNil(bar.body)
    }

    func testTabProtocolProperties() {
        let tab = SampleTab(id: 42, title: "Vocabulary", symbol: "character.book.closed")
        XCTAssertEqual(tab.id, 42)
        XCTAssertEqual(tab.title, "Vocabulary")
        XCTAssertEqual(tab.symbol, "character.book.closed")
        XCTAssertNil(tab.badgeCount)
    }

    func testTabEqualityAndConformances() {
        let tabA = SampleTab(id: 1, title: "Tab", symbol: "star")
        let tabB = SampleTab(id: 1, title: "Tab", symbol: "star")
        let tabC = SampleTab(id: 2, title: "Tab", symbol: "star")

        XCTAssertEqual(tabA, tabB)
        XCTAssertNotEqual(tabA, tabC)
    }
}
