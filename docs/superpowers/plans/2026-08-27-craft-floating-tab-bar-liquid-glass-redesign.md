# CraftFloatingTabBar Architecture & Liquid Glass Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul `CraftFloatingTabBar` with a 3-tier coordinate-tracked rendering engine, Apple Liquid Glass optical refraction and squash/stretch fluid motion, and encapsulate `showsTitle`/`showsSymbol` presentation within `CraftTabItemProtocol`.

**Architecture:** Decouple button press gestures from active indicator geometry by tracking tab frame coordinates via `TabBarItemPreferenceKey`. Render an independent sliding optical glass pill with dynamic squash/stretch spring kinematics (`Spring(duration: 0.36, bounce: 0.18)`), specular rim highlight, and SF Symbol micro-bounce. Migrate `showsTitle` and `showsSymbol` to `CraftTabItemProtocol` defaults so each item controls its presentation while preserving full accessibility metadata.

**Tech Stack:** Swift 6.0, SwiftUI, iOS 26+ `GlassEffectContainer` / `.glassEffect()`, `PreferenceKey`, `Spring`, `SymbolEffect`.

**Spec:** `docs/superpowers/specs/2026-08-27-craft-floating-tab-bar-liquid-glass-redesign.md`

## Global Constraints

- **Strict Zero Hardcoded Strings Rule**: All labels, formats, accessibility keys use `CraftLocalized` / `Localizable.xcstrings` (EN & VI parity).
- **Accessibility Minimums**: 44x44pt touch targets, full VoiceOver titles on all items, proper Reduce Motion & Reduce Transparency adaptations.
- **Backwards Compatibility**: Keep clean public APIs across `CraftUIKit` while streamlining `CraftFloatingTabBar` initializers.

---

### Task 1: Protocol & Model Presentation Encapsulation (`CraftTabItemProtocol`, `CraftTabItem`, and `TabItem`)

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift:3-58`
- Modify: `VocabCraftApp/App/Navigation/TabItem.swift:1-43`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift:110-145`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift:20-50`

**Interfaces:**
- Consumes: `CraftTabItemProtocol`, `CraftTabItem`, `TabItem`
- Produces:
  - `CraftTabItemProtocol.showsTitle: Bool { get }` (default `true`)
  - `CraftTabItemProtocol.showsSymbol: Bool { get }` (default `true`)
  - `CraftTabItem.init(id:title:symbol:badgeCount:showsTitle:showsSymbol:)`
  - `CraftTabItem.init(id:titleKey:symbol:badgeCount:showsTitle:showsSymbol:)`
  - `TabItem.showsTitle: Bool { false }`

- [ ] **Step 1: Write the failing tests in `NavigationTests.swift`**

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter NavigationTests`
Expected: FAIL with compilation error on `showsTitle`/`showsSymbol`.

- [ ] **Step 3: Update `CraftTabItemProtocol`, `CraftTabItem`, and `TabItem`**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`:
```swift
public protocol CraftTabItemProtocol: Identifiable, Equatable, Sendable where ID: Sendable & Hashable {
    var id: ID { get }
    var title: String { get }
    var symbol: String { get }
    var badgeCount: Int? { get }
    var titleKey: LocalizedStringKey? { get }
    var showsTitle: Bool { get }
    var showsSymbol: Bool { get }
}

public extension CraftTabItemProtocol {
    var badgeCount: Int? { nil }
    var titleKey: LocalizedStringKey? { nil }
    var showsTitle: Bool { true }
    var showsSymbol: Bool { true }
}

public struct CraftTabItem: CraftTabItemProtocol {
    public let id: String
    public let title: String
    public let titleKey: LocalizedStringKey?
    public let symbol: String
    public let badgeCount: Int?
    public let showsTitle: Bool
    public let showsSymbol: Bool

    public init(
        id: String,
        title: String,
        symbol: String,
        badgeCount: Int? = nil,
        showsTitle: Bool = true,
        showsSymbol: Bool = true
    ) {
        self.id = id
        self.title = title
        self.titleKey = nil
        self.symbol = symbol
        self.badgeCount = badgeCount
        self.showsTitle = showsTitle
        self.showsSymbol = showsSymbol
    }

    public init(
        id: String,
        titleKey: LocalizedStringKey,
        symbol: String,
        badgeCount: Int? = nil,
        showsTitle: Bool = true,
        showsSymbol: Bool = true
    ) {
        self.id = id
        self.title = ""
        self.titleKey = titleKey
        self.symbol = symbol
        self.badgeCount = badgeCount
        self.showsTitle = showsTitle
        self.showsSymbol = showsSymbol
    }
}
```

In `VocabCraftApp/App/Navigation/TabItem.swift`:
```swift
    public var showsTitle: Bool { false }
    public var showsSymbol: Bool { true }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter NavigationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift Packages/CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift VocabCraftApp/App/Navigation/TabItem.swift
git commit -m "feat(navigation): encapsulate showsTitle and showsSymbol in CraftTabItemProtocol"
```

---

### Task 2: 3-Tier Coordinate Space Engine & Fluid Liquid Glass Motion in `CraftFloatingTabBar.swift`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift:99-463`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift:20-330`

**Interfaces:**
- Consumes: `CraftTabItemProtocol`, `CraftTheme`, `CraftSurfaceStyle`, `CraftCenterButtonPosition`
- Produces:
  - `CraftTabBarItemPreferenceKey: PreferenceKey`
  - Streamlined `CraftFloatingTabBar.init(selectedItem:items:style:centerPosition:centerAction:centerSymbol:centerTitle:centerTitleKey:)` (without `showsTitles`)
  - `CraftSlidingFluidPill` view layer with specular rim highlight and squash/stretch kinematics
  - Decoupled `CraftTabButton` with SF Symbol hierarchical micro-bounce and isolated press effect

- [ ] **Step 1: Write failing unit tests in `NavigationTests.swift` for streamlined initializers and coordinate layout**

```swift
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter NavigationTests`
Expected: FAIL with missing initializer or deprecated arguments.

- [ ] **Step 3: Implement 3-Tier Layered Rendering & Fluid Motion in `CraftFloatingTabBar.swift`**

1. Define `CraftTabBarItemPreferenceKey`:
```swift
struct CraftTabBarItemPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
```

2. Implement `CraftFloatingTabBar` with state tracking for tab item frames and active indicator translation:
- Manage `tabFrames: [String: CGRect]` and `@State private var isTransitioning = false`.
- Calculate target frame for `selectedItem.id`.
- Render Tier 1 (Background Capsule Container), Tier 2 (Independent `CraftSlidingFluidPill` on coordinate space `"CraftTabBarTrack"`), and Tier 3 (Foreground `HStack` of `CraftTabButton`s reporting geometry).
- In `select(_ item: Item)`:
  - Trigger `isTransitioning = true`.
  - Animate with `withAnimation(theme.animations.springSnappy)` (or `Spring(duration: 0.36, bounce: 0.18)`).
  - Reset `isTransitioning = false` after settle or inside completion/withAnimation block.
- Remove `showsTitles` argument from initializers.

3. Refactor `CraftTabButton`:
- Use `showsTitle = item.showsTitle` and `showsSymbol = item.showsSymbol`.
- Remove `matchedGeometryEffect` from inside button background.
- Set button style to scale only the icon/label on press (`.buttonStyle(.craftPress(scale: 0.95))`), not the frame.
- Attach `.background(GeometryReader { proxy in Color.clear.preference(key: CraftTabBarItemPreferenceKey.self, value: [String(describing: item.id): proxy.frame(in: .named("CraftTabBarTrack"))]) })`.
- Apply SF Symbol scale `1.08x` and hierarchical rendering when selected.

4. Implement `CraftSlidingFluidPill`:
- Renders at the target `selectedFrame`.
- For `.glass` style:
  - Specular glass base with `.glassEffect(.regular.tint(theme.colors.brandPrimary).interactive(), in: .capsule)` on iOS 26+, or multi-stop linear gradient (`LinearGradient(colors: [theme.colors.brandPrimary.opacity(0.18), theme.colors.brandPrimary.opacity(0.08)], startPoint: .top, endPoint: .bottom)`) on pre-iOS 26.
  - Specular rim highlight: `Capsule().strokeBorder(LinearGradient(colors: [.white.opacity(0.40), theme.colors.brandPrimary.opacity(0.12)], startPoint: .top, endPoint: .bottom), lineWidth: 0.8)`.
  - Ambient glow shadow: `theme.colors.brandPrimary.opacity(0.20)`, radius: 6, y: 2.
  - Squash & Stretch kinetic scaling: `.scaleEffect(x: (isTransitioning && !reduceMotion) ? 1.08 : 1.0, y: (isTransitioning && !reduceMotion) ? 0.94 : 1.0)`.

- [ ] **Step 4: Update existing tests in `NavigationTests.swift`**

Update test cases that passed `showsTitles:` to use new initializers and test new capabilities.

- [ ] **Step 5: Run tests to verify they pass**

Run: `swift test --package-path Packages/CraftUIKit --filter NavigationTests`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift Packages/CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift
git commit -m "feat(CraftFloatingTabBar): 3-tier coordinate tracking with fluid liquid glass motion"
```

---

### Task 3: Update `CraftCatalogView` Previews, Call Sites, and Full Integration Verification

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift:2230-2265`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:79-94`
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift:20-50`

**Interfaces:**
- Consumes: Updated `CraftFloatingTabBar` and `TabItem`
- Produces: Clean compilation and passing integration tests across app and design system.

- [ ] **Step 1: Update `CraftCatalogView.swift` call sites and preview models**

Update `CatalogTabItem` or preview tabs to set `showsTitle: false` for icon-only demos and call `CraftFloatingTabBar` with updated signature.

- [ ] **Step 2: Update `HomepageView.swift` and `HomepageViewTests.swift`**

Remove `showsTitles: false` in `HomepageView.swift` (since `TabItem.showsTitle` is `false`).
Update `HomepageViewTests.swift` initializers.

- [ ] **Step 3: Run all CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS (All test suites pass)

- [ ] **Step 4: Run app tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift
git commit -m "refactor(navigation): update catalog previews and app homepage integration for CraftFloatingTabBar"
```

---

## Verification Plan

### Automated Tests
1. `swift test --package-path Packages/CraftUIKit`
2. `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:VocabCraftAppTests`
3. `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`

### Manual Verification
1. Run app on iOS Simulator.
2. Switch between Home, Vocabulary, Search, and Settings tabs:
   - Observe smooth fluid glide with horizontal stretch (`1.08x`) and settle bounce.
   - Observe specular glass refraction highlight on active pill.
   - Observe SF Symbol hierarchical bounce on selection.
3. Test tap on Center FAB (Reflex Blitz) to ensure zIndex and layout gap integrity.
4. Toggle Accessibility -> Reduce Motion & Reduce Transparency in iOS Settings to verify fallback rendering.
