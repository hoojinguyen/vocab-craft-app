# CraftLearningPath Enhancements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a production-grade enhancement suite for `CraftLearningPath` in `CraftUIKit`: Top Floating Sticky HUD builder on section dock, debounced `onNodeImpression` telemetry, and advanced Focus & Accessibility for `CraftLessonDetailSheet`.

**Architecture:** Extend `CraftLearningPath` and its child components (`CraftLessonDetailSheet`, `CraftLessonNode`, `CraftLessonRow`, `CraftLessonSectionView`) using SwiftUI `@AccessibilityFocusState`, cancellable `Task` debounce timers, and top-layer floating overlay HUD with Design Tokens and ViewBuilder ergonomics.

**Tech Stack:** Swift 5.9+, SwiftUI, CraftUIKit design tokens, Swift Testing / XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-28-craft-learning-path-enhancements-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-28-craft-learning-path-enhancements-design.md)

## Global Constraints

- **Design System Tokens**: Mandatory use of `CraftTheme` tokens (`theme.colors`, `theme.typography`, `theme.radii`, `theme.shadows`, `theme.spacing`). Zero hardcoded colors or raw padding.
- **Zero Hardcoded Strings**: All new user-facing copy and a11y labels must be in `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` under `craft.learning_path.*` with 100% EN & VI parity.
- **Strict Quality Gate**: 0 test failures, 0 lint warnings, 0 compiler warnings.

---

### Task 1: Modal Sheet Focus & Accessibility Enhancements (`CraftLessonDetailSheet`)

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonDetailSheet.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `CraftTheme`, `CraftBadge`, `CraftCard`, `CraftButton`
- Produces: Enhanced `CraftLessonDetailSheet` with `@AccessibilityFocusState`, `.accessibilityAction(.escape)`, and semantic combined metric chips.

- [ ] **Step 1: Write failing tests for detail sheet accessibility and actions**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`:
```swift
func testDetailSheetAccessibilityProperties() {
    let node = LessonNodeModel(
        id: "node_detail_a11y",
        title: "Advanced Phrasal Verbs",
        subtitle: "12 words • 3 min",
        iconName: "flame.fill",
        state: .active,
        xpReward: 35,
        estimatedMinutes: 3
    )
    let sheet = CraftLessonDetailSheet(node: node, onStart: { _ in }, onDismiss: { })
    XCTAssertEqual(sheet.node.id, "node_detail_a11y")
    XCTAssertEqual(sheet.formattedXPReward, "+35 XP")
    XCTAssertEqual(sheet.formattedDuration, "3 mins")
}
```

- [ ] **Step 2: Run test to verify it builds and passes/fails appropriately**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests/testDetailSheetAccessibilityProperties`

- [ ] **Step 3: Implement Focus & Accessibility in `CraftLessonDetailSheet.swift`**

1. Add `@AccessibilityFocusState private var isHeaderFocused: Bool`
2. Add `.accessibilityFocused($isHeaderFocused)` and `.accessibilityAddTraits(.isHeader)` to the modal title.
3. Add `.task { try? await Task.sleep(nanoseconds: 100_000_000); isHeaderFocused = true }`
4. Add `.accessibilityAction(.escape) { triggerDismissFeedback(); onDismiss?() }`
5. Wrap each `metricChip` in `.accessibilityElement(children: .combine)` with accessibility label describing title and context.

- [ ] **Step 4: Run test suite to verify tests pass**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests`

- [ ] **Step 5: Commit changes**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonDetailSheet.swift Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings
git commit -m "feat(craftui): enhance CraftLessonDetailSheet with accessibility focus and escape action"
```

---

### Task 2: Advanced Telemetry `onNodeImpression` with Debounce & Threshold

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonNode.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonRow.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `onNodeImpression: (@Sendable (LessonNodeModel) -> Void)?`, `nodeImpressionThreshold: TimeInterval`
- Produces: Visibility impression tracking with task debounce and cancellation on scroll away.

- [ ] **Step 1: Write failing tests for `onNodeImpression` telemetry**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`:
```swift
func testNodeImpressionInitializationAndThresholdDefaults() {
    let node = LessonNodeModel(id: "n_imp", title: "Impression Test")
    let expectation = XCTestExpectation(description: "Node impression triggered")
    
    let lessonNode = CraftLessonNode(
        model: node,
        onNodeImpression: { impressed in
            XCTAssertEqual(impressed.id, "n_imp")
            expectation.fulfill()
        },
        impressionThreshold: 0.1
    )
    XCTAssertEqual(lessonNode.impressionThreshold, 0.1)
}
```

- [ ] **Step 2: Run test to verify it fails compilation / fails test**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests/testNodeImpressionInitializationAndThresholdDefaults`

- [ ] **Step 3: Implement `onNodeImpression` pipeline**

1. In `CraftLessonNode.swift`:
   - Add `public let onNodeImpression: (@Sendable (LessonNodeModel) -> Void)?`
   - Add `public let impressionThreshold: TimeInterval` (default `0.5`)
   - Add `@State private var impressionTask: Task<Void, Never>? = nil`
   - Add `@State private var hasTrackedImpression: Bool = false`
   - In `.onAppear`: if `!hasTrackedImpression`, start Task sleeping `UInt64(impressionThreshold * 1_000_000_000)`, then invoke `onNodeImpression?(model)` and set `hasTrackedImpression = true`.
   - In `.onDisappear`: `impressionTask?.cancel(); impressionTask = nil`.
2. In `CraftLessonRow.swift`:
   - Accept and forward `onNodeImpression` and `impressionThreshold`.
3. In `CraftLessonSectionView.swift`:
   - Accept and forward `onNodeImpression` and `impressionThreshold` in `CraftLessonSectionBodyView` and `CraftLessonSectionView`.
4. In `CraftLearningPath.swift`:
   - Add `public let onNodeImpression: (@Sendable (LessonNodeModel) -> Void)?`
   - Add `public let nodeImpressionThreshold: TimeInterval` (default `0.5`)
   - Pass them to `CraftLessonSectionBodyView`.

- [ ] **Step 4: Run test suite to verify tests pass**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests`

- [ ] **Step 5: Commit changes**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/ Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(craftui): add onNodeImpression debounced telemetry to CraftLearningPath"
```

---

### Task 3: Top Floating Sticky HUD Builder on Section Docking

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonSection`, `headerDockThreshold`, `onDockChange: ((Bool) -> Void)?`
- Produces: `stickyHUDBuilder: (@Sendable (LessonSection) -> AnyView)?`, `@ViewBuilder stickyHUD: ((LessonSection) -> some View)?`, and default floating capsule HUD.

- [ ] **Step 1: Write failing tests for sticky HUD builder**

In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`:
```swift
func testCraftLearningPathStickyHUDBuilderInitialization() {
    let section = LessonSection(
        id: "unit_hud",
        title: "Unit HUD",
        level: "LEVEL 1",
        progressText: "50%",
        progressValue: 0.5,
        nodes: [LessonNodeModel(id: "n1", title: "Node 1")]
    )
    let path = CraftLearningPath(
        sections: [section],
        stickyHUD: { s in
            Text("Custom HUD: \(s.title)")
        }
    )
    XCTAssertNotNil(path.stickyHUDBuilder)
}
```

- [ ] **Step 2: Run test to verify it fails compilation / fails test**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests/testCraftLearningPathStickyHUDBuilderInitialization`

- [ ] **Step 3: Implement Sticky HUD in `CraftLearningPath.swift` & `CraftLessonSectionView.swift`**

1. In `CraftLessonSectionView.swift`:
   - In `CraftLessonSectionHeaderView`, ensure `onDockChange` correctly reports `minY <= dockThreshold`.
2. In `CraftLearningPath.swift`:
   - Add `public let stickyHUDBuilder: (@Sendable (LessonSection) -> AnyView)?`
   - Add `@State private var dockedSection: LessonSection? = nil`
   - In initializers, support `stickyHUDBuilder` and convenience `@ViewBuilder stickyHUD:` initializers.
   - In `scrollableView`: Wire `CraftLessonSectionHeaderView`'s `onDockChange: { isDocked in handleDockChange(section: section, isDocked: isDocked) }`.
   - Add overlay view on top of ScrollView:
     - When `let section = dockedSection`, render:
       - If `stickyHUDBuilder` provided: `stickyHUDBuilder(section)`
       - Else: `defaultStickyHUD(for: section)`
     - Transition: `.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity))`
     - Animation: `.spring(response: 0.35, dampingFraction: 0.8)`
3. Implement `defaultStickyHUD(for: section)`:
   - Floating capsule with `theme.colors.surfaceElevated`, `theme.radii.xl`, `craftShadow(theme.shadows.md)`, hairline stroke border.
   - Leading SF Symbol / bannerIcon, section level pill, title text, and mini progress bar/pill.
4. Add localization string `"craft.learning_path.sticky_hud_progress_format"` in `Localizable.xcstrings` if needed.

- [ ] **Step 4: Run test suite to verify tests pass**

Run: `swift test --package-path Packages/CraftUIKit --filter CraftLearningPathTests`

- [ ] **Step 5: Commit changes**

```bash
git add Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/ Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings Packages/CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(craftui): add floating sticky HUD on section dock to CraftLearningPath"
```

---

### Task 4: Full Quality Gate Verification & Cleanup

**Files:**
- Test: Full `CraftUIKit` test suite & localization tests

- [ ] **Step 1: Run all CraftUIKit unit tests**

Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% PASS

- [ ] **Step 2: Run Localization parity tests**

Run: `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`
Expected: 100% PASS (Zero missing keys, 100% EN/VI match)

- [ ] **Step 3: Run SwiftLint audit**

Run: `swiftlint lint Packages/CraftUIKit`
Expected: 0 errors, 0 warnings

- [ ] **Step 4: Verify Xcode compilation diagnostics**

Check build output for 0 warnings and 0 errors.

- [ ] **Step 5: Commit any final test and cleanup adjustments**

```bash
git commit -am "chore(craftui): complete quality gate verification for CraftLearningPath enhancements"
```
