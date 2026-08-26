# CraftChoiceCard UI/UX Modernization & Dynamic Prefix Style Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Modernize `CraftChoiceCard` with a versatile prefix styling system (`CraftChoicePrefixStyle`), high-contrast WCAG AAA typography, subtle state tint washes, and refined iOS 26 Liquid Glass refraction.

**Architecture:** Extend `CraftChoiceCard` with `CraftChoicePrefixStyle` enum (`.circle`, `.roundedSquare`, `.minimal`, `.none`), default to `.circle` for clean modern quiz aesthetics, decouple text ink colors from background tints for >7:1 to >12:1 contrast ratios, and refine Liquid Glass rendering.

**Tech Stack:** Swift 6.0, SwiftUI, SF Pro Rounded, Apple Liquid Glass (iOS 26+ with iOS 17/18 fallbacks), Swift Testing / XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-26-craft-choice-card-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-26-craft-choice-card-design.md)

## Global Constraints

- Swift 6 strict concurrency compliance (`Sendable` structs and enums).
- 100% backward API compatibility for existing `CraftChoiceCard` call sites.
- System fonts only (SF Pro and `.fontDesign(.rounded)`).
- WCAG AAA compliance (>7:1 contrast ratio for all readable text).
- Dynamic Type & VoiceOver compatibility.

---

### Task 1: Implement `CraftChoicePrefixStyle` & High-Contrast Visual Engine in `CraftChoiceCard`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`

**Interfaces:**
- Produces: `public enum CraftChoicePrefixStyle: String, Sendable, CaseIterable { case circle, roundedSquare, minimal, none }`
- Produces: Updated initializers `CraftChoiceCard.init(prefix:prefixStyle:title:subtitle:state:style:action:)` (with `prefixStyle: CraftChoicePrefixStyle = .circle` default).

- [ ] **Step 1: Write failing unit test for `CraftChoicePrefixStyle` in `ControlComponentTests.swift`**

```swift
func testCraftChoicePrefixStyleCases() {
    let cardCircle = CraftChoiceCard(prefix: "A", prefixStyle: .circle, title: "Option A") {}
    let cardMinimal = CraftChoiceCard(prefix: "B", prefixStyle: .minimal, title: "Option B") {}
    let cardSquare = CraftChoiceCard(prefix: "C", prefixStyle: .roundedSquare, title: "Option C") {}
    let cardNone = CraftChoiceCard(prefix: nil, prefixStyle: .none, title: "Option None") {}

    XCTAssertEqual(cardCircle.prefixStyle, .circle)
    XCTAssertEqual(cardMinimal.prefixStyle, .minimal)
    XCTAssertEqual(cardSquare.prefixStyle, .roundedSquare)
    XCTAssertEqual(cardNone.prefixStyle, .none)
}
```

- [ ] **Step 2: Run test to verify it fails to compile**

Run: `swift test --package-path CraftUIKit --filter testCraftChoicePrefixStyleCases`  
Expected: Compilation failure (`'CraftChoicePrefixStyle' is undefined` or `'prefixStyle' not found`).

- [ ] **Step 3: Implement `CraftChoicePrefixStyle`, updated inits, high-contrast colors, and badge rendering in `CraftChoiceCard.swift`**

Update `CraftChoiceCard.swift`:
1. Define `public enum CraftChoicePrefixStyle: String, Sendable, CaseIterable`.
2. Add `public let prefixStyle: CraftChoicePrefixStyle` property.
3. Update `init(prefix:prefixStyle:title:subtitle:state:style:action:)` for both `String` and `LocalizedStringKey` signatures with default `prefixStyle: CraftChoicePrefixStyle = .circle`.
4. Refactor `prefixBadge` with shape dispatch:
   - `.circle`: `Circle()` with `32x32` min size, filled with state color when selected/correct/wrong with white text.
   - `.roundedSquare`: `RoundedRectangle(cornerRadius: theme.radii.sm)`.
   - `.minimal`: Plain text with `.headline.bold().fontDesign(.rounded)` and state-colored ink.
   - `.none`: `EmptyView()`.
5. Update `titleColor` -> `theme.colors.textPrimary` (or `textMuted` when disabled).
6. Update `subtitleColor` -> `theme.colors.textSecondary` (or `textMuted` when disabled).
7. Refine `stateTintOverlay` to subtle wash (0.08 light / 0.16 dark) and `cardBorderOverlay` with 2.0pt vivid state strokes.
8. Refine Liquid Glass `.glassEffect` to prevent double-glass rendering on nested badges.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter testCraftChoicePrefixStyleCases`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift
git commit -m "feat(CraftUIKit): implement CraftChoicePrefixStyle and high-contrast text engine in CraftChoiceCard"
```

---

### Task 2: Comprehensive Unit Tests for All Prefix Styles, States, and Accessibility

**Files:**
- Modify: `CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `CraftChoicePrefixStyle`, `CraftChoiceState`, `CraftChoiceCard`.

- [ ] **Step 1: Write unit tests for all prefix styles and states combinations**

Add comprehensive test cases in `ControlComponentTests.swift`:
- `testChoiceCardAllPrefixStyles()`: Verifies that `.circle`, `.roundedSquare`, `.minimal`, `.none` instantiate with correct defaults and accessibility descriptions.
- `testChoiceCardDefaultPrefixStyleIsCircle()`: Verifies that omitting `prefixStyle` defaults to `.circle`.
- `testChoiceCardAccessibilityValues()`: Verifies accessibility descriptions across `.idle`, `.selected`, `.correct`, `.wrong`, and `.disabled`.

- [ ] **Step 2: Run all ControlComponentTests and InteractiveCardTests**

Run: `swift test --package-path CraftUIKit --filter "(ControlComponentTests|InteractiveCardTests)"`  
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Tests/CraftUIKitTests/ControlComponentTests.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "test(CraftUIKit): add comprehensive unit tests for CraftChoicePrefixStyle and choice card states"
```

---

### Task 3: Showcase Prefix Styles and Refined Glass in Catalog Preview

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`

**Interfaces:**
- Consumes: `CraftChoiceCard`, `CraftChoicePrefixStyle`, `CraftChoiceState`, `CraftSurfaceStyle`.

- [ ] **Step 1: Add prefix style segmented picker in `CraftCatalogView.swift`**

Add a dedicated `CraftChoicePrefixStyle` segmented picker and dynamic state cards showcase in `CraftCatalogView.swift`:
- Allows toggling between `.circle`, `.roundedSquare`, `.minimal`, `.none`.
- Demonstrates interactive selection across all 5 states with live surface style switching (`.tactile3D`, `.glass`, `.elevated`, `.outlined`, `.flat`).

- [ ] **Step 2: Run catalog view test suite**

Run: `swift test --package-path CraftUIKit --filter CatalogViewTests`  
Expected: PASS

- [ ] **Step 3: Verify overall package builds cleanly without warnings**

Run: `swift build --package-path CraftUIKit`  
Expected: Build succeeded with zero warnings.

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "feat(CraftUIKit): add prefix style picker and state showcase in CraftCatalogView"
```
