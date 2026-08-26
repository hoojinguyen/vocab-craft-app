# CraftChoiceCard Tactile 3D Refinement & Flexible Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Uplift `CraftChoiceCard` to support flexible text alignment (`.leading` and `.center`) for minimalist phrase practice cards (e.g. video listening exercises) and fix the `tactile3D` button style geometry and surface contrast.

**Architecture:** Extend `CraftChoiceCard` with a `textAlignment: TextAlignment` property and conditional centered layout. Refactor `CraftChoiceCardButtonStyle` to use `.offset(y: depth)` for pixel-perfect 3D extrusion curvature and improve high-contrast surface coloring.

**Tech Stack:** Swift 6.0, SwiftUI, XCTest, CraftUIKit design tokens.

**Spec:** `docs/superpowers/specs/2026-08-26-craft-choice-card-tactile-and-alignment-design.md`

## Global Constraints

- 100% Backward Compatibility: All existing `CraftChoiceCard` call sites must compile without changes (`textAlignment` defaults to `.leading`).
- WCAG AAA Text Contrast: All interactive states must preserve high-contrast text against card surfaces.
- Zero Geometry Glitches: Tactile 3D base layer must match top face corner radius without visual protrusion or clipping.
- Platform: iOS 17.0+, macOS 14.0+.

---

### Task 1: Add `textAlignment: TextAlignment` Support to `CraftChoiceCard`

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `TextAlignment` from SwiftUI, `CraftChoicePrefixStyle`, `CraftChoiceState`.
- Produces: `CraftChoiceCard.textAlignment` property and updated `cardSurface` layout.

- [ ] **Step 1: Write the failing tests in `InteractiveCardTests.swift`**

```swift
// Add to InteractiveCardTests.swift
func testChoiceCardTextAlignmentDefaultAndCustom() {
    let defaultCard = CraftChoiceCard(title: "Default Alignment") {}
    XCTAssertEqual(defaultCard.textAlignment, .leading)

    let centeredCard = CraftChoiceCard(
        prefix: nil,
        prefixStyle: .none,
        title: "Centered Practice Option",
        textAlignment: .center,
        showsStatusIndicator: false
    ) {}
    XCTAssertEqual(centeredCard.textAlignment, .center)
    XCTAssertEqual(centeredCard.prefixStyle, .none)
    XCTAssertFalse(centeredCard.showsStatusIndicator)
    XCTAssertNotNil(centeredCard.body)
}

func testChoiceCardLocalizedKeyWithTextAlignment() {
    let localizedCard = CraftChoiceCard(
        title: LocalizedStringKey("craft.choice.practice_title"),
        textAlignment: .center,
        showsStatusIndicator: false
    ) {}
    XCTAssertEqual(localizedCard.textAlignment, .center)
    XCTAssertFalse(localizedCard.showsStatusIndicator)
    XCTAssertNotNil(localizedCard.body)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path CraftUIKit --filter testChoiceCardTextAlignmentDefaultAndCustom`  
Expected: Build failure / missing `textAlignment` property.

- [ ] **Step 3: Implement `textAlignment` in `CraftChoiceCard.swift`**

Update `CraftChoiceCard.swift`:
1. Add `public let textAlignment: TextAlignment`.
2. Update all initializers (`String`, `LocalizedStringKey`, `CraftSymbol`) to accept `textAlignment: TextAlignment = .leading`.
3. Update `cardSurface` to render a centered `VStack` when `textAlignment == .center && (prefixStyle == .none || (prefixKey == nil && rawPrefix == nil)) && !showsStatusIndicator`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter InteractiveCardTests`  
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "feat(CraftChoiceCard): add textAlignment support and centered layout mode"
```

---

### Task 2: Refactor `CraftChoiceCardButtonStyle` Tactile 3D Geometry & Contrast

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Test: `CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift`

**Interfaces:**
- Consumes: `theme.depths.depthMd`, `theme.radii.lg`, `theme.colors`.
- Produces: Corrected `CraftChoiceCardButtonStyle` with `.offset(y: depth)`, high-contrast `bottomLipColor`, and clean `.tactile3D` surface without interfering highlights.

- [ ] **Step 1: Write the failing tests in `InteractiveCardTests.swift`**

```swift
func testChoiceCardButtonStylePropertiesAndTactileDepth() {
    let buttonStyle = CraftChoiceCardButtonStyle(state: .selected, style: .tactile3D, depth: 4)
    XCTAssertEqual(buttonStyle.state, .selected)
    XCTAssertEqual(buttonStyle.style, .tactile3D)
    XCTAssertEqual(buttonStyle.depth, 4)

    let idleStyle = CraftChoiceCardButtonStyle(state: .idle, style: .tactile3D, depth: 4)
    XCTAssertEqual(idleStyle.state, .idle)
}

func testTactileCardRenderingAcrossAllStates() {
    for state in CraftChoiceState.allCases {
        let card = CraftChoiceCard(
            prefix: nil,
            prefixStyle: .none,
            title: "Option in \(state.rawValue)",
            textAlignment: .center,
            state: state,
            style: .tactile3D,
            showsStatusIndicator: false
        ) {}
        XCTAssertNotNil(card.body)
    }
}
```

- [ ] **Step 2: Run test to verify it passes or fails**

Run: `swift test --package-path CraftUIKit --filter testChoiceCardButtonStylePropertiesAndTactileDepth`  
Expected: Test execution.

- [ ] **Step 3: Implement tactile 3D geometry fix and high-contrast styling**

In `CraftChoiceCard.swift`:
1. In `CraftChoiceCardButtonStyle.makeBody`:
   Replace `.padding(.top, depth)` on the bottom rectangle with `.offset(y: depth)`.
2. Update `bottomLipColor`:
   - `.idle`: `.craftDynamic(light: Color(hex: 0xD1D5DB), dark: Color(hex: 0x374151))`
   - `.selected`: `theme.colors.brandSecondary`
   - `.correct`: `.craftDynamic(light: Color(hex: 0x059669), dark: Color(hex: 0x047857))`
   - `.wrong`: `.craftDynamic(light: Color(hex: 0xDC2626), dark: Color(hex: 0xB91C1C))`
   - `.disabled`: `.clear`
3. In `topHighlightOverlay`:
   Do not render top highlight in `.tactile3D` when `state != .idle`, ensuring vibrant semantic borders are not washed out.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path CraftUIKit --filter InteractiveCardTests`  
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift CraftUIKit/Tests/CraftUIKitTests/InteractiveCardTests.swift
git commit -m "fix(CraftChoiceCard): fix tactile3D extrusion geometry and contrast styling"
```

---

### Task 3: Showcase Centered Cards in Preview and Catalog

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`

**Interfaces:**
- Consumes: `CraftChoiceCard` with `.center` and `.tactile3D`.
- Produces: Updated preview container and catalog section for interactive practice quiz cards.

- [ ] **Step 1: Update `CraftChoiceCardPreviewContainer`**

In `CraftChoiceCard.swift`:
Add a Segmented Picker for `Alignment` (`.leading` vs `.center`) and render a dedicated Practice / Video Quiz demo matching the user's reference screenshot.

- [ ] **Step 2: Update `CraftCatalogView.swift`**

In `CraftCatalogView.swift`:
Include both Standard A/B/C/D Choice Cards and Minimalist Centered Practice Option Cards in the Controls gallery section.

- [ ] **Step 3: Run full test suite to ensure clean build and 100% test pass**

Run: `swift test --package-path CraftUIKit`  
Expected: All tests pass without warnings or errors.

- [ ] **Step 4: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Controls/CraftChoiceCard.swift CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift
git commit -m "docs(CraftChoiceCard): add centered practice card showcase to preview and catalog"
```
