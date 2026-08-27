# Learning Path UX Refinements: Full-View Detail Sheet & Configurable Sticky Unit Headers

**Date**: 2026-08-27  
**Status**: Proposed  
**Layer**: Design System (`CraftUIKit`) & Main Application (`VocabCraftApp`)

---

## 1. Overview & Problem Statement

After testing Feature 1 (Home — Learning Path), two UX frictions were identified in the user journey:

1. **Detail Modal Truncation / Content Clipping**:
   - **Current Behavior**: When tapping an unlocked node, [`CraftLessonDetailSheet`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonDetailSheet.swift) opens at `.fraction(0.48)` detent. The natural content height (3D Tactile Icon, Title, Status Badge, Metrics Chips, Objectives Card, and Primary Action Button) is ~520pt. At `0.48` (~408pt on iPhone), the metrics chips and objectives card are cut off mid-screen, forcing the user to swipe up manually before reading the objectives or starting the lesson.
   - **Target Behavior**: The sheet presents at a comfortable full-view detent (`.fraction(0.62)` / height ~520pt) with compact vertical rhythm so 100% of the content is visible immediately with zero scrolling required.

2. **Loss of Unit Context on Scroll (Sticky Unit Headers)**:
   - **Current Behavior**: As the user scrolls down the serpentine learning path, the Unit Portal Header Card (`Unit 1: Giao Tiếp Hằng Ngày`, CEFR level, progress `0/3`) scrolls out of view. In long units (4–8 nodes), the user loses context of which Unit they are currently navigating.
   - **Target Behavior**: The Unit Header card sticks neatly below the app's top [`HeaderView`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Homepage/Views/HeaderView.swift) as the user scrolls through that Unit's nodes, smoothly transitioning to the next Unit header when scrolling into the next unit. To support diverse use cases across the codebase, this behavior must be **fully configurable via a toggle flag (`pinSectionHeaders: Bool`) in `CraftUIKit`**.

---

## 2. Architecture & Design Decisions

### 2.1 Package Boundary: Design System (`CraftUIKit`) vs Main App (`VocabCraftApp`)

- **Placement**: Both features belong in **`CraftUIKit`** inside [`CraftLearningPath`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift) and [`CraftLessonDetailSheet`](file:///Users/hoojinguyen/Projects/vocab-craft-app/Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonDetailSheet.swift).
- **Rationale**:
  1. `CraftLearningPath` encapsulates the `ScrollView`, `LazyVStack`, section layout, and sheet presentation. Putting sticky header support inside `CraftUIKit` preserves encapsulation.
  2. Making `pinSectionHeaders` configurable in `CraftUIKit` allows any future feature (e.g., Topic Roadmap, Grammar Journey, Review Path) to toggle sticky behavior with a single parameter without duplicating scroll logic.

---

## 3. Detailed Component Specifications

### 3.1 `CraftLearningPath` (`Packages/CraftUIKit`)

#### 3.1.1 Configurable Sticky Header Parameter
Add `pinSectionHeaders: Bool = true` to all initializers:
```swift
public struct CraftLearningPath: View {
    public let sections: [LessonSection]
    public let winding: SerpentineWinding
    public let rowPattern: RowPattern
    public let pinSectionHeaders: Bool // Default: true
    public let onNodeTap: (@Sendable (LessonNodeModel) -> Void)?
    public let onStartLesson: (@Sendable (LessonNodeModel) -> Void)?
    public let showDetailModal: Bool
    public let scrollToActive: Bool
    public let showCelebration: Bool
    ...
```

#### 3.1.2 Scroll View & Section Layout
- When `pinSectionHeaders == true`:
  - `LazyVStack(spacing: theme.spacing.xxl, pinnedViews: [.sectionHeaders])`.
  - For each `LessonSection`:
    ```swift
    Section {
        CraftLessonSectionBodyView(
            section: section,
            rowPattern: rowPattern != .standard ? rowPattern : section.rowPattern,
            onNodeTap: onNodeTap
        )
    } header: {
        CraftLessonSectionHeaderView(section: section)
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.xs)
            .background(theme.colors.canvasBackground)
    }
    ```
- When `pinSectionHeaders == false`:
  - `LazyVStack(spacing: theme.spacing.xxl, pinnedViews: [])`.
  - Renders `CraftLessonSectionView` unpinned (standard continuous scroll).

#### 3.1.3 Modal Sheet Presentation Detents
Update `.sheet(item: $selectedNodeForDetail)`:
```swift
.sheet(item: $selectedNodeForDetail) { node in
    CraftLessonDetailSheet(
        node: node,
        onStart: handleStartLesson,
        onDismiss: {
            selectedNodeForDetail = nil
        }
    )
    .presentationDetents([.fraction(0.62), .large])
    .presentationDragIndicator(.visible)
}
```

---

### 3.2 `CraftLessonDetailSheet` (`Packages/CraftUIKit`)

#### 3.2.1 Vertical Rhythm & Sizing Optimization
Optimize spacing within `CraftLessonDetailSheet` to fit 100% within a `~520pt` / `0.62` detent:
1. **Header Section**:
   - Tactile 3D Icon: Diameter `54pt` (scalable with Dynamic Type).
   - Spacing between Icon, Title, and Badge: `theme.spacing.xs` (4–6pt).
   - Title: `theme.typography.titleMedium.bold()` with `lineLimit(2)`.
2. **Metrics Chips Row**:
   - Height: `36pt` with `padding(.vertical, 6)`.
   - 3 Chips: `+XP`, `Duration`, `Words`.
3. **Objectives Card**:
   - Compact `CraftCard(style: .outlined)`.
   - Header with `target` SF Symbol + "Mục tiêu bài học".
   - 3 bullet items with compact vertical padding (`spacing: 6`).
4. **Primary Action Button**:
   - Height: `50pt` with `theme.spacing.base` horizontal padding and `theme.spacing.md` bottom safe-area margin.

---

### 3.3 `CraftLessonSectionHeaderView` (`Packages/CraftUIKit`)

Extract and modularize the header of `CraftLessonSectionView`:
- **Visual Design**: Rounded card (`theme.radii.xl`) with subtle gradient wash (`theme.colors.surfaceCard`), border hairline, and `theme.colors.canvasBackground` outer container wrapper.
- **Z-Index & Solid Backdrop**: Outer container has `theme.colors.canvasBackground` filling the full horizontal width so scrolling node elements underneath are cleanly masked.

---

### 3.4 Integration in `VocabCraftApp`

In [`HomepageView.swift`](file:///Users/hoojinguyen/Projects/vocab-craft-app/VocabCraftApp/Features/Homepage/Views/HomepageView.swift):
```swift
CraftLearningPath(
    sections: viewModel.sections,
    winding: .standard,
    rowPattern: .standard,
    pinSectionHeaders: true,
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
    showCelebration: false
)
```

---

## 4. Localization & String Taxonomy

All UI text in `CraftUIKit` uses existing `craft.*` keys via `CraftLocalized`. No new localization keys are required.
- `craft.learning_path.start_lesson`
- `craft.learning_path.continue_lesson_format`
- `craft.learning_path.review_lesson_format`
- `craft.learning_path.objectives_header`
- `craft.common.unit.minutes_format`
- `craft.common.unit.words_format`

---

## 5. Verification & Testing Plan

### 5.1 Unit Tests in `CraftUIKitTests`
1. **`CraftLearningPathTests`**:
   - Verify `pinSectionHeaders` defaults to `true`.
   - Verify initialization with `pinSectionHeaders: false`.
   - Verify sheet detents configuration.
2. **`CraftLessonDetailSheetTests`**:
   - Verify all objective rows, chips, and CTA buttons are present for `.active`, `.inProgress`, `.completed`, and `.locked` states.

### 5.2 Integration Tests in `VocabCraftAppTests`
1. **`HomepageViewTests`**:
   - Verify `HomepageView` renders `CraftLearningPath` with `pinSectionHeaders: true`.
2. **Regression Suite**:
   - Run `swiftlint lint` (0 violations).
   - Run `swift test` (All tests pass).
   - Run `xcodebuild test` (All simulator tests pass).
