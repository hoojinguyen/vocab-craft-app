# CraftFloatingTabBar Scroll-Responsive Liquid Glass Design

**Date:** 2026-08-30  
**Status:** User-approved design; pending implementation-plan review  
**Scope:** `CraftUIKit` navigation and learning path components; Homepage integration

## Goal

Refine `CraftFloatingTabBar` into a native Liquid Glass control on iOS 26+ and add an Instagram-inspired, direction-aware compact presentation: deliberate downward scrolling condenses the bar, while deliberate upward scrolling restores it. The behavior must remain stable during bounce, preserve every 44 pt minimum hit target, and respect accessibility settings.

## Existing Context

`CraftFloatingTabBar` already has a native iOS 26 glass capsule, a legacy material fallback, a matched-geometry active pill, theme tokens, and `CraftTabBarSize` tiers. Its center FAB is outside the current `GlassEffectContainer`, and the bar has no scroll input. `HomepageView` overlays the bar outside `CraftLearningPath`, whose internal `ScrollView` therefore cannot currently influence the bar.

This change extends the prior Liquid Glass work rather than replacing its public tab-item API or surface-style system.

## Design

### 1. Presentation Contract

Add a public, `Sendable`, `Equatable` `CraftTabBarPresentation` with `.expanded` and `.compact`. `CraftFloatingTabBar` receives it as a value with a default of `.expanded`, so all existing call sites retain their current appearance and behavior. The bar does not attach a drag gesture or inspect a screen's scroll view; the scroll-owning component remains responsible for producing presentation changes.

This separation keeps gesture ownership with `ScrollView`, works with other future scroll containers, and confines the animation to the tab bar subtree.

### 2. Scroll Direction Pipeline

`CraftLearningPath` gains one optional closure for presentation changes. On supported system versions, its scroll geometry produces a scalar content offset; a small internal, testable reducer converts that offset into `.expanded` or `.compact`.

- Normalize the offset at zero so overscroll above the top never compacts the bar.
- Accumulate only deliberate directional travel, using existing spacing tokens for its hysteresis threshold.
- Emit only when the presentation actually changes; per-frame geometry remains local to `CraftLearningPath`.
- Initial and programmatic positioning establish the baseline but do not cause a visible presentation transition.
- On system versions without the scroll-geometry API, retain `.expanded` rather than overlaying a competing drag gesture. The iOS 17 fallback stays fully functional and visually stable.

`HomepageView` owns `@State private var tabBarPresentation`, passes it to both components, and resets it to `.expanded` when leaving the Home tab. The first integration is Home/Learning Path only; later scroll surfaces can opt in through the same public value contract.

### 3. Liquid Glass Composition

For `style == .glass` on iOS 26+, one `GlassEffectContainer` groups the capsule and optional center action. Both use native glass effects after their layout and visual modifiers. The capsule and FAB use stable `glassEffectID` values in a shared namespace so the system can preserve the optical surface through compact/expanded hierarchy changes. The center action uses an interactive tinted glass effect; the passive capsule and selection lens do not claim interactivity.

The compact visual state uses existing small-tier metrics: a shorter capsule, tighter token-based insets, a smaller center action, and a naturally narrower strip. It does not apply a scale transform to tappable controls. Each tab and the center action maintain at least a 44 by 44 pt hit area, while the visible surface interpolates around those targets. The active pill, SF Symbol emphasis, existing haptic feedback, and tab selection behavior remain intact.

On iOS 17 through iOS 25, preserve the existing themed material/opaque fallback. `accessibilityReduceTransparency` selects the opaque surface. No new user-visible or accessibility copy is introduced, so no localization catalog entries are required.

### 4. Motion Policy

Tab selection and scroll presentation use separate, narrowly scoped animations. Selection retains the existing smooth token. Presentation changes use the theme's gentle spring token, driving capsule dimensions, insets, center-action geometry, and visual opacity together. The reducer's hysteresis prevents direction jitter from repeatedly restarting the spring.

When Reduce Motion is enabled, the state changes without scale, squash/stretch, or spring movement. VoiceOver semantics, badges, selected traits, and haptic selection feedback remain unchanged.

### 5. Boundaries and Failure Handling

The reducer treats non-finite and top-bounce offsets as no-op input, preserving its current state. Empty and non-scrollable learning paths never emit a compact state. The effect is opt-in at the learning-path integration point, so an unrelated screen cannot accidentally change the global tab bar. No new ad-hoc view, color, typography, radius, spacing, or localization string is introduced outside CraftUIKit's existing design system.

## Files and Responsibilities

| File | Responsibility |
| --- | --- |
| `Packages/CraftUIKit/Sources/CraftUIKit/Components/Navigation/CraftFloatingTabBar.swift` | Public presentation state, metric selection, native grouped glass composition, scoped presentation motion, and accessibility-preserving fallbacks. |
| `Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/LearningPath/CraftLearningPath.swift` | Local scroll-geometry observation and optional presentation callback. |
| `Packages/CraftUIKit/Tests/CraftUIKitTests/CraftFloatingTabBarTests.swift` | Reducer, default compatibility, threshold/hysteresis, and Reduce Motion motion-policy tests. |
| `Packages/CraftUIKit/Tests/CraftUIKitTests/NavigationTests.swift` | Construction and style compatibility for expanded and compact presentations. |
| `VocabCraftApp/Features/Homepage/Views/HomepageView.swift` | Home-owned presentation state and Learning Path / tab bar wiring. |
| `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift` | Homepage construction and presentation-reset coverage. |
| `Packages/CraftUIKit/Sources/CraftUIKit/Previews/CraftCatalogView.swift` | Deterministic expanded/compact catalog preview. |

## Acceptance Criteria

1. Existing `CraftFloatingTabBar` initializers compile without source changes and default to `.expanded`.
2. On iOS 26+ glass mode, the capsule and center action share a `GlassEffectContainer`; glass effects are availability-gated, use consistent shapes, and appear after layout modifiers.
3. A deliberate downward Learning Path scroll compacts the Home tab bar once; upward travel past the same threshold restores it. Top bounce and small reversals do not toggle it.
4. Compact controls retain 44 pt minimum hit areas and preserve VoiceOver labels, selected traits, badge values, and actions.
5. Reduce Motion removes motion; Reduce Transparency uses opaque fallbacks; iOS 17 retains an expanded, functional fallback.
6. All new behavior is covered by test-first unit tests, rendered in a deterministic preview, and verified with CraftUIKit tests, localization tests, SwiftLint, the app test suite, and a warning-free Simulator build.

## Out of Scope

- Automatically applying scroll compaction to Vocabulary, Search, Settings, or Reflex in this change.
- Changing tab destinations, title localization, theme values, or existing non-glass surface semantics.
- Adding a custom `UIScrollView` bridge, a global scroll singleton, or a drag gesture above the scroll view.
