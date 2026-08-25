# CraftIconButton Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign and upgrade `CraftIconButton` with physical 3D press depression (`.tactile3D`), sensory haptics, disabled opacity, loading spinner state, toggle selection (`isSelected`), danger variant, and localized accessibility traits while preserving 100% backwards compatibility.

**Architecture:** Split button interaction and presentation: `CraftIconButton` acts as the declarative container handling accessibility, loading state, and action triggers, while a dedicated `CraftIconButtonStyle: ButtonStyle` handles live press detection (`configuration.isPressed`), mechanical 3D depression offset via `craftSurface`, 44x44pt touch target bounding, and spring scaling.

**Tech Stack:** Swift 5.9+ / Swift 6, SwiftUI, Swift Testing / XCTest, iOS 17+ HIG.

**Spec:** [docs/superpowers/specs/2026-08-25-craft-icon-button-design.md](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-25-craft-icon-button-design.md)

## Global Constraints

- 100% backwards compatibility for existing call sites across `CraftUIKit` and apps.
- Enforce Apple HIG minimum touch target of 44x44pt on all sizes.
- Respect `accessibilityReduceMotion` for press down scaling.
- Zero compile warnings and 100% test pass on `swift test --package-path CraftUIKit`.

---

### Task 1: Extend `CraftIconButtonVariant` with `.danger` & Update Enum Tests

**Files:**
- Modify: [CraftIconButton.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift)
- Test: [AtomComponentTests.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift)

**Interfaces:**
- Produces: `CraftIconButtonVariant.danger`

- [ ] **Step 1: Write the failing test for `danger` variant**

Add to [AtomComponentTests.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift#L234-L253):
```swift
func testIconButtonDangerVariant() {
    let btn = CraftIconButton(
        iconName: "trash.fill",
        variant: .danger,
        accessibilityLabel: "Delete"
    ) {}
    XCTAssertEqual(btn.variant, .danger)
    XCTAssertEqual(CraftIconButtonVariant.allCases.contains(.danger), true)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter AtomComponentTests/testIconButtonDangerVariant`
Expected: Compilation failure due to type `CraftIconButtonVariant` having no member `danger`.

- [ ] **Step 3: Add `case danger` to `CraftIconButtonVariant`**

In [CraftIconButton.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift#L17-L22):
```swift
public enum CraftIconButtonVariant: String, Sendable, CaseIterable {
    case filled
    case subtle
    case outline
    case ghost
    case danger
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter AtomComponentTests/testIconButtonDangerVariant`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift
git commit -m "feat(CraftUIKit): add danger variant to CraftIconButtonVariant"
```

---

### Task 2: Implement `CraftIconButtonStyle` with 3D Depression, Touch Targets, and Haptics

**Files:**
- Modify: [CraftIconButton.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift)
- Test: [AtomComponentTests.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift)

**Interfaces:**
- Produces: `public struct CraftIconButtonStyle: ButtonStyle`

- [ ] **Step 1: Write test for `CraftIconButtonStyle` and tactile press resolution**

Add to [AtomComponentTests.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift):
```swift
func testIconButtonStyleInstantiation() {
    let style = CraftIconButtonStyle(
        size: .md,
        shape: .circle,
        variant: .subtle,
        style: .tactile3D,
        customTint: nil,
        isSelected: false,
        isLoading: false
    )
    XCTAssertEqual(style.size, .md)
    XCTAssertEqual(style.shape, .circle)
    XCTAssertEqual(style.variant, .subtle)
    XCTAssertEqual(style.style, .tactile3D)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter AtomComponentTests/testIconButtonStyleInstantiation`
Expected: FAIL (`CraftIconButtonStyle` not found).

- [ ] **Step 3: Implement `CraftIconButtonStyle` in `CraftIconButton.swift`**

Implement `CraftIconButtonStyle` with:
- `@Environment(\.craftTheme) private var theme`
- `@Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle`
- `@Environment(\.isEnabled) private var isEnabled`
- `@Environment(\.accessibilityReduceMotion) private var reduceMotion`
- Live `isPressed` observation via `configuration.isPressed`
- Forwarding `isPressed` to `.craftSurface(..., isPressed: isPressed)`
- `.frame(width: visualDimension, height: visualDimension)` + `.frame(minWidth: 44, minHeight: 44)` + `.contentShape(Rectangle())`
- Disabled state `opacity: isEnabled ? (isLoading ? 0.8 : 1.0) : 0.4`
- Haptic feedback `.sensoryFeedback(.impact(weight: .light), trigger: isPressed)`

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter AtomComponentTests/testIconButtonStyleInstantiation`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift
git commit -m "feat(CraftUIKit): implement CraftIconButtonStyle with 3D press depression and haptics"
```

---

### Task 3: Upgrade `CraftIconButton` with `isSelected`, `isLoading`, and Localized Inits

**Files:**
- Modify: [CraftIconButton.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift)
- Test: [AtomComponentTests.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift)

**Interfaces:**
- Consumes: `CraftIconButtonStyle`, `CraftSpinner`, `CraftIcon`, `CraftSymbol`
- Produces: Upgraded `CraftIconButton` view with `isSelected`, `isLoading`, `accessibilityHint`, `LocalizedStringKey` inits.

- [ ] **Step 1: Write tests for `isSelected`, `isLoading`, `accessibilityHint`, and localized initializers**

Add to [AtomComponentTests.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift):
```swift
func testIconButtonSelectedAndLoadingStates() {
    var executed = false
    let selectedBtn = CraftIconButton(
        symbol: .favoriteFill,
        isSelected: true,
        accessibilityLabel: "Favorited"
    ) {
        executed = true
    }
    XCTAssertTrue(selectedBtn.isSelected)
    XCTAssertFalse(selectedBtn.isLoading)
    XCTAssertEqual(selectedBtn.accessibilityLabel, "Favorited")
    XCTAssertNotNil(selectedBtn.body)

    let loadingBtn = CraftIconButton(
        iconName: "arrow.clockwise",
        isLoading: true,
        accessibilityLabel: "Refreshing",
        accessibilityHint: "Fetches latest data"
    ) {
        executed = true
    }
    XCTAssertTrue(loadingBtn.isLoading)
    XCTAssertEqual(loadingBtn.accessibilityHint, "Fetches latest data")
    XCTAssertNotNil(loadingBtn.body)
}

func testIconButtonLocalizedStringKeyInit() {
    let localizedBtn = CraftIconButton(
        symbol: .settings,
        accessibilityLabelKey: "craft.settings",
        accessibilityHint: "Opens settings"
    ) {}
    XCTAssertEqual(localizedBtn.accessibilityLabelKey, "craft.settings")
    XCTAssertNotNil(localizedBtn.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter AtomComponentTests/testIconButtonSelectedAndLoadingStates`
Expected: FAIL (missing parameters / properties).

- [ ] **Step 3: Update `CraftIconButton` implementation**

In [CraftIconButton.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift):
1. Add `public let isSelected: Bool` (default `false`).
2. Add `public let isLoading: Bool` (default `false`).
3. Add `public let accessibilityLabel: String?` and `public let accessibilityLabelKey: LocalizedStringKey?`.
4. Add `public let accessibilityHint: String?`.
5. In `body`:
   - Button action guards against `isLoading` (`guard !isLoading else { return }`).
   - If `isLoading`, renders `CraftSpinner(size: size, color: foregroundColor)`.
   - If not `isLoading`, renders `CraftIcon(...)`.
   - Applies `.buttonStyle(CraftIconButtonStyle(...))`.
   - Sets `.accessibilityLabel`, `.accessibilityHint`, `.accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)`.
   - Sets `.disabled(isLoading)`.
6. Harmonize `foregroundColor` and `effectiveTint` with `CraftButton.swift` rules.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path CraftUIKit --filter AtomComponentTests`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift CraftUIKit/Tests/CraftUIKitTests/AtomComponentTests.swift
git commit -m "feat(CraftUIKit): support isSelected, isLoading, and localized accessibility in CraftIconButton"
```

---

### Task 4: Polish Previews & Verify CatalogView and Package Build

**Files:**
- Modify: [CraftIconButton.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift#L222-L241)
- Verify: [CraftCatalogView.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift)
- Verify: [CatalogViewTests.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift)

- [ ] **Step 1: Update `#Preview("CraftIconButton")`**

Update `#Preview` in [CraftIconButton.swift](file:///Users/hoojinguyen/Projects/vocab-craft-app/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift) to showcase:
- All 5 Variants: `filled`, `subtle`, `outline`, `ghost`, `danger`.
- All 5 Surface Styles: `flat`, `elevated`, `outlined`, `tactile3D`, `glass`.
- Interactive States: Default, `isSelected: true`, `isLoading: true`, `.disabled(true)`.

- [ ] **Step 2: Run complete test suite across CraftUIKit**

Run: `swift test --package-path CraftUIKit`
Expected: 100% tests pass (415+ tests).

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftIconButton.swift CraftUIKit/Tests/CraftUIKitTests/
git commit -m "chore(CraftUIKit): update CraftIconButton preview and verify full test suite"
```

---

## Plan Self-Review

1. **Spec Coverage Check**:
   - 3D tactile depression via `CraftIconButtonStyle` -> Task 2
   - `isEnabled` disabled opacity & haptics -> Task 2
   - `isSelected`, `isLoading`, `LocalizedStringKey`, `accessibilityHint` -> Task 3
   - `case danger` variant -> Task 1
   - Previews & Catalog integration -> Task 4
2. **Placeholder Scan**: No `TODO`, `TBD`, or ambiguous logic.
3. **Type & Signature Consistency**: Types match between spec and tasks.
