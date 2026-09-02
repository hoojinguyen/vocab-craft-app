# HomeScreen UI/UX Overhaul & Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign and optimize the Home Screen UI/UX by standardizing the top header to unified 36pt controls, removing the redundant week streak strip, eliminating sticky header scroll collisions, increasing node breathing room, and smoothing snake path curves.

**Architecture:** Refactor `HomeTopHeaderView` to strict 36pt vertical alignment across streak, daily goal ring, and avatar; remove `StreakWeekStripView` from `HomepageView`; streamline `CraftLearningPath` sticky HUD docking to prevent colliding pinned views; upgrade `CraftSnakePathGeometry` for organic Bézier curves.

**Tech Stack:** Swift 5.10, SwiftUI, CraftUIKit Design System, Swift Testing / XCTest, XcodeBuildMCP.

**Spec:** `docs/superpowers/specs/2026-09-02-homescreen-uiux-overhaul-design.md`

## Global Constraints

- Zero Raw Styling: All styling must strictly utilize `CraftUIKit` tokens (`CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`).
- Zero Hardcoded Strings Policy: Display text and accessibility labels must come from `Localizable.xcstrings`.
- 100% Bilingual Parity (EN & VI) on all localization entries.
- Quality Gate: 0 compiler warnings, 0 SwiftLint violations, 100% passing tests.

---

### Task 1: Standardize `HomeTopHeaderView` Action Controls to 36pt

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift:70-135`
- Test: `VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift`

**Interfaces:**
- Consumes: `CraftTheme`, `CraftStreakBadge`, `CraftProgressRing`, `AppStrings.Home`
- Produces: Clean 36pt action bar trailing group with exact vertical baseline alignment

- [ ] **Step 1: Write Unit Test for 36pt layout sizing**

In `VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift`:
```swift
import XCTest
import SwiftUI
@testable import VocabCraftApp
@testable import CraftUIKit

final class HomeTopHeaderViewTests: XCTestCase {
    func testHomeTopHeaderViewInitialization() {
        let view = HomeTopHeaderView(
            userName: "Alex",
            streakDays: 5,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10
        )
        XCTAssertNotNil(view.body)
    }
}
```

- [ ] **Step 2: Update `HomeTopHeaderView.swift`**

In `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`:
- Refactor streak badge to `CraftStreakBadge(size: .sm)`.
- Configure `CraftProgressRing` with 36pt parent frame and `lineWidth: 2.5` to visually harmonize with 36pt circular controls.
- Maintain identical 36pt circular avatar geometry.
- Remove sub-label text "today" beneath progress ring.

- [ ] **Step 3: Run Home tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VocabCraftAppTests/HomeTopHeaderViewTests`
Expected: PASS.

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift
git commit -m "fix(home): balance avatar and progress ring styling to 36pt baseline"
```

---

### Task 2: Remove `StreakWeekStripView` from `HomepageView`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `HomeTopHeaderView`, `CraftLearningPath`
- Produces: Streamlined Homepage layout without redundant streak week row

- [ ] **Step 1: Remove `StreakWeekStripView` from `HomepageView.swift`**

In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
- Remove `StreakWeekStripView` instance above the learning path list.
- Keep `StreakWeekStripView.swift` component available in codebase for detail/profile sheets.

- [ ] **Step 2: Run Homepage tests**

Run: `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VocabCraftAppTests`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift
git commit -m "refactor(home): remove redundant week streak strip from homepage"
```

---

### Task 3: Streamline `CraftLearningPath` Section Spacing & Sticky HUD

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift:380-410`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift:420-520`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `CraftSpacingTokens`, `CraftLessonSectionHeaderView`
- Produces: Collision-free, smooth scrolling learning path with proper node spacing

- [ ] **Step 1: Add/update unit test for non-empty learning path**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`:
```swift
@Test("Learning path non-empty render")
func testLearningPathNonEmpty() {
    let section = LessonSection(
        id: "sec_1",
        title: "Unit 1",
        nodes: [LessonNodeModel(id: "n1", title: "Lesson 1", state: .active)]
    )
    let path = CraftLearningPath(sections: [section], pinSectionHeaders: false)
    #expect(!path.isEmpty)
    #expect(path.activeNodeID == "n1")
}
```

- [ ] **Step 2: Update `CraftLessonSectionView.swift` for node spacing**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift`:
- Set vertical spacing between `CraftLessonSectionHeaderView` and `CraftLessonSectionBodyView` to `theme.spacing.xl` (32pt) to prevent any clipping of the first node's halo and callout bubble.

- [ ] **Step 3: Refine `CraftLearningPath.swift` Sticky HUD Docking**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`:
- Ensure `stickyHUDOverlay` transitions smoothly and triggers cleanly when the section header card scrolls completely past the top boundary, utilizing the `dockedSectionIDs` collection and debounce task.

- [ ] **Step 4: Run CraftUIKit test suite**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS with 100% success rate.

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/
git commit -m "fix(craftuikit): optimize learning path section spacing and sticky HUD docking"
```

---

### Task 4: Upgrade Snake Path Geometry to Organic Bézier Curves

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftSnakePathGeometry.swift:100-185`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `CGPoint`, `SnakePathSegmentGeometry`
- Produces: Smooth tangent fillet arcs with `turnRadius: 40pt` and `edgeInset: 24pt`

- [ ] **Step 1: Write test for `SnakePathGeometry` segment creation**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`:
```swift
@Test("SnakePathGeometry creates smooth hairpin segments with updated radius")
func testSnakePathGeometryHairpin() {
    let from = CGPoint(x: 180, y: 100)
    let to = CGPoint(x: 90, y: 250)
    let segment = SnakePathGeometry.createSegment(from: from, to: to, containerWidth: 360, turnRadius: 40, edgeInset: 24)
    #expect(segment.turnRadius == 40)
    #expect(segment.type == .leftHairpin)
}
```

- [ ] **Step 2: Update `SnakePathGeometry.swift` default constants and fillet math**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftSnakePathGeometry.swift`:
- Update default parameters: `turnRadius: CGFloat = 40.0`, `edgeInset: CGFloat = 24.0`.
- Ensure clean tangent arcs for both left and right hairpin turns.

- [ ] **Step 3: Run CraftUIKit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftSnakePathGeometry.swift
git commit -m "feat(craftuikit): enhance snake path geometry with smooth organic curves"
```

---

### Task 5: End-to-End Build & Simulator Screenshot Verification

**Files:**
- Verification only

- [ ] **Step 1: Run full test suite across app and packages**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% tests passing.

- [ ] **Step 2: Build and run app on iPhone 17 Simulator via XcodeBuildMCP**

Call `build_run_sim` tool.
Expected: Build succeeds with 0 errors and 0 warnings.

- [ ] **Step 3: Capture full-scroll screenshots via Simulator**

Capture:
1. Top screen (showing Large Title "Home", 36pt controls, no week strip, generous space above first node).
2. Middle scroll (showing Unit 1 to Unit 2 transition with clean floating HUD, 0 collisions).
3. Bottom screen (showing final treasure chest comfortably above floating tab bar).

- [ ] **Step 4: Inspect screenshots and confirm visual polish**
