# HomeScreen UI/UX Overhaul & Optimization Design

- **Date**: 2026-09-02
- **Status**: Draft (Under Review)
- **Scope**: `VocabCraftApp` (Homepage Feature) & `CraftUIKit` (LearningPath & Header Components)

---

## 1. Problem Statement & Motivation

During interactive verification on iOS Simulator (iPhone 17, iOS 26.5), several critical UI/UX and visual layout bugs were identified on the main `HomepageView`:

1. **Header Stacking & Screen Congestion**: Over 40% of the screen height was consumed by multiple static header layers (`HomeTopHeaderView`, `StreakWeekStripView`, and pinned section cards), severely squeezing the learning path viewport.
2. **Header Collision Bug during Scroll**: `CraftLearningPath` was concurrently running two competing sticky mechanisms (`pinnedViews: [.sectionHeaders]` and `stickyHUDOverlay`). Scrolling past Unit boundaries caused pinned unit cards and the floating HUD capsule to collide and overlap into an illegible visual artifact.
3. **Uneven Top Bar Action Controls**: In `HomeTopHeaderView`, the streak badge (~28pt), daily progress ring (~52pt with "today" sub-label), and avatar (36x36pt circle) had mismatched heights and baseline misalignment, creating a cluttered look.
4. **Node Clipping & Spacing Deficiencies**: The initial lesson node of each Unit was positioned too close to the Unit Gateway Card, causing the node's halo glow and active callout bubble to be clipped.
5. **Rigid Connector Curves**: Dotted snake path lines had tight, boxy 90-degree corners rather than organic, smooth Bézier curves.

---

## 2. Architecture & Design Specification

### 2.1 Top Header Refactor (`HomeTopHeaderView`)
- **Title**: Large title typography (`CraftPageHeader`) aligned to the leading edge.
- **Unified 36pt Action Controls**:
  1. `CraftStreakBadge`: Compact capsule with flame icon and bold day count, height standardized to 36pt.
  2. `CraftProgressRing`: Circular progress indicator (36x36pt) with center-aligned text (`8/10` or progress percentage). The sub-label (`"today"`) is removed from layout to maintain exact 36pt height parity.
  3. `Avatar Button`: 36x36pt circular avatar with initials and subtle highlight border.
- **Horizontal Alignment**: All 3 items are aligned along a single center baseline with standard design token spacing (`theme.spacing.sm` / 8pt).

### 2.2 Removal of 7-Day Streak Week Strip (`StreakWeekStripView`)
- Remove `StreakWeekStripView` from `HomepageView`.
- Streak information is now consolidated in the `CraftStreakBadge`. Tapping the streak badge triggers detailed streak history / sheet navigation without cluttering the main screen.

### 2.3 Learning Path Sticky HUD & Section Transition (`CraftLearningPath`)
- **Section Gateway Banner (`CraftLessonSectionHeaderView`)**:
  - Renders as an in-scroll gateway card at the beginning of each Unit (`pinnedViews: []`).
  - Scrolls naturally with content.
- **Floating Liquid Glass HUD (`stickyHUDOverlay`)**:
  - Triggers only when the current Unit's gateway card scrolls completely past the top boundary.
  - Displays a clean capsule: `[Icon] [Level/Title] [Progress]`.
  - Tapping the capsule smoothly scrolls back to the top of the active Unit.
  - Smooth spring transition (`.move(edge: .top).combined(with: .opacity)`) when switching between Units, preventing card overlapping.
- **Node Spacing & Breathing Room**:
  - Add explicit vertical spacing (`theme.spacing.xl` / 32pt) between `CraftLessonSectionHeaderView` and `CraftLessonSectionBodyView`.

### 2.4 Organic Snake Path Geometry (`CraftSnakePathGeometry`)
- Upgrade turning radii (`turnRadius: 40pt`, `edgeInset: 24pt`) and smooth out tangent circular fillet arcs in `SnakePathSegmentGeometry`.
- Ensure dotted connectors flow smoothly between offset columns and maintain consistent dot spacing.

---

## 3. Component Breakdown & Impacted Files

| Component / Layer | File | Changes |
| :--- | :--- | :--- |
| **Main App / Home** | `VocabCraftApp/Features/Homepage/Views/HomepageView.swift` | Remove `StreakWeekStripView`, configure `pinSectionHeaders: false` on `CraftLearningPath`. |
| **Main App / Home** | `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift` | Refactor trailing group to 3 unified 36pt items, remove "today" sub-label. |
| **Design System / UI** | `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift` | Fix sticky header collision, streamline HUD docking debounce and transitions. |
| **Design System / UI** | `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLessonSectionView.swift` | Adjust spacing between header card and body nodes. |
| **Design System / UI** | `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftSnakePathGeometry.swift` | Enhance fillet arcs and turn radii for organic Bézier feel. |

---

## 4. Localization & Design System Compliance

- **Zero Hardcoded Strings**: All accessibility labels and textual tokens remain localized via `Localizable.xcstrings` (`craft.learning_path.*` and `app.home.*`).
- **Token Discipline**: All colors, paddings, corner radii, and elevations use `CraftTheme` tokens (`CraftColorTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`).

---

## 5. Verification & Testing Plan

1. **Unit & Localization Tests**:
   - Run `swift test` in `Packages/CraftUIKit` to verify component integrity.
   - Run `VocabCraftAppTests` to ensure view models and headers remain fully functional.
2. **Interactive Simulator Verification (iPhone 17)**:
   - Build and launch via XcodeBuildMCP.
   - Capture before-and-after screenshots across the scroll range (top, unit transition, bottom).
   - Confirm 0 compiler warnings, 0 SwiftLint violations, and smooth 60fps scrolling.
