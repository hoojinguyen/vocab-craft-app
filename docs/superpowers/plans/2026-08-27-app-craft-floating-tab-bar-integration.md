# CraftFloatingTabBar Integration in VocabCraftApp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace legacy in-app `LiquidGlassTabBar` with `CraftUIKit.CraftFloatingTabBar`, isolate `TabItem` model conforming to `CraftTabItemProtocol`, and bind 4 symmetrical side tabs with center Reflex Blitz hero action button.

**Architecture:** Isolate `TabItem` into `VocabCraftApp/App/Navigation/TabItem.swift` conforming to `CraftTabItemProtocol`, adopting `AppStrings.Tabs.*` and `CraftSymbol`. Migrate `HomepageView.swift` to render `CraftFloatingTabBar(selectedItem:items:style:centerPosition:centerAction:centerSymbol:centerTitleKey:)`. Delete legacy `LiquidGlassTabBar.swift` and update unit tests in `HomepageViewTests.swift`.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit (Design System), XCTest.

**Spec:** `docs/superpowers/specs/2026-08-27-app-craft-floating-tab-bar-integration-design.md`

## Global Constraints

- Strict Zero Hardcoded Strings Policy: Never write literal strings for titles, accessibility labels, or actions. Use `AppStrings.Tabs.*` from `Localizable.xcstrings`.
- Strict No-Mixing Localization Policy: Both `en` and `vi` localizations must be maintained with 100% parity.
- Backward Compatibility: Maintain `AppRouter` tab routing and Deep Link behavior seamlessly.

---

### Task 1: Create `TabItem` Conforming to `CraftTabItemProtocol`

**Files:**
- Create: `VocabCraftApp/App/Navigation/TabItem.swift`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `CraftUIKit.CraftTabItemProtocol`, `CraftUIKit.CraftSymbol`, `AppStrings.Tabs`
- Produces: `TabItem: Int, CaseIterable, Identifiable, Sendable, CraftTabItemProtocol`
  - `.home`, `.vocabulary`, `.search`, `.reflex`, `.settings`
  - `var id: Int { get }`
  - `var title: String { get }`
  - `var titleKey: LocalizedStringKey? { get }`
  - `var symbol: String { get }`
  - `var badgeCount: Int? { get }`
  - `static var navigationTabs: [TabItem] { get }`

- [ ] **Step 1: Write the failing unit tests for `TabItem` CraftTabItemProtocol conformance in `HomepageViewTests.swift`**

```swift
    func testTabItemCraftProtocolConformance() {
        XCTAssertEqual(TabItem.home.titleKey, AppStrings.Tabs.home)
        XCTAssertEqual(TabItem.home.symbol, CraftSymbol.home.rawValue)
        XCTAssertEqual(TabItem.vocabulary.titleKey, AppStrings.Tabs.vocabulary)
        XCTAssertEqual(TabItem.vocabulary.symbol, CraftSymbol.study.rawValue)
        XCTAssertEqual(TabItem.search.titleKey, AppStrings.Tabs.search)
        XCTAssertEqual(TabItem.search.symbol, CraftSymbol.search.rawValue)
        XCTAssertEqual(TabItem.reflex.titleKey, AppStrings.Tabs.reflex)
        XCTAssertEqual(TabItem.reflex.symbol, CraftSymbol.practice.rawValue)
        XCTAssertEqual(TabItem.settings.titleKey, AppStrings.Tabs.settings)
        XCTAssertEqual(TabItem.settings.symbol, CraftSymbol.settings.rawValue)
        XCTAssertEqual(TabItem.navigationTabs, [.home, .vocabulary, .search, .settings])
        XCTAssertEqual(TabItem.allCases.count, 5)
        XCTAssertNil(TabItem.home.badgeCount)
    }
```

- [ ] **Step 2: Create `VocabCraftApp/App/Navigation/TabItem.swift`**

```swift
import CraftUIKit
import Foundation
import SwiftUI

public enum TabItem: Int, CaseIterable, Identifiable, Sendable, CraftTabItemProtocol {
    case home = 0
    case vocabulary = 1
    case search = 4 // Tra từ
    case reflex = 2 // Phản xạ
    case settings = 3 // Cài đặt

    public var id: Int { rawValue }

    public var title: String { "" }

    public var titleKey: LocalizedStringKey? {
        switch self {
        case .home: return AppStrings.Tabs.home
        case .vocabulary: return AppStrings.Tabs.vocabulary
        case .search: return AppStrings.Tabs.search
        case .reflex: return AppStrings.Tabs.reflex
        case .settings: return AppStrings.Tabs.settings
        }
    }

    public var symbol: String {
        switch self {
        case .home: return CraftSymbol.home.rawValue
        case .vocabulary: return CraftSymbol.study.rawValue
        case .search: return CraftSymbol.search.rawValue
        case .reflex: return CraftSymbol.practice.rawValue
        case .settings: return CraftSymbol.settings.rawValue
        }
    }

    public var badgeCount: Int? { nil }

    /// The 4 standard navigation tabs rendered on the dock sides.
    public static var navigationTabs: [TabItem] {
        [.home, .vocabulary, .search, .settings]
    }
}
```

- [ ] **Step 3: Run unit tests to verify `TabItem` conformance passes**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/HomepageViewTests/testTabItemCraftProtocolConformance -quiet`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/App/Navigation/TabItem.swift VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift
git commit -m "feat(navigation): create TabItem conforming to CraftTabItemProtocol"
```

---

### Task 2: Integrate `CraftFloatingTabBar` into `HomepageView`, Remove `LiquidGlassTabBar`, and Update Xcode Project

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Delete: `VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `TabItem`, `CraftFloatingTabBar`, `CraftSymbol.practice`, `AppStrings.Tabs.reflex`
- Produces: Updated `HomepageView` rendering `CraftFloatingTabBar`

- [ ] **Step 1: Update `HomepageView.swift` to use `CraftFloatingTabBar`**

In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
Replace:
```swift
            if router.selectedTab != .reflex {
                LiquidGlassTabBar(selectedTab: $router.selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
```
With:
```swift
            if router.selectedTab != .reflex {
                CraftFloatingTabBar(
                    selectedItem: $router.selectedTab,
                    items: TabItem.navigationTabs,
                    style: .glass,
                    centerPosition: .floating,
                    centerAction: {
                        router.navigateToReflex()
                    },
                    centerSymbol: CraftSymbol.practice.rawValue,
                    centerTitleKey: AppStrings.Tabs.reflex
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
```

- [ ] **Step 2: Delete `VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift` and update `VocabCraftApp.xcodeproj/project.pbxproj`**

Delete `VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift` and update `VocabCraftApp.xcodeproj/project.pbxproj` to replace references of `LiquidGlassTabBar.swift` with `VocabCraftApp/App/Navigation/TabItem.swift`.

- [ ] **Step 3: Run unit tests to verify compilation and basic execution**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests/HomepageViewTests -quiet`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftApp.xcodeproj/project.pbxproj
git rm VocabCraftApp/Features/Homepage/Views/LiquidGlassTabBar.swift
git commit -m "feat(homepage): integrate CraftFloatingTabBar and remove legacy LiquidGlassTabBar"
```

---

### Task 3: Complete Test Suite Verification & Accessibility Validation

**Files:**
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `VocabCraftApp`, `CraftUIKit`, `HomepageView`, `AppRouter`, `TabItem`
- Produces: Comprehensive test suite validating tab bar initialization, tab switching, and navigation routing.

- [ ] **Step 1: Update `HomepageViewTests.swift` test cases**

Replace `testLiquidGlassTabBarInitialization` with `testCraftFloatingTabBarInitialization`:
```swift
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
    }
```

- [ ] **Step 2: Run all unit test targets to verify zero regressions**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -quiet`
Expected: ALL TESTS PASS

- [ ] **Step 3: Run CraftUIKit tests to verify no regressions in design system package**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: ALL TESTS PASS

- [ ] **Step 4: Commit test updates**

```bash
git add VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift
git commit -m "test(homepage): update test suite for CraftFloatingTabBar and TabItem"
```
