# CraftLearningPath Sticky HUD & Docking Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate duplicate sticky header collision in `CraftLearningPath`, implement a Liquid Glass floating HUD that appears only when the unit card exits the viewport, and add tap-to-scroll interactivity.

**Architecture:** Refactor `CraftLessonSectionHeaderView` docking geometry from `minY` to `maxY <= dockThreshold` (`dockThreshold = 0`), remove `pinnedViews: [.sectionHeaders]` from `LazyVStack` to let cards scroll naturally, and elevate `defaultStickyHUD` with `.ultraThinMaterial`, border highlights, haptics, and `proxy.scrollTo(section.id)` navigation.

**Tech Stack:** SwiftUI, Swift 6 Concurrency, CraftUIKit design tokens, Liquid Glass, Swift Testing / XCTest.

**Spec:** `docs/superpowers/specs/2026-08-28-craft-learning-path-sticky-hud-refinement-design.md`

## Global Constraints

- Must strictly adhere to `AGENTS.md` and `CraftUIKit` design system tokens (no raw colors, fonts, or padding).
- Zero hardcoded strings: All user-facing text and VoiceOver hints must be localized in `Localizable.xcstrings` with 100% EN & VI parity (`extractionState: "manual"`, `state: "translated"`).
- Strict Quality Gate: 0 errors, 0 warnings in Xcode and SwiftLint, 100% tests passing.

---

### Task 1: Localization Keys for Sticky HUD Tap-to-Scroll Hint

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift`

**Interfaces:**
- Produces: `craft.learning_path.tap_to_scroll_unit_hint` in `CraftUIKit/Localizable.xcstrings`

- [ ] **Step 1: Write the failing localization test**

Add test in `LocalizationTests.swift`:
```swift
func testLearningPathStickyHUDTapToScrollHintLocalization() {
    let key = "craft.learning_path.tap_to_scroll_unit_hint"
    let enValue = CraftLocalized.string(key, locale: Locale(identifier: "en"))
    let viValue = CraftLocalized.string(key, locale: Locale(identifier: "vi"))

    XCTAssertFalse(enValue.isEmpty)
    XCTAssertFalse(viValue.isEmpty)
    XCTAssertEqual(enValue, "Double tap to scroll to the top of this unit")
    XCTAssertEqual(viValue, "Chạm hai lần để cuộn về đầu bài học này")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/CraftUIKit --filter testLearningPathStickyHUDTapToScrollHintLocalization`
Expected: FAIL (key missing or returning raw key)

- [ ] **Step 3: Add localization strings to `Localizable.xcstrings`**

Add JSON entry in `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:
```json
"craft.learning_path.tap_to_scroll_unit_hint": {
  "extractionState": "manual",
  "localizations": {
    "en": {
      "stringUnit": {
        "state": "translated",
        "value": "Double tap to scroll to the top of this unit"
      }
    },
    "vi": {
      "stringUnit": {
        "state": "translated",
        "value": "Chạm hai lần để cuộn về đầu bài học này"
      }
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/CraftUIKit --filter testLearningPathStickyHUDTapToScrollHintLocalization`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings Packages/CraftUIKit/Tests/CraftUIKitTests/LocalizationTests.swift
git commit -m "feat(craftuikit): add localization key for sticky HUD tap to scroll hint"
```

---

### Task 2: Docking Geometry Refinement in `CraftLessonSectionHeaderView`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `CraftLearningPath.scrollCoordinateSpaceName`
- Produces: `CraftLessonSectionHeaderView(section:isPinned:dockThreshold:onDockChange:)` with `dockThreshold` defaulting to `0` and docking triggered by `maxY <= dockThreshold`.

- [ ] **Step 1: Write the failing unit tests for `maxY` docking detection**

Add tests in `CraftLearningPathTests.swift`:
```swift
func testCraftLessonSectionHeaderViewDockThresholdDefaultIsZero() {
    let section = LessonSection(
        id: "unit_dock_zero",
        title: "Dock Unit Zero",
        nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
    )
    let headerView = CraftLessonSectionHeaderView(section: section)
    XCTAssertEqual(headerView.dockThreshold, 0)
}

func testCraftLessonSectionViewDockThresholdDefaultIsZero() {
    let section = LessonSection(
        id: "unit_sec_zero",
        title: "Section Dock Zero",
        nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
    )
    let sectionView = CraftLessonSectionView(section: section)
    XCTAssertEqual(sectionView.dockThreshold, 0)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/CraftUIKit --filter testCraftLessonSectionHeaderViewDockThresholdDefaultIsZero`
Expected: FAIL (returns 15 instead of 0)

- [ ] **Step 3: Update `CraftLessonSectionView.swift` implementation**

In `CraftLessonSectionHeaderView`:
- Change `public init(section: LessonSection, isPinned: Bool = false, dockThreshold: CGFloat = 0, onDockChange: ((Bool) -> Void)? = nil)`
- In `body`: Add `.id(section.id)` on the main header card ZStack/VStack container.
- In `GeometryReader` background:
```swift
GeometryReader { geo in
    let maxY = geo.frame(in: .named(CraftLearningPath.scrollCoordinateSpaceName)).maxY
    Color.clear
        .onChange(of: maxY) { _, newValue in
            let docked = newValue <= dockThreshold
            if isDocked != docked {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isDocked = docked
                }
                onDockChange?(docked)
            }
        }
        .onAppear {
            let docked = maxY <= dockThreshold
            if isDocked != docked {
                isDocked = docked
                onDockChange?(docked)
            }
        }
}
```
In `CraftLessonSectionView`:
- Change `dockThreshold: CGFloat = 0` in initializers.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "refactor(craftuikit): refine CraftLessonSectionHeaderView docking geometry to maxY <= 0"
```

---

### Task 3: Seamless Floating Sticky HUD with Liquid Glass & Tap-to-Scroll in `CraftLearningPath`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `theme.colors`, `theme.radii`, `theme.shadows`, `theme.depths`, `craft.learning_path.tap_to_scroll_unit_hint`
- Produces: `CraftLearningPath` with non-colliding `LazyVStack(pinnedViews: [])` and interactive liquid glass floating HUD.

- [ ] **Step 1: Write unit tests for interactive sticky HUD tap & smooth transition**

Add tests in `CraftLearningPathTests.swift`:
```swift
func testCraftLearningPathDefaultPinSectionHeadersIsFalse() {
    let section = LessonSection(
        id: "unit_pin_default",
        title: "Default Pin Unit",
        nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
    )
    let path = CraftLearningPath(sections: [section])
    XCTAssertFalse(path.pinSectionHeaders)
}

func testCraftLearningPathStickyHUDTapGestureAccessibility() {
    let section = LessonSection(
        id: "unit_tap_hud",
        title: "Tap HUD Unit",
        level: "LEVEL 2",
        progressText: "2/4",
        progressValue: 0.5,
        nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
    )
    let path = CraftLearningPath(sections: [section])
    XCTAssertNotNil(path.body)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `swift test --package-path Packages/CraftUIKit --filter testCraftLearningPathDefaultPinSectionHeadersIsFalse`
Expected: FAIL (was defaulting to `true`)

- [ ] **Step 3: Update `CraftLearningPath.swift` implementation**

1. Change default parameter: `pinSectionHeaders: Bool = false` in all `CraftLearningPath` initializers.
2. In `scrollableView`:
   Remove `pinnedViews: [.sectionHeaders]` from `LazyVStack` when rendering sections, ensuring that section headers render inside the standard scroll body without SwiftUI ghim/pinning duplication:
   ```swift
   LazyVStack(spacing: theme.spacing.xxl, pinnedViews: pinSectionHeaders ? [.sectionHeaders] : []) {
       ForEach(sections) { section in
           Section {
               CraftLessonSectionBodyView(...)
                   .scrollTransition(.animated) { content, phase in
                       content
                           .opacity(isReducedMotion ? 1.0 : (1.0 - abs(phase.value) * 0.25))
                           .scaleEffect(isReducedMotion ? 1.0 : (1.0 - abs(phase.value) * 0.04))
                   }
                   .onAppear { onSectionAppear?(section) }
           } header: {
               if CraftLessonSectionHeaderView(section: section).hasHeaderContent {
                   CraftLessonSectionHeaderView(
                       section: section,
                       onDockChange: { isDocked in
                           handleDockChange(section: section, isDocked: isDocked)
                       }
                   )
                   .id(section.id)
                   .accessibilityAddTraits(.isHeader)
                   .padding(.vertical, theme.spacing.xs)
               }
           }
       }
   }
   ```
3. Update `stickyHUDOverlay` and `defaultStickyHUD(for section: LessonSection, proxy: ScrollViewProxy)`:
   - Render liquid glass material `.background(.ultraThinMaterial)` over `theme.colors.surfaceElevated.opacity(0.85)`.
   - Wrap capsule in a `Button` (or `.onTapGesture`) that executes `withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { proxy.scrollTo(section.id, anchor: .top) }`.
   - Add `.sensoryFeedback(.impact(weight: .light), trigger: isHUDTapped)`.
   - Add `.accessibilityHint(CraftLocalized.string("craft.learning_path.tap_to_scroll_unit_hint"))`.
   - Apply `.animation(.spring(response: 0.35, dampingFraction: 0.8), value: dockedSection?.id)`.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% tests PASS (607+ tests)

- [ ] **Step 5: Commit**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(craftuikit): implement liquid glass floating sticky HUD with tap to scroll in CraftLearningPath"
```

---

### Task 4: Main Application Integration & Verification in `HomepageView`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Test: Full App Test Suite

- [ ] **Step 1: Update `HomepageView.swift`**

Verify `CraftLearningPath` call in `HomepageView.swift`:
```swift
CraftLearningPath(
    sections: viewModel.sections,
    winding: .standard,
    rowPattern: .standard,
    onNodeTap: { node in
        MainActor.assumeIsolated {
            viewModel.handleNodeTap(node)
        }
    },
    onStartLesson: { node in
        MainActor.assumeIsolated {
            startLesson(for: node)
        }
    },
    showDetailModal: true,
    scrollToActive: true,
    showCelebration: false,
    pinSectionHeaders: false
)
```

- [ ] **Step 2: Run full automated verification suite**

Run:
```bash
swift test --package-path Packages/CraftUIKit
rm -rf /tmp/vocab_test.xcresult && xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -resultBundlePath /tmp/vocab_test.xcresult
swiftlint lint --strict
```
Expected: 100% tests pass, 0 compiler warnings, 0 lint violations.

- [ ] **Step 3: Commit**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift
git commit -m "feat(app): configure HomepageView with refined floating sticky HUD learning path"
```
