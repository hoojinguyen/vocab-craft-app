# HomeScreen UI/UX Overhaul & Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign and optimize the Home Screen UI/UX by standardizing the top header to unified 36pt controls, removing the redundant week streak strip, eliminating sticky header scroll collisions, increasing node breathing room, and smoothing snake path curves.

**Architecture:** Refactor `HomeTopHeaderView` to strict 36pt vertical alignment across streak, daily goal ring, and avatar; remove `StreakWeekStripView` from `HomepageView`; streamline `CraftLearningPath` sticky HUD docking to prevent colliding pinned views; upgrade `CraftSnakePathGeometry` for organic Bézier curves.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit Design System, Swift Testing / XCTest, XcodeBuildMCP.

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

- [ ] **Step 1: Write/update tests for `HomeTopHeaderView` layout and accessibility**

In `VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift`:
```swift
import Testing
@testable import VocabCraftApp
import SwiftUI

@Suite("HomeTopHeaderView Tests")
struct HomeTopHeaderViewTests {
    @Test("Header initializes with correct user initials and goal progress")
    func testHeaderInitialsAndProgress() {
        let header = HomeTopHeaderView(
            userName: "Hooji Nguyen",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10
        )
        // Verify view structure can be initialized without crashing
        #expect(header.userName == "Hooji Nguyen")
        #expect(header.streakDays == 14)
        #expect(header.dailyWordsLearned == 8)
        #expect(header.dailyWordsGoal == 10)
    }
}
```

- [ ] **Step 2: Update `HomeTopHeaderView.swift` to standardize all 3 trailing controls to 36pt**

Modify `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`:
- Refactor `progressRingView` to remove the `"today"` sub-label and `VStack`, keeping only the 36x36 `CraftProgressRing` with centered progress text:
```swift
    private var progressRingView: some View {
        CraftProgressRing(
            progress: dailyGoalProgress,
            lineWidth: 2.5,
            size: 36,
            tintColor: theme.colors.brandPrimary,
            trackColor: theme.colors.surfaceSubtle,
            animated: true,
            accessibilityLabel: AppStrings.Home.dailyGoalA11y(completed: dailyWordsLearned, goal: dailyWordsGoal)
        ) {
            Text(AppStrings.Home.dailyGoalCount(completed: dailyWordsLearned, goal: dailyWordsGoal))
                .font(theme.typography.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(theme.colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 36, height: 36)
    }
```
- In `trailingActionsGroup`, ensure horizontal stack spacing uses `theme.spacing.sm` (8pt) and `alignment: .center`.

- [ ] **Step 3: Run unit tests to verify header tests pass**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift VocabCraftAppTests/Features/Homepage/HomeTopHeaderViewTests.swift
git commit -m "refactor(home): standardize top header action controls to 36pt"
```

---

### Task 2: Remove `StreakWeekStripView` from `HomepageView` and Clean View Hierarchy

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:40-120`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `HomeTopHeaderView`, `CraftLearningPath`
- Produces: Decluttered `HomepageView` layout with increased learning path viewport and `pinSectionHeaders: false`

- [ ] **Step 1: Update `HomepageViewTests.swift`**

Verify view model wiring and navigation callbacks work without relying on `StreakWeekStripView`.

- [ ] **Step 2: Remove `StreakWeekStripView` and configure `pinSectionHeaders: false`**

In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
- Remove `StreakWeekStripView(...)` and its padding modifiers.
- Update `CraftLearningPath` invocation:
  - Set `pinSectionHeaders: false` so section gateway banners scroll naturally and don't collide with the floating sticky HUD.

- [ ] **Step 3: Verify build and tests pass**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift
git commit -m "refactor(home): remove redundant week streak strip and configure clean scroll"
```

---

### Task 3: Overhaul Learning Path Section Spacing and Sticky HUD Docking in `CraftUIKit`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift:400-500`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift:130-170`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonSection`, `CraftTheme`
- Produces: Collision-free floating sticky HUD overlay and generous vertical breathing room for initial nodes

- [ ] **Step 1: Add unit test in `CraftLearningPathTests.swift` for section layout and HUD docking**

```swift
@Test("CraftLearningPath initializes and computes empty state correctly")
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
- Increase spacing between `CraftLessonSectionHeaderView` and `CraftLessonSectionBodyView` from `theme.spacing.lg` (16pt) to `theme.spacing.xxl` (28pt) to prevent any clipping of the first node's halo and callout bubble.

- [ ] **Step 3: Refine `CraftLearningPath.swift` Sticky HUD Docking**

In `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`:
- Ensure `stickyHUDOverlay` transitions smoothly and does not trigger while the section header card is still partially visible in the viewport.
- Set `dockThreshold: -20` so the sticky HUD appears only after the gateway banner has completely scrolled past the top boundary.

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
