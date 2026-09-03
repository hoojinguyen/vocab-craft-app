# `CraftFluidJourney` Visual Refinements & Surface Style Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `CraftFluidJourney` to adopt uniform 88x88pt continuous squircle nodes, preserve distinct lesson icons without generic padlock overrides, support all 5 `CraftSurfaceStyle` variants customizable via `CraftTheme`, and eliminate redundant "Unit 1" milestone pill duplication.

**Architecture:** Expand `CraftTheme` protocol with `journeySurfaceStyle: CraftSurfaceStyle` token across preset themes; refactor `CraftJourneyNode` to render continuous squircle geometry (`RoundedRectangle(cornerRadius: 30 * baseScale, style: .continuous)`) with cascading surface style resolution and distinct lesson icons; adjust `CraftFluidJourney` and `CraftMilestonePill` hierarchy so the pinned header acts as Deck portal while in-scroll pills indicate sub-topics.

**Tech Stack:** Swift 5.10, SwiftUI, CraftUIKit Design System, XCTest / Swift Testing.

**Spec:** `docs/superpowers/specs/2026-09-03-craft-fluid-journey-refinement-design.md`

## Global Constraints

- Zero Raw Styling: All colors, typography, paddings, corner radii, and elevations must strictly use `CraftUIKit` tokens (`CraftTheme`, `CraftColorTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`, `CraftSurfaceStyle`).
- Zero Hardcoded Strings Policy: Display text and accessibility labels must come from `Localizable.xcstrings` via `CraftLocalized.string` / `format` (Layer 1) or `LocalizedStringKey` / `String(localized:)` (Layer 2).
- 100% Bilingual Parity (EN & VI) on all localization entries.
- Quality Gate: 0 compiler warnings, 0 SwiftLint violations, 100% passing tests.

---

### Task 1: Expand `CraftTheme` Protocol & Configure Preset Themes for `journeySurfaceStyle`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift:7-29`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftTactileClayTheme.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftAIAcousticTheme.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftNordicZenTheme.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftOxfordHeritageTheme.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftNeoArcadeTheme.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/Themes/CraftDefaultTheme.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle` (`.elevated`, `.flat`, `.outlined`, `.tactile3D`, `.glass`)
- Produces: `CraftTheme.journeySurfaceStyle: CraftSurfaceStyle` token with default `.elevated` fallback in extension

- [ ] **Step 1: Write Unit Test for `journeySurfaceStyle` Theme Tokens**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift`, add:
```swift
func testThemeJourneySurfaceStyleDefaultsAndOverrides() {
    let defaultTheme = CraftDefaultTheme()
    XCTAssertEqual(defaultTheme.journeySurfaceStyle, .elevated)

    let tactileClayTheme = CraftTactileClayTheme()
    XCTAssertEqual(tactileClayTheme.journeySurfaceStyle, .tactile3D)

    let aiAcousticTheme = CraftAIAcousticTheme()
    XCTAssertEqual(aiAcousticTheme.journeySurfaceStyle, .glass)

    let nordicZenTheme = CraftNordicZenTheme()
    XCTAssertEqual(nordicZenTheme.journeySurfaceStyle, .flat)

    let oxfordTheme = CraftOxfordHeritageTheme()
    XCTAssertEqual(oxfordTheme.journeySurfaceStyle, .outlined)

    let neoArcadeTheme = CraftNeoArcadeTheme()
    XCTAssertEqual(neoArcadeTheme.journeySurfaceStyle, .tactile3D)
}
```

- [ ] **Step 2: Run test to verify it fails to compile**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: Compilation failure due to missing `journeySurfaceStyle` property on `CraftTheme`.

- [ ] **Step 3: Update `CraftTheme.swift` and Preset Themes**

In `Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`:
```swift
public protocol CraftTheme: Sendable {
    var colors: CraftColorTokens { get }
    var typography: CraftTypographyTokens { get }
    var spacing: CraftSpacingTokens { get }
    var radii: CraftRadiusTokens { get }
    var shadows: CraftShadowTokens { get }
    var gradients: CraftGradientTokens { get }
    var animations: CraftAnimationTokens { get }
    var opacities: CraftOpacityTokens { get }
    var depths: CraftDepthTokens { get }
    var glass: CraftGlassTokens { get }
    var journeySurfaceStyle: CraftSurfaceStyle { get }
}

public extension CraftTheme {
    var depths: CraftDepthTokens {
        CraftDefaultDepthTokens()
    }

    var glass: CraftGlassTokens {
        CraftDefaultGlassTokens()
    }

    var journeySurfaceStyle: CraftSurfaceStyle {
        .elevated
    }
}
```

In `CraftTactileClayTheme.swift`:
```swift
public var journeySurfaceStyle: CraftSurfaceStyle { .tactile3D }
```

In `CraftNeoArcadeTheme.swift`:
```swift
public var journeySurfaceStyle: CraftSurfaceStyle { .tactile3D }
```

In `CraftAIAcousticTheme.swift`:
```swift
public var journeySurfaceStyle: CraftSurfaceStyle { .glass }
```

In `CraftNordicZenTheme.swift`:
```swift
public var journeySurfaceStyle: CraftSurfaceStyle { .flat }
```

In `CraftOxfordHeritageTheme.swift`:
```swift
public var journeySurfaceStyle: CraftSurfaceStyle { .outlined }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter ThemeTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Tokens/ Packages/CraftUIKit/Tests/CraftUIKitTests/ThemeTests.swift
git commit -m "feat(CraftUIKit): add journeySurfaceStyle token to CraftTheme and configure presets"
```

---

### Task 2: Refactor `CraftJourneyNode` to 88pt Uniform Squircle, 5 Surface Styles, and Topic Icons

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `CraftSurfaceStyle`, `CraftTheme.journeySurfaceStyle`, `@Environment(\.craftSurfaceStyle)`
- Produces: 88x88pt continuous squircle node (`RoundedRectangle(cornerRadius: 30 * baseScale, style: .continuous)`) rendering:
  - 5 surface styles: `elevated`, `flat`, `outlined`, `tactile3D`, `glass`
  - Preserved lesson icons on locked nodes (`node.iconName`, muted tone, no `lock.fill` replacement)
  - Breathing glow aura on active node without mechanical scale ballooning
  - Bottom-right green checkmark badge (`✓`) on completed node

- [ ] **Step 1: Write Unit Tests for `CraftJourneyNode` Refinements**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`, add:
```swift
func testCraftJourneyNodeUniformSizingAcrossStates() {
    let completed = CraftJourneyNode.diameter(for: .completed)
    let active = CraftJourneyNode.diameter(for: .active)
    let inProgress = CraftJourneyNode.diameter(for: .inProgress)
    let locked = CraftJourneyNode.diameter(for: .locked)
    let upcoming = CraftJourneyNode.diameter(for: .upcoming)

    XCTAssertEqual(completed, 88, "Completed node must be 88pt")
    XCTAssertEqual(active, 88, "Active node base diameter must be 88pt, matching other nodes")
    XCTAssertEqual(inProgress, 88, "InProgress node must be 88pt")
    XCTAssertEqual(locked, 88, "Locked node must be 88pt")
    XCTAssertEqual(upcoming, 88, "Upcoming node must be 88pt")
}

func testCraftJourneyNodePreservesLessonIconWhenLocked() {
    let node = LessonNodeModel(
        id: "lesson_1",
        title: "Vocabulary Basics",
        iconName: "bubble.left.and.bubble.right.fill",
        state: .locked
    )
    let journeyNode = CraftJourneyNode(node: node)
    XCTAssertEqual(journeyNode.displayedIconName, "bubble.left.and.bubble.right.fill", "Locked node must preserve original lesson icon instead of lock.fill")
}

func testCraftJourneyNodeSurfaceStyleResolution() {
    let node = LessonNodeModel(id: "n1", title: "Test", iconName: "book.fill", state: .active)
    let explicitNode = CraftJourneyNode(node: node, surfaceStyle: .glass)
    XCTAssertEqual(explicitNode.surfaceStyle, .glass)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftFluidJourneyTests`
Expected: FAIL due to previous 82/68/60 sizing, `lock.fill` override, and missing `surfaceStyle` property.

- [ ] **Step 3: Refactor `CraftJourneyNode.swift`**

Update `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift`:
1. Sizing:
   ```swift
   public static func diameter(for state: LessonNodeState) -> CGFloat {
       88
   }
   ```
2. Icon preservation:
   ```swift
   var displayedIconName: String {
       node.iconName.isEmpty ? "book.fill" : node.iconName
   }
   ```
3. Surface style resolution property:
   ```swift
   public let surfaceStyle: CraftSurfaceStyle?
   @Environment(\.craftSurfaceStyle) private var environmentSurfaceStyle

   var effectiveSurfaceStyle: CraftSurfaceStyle {
       if let surfaceStyle {
           return surfaceStyle
       }
       if environmentSurfaceStyle != .flat {
           return environmentSurfaceStyle
       }
       return theme.journeySurfaceStyle
   }
   ```
4. Squircle shape body with all 5 styles:
   - Geometry: `RoundedRectangle(cornerRadius: 30 * baseScale, style: .continuous)`
   - Implement `faceBackgroundView` supporting `.elevated`, `.flat`, `.outlined`, `.tactile3D`, `.glass`
   - Active breathing glow aura without scale ballooning
   - Completed badge: bottom-right green circle with white checkmark
   - Inactive/Locked: Muted icon (`theme.colors.textMuted.opacity(0.7)`), subtle surface fill, disabled tap

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftFluidJourneyTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift
git commit -m "feat(CraftUIKit): standardize CraftJourneyNode to 88pt squircle with 5 surface styles and icon preservation"
```

---

### Task 3: Refactor Milestone Stacking & Docking in `CraftFluidJourney` and `CraftMilestonePill`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftMilestonePill.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`

**Interfaces:**
- Consumes: `LessonSection`, `CraftTheme.journeySurfaceStyle`
- Produces:
  - `CraftMilestonePill` adapting to surface styles
  - `CraftFluidJourney` with clean clearance height and milestone positioning so the top pinned card acts as Deck portal without duplicate "Unit 1" milestone pill stacking

- [ ] **Step 1: Write Unit Test for Milestone Pill and Docking Hierarchy**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`, add:
```swift
func testMilestonePillInitializationAndProperties() {
    let pill = CraftMilestonePill(sectionId: "s1", title: "Present Simple for Personal Facts")
    XCTAssertEqual(pill.sectionId, "s1")
    XCTAssertEqual(pill.title, "Present Simple for Personal Facts")
    XCTAssertEqual(pill.accessibilityLabelText, "Present Simple for Personal Facts")
}

func testFluidJourneyDockingResolvesDeckAndSubtopic() {
    let s1 = LessonSection(id: "s1", title: "Present Simple", subtitle: "Basics", level: "A2", nodes: [])
    let s2 = LessonSection(id: "s2", title: "Reading Bios", subtitle: "Intermediate", level: "A2", nodes: [])
    let journey = CraftFluidJourney(sections: [s1, s2], deckTitle: "Personal Details Vocabulary")

    XCTAssertEqual(journey.resolvedDeckTitle, "Personal Details Vocabulary")
}
```

- [ ] **Step 2: Run test to verify it compiles and passes**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftFluidJourneyTests`
Expected: PASS.

- [ ] **Step 3: Update `CraftMilestonePill.swift` and `CraftFluidJourney.swift`**

In `CraftMilestonePill.swift`:
- Adapt surface background based on `theme.journeySurfaceStyle` (glass, elevated, tactile3D, flat, outlined).
- Ensure styling uses design system tokens.

In `CraftFluidJourney.swift`:
- Ensure `CraftPinnedUnitHeader` receives the overall deck/level context.
- Ensure `sectionBlock(section:)` renders sub-topic milestone pills cleanly with proper spacing and geometry tracking.

- [ ] **Step 4: Run full `CraftUIKit` test suite**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% tests passing.

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/ Packages/CraftUIKit/Tests/CraftUIKitTests/
git commit -m "fix(CraftUIKit): refine milestone pill surface styling and clearance geometry in CraftFluidJourney"
```

---

### Task 4: Integrate and Verify in `VocabCraftApp` Homepage

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift` (or `HomepageViewModel.swift`)
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `CraftFluidJourney`, `HomepageViewModel.sections`, `AppContainer`
- Produces: Clean Homepage presentation where pinned header displays Deck title + Level, while journey milestones display sub-topic names without duplicating "Unit 1"

- [ ] **Step 1: Check Data Mapper and ViewModel sub-topic milestone labeling**

In `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift`:
- Verify that `LessonSection.title` is assigned the specific sub-topic title (e.g. `Present Simple for Personal Facts`) rather than generic "Unit 1" repeated over and over.

- [ ] **Step 2: Update `HomepageView.swift`**

In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
- Ensure `CraftFluidJourney` is provided `deckTitle: viewModel.currentDeckTitle` (or active topic title) and `deckSubtitle: viewModel.currentDeckSubtitle`.

- [ ] **Step 3: Run app unit tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VocabCraftAppTests`
Expected: PASS.

- [ ] **Step 4: SwiftLint and Warnings Quality Gate**

Run: `swiftlint --strict`
Expected: 0 errors, 0 warnings.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/Homepage/ VocabCraftAppTests/Features/Homepage/
git commit -m "feat(home): map sub-topic milestone titles and integrate refined CraftFluidJourney"
```

---

### Task 5: Interactive Verification on Device / Simulator & Walkthrough

**Files:**
- Output: `walkthrough.md`

- [ ] **Step 1: Build & Launch on iOS Simulator or Device**
- [ ] **Step 2: Capture Screenshots across Scroll Range (Top, Active Node, Inactive Nodes, Completed Nodes)**
- [ ] **Step 3: Verify 0 Compiler Warnings and 0 Lints**
- [ ] **Step 4: Create Walkthrough Documentation**
