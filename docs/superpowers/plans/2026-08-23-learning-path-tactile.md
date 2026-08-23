# CraftLearningPath Apple Tactile Serpentine Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild `CraftLearningPath` in `CraftUIKit` into an Apple-grade tactile serpentine learning journey featuring 3-layer 3D depress buttons, visible typography labels, active callout bobbing tooltips, smart dynamic connectors, unit portal headers, and an interactive lesson detail sheet.

**Architecture:** 
1. `CraftLearningPathModels`: 1-node continuous sinusoidal serpentine winding (`SerpentineWinding`), enhanced `LessonNodeModel` (subtitles, XP, minutes, stars, kinds), and smart connector state pair resolution.
2. `CraftLessonNode`: 3D tactile extrusion with mechanical press animation, typography subtitle stack, floating `ActiveCalloutBubble`, and haptic feedback.
3. `CraftNodeConnector`: State-pair-driven Bézier curve renderer (`Solid`, `Breathing`, `Dashed`, `Muted`).
4. `CraftLessonRow` & `CraftLessonSectionView`: 1-node horizontal offset positioning and Unit Portal gateway header banner.
5. `CraftLessonDetailSheet`: Dedicated bottom sheet modal with lesson rewards, description, and dynamic CTA buttons.
6. `CraftLearningPath`: Top-level scrollable organism with auto-scroll, detail sheet presentation, and confetti triggers.

**Tech Stack:** Swift 5.9+, SwiftUI (iOS 17+ / macOS 14+ SDK), XCTest.

**Spec:** [`docs/superpowers/specs/2026-08-23-learning-path-tactile-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-08-23-learning-path-tactile-design.md)

---

## Global Constraints

- **Platform**: iOS 17.0+ / macOS 14.0+ (Swift 5.9+).
- **Typography**: System SF Pro (`.rounded`, `.default`, `.serif`) via `CraftTypographyTokens`. No custom font assets.
- **Design Tokens**: Strict adherence to `CraftTheme` (`theme.colors`, `theme.radii`, `theme.shadows`, `theme.spacing`).
- **Touch Target**: Minimum `44×44pt` tap area on all interactive controls.
- **Accessibility**: VoiceOver semantic labels, Dynamic Type scaling, `@Environment(\.accessibilityReduceMotion)` fallbacks for all `PhaseAnimator` loops.

---

### Task 1: Update Data Models & Serpentine Winding Algorithms

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Produces: `LessonNodeKind`, updated `LessonNodeModel`, `SerpentineWinding` (with `offsetRatio(for:)`), updated `LessonSection`, and `SmartConnectorStyle`.

- [ ] **Step 1: Write failing unit tests for new models & SerpentineWinding**

In `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`, add tests for `LessonNodeKind`, `SerpentineWinding`, updated `LessonNodeModel` (with `xpReward`, `subtitle`, `estimatedMinutes`, `stars`), and `LessonSection`.

```swift
func testLessonNodeKindEnum() {
    XCTAssertEqual(LessonNodeKind.allCases, [.standard, .checkpoint, .treasureChest])
}

func testSerpentineWindingOffsetRatios() {
    let standard = SerpentineWinding.standard
    XCTAssertEqual(standard.offsetRatio(for: 0), 0.0, accuracy: 0.01)
    XCTAssertEqual(standard.offsetRatio(for: 1), -0.40, accuracy: 0.01)
    XCTAssertEqual(standard.offsetRatio(for: 2), -0.55, accuracy: 0.01)
    XCTAssertEqual(standard.offsetRatio(for: 3), -0.25, accuracy: 0.01)
    XCTAssertEqual(standard.offsetRatio(for: 4), 0.0, accuracy: 0.01)
    XCTAssertEqual(standard.offsetRatio(for: 5), 0.25, accuracy: 0.01)
    XCTAssertEqual(standard.offsetRatio(for: 6), 0.55, accuracy: 0.01)
    XCTAssertEqual(standard.offsetRatio(for: 7), 0.40, accuracy: 0.01)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftLearningPathTests`
Expected: Compilation failure due to missing types (`LessonNodeKind`, `SerpentineWinding`).

- [ ] **Step 3: Implement updated data models**

In `CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift`, update `LessonNodeKind`, `LessonNodeModel`, `SerpentineWinding`, `SmartConnectorStyle`, and `LessonSection`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Models/CraftLearningPathModels.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(models): add SerpentineWinding and enhanced LessonNodeModel"
```

---

### Task 2: Tactile 3D Lesson Node Atom + Visible Labels + Active Callout Bubble

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPathAnimations.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `LessonNodeState`, `LessonNodeKind`.
- Produces: `CraftLessonNode`, `ActiveCalloutBubble`, `BobbingPhase`.

- [ ] **Step 1: Write failing tests for CraftLessonNode tactile sizing, labels, and callout**

```swift
func testCraftLessonNodeAccessibilityAndLabels() {
    let nodeModel = LessonNodeModel(
        id: "test_act",
        title: "Daily Greetings",
        subtitle: "10 words • 3m",
        iconName: "hand.wave.fill",
        state: .active,
        progress: 0.65,
        xpReward: 25
    )
    let nodeView = CraftLessonNode(model: nodeModel)
    XCTAssertEqual(nodeView.accessibilityLabelText, "Lesson: Daily Greetings, Current lesson. 65% complete. Reward: 25 XP")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftLearningPathTests.testCraftLessonNodeAccessibilityAndLabels`
Expected: FAIL.

- [ ] **Step 3: Implement tactile 3D button mechanism, typography label stack, and ActiveCalloutBubble**

In `CraftLessonNode.swift`:
1. Implement 3D layered background with base bevel extrusion (4pt offset) and top inner highlight.
2. Implement physical button depress using `.buttonStyle(TactileButtonStyle(depth: 4))`.
3. Add `ActiveCalloutBubble` floating above `.active` nodes with bobbing `PhaseAnimator`.
4. Add visible title (`.subheadline.weight(.bold)`) and subtitle (`.caption2`) underneath.

In `CraftLearningPathAnimations.swift`:
Add `BobbingPhase` enum (`.high`, `.low`) and `.craftBobbing` animation token.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonNode.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPathAnimations.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(ui): add 3D tactile button physics, visible labels, and active callout bubble to CraftLessonNode"
```

---

### Task 3: Smart Dynamic Connectors & Smooth Bézier Path

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftNodeConnector.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonNodeState`, `SmartConnectorStyle`.
- Produces: `CraftSmartConnector`, `BreathingConnectorView`, `CraftNodeConnector`.

- [ ] **Step 1: Write failing tests for Smart Connector state pair resolution**

```swift
func testSmartConnectorStyleInference() {
    let completedToCompleted = SmartConnectorStyle.infer(from: .completed, to: .completed)
    XCTAssertEqual(completedToCompleted, .solid)

    let completedToActive = SmartConnectorStyle.infer(from: .completed, to: .active)
    XCTAssertEqual(completedToActive, .breathing)

    let activeToUpcoming = SmartConnectorStyle.infer(from: .active, to: .upcoming)
    XCTAssertEqual(activeToUpcoming, .dashed)

    let upcomingToLocked = SmartConnectorStyle.infer(from: .upcoming, to: .locked)
    XCTAssertEqual(upcomingToLocked, .muted)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftLearningPathTests.testSmartConnectorStyleInference`
Expected: FAIL.

- [ ] **Step 3: Implement Smart Connector inference and Bézier curve rendering**

In `CraftNodeConnector.swift`:
1. Implement `SmartConnectorStyle.infer(from:to:)`.
2. Implement `CraftSmartConnector` which renders `Solid`, `Breathing`, `Dashed`, or `Muted` lines dynamically.
3. Smooth cubic Bézier geometry calculation with horizontal tangents.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftNodeConnector.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(ui): add smart dynamic state-pair connector rendering"
```

---

### Task 4: Serpentine Row Molecule & Unit Portal Gateway Header

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonRow.swift`
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonSectionView.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `SerpentineWinding`, `LessonSection`.
- Produces: `CraftLessonRow` (1-node serpentine offset molecule), `CraftLessonSectionView` (with Unit Portal header).

- [ ] **Step 1: Write failing tests for 1-node serpentine row and portal header**

```swift
func testCraftLessonRowOffsetCalculation() {
    let node = LessonNodeModel(id: "n1", title: "Intro", state: .completed)
    let row = CraftLessonRow(node: node, offsetRatio: -0.4)
    XCTAssertEqual(row.node.id, "n1")
    XCTAssertEqual(row.offsetRatio, -0.4, accuracy: 0.01)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftLearningPathTests.testCraftLessonRowOffsetCalculation`
Expected: FAIL.

- [ ] **Step 3: Implement 1-node offset row and Unit Portal Header banner**

In `CraftLessonRow.swift`:
1. Lay out single node with horizontal offset calculated from `offsetRatio` relative to parent container width.
2. Emit node center anchor via `NodeAnchorPreferenceKey`.

In `CraftLessonSectionView.swift`:
1. Build Unit Portal Header with category watermark icon, level capsule badge, title/subtitle, and mini progress bar.
2. Render vertical stack of `CraftLessonRow`s with winding offsets.
3. Overlay `CraftSmartConnector`s connecting consecutive nodes behind the 3D buttons.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonRow.swift CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonSectionView.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(ui): add 1-node serpentine offset rows and Unit Portal Header"
```

---

### Task 5: Interactive Lesson Detail Sheet Component

**Files:**
- Create: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonDetailSheet.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `CraftTheme`.
- Produces: `CraftLessonDetailSheet`.

- [ ] **Step 1: Write failing tests for CraftLessonDetailSheet CTA resolution**

```swift
func testLessonDetailSheetCTAActionTitle() {
    let activeNode = LessonNodeModel(id: "act", title: "Travel", state: .active)
    let sheetActive = CraftLessonDetailSheet(node: activeNode, onStart: { _ in })
    XCTAssertEqual(sheetActive.ctaTitle, "BẮT ĐẦU HỌC")

    let completedNode = LessonNodeModel(id: "comp", title: "Basics", state: .completed)
    let sheetComp = CraftLessonDetailSheet(node: completedNode, onStart: { _ in })
    XCTAssertEqual(sheetComp.ctaTitle, "ÔN TẬP LẠI (+5 XP)")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftLearningPathTests.testLessonDetailSheetCTAActionTitle`
Expected: FAIL.

- [ ] **Step 3: Implement CraftLessonDetailSheet**

In `CraftLessonDetailSheet.swift`:
1. Large 3D tactile icon hero + title + status pill.
2. Metrics chips (`+20 XP`, `⏱ 4 phút`, `15 từ mới`).
3. Objectives description.
4. Dynamic `CraftButton` for primary action (`BẮT ĐẦU HỌC`, `TIẾP TỤC`, `ÔN TẬP`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLessonDetailSheet.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(ui): create CraftLessonDetailSheet modal with dynamic action CTA"
```

---

### Task 6: Root Container Integration, Sheet Wiring & Auto-Scroll

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPath.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: `CraftLessonSectionView`, `CraftLessonDetailSheet`, `LessonSection`.
- Produces: `CraftLearningPath` (with `showDetailModal`, `onStartLesson`, `scrollToActive`).

- [ ] **Step 1: Write failing integration tests for CraftLearningPath**

```swift
func testCraftLearningPathSheetPresentationAndAutoScroll() {
    let node1 = LessonNodeModel(id: "n1", title: "A", state: .completed)
    let node2 = LessonNodeModel(id: "n2", title: "B", state: .active)
    let section = LessonSection(id: "s1", title: "Unit 1", nodes: [node1, node2])
    let path = CraftLearningPath(sections: [section], showDetailModal: true)
    XCTAssertEqual(path.activeNodeID, "n2")
    XCTAssertTrue(path.showDetailModal)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter CraftLearningPathTests.testCraftLearningPathSheetPresentationAndAutoScroll`
Expected: FAIL.

- [ ] **Step 3: Implement CraftLearningPath integration**

In `CraftLearningPath.swift`:
1. Connect `selectedNodeForDetail: LessonNodeModel?` state to `.sheet(item:)` presenting `CraftLessonDetailSheet`.
2. Support `onStartLesson: ((LessonNodeModel) -> Void)?` callback.
3. Keep smooth `ScrollViewReader` auto-scroll to active node with 300ms layout stabilization.
4. Integrate `craftConfetti` on milestone completion.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter CraftLearningPathTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Components/Containers/CraftLearningPath.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(ui): integrate detail sheet presentation and full serpentine path in CraftLearningPath"
```

---

### Task 7: Update Interactive Catalog Showcase & Full Test Suite Verification

**Files:**
- Modify: `CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Modify: `CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift`

**Interfaces:**
- Consumes: Complete `CraftLearningPath` component system.

- [ ] **Step 1: Update Catalog showcase view**

In `CraftCatalogView.swift`:
1. Update `CatalogLearningPathSection` to showcase `SerpentineWinding` presets (`.standard`, `.gentle`, `.linear`).
2. Update mock data with realistic titles, subtitles, XP rewards, kinds (`.standard`, `.checkpoint`, `.treasureChest`), and star ratings.
3. Wire up node inspector with state changer, 3D button tester, and detail sheet trigger.

- [ ] **Step 2: Run full unit test suite**

Run: `swift test`
Expected: All tests PASS with 0 failures.

- [ ] **Step 3: Commit**

```bash
git add CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift CraftUIKit/Tests/CraftUIKitTests/CraftLearningPathTests.swift
git commit -m "feat(catalog): update CraftCatalogView with tactile learning path showcase"
```

---

## Verification Plan

### Automated Tests
- Run full test suite: `swift test`
- Specific test targets: `CraftLearningPathTests` covering:
  - `testLessonNodeKindEnum`
  - `testSerpentineWindingOffsetRatios`
  - `testSmartConnectorStyleInference`
  - `testCraftLessonNodeAccessibilityAndLabels`
  - `testCraftLessonRowOffsetCalculation`
  - `testLessonDetailSheetCTAActionTitle`
  - `testCraftLearningPathFullIntegration`

### Manual Verification
1. Inspect `CraftCatalogView` in Xcode Previews:
   - Verify 3D button physical depress animation and top inner highlight.
   - Verify active callout bobbing bubble on active node.
   - Verify smooth S-curve connectors connecting offset nodes without clipping.
   - Verify tapping a node opens `CraftLessonDetailSheet` with correct XP and CTA.
   - Verify dark mode adaptation across all 6 states.
