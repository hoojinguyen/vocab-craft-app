# Craft Fluid Journey Tactile 3D Redesign & UX Polish

**Design Document**  
**Date**: 2026-09-03  
**Status**: Approved (Brainstormed with User)  
**Target Branches**: `feature/craft-fluid-journey`  

---

## 1. Context & Motivation

Following the initial overhaul in `Craft Journey UI Improvements`, extensive visual and interaction review against reference applications identified seven critical UI/UX and architectural discrepancies:

1. **Active Node Label Clipping**: The `"START LESSON"` capsule in `CraftJourneyNode` was placed in a tight `VStack` below the 72pt node, overlapping directly onto the 96pt pulsing halo stroke border.
2. **Node Sizing Disparity**: The 72pt node was significantly undersized on modern 393pt viewports (less than 18% screen width), creating vast empty negative space. Reference apps feature prominent, tactile nodes measuring 88–96pt (~25% viewport width) with large, recognizable icons.
3. **First Node Alignment Asymmetry**: The S-curve offset sequence `[-45, 0, 45, 0]` assigned `-45pt` to index 0, pushing the opening lesson node far to the left margin. In reference designs, the opening node is **strictly centered (`x = 0`)**, providing a stable visual anchor directly beneath the milestone pill.
4. **Curriculum Hierarchy Inversion & "Unit" Clutter**: Milestone pills were mistakenly labeled with stage titles (e.g. *"Chặng 1: Thói quen & Cảm xúc"*), while headers redundantly displayed *"Unit 1: ..."*. The correct pedagogical hierarchy requires:
   - **Topic/Deck**: The top-level learning domain.
   - **Milestones/Sub-topics**: Represented by in-scroll pills (clean topic names, e.g. *"Thói quen & Cảm xúc"*, without *"Chặng"* or *"Unit"* prefixes).
   - **Nodes**: Each individual lesson milestone along the fluid path. Node counts per milestone are dynamic based on backend data.
5. **Tactile 3D Design Language Dilution**: While `.tactile3D` was selected, `CraftPinnedUnitHeader` only offered a flat Liquid Glass surface, and `CraftMilestonePill` lacked 3D extrusion, bevel depth, and specular highlights.
6. **Completed (Done) Node State Visuals & Preview Gap**: Reference applications preserve the semantic lesson icon in full vibrant brand color on a soft pastel background, pinned with a crisp circular green checkmark badge (`✓`) at the bottom-trailing corner. KIT lacked a comprehensive preview for this progression state.
7. **Lesson Launch Abrupt Dismissal Bug**: Tapping "Start Lesson" inside `CraftLessonDetailSheet` triggered sheet dismissal (`selectedNodeForDetail = nil`) and synchronously invoked `startLesson`, which presented `LessonLearningView` via `.fullScreenCover`. In UIKit/SwiftUI, presenting a view controller while another is actively dismissing causes presentation cancellation, immediately dumping the learner back to the Home screen.

---

## 2. Architecture & Design Specifications

```
┌─────────────────────────────────────────────────────────────┐
│                 CraftPinnedUnitHeader                       │
│    [A2 · B1]  Giao Tiếp Hằng Ngày                           │
│    6 bài học • Sơ cấp                              [ › ]    │
│    (Tactile 3D: Top Highlight + 4pt Bottom Bevel Rim)       │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
            ┌──────────────────────────────────────┐
            │   CraftMilestonePill (Tactile 3D)    │
            │        Thói quen & Cảm xúc           │
            └──────────────────────────────────────┘
                               │
                               ▼
                     [ BẮT ĐẦU ]  (ActiveCalloutBubble)
                          ▼  (CaretDown)
                   ┌──────────────┐
                   │  (Node 1)    │  (88pt Centered x = 0, Active White Icon)
                   └──────────────┘
                          \
                           \  (S-Curve x = -48pt)
                            ▼
                     ┌──────────────┐
                     │  (Node 2) [✓]│  (88pt Done: Pastel tint + Green Checkmark Badge)
                     └──────────────┘
                            /
                           /  (S-Curve x = 0 or +12pt)
                          ▼
                     ┌──────────────┐
                     │  (Node 3)    │  (88pt Locked: Muted Gray Semantic Icon)
                     └──────────────┘
```

### 2.1 Component Geometry & S-Curve Layout

- **Node Diameter (`CraftJourneyNode`)**:
  - Base unscaled diameter increased from **72pt to 88pt** (`RoundedRectangle(cornerRadius: 30, style: .continuous)`).
  - Semantic icon size proportionally increased from **24pt to 34pt** (`.system(size: iconSize, weight: .bold)`).
  - Preserves accessibility `@ScaledMetric` responsiveness.
- **S-Curve Horizontal Offsets (`FluidJourneyNodeOffset`)**:
  - New sequence: `[0, -48, 0, 48]` (or natural winding `[0, -48, 12, 48]`).
  - **Index 0 is guaranteed `0.0pt`**, perfectly centered along the vertical axis of the milestone pill.
  - Subsequent nodes weave left and right with comfortable margin clearance on 393pt+ displays.

### 2.2 Active Callout Bubble & Icon State Preservation

- **`ActiveCalloutBubble` (Floating Speech Bubble)**:
  - Removed `activeStartTag` from below the node.
  - Positioned above the active node with an 8pt–10pt clearance gap from the halo stroke.
  - Structure: Capsule containing uppercase localized text (`START LESSON` / `BẮT ĐẦU`) + downward triangle caret (`CaretDownShape`) pointing at the node's top edge.
  - Subtle vertical bobbing animation (`PhaseAnimator`, -2pt to +2pt) when Reduce Motion is off.
- **Semantic Icon Preservation Matrix**:
  | State | Surface Background | Semantic Icon Styling | Corner Badge |
  | :--- | :--- | :--- | :--- |
  | **Active** | Vibrant brand hero gradient | Pure White (`#FFFFFF`), bold weight | None (halo pulse + callout bubble) |
  | **Completed (Done)** | Soft brand pastel tint (`brandPrimary.opacity(0.12)`) | Vibrant Brand Primary (`brandPrimary`), bold weight | 26pt circular green badge (`#22C55E`) with white checkmark `✓` and 2pt background cutout stroke at `.bottomTrailing` |
  | **In-Progress** | Soft brand tint + 3pt progress trim arc | Vibrant Brand Primary | None |
  | **Locked / Upcoming** | Soft neutral card (`surfaceSubtle`) | Muted Gray (`textMuted`), semibold weight (never replaced with padlock) | None |
  | **Bonus / Treasure** | Accent shine gradient | Pure White or Accent Gold | None |

### 2.3 Tactile 3D Design System Adoption

- **`CraftPinnedUnitHeader`**:
  - Introduces `surfaceStyle: CraftSurfaceStyle` parameter (defaulting to `.tactile3D` or environment theme).
  - In `.tactile3D`:
    - Top face: `theme.colors.surfaceCard` with `topHighlight` hairline border (`1.5pt`).
    - Bottom extrusion rim: 4pt physical extrusion offset (`theme.depths.depthMd`) with darker shadow bevel (`#080A0D` or `borderDefault`).
    - Button feedback: Spring-based mechanical translation (`offset(y: 4)`) on tap, providing real tactile depression before opening the curriculum drawer.
  - In `.glass`: Translucent Liquid Glass `.ultraThinMaterial` with refractive border gradient.
- **`CraftMilestonePill`**:
  - In `.tactile3D`: Solid capsule background with 2.5pt bottom bevel rim (`theme.depths.depthSm`), `topHighlight` stroke, and `shadows.sm` elevation.
  - In `.elevated`: Elevated surface card with subtle highlight and `shadows.md`.
  - In `.glass`: Translucent material with hairline stroke.
- **`CraftJourneyNode`**:
  - Mechanical press button style translating 4pt downward upon depress.
  - Bottom rim extrusion layer (`bottomRimShape`) rendered 5pt lower than top face.
  - Top highlight stroke highlighting the upper bevel edge.

### 2.4 Curriculum Hierarchy & Data Mapping

- **Elimination of "Unit" and "Chặng"**:
  - Top card title: Displays clean Topic Deck title (e.g. *"Giao Tiếp Hằng Ngày"*), CEFR level (e.g. *"A2 · B1"*), and dynamic lesson count.
  - Milestone pills: Displays clean Milestone/Sub-topic title (e.g. *"Thói quen & Cảm xúc"*, *"Present Simple for Personal Facts"*).
  - Nodes: Represent each stage in the sub-topic with dynamic count from backend (not fixed to 4).
- **Mapper Updates (`LearningPathDataMapper`)**:
  - Refactors section title generation to omit `"Unit %lld:"` prefix.
  - Refactors milestone titles to display natural sub-topic labels.

### 2.5 Lesson Launch Transition Lifecycle Fix

- **Problem Root Cause**:
  In `CraftFluidJourney`, the detail sheet dismiss action:
  ```swift
  selectedNodeForDetail = nil
  onStartLesson?(started)
  ```
  dispatches both simultaneously. While SwiftUI is executing the sheet dismiss animation (taking ~350ms in UIKit), `HomepageView` sets `activeLessonLearningVM = vm` to present `.fullScreenCover`. UIKit rejects presenting a modal while another transition is in progress, causing the cover to dismiss immediately.
- **Architectural Solution**:
  Use SwiftUI's native `.sheet(item: ..., onDismiss: { ... })` lifecycle hook:
  ```swift
  @State private var pendingLessonToStart: LessonNodeModel?

  // In detailSheet:
  onStart: { started in
      pendingLessonToStart = started
      selectedNodeForDetail = nil // Triggers dismissal animation
  }

  // In .sheet modifier:
  .sheet(item: $selectedNodeForDetail, onDismiss: {
      if let node = pendingLessonToStart {
          pendingLessonToStart = nil
          onStartLesson?(node) // Dispatched ONLY after UIKit dismissal completes
      }
  })
  ```
  This guarantees a clean, stable view controller hierarchy before presenting `LessonLearningView`.

### 2.6 CraftUIKit Catalog Interactive Preview

- Adds a dedicated **Fluid Journey Showcase** in `CraftCatalogView` under the Navigation / Containers category.
- Features:
  - Live journey path rendered with nodes in all 5 states (Active, In-Progress, Done, Locked, Bonus).
  - Interactive Surface Style picker (`.tactile3D`, `.elevated`, `.glass`, `.outlined`, `.flat`).
  - Light Mode and Dark Mode support.
  - Functional detail sheet and start lesson mock handler.

---

## 3. Files Impacted

| Component | File Path | Action |
| :--- | :--- | :--- |
| `CraftUIKit` | `Sources/CraftUIKit/Components/Containers/FluidJourney/CraftJourneyNode.swift` | **Modify**: 88pt diameter, icon sizing, 3D tactile extrusion, completed checkmark badge, remove sub-tag |
| `CraftUIKit` | `Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourneyModels.swift` | **Modify**: S-curve sequence `[0, -48, 0, 48]` |
| `CraftUIKit` | `Sources/CraftUIKit/Components/Containers/FluidJourney/CraftFluidJourney.swift` | **Modify**: Callout bubble integration, safe sheet `onDismiss` launch, spacing refinement |
| `CraftUIKit` | `Sources/CraftUIKit/Components/Containers/FluidJourney/CraftPinnedUnitHeader.swift` | **Modify**: Add `.tactile3D` surface style, 3D bottom bevel rim, tactile press button style |
| `CraftUIKit` | `Sources/CraftUIKit/Components/Containers/FluidJourney/CraftMilestonePill.swift` | **Modify**: Implement full `.tactile3D` and `.elevated` surface styles |
| `CraftUIKit` | `Sources/CraftUIKit/Previews/CraftCatalogView.swift` | **Modify**: Add complete interactive Fluid Journey preview section |
| `VocabCraftApp` | `Features/Homepage/ViewModels/LearningPathDataMapper.swift` | **Modify**: Remove "Unit" and "Chặng" prefixes, clean topic title mapping |
| `VocabCraftApp` | `Features/Homepage/Views/HomepageView.swift` | **Modify**: Seamless presentation integration with safe dismissal hook |
| Tests | `CraftUIKitTests/CraftJourneyNodeTests.swift`, `CraftFluidJourneyTests.swift`, `CraftMilestonePillTests.swift`, `HomepageViewModelTests.swift` | **Modify/Add**: Unit test coverage for new dimensions, offsets, tactile styles, and lifecycle |

---

## 4. Verification Plan

1. **Unit & Snapshot Tests**:
   - `swift test --filter CraftJourneyNodeTests`: Verify 88pt diameter, semantic icon preservation, green checkmark badge visibility in completed state.
   - `swift test --filter CraftFluidJourneyTests`: Verify index 0 offset is `0.0pt`, subsequent S-curve coordinates, and `pendingLessonToStart` lifecycle.
   - `swift test --filter CraftMilestonePillTests`: Verify 5 surface styles.
   - `swift test --filter LearningPathDataMapperTests`: Verify no "Unit" or "Chặng" prefixes in titles.
2. **Interactive Simulator Verification (iOS Simulator)**:
   - Run `VocabCraftApp` on iPhone 16 Pro simulator.
   - Verify Node 1 is centered beneath the milestone pill.
   - Verify active node has breathing glow with floating speech bubble above (no clipping).
   - Tap Active Node $\rightarrow$ Tap "Start Lesson" in detail sheet $\rightarrow$ Verify `LessonLearningView` opens seamlessly without quitting back to Home.
   - Complete lesson $\rightarrow$ Verify completed node shows light pastel surface, vibrant brand icon, and bottom-right green checkmark badge.
3. **SwiftLint & Xcode Warnings**:
   - Run `swiftlint` and ensure 0 errors and 0 warnings.
