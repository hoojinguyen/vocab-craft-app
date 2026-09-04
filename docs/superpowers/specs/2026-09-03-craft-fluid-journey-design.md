# Design Specification: `CraftFluidJourney` Learning Path

- **Author**: Antigravity & Pair Programming Partner
- **Date**: 2026-09-03
- **Status**: Validated Design Spec (Awaiting User Review Gate)
- **Target Component**: `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/`
- **Host Feature**: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`

---

## 1. Overview & Problem Statement

### 1.1 Context & Motivation
The existing `CraftLearningPath` in `VocabCraftApp` utilizes a standard serpentine layout with dotted lines and narrow text labels underneath small circular nodes. Testing and developer review revealed key UI/UX drawbacks:
1. **Visual Fatigue & Clutter**: Dotted connector lines and cramped typography under 50pt nodes (`Resilience • Overwh...`) create visual noise and feel like a tedious checklist.
2. **Weak Call-to-Action**: The active node lacks sufficient scale and vitality to inspire immediate learning.
3. **Flat Atmosphere**: A plain canvas without depth or ambient warmth makes the journey feel sterile.

### 1.2 The Praktika Inspiration & Core Goal
Inspired by the modern, airy, and high-end aesthetic of **Praktika**, we are building a brand-new component in `CraftUIKit`: **`CraftFluidJourney`**.

The existing `CraftLearningPath` component will remain **completely untouched**. `CraftFluidJourney` is an independent, next-generation learning journey organism that provides:
1. **Clean, Ethereal Atmosphere**: Soft radial ambient glow auras (emerald & mint) behind floating nodes with subtle parallax.
2. **Zero Dotted-Line Clutter**: Nodes float organically in an airy, balanced S-curve. The eye naturally perceives the sequence without connecting lines.
3. **Scroll-Driven Pinned Unit Card**: Pinned under the status bar. As the user scrolls past milestone section pills on the path, the pinned card automatically and smoothly transitions its title, level, and progress.
4. **Bold Visual Hierarchy (Hero Active Node)**:
   - Completed nodes are soft translucent discs with green checkmark badges (`✓`).
   - Active node is a massive (82pt), saturated emerald orb with a gentle breathing glow animation (`PhaseAnimator`) and tactile spring physics.
5. **Expandable Accordion Curriculum Drawer**: Tapping the pinned unit card opens a full sheet with collapsible unit accordion cards. Tapping any sub-lesson dismisses the sheet and smoothly scrolls the Home screen directly to that lesson's node.

---

## 2. Architecture & Component Decomposition

All new files will reside in `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/`:

```
Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/FluidJourney/
├── CraftFluidJourney.swift          // Main organism container
├── CraftPinnedUnitHeader.swift      // Sticky navigation card with scroll-driven morph transitions
├── CraftMilestonePill.swift         // In-scroll floating milestone pill reporting geometry offset
├── CraftJourneyNode.swift           // 3D tactile floating node (Completed, Hero Active, Upcoming)
├── CraftUnitDrawerSheet.swift       // Full-screen accordion curriculum drawer
└── CraftFluidJourneyModels.swift    // Models, protocols, preferences & geometry keys
```

### 2.1 `CraftFluidJourneyModels.swift`
Provides presentation models and coordinate preference keys:

```swift
public struct FluidJourneyMilestonePreferenceKey: PreferenceKey, Sendable {
    public static var defaultValue: [String: CGFloat] = [:]
    public static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
```

- Reuses `LessonSection` and `LessonNodeModel` presentation DTOs for seamless integration with existing domain use cases (`FetchLearningPathUseCase`).

### 2.2 `CraftPinnedUnitHeader.swift`
- Positioned directly beneath the Home top status header.
- Renders:
  - Unit badge / level (e.g. `A2 • Unit 1`).
  - Active section title (e.g. `Everyday Conversations`).
  - Active sub-lesson title (e.g. `Habits & Moods Vocabulary`).
  - Trailing chevron `›`.
- **Morphing Animation**: When `activeSectionId` changes via scroll preference:
  - Employs `.transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))`.
  - Driven by `.animation(.smooth(duration: 0.28), value: activeSectionId)`.
  - Level and numeric indicators animate with `contentTransition(.numericText())`.
- Tapping triggers `onHeaderTap` callback to open `CraftUnitDrawerSheet`.

### 2.3 `CraftMilestonePill.swift`
- In-scroll floating capsule representing unit boundary titles: `[ Present Simple for Personal Facts ]`.
- Features a `GeometryReader` observing its `minY` in the named coordinate space `CraftFluidJourney.scrollCoordinateSpaceName`.
- Posts its vertical coordinate to `FluidJourneyMilestonePreferenceKey`.

### 2.4 `CraftJourneyNode.swift`
Renders an individual floating node in the S-curve:
1. **Completed Node**:
   - Diameter: 68pt.
   - Background: Soft translucent mint/emerald tint (`theme.colors.brandPrimary.opacity(0.12)`).
   - Icon: Crisp glyph (e.g. whiteboard easel, A-Z, trophy).
   - Trailing Bottom-Right Badge: 22pt green circle with bold white checkmark (`✓`).
2. **Hero Active Node**:
   - Diameter: 82pt (commanding focal point).
   - Background: Vibrant linear gradient (`theme.gradients.brandHero` / `#16D68C` -> `#0E7A53`).
   - Sizing & Motion: Multi-layer breathing glow pulse using `PhaseAnimator(GlowPhase.allCases)` with `.craftGlow` spring.
   - Depress Physics: Mechanical press scale (`0.95`) with medium haptic click (`CraftHaptics.shared.medium()`).
   - Label: Subtle "START LESSON" sub-tag below the orb.
3. **Upcoming / Locked Node**:
   - Diameter: 60pt.
   - Background: Muted translucent surface (`theme.colors.surfaceSubtle`).
   - Icon: Muted glyph or lock icon (`theme.colors.textMuted`).

### 2.5 `CraftUnitDrawerSheet.swift`
- Presented modally when the user taps the pinned header card.
- Renders:
  - Top navigation bar: Circular `✕` dismiss button, Current Deck title (`Giao Tiếp Hằng Ngày ›`), subtitle (`A2 • Career growth`), and `[ ☵ Tuỳ chỉnh lộ trình ]` pill button.
  - **Expandable Accordion Cards**:
    - Active unit is expanded by default, displaying all contained sub-lessons with their completion status (completed `✓`, in-progress `○`, upcoming `○`).
    - Other units are collapsed cards with status rings and chevrons `▼`.
    - Tapping a collapsed unit toggles expansion with `.spring(response: 0.35, dampingFraction: 0.8)`.
  - **1-Tap Jump**: Tapping any lesson item invokes `onSelectLesson(sectionId, nodeId)`, dismissing the sheet and triggering a smooth programmatic scroll to that node on the Home screen.

### 2.6 `CraftFluidJourney.swift`
The primary container view composing all parts:
- `ScrollViewReader` wrapping a `ScrollView(.vertical, showsIndicators: false)`.
- Coordinate space named `CraftFluidJourney.scrollCoordinateSpaceName`.
- Ethereal ambient background with soft radial gradients (`ZStack` behind content).
- Floating S-curve layout positioning:
  - Alternates horizontal offsets: `[ -45pt, 0pt, +45pt, 0pt ]` without harsh connecting lines.
- Intercepts `FluidJourneyMilestonePreferenceKey` to determine which section is currently docked at the top.

---

## 3. Integration with `VocabCraftApp`

### 3.1 `HomepageView.swift`
- Replace `CraftLearningPath(...)` with `CraftFluidJourney(...)`.
- Wire `sections: viewModel.sections`.
- Wire `onNodeTap: { node in viewModel.handleNodeTap(node) }`.
- Wire `onStartLesson: { node in startLesson(for: node) }`.
- Wire `onTabBarPresentationChange` to preserve the floating tab bar auto-collapse behavior.

### 3.2 Programmatic Scroll Synchronization
When a lesson is selected from `CraftUnitDrawerSheet`:
```swift
withAnimation(.smooth(duration: 0.45)) {
    scrollProxy.scrollTo(targetNodeId, anchor: .center)
}
```

---

## 4. Design Tokens, Motion & Accessibility

### 4.1 Strict Token Discipline
All colors and spacing must use `CraftUIKit` tokens:
- **Tints & Surfaces**: `theme.colors.brandPrimary`, `theme.colors.canvasBackground`, `theme.colors.surfaceCard`, `theme.colors.surfaceElevated`.
- **Radii**: `theme.radii.xl` (20pt), `theme.radii.full` (999pt for capsules).
- **Shadows & Depth**: `theme.shadows.sm`, `theme.shadows.md`, `theme.depths.depthMd`.
- **Typography**: `theme.typography.titleMedium`, `theme.typography.bodyMedium`, `theme.typography.label`.

### 4.2 Accessibility & Reduce Motion
- Support `@Environment(\.accessibilityReduceMotion) var reduceMotion`:
  - When enabled, breathing animations and scale transitions are disabled, falling back to static visual hierarchy.
- Full VoiceOver labels and accessibility traits on all nodes, milestone pills, and drawer accordion items.

---

## 5. Localization Architecture

Full bilingual parity (English & Vietnamese) in `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings`:

| Key | English (`en`) | Vietnamese (`vi`) |
| :--- | :--- | :--- |
| `craft.fluid_journey.start_lesson` | "START LESSON" | "BẮT ĐẦU HỌC" |
| `craft.fluid_journey.completed_status` | "Completed" | "Đã xong" |
| `craft.fluid_journey.current_status` | "Current" | "Đang học" |
| `craft.fluid_journey.unit_picker_title` | "Curriculum & Units" | "Lộ trình & Chủ đề" |
| `craft.fluid_journey.adjust_plan` | "Adjust plan" | "Tuỳ chỉnh lộ trình" |
| `craft.fluid_journey.select_unit_hint` | "Double tap to switch to this unit" | "Chạm hai lần để chuyển sang chủ đề này" |

---

## 6. Verification Plan

### 6.1 Automated Tests
1. **Unit Tests (`CraftFluidJourneyTests.swift`)**:
   - Verify layout generation for various section counts (1, 3, 10 sections).
   - Test milestone scroll offset calculation logic.
   - Verify node state resolution (completed, active, upcoming).
2. **Localization Parity**:
   - `swift test --filter LocalizationTests` to ensure 100% parity and valid tokens.
3. **SwiftLint & Build**:
   - Run `swiftlint` across packages.
   - Xcodebuild compilation for 0 warnings and 0 errors.

### 6.2 Manual Verification on Simulator
- Launch on iPhone 17 Simulator.
- Verify smooth scrolling at 60/120fps.
- Verify pinned unit card title morphs accurately as milestone pills scroll past.
- Verify tapping pinned card opens accordion drawer sheet.
- Verify tapping a lesson in drawer smoothly scrolls the Home screen to that lesson.
- Verify tapping Hero Active Node opens lesson briefing and starts learning session.
