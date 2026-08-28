# Design Spec: CraftLearningPath Sticky HUD & Docking Refinement

- **Author**: Antigravity & Hoo Ji Nguyen
- **Date**: 2026-08-28
- **Status**: Ready for Review
- **Target Package**: `CraftUIKit` (Design System) & `VocabCraftApp`

---

## 1. Overview & Problem Statement

In the previous iteration of `CraftLearningPath`, a visual glitch occurs during scrolling where two headers are displayed simultaneously:
1. **SwiftUI Native Pinning**: `LazyVStack(pinnedViews: [.sectionHeaders])` pins the full `CraftLessonSectionHeaderView` (~130pt Unit Portal Card) at the top of the scroll view.
2. **Floating HUD Overlay Collision**: Concurrently, `CraftLessonSectionHeaderView` measures `minY <= 15pt` and triggers `onDockChange(true)`, prompting `CraftLearningPath` to render the floating mini capsule `stickyHUDOverlay` directly on top of the pinned large card.
3. **Premature Docking Threshold**: Because `minY <= 15` was used instead of measuring the bottom of the card (`maxY <= 0`), the mini HUD activated while 90% of the large unit card was still in view.

This design spec outlines the comprehensive architectural solution to eliminate duplicate headers, implement a refined Liquid Glass floating HUD that activates only when the unit card exits the viewport, support tap-to-scroll navigation back to the unit header, and ensure smooth multi-unit section transitions.

---

## 2. Architectural Design & Public APIs

### 2.1 Docking Geometry & Threshold Correction

#### `CraftLessonSectionHeaderView.swift`
- Replace `minY` tracking with `maxY` tracking in coordinate space `CraftLearningPath.scrollCoordinateSpaceName`:
  ```swift
  let maxY = geo.frame(in: .named(CraftLearningPath.scrollCoordinateSpaceName)).maxY
  let docked = maxY <= dockThreshold
  ```
- Change default `dockThreshold` from `15` to `0` (or the top padding margin):
  ```swift
  public init(
      section: LessonSection,
      isPinned: Bool = false,
      dockThreshold: CGFloat = 0,
      onDockChange: ((Bool) -> Void)? = nil
  )
  ```
- Add `.id(section.id)` to `CraftLessonSectionHeaderView` so that `ScrollViewReader` can programmatically scroll back to the unit gateway.

---

### 2.2 Scroll Hierarchy & HUD Presentation

#### `CraftLearningPath.swift`
- Change `LazyVStack` configuration to `pinnedViews: []` by default (or when floating sticky HUD is active), allowing the large Unit Card to scroll naturally in the content stream.
- Update `defaultStickyHUD(for section: LessonSection)`:
  - **Material & Liquid Glass**: Apply `.background(.ultraThinMaterial)` layered over `theme.colors.surfaceElevated.opacity(0.85)`.
  - **Border & Depth**: Apply `Capsule().strokeBorder(theme.colors.hairline, lineWidth: 1)` with subtle top highlight overlay.
  - **Interactivity**: Wrap in a button/tap action that executes:
    ```swift
    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        proxy.scrollTo(section.id, anchor: .top)
    }
    ```
  - **Haptics**: Trigger `.sensoryFeedback(.impact(weight: .light))` on tap.
  - **Accessibility**: Add `.accessibilityHint(CraftLocalized.string("craft.learning_path.tap_to_scroll_unit_hint"))`.
  - **Content Transition**: Apply `.animation(.spring(response: 0.35, dampingFraction: 0.8), value: dockedSection?.id)` for smooth crossfades between Unit 1, Unit 2, etc.

---

### 2.3 Integration with Homepage

#### `HomepageView.swift`
- Configure `CraftLearningPath` with `pinSectionHeaders: false` to allow the seamless floating HUD to provide orientation without obstructing content.

---

## 3. Design System & Token Discipline

All components strictly utilize `CraftUIKit` design tokens:
- **Colors**: `theme.colors.surfaceElevated`, `theme.colors.brandPrimary`, `theme.colors.hairline`, `theme.colors.textPrimary`, `theme.colors.textSecondary`.
- **Typography**: `theme.typography.label`, `theme.typography.caption`.
- **Spacing & Radii**: `theme.spacing.base`, `theme.spacing.sm`, `theme.spacing.xs`, `theme.radii.full`.
- **Depth & Shadows**: `theme.shadows.md`, `theme.depths.topHighlight`.

---

## 4. Localization Architecture (100% Bilingual Parity)

Catalog: `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`
Prefix: `craft.learning_path.*`

| Key | English (`en`) | Vietnamese (`vi`) |
|---|---|---|
| `craft.learning_path.tap_to_scroll_unit_hint` | `Double tap to scroll to the top of this unit` | `Chạm hai lần để cuộn về đầu bài học này` |

---

## 5. Verification & Testing Plan

### 5.1 Automated Unit Tests (`CraftLearningPathTests.swift`)
1. **Docking Geometry Tests**:
   - Verify `CraftLessonSectionHeaderView` triggers `onDockChange(true)` when `maxY <= dockThreshold`.
   - Verify `CraftLessonSectionHeaderView` triggers `onDockChange(false)` when `maxY > dockThreshold`.
2. **Sticky HUD Interaction & Builder Tests**:
   - Verify default and custom sticky HUD view rendering.
   - Verify tap gesture triggers scroll action without crashes.
3. **Localization Tests**:
   - Run `swift test --package-path Packages/CraftUIKit --filter LocalizationTests`.

### 5.2 Integration Tests & Quality Gates
1. Run `swift test --package-path Packages/CraftUIKit` (0 failures).
2. Run `xcodebuild test -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (0 failures).
3. Run `swiftlint lint --strict` (0 warnings, 0 errors).
