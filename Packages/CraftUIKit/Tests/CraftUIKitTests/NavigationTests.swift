import XCTest
import SwiftUI
@testable import CraftUIKit

struct SampleTab: CraftTabItemProtocol, CaseIterable {
    let id: Int
    let title: String
    let symbol: String

    static let home = SampleTab(id: 0, title: "Home", symbol: "house.fill")
    static let search = SampleTab(id: 1, title: "Search", symbol: "magnifyingglass")
    static let library = SampleTab(id: 2, title: "Library", symbol: "books.vertical")
    static let profile = SampleTab(id: 3, title: "Profile", symbol: "person.fill")

    static var allCases: [SampleTab] {
        [.home, .search, .library, .profile]
    }
}

struct CustomStringTab: CraftTabItemProtocol {
    let id: String
    let title: String
    let symbol: String
}

final class NavigationTests: XCTestCase {

    func testFloatingTabBarStreamlinedInit() {
        let binding = Binding(get: { SampleTab.home }, set: { _ in })
        let tabs = SampleTab.allCases
        let bar = CraftFloatingTabBar(selectedItem: binding, items: tabs, style: .glass)
        XCTAssertEqual(bar.items.count, 4)
        XCTAssertEqual(bar.style, .glass)
    }

    func testFloatingTabBarItemPresentationRespectsProtocol() {
        let item1 = CraftTabItem(id: "1", title: "Tab 1", symbol: "house", showsTitle: false)
        let item2 = CraftTabItem(id: "2", title: "Tab 2", symbol: "gear", showsTitle: true)
        let binding = Binding(get: { item1 }, set: { _ in })
        let bar = CraftFloatingTabBar(selectedItem: binding, items: [item1, item2])
        XCTAssertFalse(bar.items[0].showsTitle)
        XCTAssertTrue(bar.items[1].showsTitle)
    }

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
        XCTAssertEqual(bar.style, .glass)
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
            style: .glass,
            centerAction: {
                centerActionExecuted = true
            },
            centerSymbol: "plus.circle.fill",
            centerTitle: "Add Word"
        )

        XCTAssertNotNil(bar.centerAction)
        XCTAssertEqual(bar.centerSymbol, "plus.circle.fill")
        XCTAssertEqual(bar.centerTitle, "Add Word")
        XCTAssertEqual(bar.style, .glass)

        bar.centerAction?()
        XCTAssertTrue(centerActionExecuted)
    }

    func testFloatingTabBarSurfaceStyles() {
        let tabs = [
            SampleTab(id: 0, title: "Home", symbol: "house"),
            SampleTab(id: 1, title: "Settings", symbol: "gear")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })

        for style in CraftSurfaceStyle.allCases {
            let bar = CraftFloatingTabBar(
                selectedItem: binding,
                items: tabs,
                style: style,
                centerAction: {},
                centerSymbol: "plus"
            )
            XCTAssertEqual(bar.style, style)
            XCTAssertNotNil(bar.body)
        }
    }

    func testFloatingTabBarLocalizedCenterTitle() {
        let tabs = [
            SampleTab(id: 0, title: "Home", symbol: "house"),
            SampleTab(id: 1, title: "Settings", symbol: "gear")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })

        let bar = CraftFloatingTabBar(
            selectedItem: binding,
            items: tabs,
            style: .glass,
            centerAction: {},
            centerSymbol: "sparkles",
            centerTitleKey: LocalizedStringKey("tab_center_title")
        )
        XCTAssertNil(bar.centerTitle)
        XCTAssertNotNil(bar.body)
    }

    func testCraftTabItemModel() {
        let item1 = CraftTabItem(id: "home", title: "Home", symbol: "house.fill", badgeCount: 2)
        XCTAssertEqual(item1.id, "home")
        XCTAssertEqual(item1.title, "Home")
        XCTAssertNil(item1.titleKey)
        XCTAssertEqual(item1.symbol, "house.fill")
        XCTAssertEqual(item1.badgeCount, 2)
        XCTAssertTrue(item1.showsTitle)
        XCTAssertTrue(item1.showsSymbol)

        let item2 = CraftTabItem(id: "saved", titleKey: LocalizedStringKey("saved_key"), symbol: "bookmark.fill")
        XCTAssertEqual(item2.id, "saved")
        XCTAssertEqual(item2.title, "")
        XCTAssertNotNil(item2.titleKey)
        XCTAssertEqual(item2.symbol, "bookmark.fill")
        XCTAssertNil(item2.badgeCount)
        XCTAssertTrue(item2.showsTitle)
        XCTAssertTrue(item2.showsSymbol)
    }

    func testCraftTabItemCustomPresentation() {
        let item = CraftTabItem(
            id: "custom",
            title: "Custom Tab",
            symbol: "star.fill",
            badgeCount: 3,
            showsTitle: false,
            showsSymbol: true
        )
        XCTAssertEqual(item.id, "custom")
        XCTAssertEqual(item.title, "Custom Tab")
        XCTAssertEqual(item.symbol, "star.fill")
        XCTAssertEqual(item.badgeCount, 3)
        XCTAssertFalse(item.showsTitle)
        XCTAssertTrue(item.showsSymbol)
    }

    func testTabItemProtocolDefaults() {
        struct MinimalTab: CraftTabItemProtocol {
            let id: String
            let title: String
            let symbol: String
        }
        let tab = MinimalTab(id: "1", title: "Test", symbol: "bell")
        XCTAssertTrue(tab.showsTitle)
        XCTAssertTrue(tab.showsSymbol)
        XCTAssertNil(tab.badgeCount)
        XCTAssertNil(tab.titleKey)
    }

    func testFloatingTabBarWithCraftTabItem() {
        let tabs = [
            CraftTabItem(id: "home", title: "Home", symbol: "house"),
            CraftTabItem(id: "search", titleKey: LocalizedStringKey("search_key"), symbol: "magnifyingglass")
        ]
        var selected = tabs[0]
        let bar = CraftFloatingTabBar(
            selectedItem: Binding(get: { selected }, set: { selected = $0 }),
            items: tabs,
            style: .glass
        )
        XCTAssertNotNil(bar.body)
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
            style: .elevated,
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
        XCTAssertNil(tab.titleKey)
    }

    func testTabEqualityAndConformances() {
        let tabA = SampleTab(id: 1, title: "Tab", symbol: "star")
        let tabB = SampleTab(id: 1, title: "Tab", symbol: "star")
        let tabC = SampleTab(id: 2, title: "Tab", symbol: "star")

        XCTAssertEqual(tabA, tabB)
        XCTAssertNotEqual(tabA, tabC)
    }

    func testCraftTactileFABButtonStyleInitialization() {
        let styleDefault = CraftTactileFABButtonStyle()
        XCTAssertEqual(styleDefault.depth, 4)

        let styleCustom = CraftTactileFABButtonStyle(depth: 6)
        XCTAssertEqual(styleCustom.depth, 6)
    }

    func testFloatingTabBarEvenOddItemSplits() {
        let oddTabs = [
            CustomStringTab(id: "1", title: "One", symbol: "1.circle"),
            CustomStringTab(id: "2", title: "Two", symbol: "2.circle"),
            CustomStringTab(id: "3", title: "Three", symbol: "3.circle"),
            CustomStringTab(id: "4", title: "Four", symbol: "4.circle"),
            CustomStringTab(id: "5", title: "Five", symbol: "5.circle")
        ]
        var selected = oddTabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })

        var fabTriggered = false
        let bar = CraftFloatingTabBar(
            selectedItem: binding,
            items: oddTabs,
            centerAction: { fabTriggered = true },
            centerSymbol: "sparkles",
            centerTitle: "AI"
        )
        XCTAssertNotNil(bar.body)
        XCTAssertNotNil(bar.centerAction)
        bar.centerAction?()
        XCTAssertTrue(fabTriggered)
    }

    func testFloatingTabBarIconOnlyTabItem() {
        let iconOnlyTabs = [
            CraftTabItem(id: "home", title: "", symbol: "house"),
            CraftTabItem(id: "search", title: "", symbol: "magnifyingglass")
        ]
        var selected = iconOnlyTabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let bar = CraftFloatingTabBar(selectedItem: binding, items: iconOnlyTabs, style: .glass)
        XCTAssertNotNil(bar.body)
        XCTAssertEqual(bar.items[0].title, "")
    }

    func testFloatingTabBarItemPresentationMixedFlags() {
        let tabs = [
            CraftTabItem(id: "home", title: "Home", symbol: "house", showsTitle: false),
            CraftTabItem(id: "settings", title: "Settings", symbol: "gear", showsTitle: true)
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let bar = CraftFloatingTabBar(selectedItem: binding, items: tabs)
        XCTAssertFalse(bar.items[0].showsTitle)
        XCTAssertTrue(bar.items[1].showsTitle)
        XCTAssertNotNil(bar.body)
    }

    func testCraftTabBarItemPreferenceKey() {
        var values: [String: CGRect] = ["tab1": CGRect(x: 0, y: 0, width: 60, height: 44)]
        let next = ["tab2": CGRect(x: 70, y: 0, width: 60, height: 44)]
        CraftTabBarItemPreferenceKey.reduce(value: &values, nextValue: { next })
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(values["tab1"], CGRect(x: 0, y: 0, width: 60, height: 44))
        XCTAssertEqual(values["tab2"], CGRect(x: 70, y: 0, width: 60, height: 44))
    }

    func testCraftSlidingFluidPillInitialization() {
        let pillGlass = CraftSlidingFluidPill(style: .glass, isTransitioning: false)
        XCTAssertEqual(pillGlass.style, .glass)
        XCTAssertFalse(pillGlass.isTransitioning)
        XCTAssertNotNil(pillGlass.body)

        let pillElevated = CraftSlidingFluidPill(style: .elevated, isTransitioning: true)
        XCTAssertEqual(pillElevated.style, .elevated)
        XCTAssertTrue(pillElevated.isTransitioning)
        XCTAssertNotNil(pillElevated.body)
    }

    func testFloatingTabBarAccessibilityWithLocalizedStringKey() {
        let localizedTabs = [
            CraftTabItem(id: "learn", titleKey: LocalizedStringKey("learn_tab"), symbol: "book.fill"),
            CraftTabItem(id: "settings", titleKey: LocalizedStringKey("settings_tab"), symbol: "gearshape.fill")
        ]
        var selected = localizedTabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })
        let bar = CraftFloatingTabBar(selectedItem: binding, items: localizedTabs)
        XCTAssertNotNil(bar.body)
    }

    func testFloatingTabBarAllSurfaceStylesWithCenterAction() {
        let tabs = [
            SampleTab(id: 0, title: "Home", symbol: "house"),
            SampleTab(id: 1, title: "Settings", symbol: "gear")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })

        for style in CraftSurfaceStyle.allCases {
            let bar = CraftFloatingTabBar(
                selectedItem: binding,
                items: tabs,
                style: style,
                centerAction: {},
                centerSymbol: "plus",
                centerTitle: "Add"
            )
            XCTAssertEqual(bar.style, style)
            XCTAssertNotNil(bar.body)
        }
    }

    func testFloatingTabBarCenterButtonPositions() {
        let tabs = [
            SampleTab(id: 0, title: "Home", symbol: "house"),
            SampleTab(id: 1, title: "Settings", symbol: "gear")
        ]
        var selected = tabs[0]
        let binding = Binding(get: { selected }, set: { selected = $0 })

        // Floating FAB position
        let floatingBar = CraftFloatingTabBar(
            selectedItem: binding,
            items: tabs,
            style: .glass,
            centerPosition: .floating,
            centerAction: {},
            centerSymbol: "plus"
        )
        XCTAssertEqual(floatingBar.centerPosition, .floating)
        XCTAssertNotNil(floatingBar.body)

        // Inline FAB position
        let inlineBar = CraftFloatingTabBar(
            selectedItem: binding,
            items: tabs,
            style: .glass,
            centerPosition: .inline,
            centerAction: {},
            centerSymbol: "plus"
        )
        XCTAssertEqual(inlineBar.centerPosition, .inline)
        XCTAssertNotNil(inlineBar.body)
    }

    // MARK: - Navigation Localization Tests

    func testFloatingTabBarLocalization() {
        XCTAssertEqual(CraftLocalized.format("craft.tab_bar.badge_count_format", language: "en", 5), "5 new items")
        XCTAssertEqual(CraftLocalized.format("craft.tab_bar.badge_count_format", language: "vi", 5), "5 mục mới")

        XCTAssertEqual(CraftLocalized.string("craft.tab_bar.center_action_fallback", language: "en"), "Action")
        XCTAssertEqual(CraftLocalized.string("craft.tab_bar.center_action_fallback", language: "vi"), "Tác vụ")
    }
}

