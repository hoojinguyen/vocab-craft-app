# CraftUIKit Core Components Visual Elevation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Elevate `CraftButton`, `CraftSearchBar`, and `CraftFloatingTabBar` with modern dark slate, tactile 3D depth, and pill-bubble active indicator design language.

**Architecture:** Extend `CraftButton` with a `.tactile` 3D push variant and uppercase tracking; introduce `.recessed` glass style and trailing slots to `CraftSearchBar`; upgrade `CraftFloatingTabBar` to an elevated pill-bubble indicator with badge support and spring animations.

**Tech Stack:** Swift 6, SwiftUI, Swift Package Manager, XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-22-craftuikit-components-elevation-design.md`

## Global Constraints
- Target platform: iOS 17.0+ / macOS 14.0+
- Retain 100% backward compatibility for all existing initializers and enum cases
- Touch target minimum: 44pt for interactive controls
- All tests must pass with `swift test` in `CraftUIKit`

---

### Task 1: Enhance `CraftButton` with `.tactile` Variant & Typography Controls

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftButtonVariant`, `CraftButtonSize`
- Produces: `CraftButtonVariant.tactile`, `CraftButtonStyle.craftTactile`, `CraftButton.init(..., isUppercase: Bool, tracking: CGFloat?, isFullWidth: Bool)`

- [ ] **Step 1: Write failing tests in `ControlComponentTests.swift` for tactile variant and typography modifiers**

```swift
func testButtonTactileVariant() {
    let button = CraftButton("PRACTICE", variant: .tactile, size: .lg, isUppercase: true, tracking: 1.2) {}
    XCTAssertEqual(button.variant, .tactile)
    XCTAssertEqual(button.size, .lg)
    XCTAssertTrue(button.isUppercase)
    XCTAssertEqual(button.tracking, 1.2)
    XCTAssertNotNil(button.body)
}

func testButtonTactileNativeStyle() {
    let view = Button("Practice") {}.buttonStyle(.craftTactile())
    XCTAssertNotNil(view)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter ControlComponentTests.testButtonTactileVariant`
Expected: FAIL (type `CraftButtonVariant` has no member `tactile`, `CraftButton` has no `isUppercase` parameter)

- [ ] **Step 3: Implement `.tactile` variant and typography extensions in `CraftButton.swift`**

Update `CraftButtonVariant` enum to include `case tactile`.
In `CraftButtonStyle`, implement 3D tactile bevel background & push-down offset (`isPressed ? 3 : 0`) and bottom shadow adjustment.
Add `isUppercase: Bool = false`, `tracking: CGFloat? = nil`, and `isFullWidth: Bool = false` to `CraftButton` initializers and render logic.
Add static convenience `.craftTactile(size: CraftButtonSize = .md, isLoading: Bool = false) -> CraftButtonStyle`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path CraftUIKit --filter ControlComponentTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftButton.swift CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift
git commit -m "feat(CraftButton): add tactile 3D push variant and uppercase tracking support"
```

---

### Task 2: Enhance `CraftSearchBar` with Recessed Glass Style & Trailing Action Slot

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftIcon`
- Produces: `CraftSearchBarStyle` (`.standard`, `.recessed`), `CraftSearchBarShape` (`.capsule`, `.roundedRectangle(radius: CGFloat)`), `CraftSearchBar.init(..., style: CraftSearchBarStyle, shape: CraftSearchBarShape, trailingAction: (() -> Void)?, trailingIcon: String?)`

- [ ] **Step 1: Write failing tests in `ControlComponentTests.swift` for `CraftSearchBarStyle` and shape options**

```swift
func testSearchBarRecessedStyleAndShape() {
    var query = "vocab"
    let searchBar = CraftSearchBar(
        text: Binding(get: { query }, set: { query = $0 }),
        placeholder: "Search words",
        style: .recessed,
        shape: .roundedRectangle(radius: 14),
        trailingIcon: "slider.horizontal.3",
        trailingAction: {}
    )
    XCTAssertEqual(searchBar.style, .recessed)
    XCTAssertEqual(searchBar.shape, .roundedRectangle(radius: 14))
    XCTAssertEqual(searchBar.trailingIcon, "slider.horizontal.3")
    XCTAssertNotNil(searchBar.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter ControlComponentTests.testSearchBarRecessedStyleAndShape`
Expected: FAIL (`CraftSearchBarStyle` not found)

- [ ] **Step 3: Implement `CraftSearchBarStyle`, `CraftSearchBarShape`, and trailing slots in `CraftSearchBar.swift`**

Define `CraftSearchBarStyle` (`standard`, `recessed`) and `CraftSearchBarShape` (`capsule`, `roundedRectangle(radius: CGFloat)`).
In `CraftSearchBar`, render dark translucent inset surface with hairline border and ambient glow on focus for `.recessed`.
Render trailing action button slot when `trailingIcon` and `trailingAction` are provided.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path CraftUIKit --filter ControlComponentTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftSearchBar.swift CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift
git commit -m "feat(CraftSearchBar): add recessed glass styling, custom shape, and trailing action slot"
```

---

### Task 3: Elevate `CraftFloatingTabBar` with Pill-Bubble Active Indicator & Badge Support

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift`

**Interfaces:**
- Consumes: `CraftTabItemProtocol`, `CraftTheme`, `CraftIcon`
- Produces: `CraftTabItemProtocol.badgeCount: Int?`, `CraftFloatingTabBar` pill-bubble active indicator & glass container styling

- [ ] **Step 1: Write failing tests in `NavigationTests.swift` for pill-bubble tab bar and badge protocol extension**

```swift
private struct _TestTabWithBadge: CraftTabItemProtocol {
    let id: String
    let title: String
    let symbol: String
    var badgeCount: Int? = 3
}

func testFloatingTabBarWithBadge() {
    var selected = _TestTabWithBadge(id: "library", title: "Library", symbol: "books.vertical", badgeCount: 5)
    let items = [
        _TestTabWithBadge(id: "home", title: "Home", symbol: "house", badgeCount: nil),
        selected
    ]
    let tabBar = CraftFloatingTabBar(selectedItem: Binding(get: { selected }, set: { selected = $0 }), items: items)
    XCTAssertNotNil(tabBar.body)
}
```

- [ ] **Step 2: Run test to verify it fails if `badgeCount` is required or missing default implementation**

Run: `swift test --package-path CraftUIKit --filter NavigationTests`
Expected: Verifies compilation & baseline test expectations.

- [ ] **Step 3: Implement Pill-Bubble Active Indicator, Badge Overlay, and Glass Styling in `CraftFloatingTabBar.swift`**

Extend `CraftTabItemProtocol` with optional `var badgeCount: Int? { get }` (default `nil`).
In `tabButton(for:)`:
- Wrap active tab in an elevated pill capsule (`theme.colors.surfaceElevated` / `#2F344C` opacity) using `.matchedGeometryEffect(id: "activeTabIndicator", in: tabNamespace)`.
- Render active tab icon with vibrant violet/brand styling and highlighted font weight.
- Add badge overlay (`CraftBadge` or indicator dot) at top-trailing of the icon when `item.badgeCount != nil`.
- Apply specular hairline border on outer floating capsule.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path CraftUIKit --filter NavigationTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift
git commit -m "feat(CraftFloatingTabBar): upgrade active tab indicator to pill bubble with badge support"
```

---

### Task 4: Update `CraftCatalogView.swift` Interactive Showcase

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Consumes: Updated `CraftButton`, `CraftSearchBar`, `CraftFloatingTabBar`
- Produces: Visual showcase for all newly added variants and options

- [ ] **Step 1: Update Buttons, SearchBar, and Navigation sections in `CraftCatalogView.swift`**

- In `CatalogButtonsSection`: Add `.tactile` variant interactive demo ("PRACTICE" uppercase CTA with 3D press).
- In `CatalogTextFieldsSection`: Add `.recessed` search bar style with filter action button.
- In `CatalogNavigationSection`: Add badge count demo to `CatalogTabItem` and show pill-bubble sliding indicator.

- [ ] **Step 2: Run catalog view tests to ensure compilation and render integrity**

Run: `swift test --package-path CraftUIKit --filter CatalogViewTests`
Expected: PASS

- [ ] **Step 3: Commit changes**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "feat(CraftCatalogView): showcase tactile buttons, recessed search, and pill-bubble tab bar"
```

---

### Task 5: End-to-End Test Suite Verification

**Files:**
- Test: All tests in `CraftUIKit/Tests/`

- [ ] **Step 1: Execute full test suite across CraftUIKit**

Run: `swift test --package-path CraftUIKit`
Expected: All tests pass with 0 failures.

- [ ] **Step 2: Verify zero warnings and clean build**

Run: `swift build --package-path CraftUIKit`
Expected: Build complete with 0 errors.
