# Craft Fluid Journey Tactile 3D Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign CraftFluidJourney to feature 88pt tactile 3D lesson nodes, a centered opening node, floating speech bubble callouts, semantic icon preservation with corner checkmark badges, deck-level milestone pills and headers, safe fullScreenCover lesson launching, and an interactive CraftCatalogView preview.

**Architecture:** Refine CraftUIKit fluid journey components (`CraftJourneyNode`, `FluidJourneyNodeOffset`, `CraftFluidJourney`, `CraftPinnedUnitHeader`, `CraftMilestonePill`), update `LearningPathDataMapper` to map decks to sections and stages to nodes without "Unit" or "Chặng" prefix clutter, fix sheet dismissal race condition in `CraftFluidJourney` via native `.sheet(..., onDismiss:)` lifecycle hook, and enrich `CraftCatalogView` with a full-featured showcase.

**Tech Stack:** Swift 6, SwiftUI, CraftUIKit design tokens, Swift Testing framework, XCTest.

**Spec:** `docs/superpowers/specs/2026-09-03-craft-fluid-journey-tactile-redesign.md`

## Global Constraints
- Zero raw colors, typography, or hardcoded paddings (must use CraftUIKit tokens: `CraftColorTokens`, `CraftTypographyTokens`, `CraftDepthTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`).
- Zero hardcoded user-visible strings (must use `Localizable.xcstrings` via `CraftLocalized` in CraftUIKit and `String(localized:)` in VocabCraftApp).
- Mandatory bilingual parity (en & vi) with exact specifier parity.
- 0 compiler warnings, 0 lint warnings, 100% test pass rate.

---

### Task 1: S-Curve Geometry & Offset Re-centering (`FluidJourneyNodeOffset`)

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourneyModels.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`

**Interfaces:**
- Consumes: `FluidJourneyNodeOffset.offset(for: Int) -> CGFloat`
- Produces: Sequence `[0, -48, 0, 48]` guaranteeing index 0 is `0.0pt`.

- [ ] **Step 1: Write the failing test for centered index 0 offset**
In `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`:
```swift
func testFluidJourneyNodeOffsetSequenceStartsAtCenter() {
    XCTAssertEqual(FluidJourneyNodeOffset.offset(for: 0), 0.0)
    XCTAssertEqual(FluidJourneyNodeOffset.offset(for: 1), -48.0)
    XCTAssertEqual(FluidJourneyNodeOffset.offset(for: 2), 0.0)
    XCTAssertEqual(FluidJourneyNodeOffset.offset(for: 3), 48.0)
    XCTAssertEqual(FluidJourneyNodeOffset.offset(for: 4), 0.0)
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter testFluidJourneyNodeOffsetSequenceStartsAtCenter` in `Packages/CraftUIKit`
Expected: FAIL (was returning `-45.0` for index 0).

- [ ] **Step 3: Update `FluidJourneyNodeOffset.sequence`**
In `CraftFluidJourneyModels.swift`:
```swift
public enum FluidJourneyNodeOffset {
    private static let sequence: [CGFloat] = [0, -48, 0, 48]

    public static func offset(for index: Int) -> CGFloat {
        let pos = max(0, index)
        return sequence[pos % sequence.count]
    }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `swift test --filter testFluidJourneyNodeOffsetSequenceStartsAtCenter`
Expected: PASS.

- [ ] **Step 5: Commit changes**
`git commit -am "feat(CraftUIKit): center opening node in FluidJourneyNodeOffset sequence"`

---

### Task 2: 88pt Node Sizing, Semantic Icon Preservation & Corner Badge (`CraftJourneyNode`)

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftJourneyNodeTests.swift`

**Interfaces:**
- Consumes: `LessonNodeModel`, `CraftSurfaceStyle`, `CraftTheme`
- Produces: `CraftJourneyNode.diameter = 88pt`, `iconSize = 34pt`, `completedCheckmarkBadge` (26pt green circle + white checkmark at `.bottomTrailing`), semantic icon preservation across all states, removal of clipping sub-tag.

- [ ] **Step 1: Write the failing tests for 88pt diameter and semantic icon preservation**
In `CraftJourneyNodeTests.swift`:
```swift
func testCraftJourneyNodeDiameterIs88pt() {
    XCTAssertEqual(CraftJourneyNode.diameter(for: .active), 88)
    XCTAssertEqual(CraftJourneyNode.diameter(for: .completed), 88)
    XCTAssertEqual(CraftJourneyNode.diameter(for: .locked), 88)
}

func testCraftJourneyNodePreservesSemanticIconAcrossStates() {
    let node = LessonNodeModel(id: "n1", title: "Empathy", iconName: "heart", state: .completed)
    let view = CraftJourneyNode(node: node)
    XCTAssertEqual(view.displayedIconName, "heart")
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter testCraftJourneyNodeDiameterIs88pt`
Expected: FAIL (was 72pt).

- [ ] **Step 3: Update `CraftJourneyNode` implementation**
- Change `diameter(for:)` to return `88`.
- Change `iconSize` to return `34` for active/inProgress, `32` for completed/locked.
- Update `squircleShape` to `RoundedRectangle(cornerRadius: 30 * baseScale, style: .continuous)`.
- Update `activeGlowBackground` to use `haloSize = currentDiameter + 24` (112pt) with corner radius `38 * baseScale`.
- In `tactile3DFace`: Set bottom rim extrusion layer offset to `theme.depths.depthMd` (5pt) with `theme.depths.topHighlight` hairline border.
- In `completedCheckmarkBadge`: Size to 26x26pt, green background (`#22C55E` / `statusSuccess`), white bold checkmark, 2.5pt border matching canvas background.
- Remove `activeStartTag` from `CraftJourneyNode` (it will be rendered as `ActiveCalloutBubble` above the node).

- [ ] **Step 4: Run tests to verify they pass**
Run: `swift test --filter CraftJourneyNodeTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**
`git commit -am "feat(CraftUIKit): standardize CraftJourneyNode to 88pt with semantic icon preservation and corner checkmark badge"`

---

### Task 3: Floating Speech Bubble (`ActiveCalloutBubble`) & Clearance in `CraftFluidJourney`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFluidJourneyTests.swift`

**Interfaces:**
- Consumes: `ActiveCalloutBubble`, `CraftJourneyNode`
- Produces: `ActiveCalloutBubble` positioned floating above active nodes with 8pt clearance and bobbing motion.

- [ ] **Step 1: Write test for active callout bubble presence in fluid journey**
In `CraftFluidJourneyTests.swift`:
Test that when a node is `.active`, `CraftFluidJourney` attaches `ActiveCalloutBubble` above it.

- [ ] **Step 2: Run test to verify current behavior**
Run: `swift test --filter CraftFluidJourneyTests`

- [ ] **Step 3: Update `sectionBlock` in `CraftFluidJourney.swift`**
In `CraftFluidJourney.swift`:
```swift
ForEach(section.nodes) { node in
    VStack(spacing: 8) {
        if node.state == .active {
            ActiveCalloutBubble(
                text: CraftLocalized.string("craft.fluid_journey.start_lesson")
            )
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
        }

        CraftJourneyNode(
            node: node,
            surfaceStyle: surfaceStyle,
            onTap: {
                handleNodeTap(node)
            }
        )
    }
    .offset(x: offset(for: node.id))
    .id(node.id)
}
```

- [ ] **Step 4: Run tests to verify they pass**
Run: `swift test --filter CraftFluidJourneyTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**
`git commit -am "feat(CraftUIKit): position ActiveCalloutBubble above active node in CraftFluidJourney"`

---

### Task 4: Tactile 3D Styling for `CraftPinnedUnitHeader` & `CraftMilestonePill`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftPinnedUnitHeader.swift`
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftMilestonePill.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftPinnedUnitHeaderTests.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftMilestonePillTests.swift`

**Interfaces:**
- Consumes: `CraftSurfaceStyle`, `CraftDepthTokens`
- Produces: `.tactile3D` surface style support with bottom bevel rim extrusion and tactile press feedback for both components.

- [ ] **Step 1: Write tests for `.tactile3D` support in `CraftPinnedUnitHeader` and `CraftMilestonePill`**
In `CraftPinnedUnitHeaderTests.swift`:
```swift
func testPinnedUnitHeaderSupportsTactile3D() {
    let header = CraftPinnedUnitHeader(section: testSection, surfaceStyle: .tactile3D)
    XCTAssertEqual(header.effectiveSurfaceStyle, .tactile3D)
}
```
In `CraftMilestonePillTests.swift`:
```swift
func testMilestonePillSupportsTactile3D() {
    let pill = CraftMilestonePill(sectionId: "s1", title: "Topic", surfaceStyle: .tactile3D)
    XCTAssertEqual(pill.effectiveSurfaceStyle, .tactile3D)
}
```

- [ ] **Step 2: Run tests to verify failure**
Run: `swift test --filter PinnedUnitHeader` and `swift test --filter MilestonePill`

- [ ] **Step 3: Implement `.tactile3D` in `CraftPinnedUnitHeader` & `CraftMilestonePill`**
- `CraftPinnedUnitHeader`:
  - Add `public let surfaceStyle: CraftSurfaceStyle?`.
  - In `cardBody`: When `effectiveSurfaceStyle == .tactile3D`:
    - Add bottom bevel extrusion rim (`offset(y: 4)`).
    - Top face with `theme.colors.surfaceCard` and `theme.depths.topHighlight` border.
    - Button style with tactile press translation `TactileButtonStyle(depth: 4)`.
- `CraftMilestonePill`:
  - In `pillBackground`: When `effectiveSurfaceStyle == .tactile3D`:
    - Capsule filled with `theme.colors.surfaceCard`.
    - Bottom rim extrusion bevel 2.5pt (`theme.depths.depthSm`).
    - Top highlight stroke.

- [ ] **Step 4: Run tests to verify they pass**
Run: `swift test --filter PinnedUnitHeader` and `swift test --filter MilestonePill`
Expected: PASS.

- [ ] **Step 5: Commit changes**
`git commit -am "feat(CraftUIKit): add tactile 3D surface style to CraftPinnedUnitHeader and CraftMilestonePill"`

---

### Task 5: Curriculum Hierarchy, Dropping "Unit" / "Chặng" & Deck Milestone Pills

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/LearningPathDataMapper.swift`
- Test: `VocabCraftAppTests/Features/Homepage/LearningPathDataMapperTests.swift`

**Interfaces:**
- Consumes: `TopicDeckDTO`, `SubTopicStageDTO`
- Produces: `section.title = deck.title` (clean deck title, no "Unit X:"), `milestoneTitle(for: section) = section.title` (Deck title for pills, never first node title), suppress milestone pill on first section.

- [ ] **Step 1: Write test for clean deck mapping without "Unit" prefix**
In `LearningPathDataMapperTests.swift`:
```swift
func testLearningPathDataMapperUsesCleanDeckTitlesWithoutUnitPrefix() {
    let sections = LearningPathDataMapper.map(decks: sampleDecks, stages: sampleStages, words: sampleWords, progressList: [])
    XCTAssertEqual(sections.first?.title, "Giao Tiếp Hằng Ngày")
    XCTAssertFalse(sections.first?.title.contains("Unit") ?? true)
}
```

- [ ] **Step 2: Run test to verify failure**
Run: `xcodebuild test` or swift test.

- [ ] **Step 3: Update `LearningPathDataMapper` and `CraftFluidJourney`**
- In `LearningPathDataMapper.swift`:
  - Change `buildSection`: `title: deck.title` (remove `AppStrings.Home.unitTitle(...)`).
  - Strip `"Chặng %lld: "` prefix from stage titles if needed or display clean titles.
- In `CraftFluidJourney.swift`:
  - Change `milestoneTitle(for section: LessonSection)` to return `section.title` directly!
  - In `journeyContentView`: Only render `CraftMilestonePill` for `section` if `section.id != sections.first?.id` (do not render redundant pill before the very first node of the initial deck).

- [ ] **Step 4: Run tests to verify they pass**
Run: `swift test --filter LearningPathDataMapperTests`
Expected: PASS.

- [ ] **Step 5: Commit changes**
`git commit -am "fix(home): map deck titles cleanly to sections and milestone pills without Unit prefix"`

---

### Task 6: Safe Lesson Launch Transition via `.sheet(onDismiss:)`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- Consumes: `selectedNodeForDetail`, `onStartLesson`
- Produces: Sequential sheet dismissal followed by `fullScreenCover` presentation with zero UIKit presentation collision.

- [ ] **Step 1: Write test for safe sequential lesson launch in `CraftFluidJourney`**
In `CraftFluidJourneyTests.swift`:
Test that when `onStart` is tapped in detail sheet, `onStartLesson` is only invoked after sheet dismissal.

- [ ] **Step 2: Implement `pendingLessonToStart` in `CraftFluidJourney.swift`**
In `CraftFluidJourney.swift`:
```swift
@State private var pendingLessonToStart: LessonNodeModel?

// In lessonDetailSheet:
CraftLessonDetailSheet(
    node: node,
    onStart: { started in
        pendingLessonToStart = started
        selectedNodeForDetail = nil
    },
    onDismiss: {
        selectedNodeForDetail = nil
    }
)

// In .sheet modifier:
.sheet(item: $selectedNodeForDetail, onDismiss: {
    if let node = pendingLessonToStart {
        pendingLessonToStart = nil
        onStartLesson?(node)
    }
}) { node in
    lessonDetailSheet(for: node)
}
```

- [ ] **Step 3: Run tests to verify they pass**
Run: `swift test --filter CraftFluidJourneyTests`
Expected: PASS.

- [ ] **Step 4: Commit changes**
`git commit -am "fix(CraftUIKit): resolve lesson launch dismissal race condition using sheet onDismiss hook"`

---

### Task 7: Interactive Fluid Journey Showcase in `CraftCatalogView`

**Files:**
- Modify: `Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift`
- Test: `Packages/CraftUIKit/Tests/CraftUIKitTests/CatalogViewTests.swift`

**Interfaces:**
- Produces: Dedicated "Fluid Journey (Tactile 3D)" showcase screen in `CraftCatalogView` displaying all node states, style toggle, and interactive detail sheet mock.

- [ ] **Step 1: Add Fluid Journey interactive section in `CraftCatalogView.swift`**
- Provide sample journey with:
  - Node 1: Active (with `ActiveCalloutBubble` and breathing halo)
  - Node 2: Completed (with lavender tint, vibrant purple icon, and green checkmark badge)
  - Node 3: In-Progress (with circular progress arc)
  - Node 4: Locked (with muted gray semantic icon)
  - Node 5: Bonus (with sparkle gradient)
- Provide surface style picker (`.tactile3D`, `.elevated`, `.glass`, `.outlined`, `.flat`).
- Interactive sheet tap and mock start lesson toast.

- [ ] **Step 2: Run catalog tests**
Run: `swift test --filter CatalogViewTests`
Expected: PASS.

- [ ] **Step 3: Commit changes**
`git commit -am "feat(CraftUIKit): add interactive Fluid Journey showcase in CraftCatalogView"`

---

### Task 8: Full Verification & Quality Gate

**Files:**
- All touched files

- [ ] **Step 1: Run CraftUIKit tests**
Run: `swift test` in `Packages/CraftUIKit`
Expected: 100% PASS.

- [ ] **Step 2: Run VocabCraftApp tests**
Run: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Expected: 100% PASS.

- [ ] **Step 3: Run SwiftLint**
Run: `swiftlint --strict`
Expected: 0 errors, 0 warnings.

- [ ] **Step 4: Interactive Simulator Validation**
- Boot simulator, run app.
- Inspect Home screen: Node 1 centered, 88pt, floating bubble above.
- Tap Node 1 $\rightarrow$ Start Lesson $\rightarrow$ Verify `LessonLearningView` opens seamlessly without quitting.
- Complete lesson $\rightarrow$ Verify completed state shows vibrant icon + green checkmark badge.
