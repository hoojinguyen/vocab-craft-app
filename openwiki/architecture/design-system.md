---
type: architecture
title: Design System — CraftUIKit
description: CraftUIKit tokens, theme presets, surface styles, and reusable components (including LearningPath, FluidJourney, and Streak containers) that enforce the CraftUIKit-first UI discipline.
tags: ["design-system", "craftuikit", "tokens", "swiftui"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-d85caf347254e99d90bcb93d
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift
  - id: openwiki-source-736f69100069b5d60cb8047c
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/Cards/CraftCard.swift
  - id: openwiki-source-e91d13f778505d16cab6a89c
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift
  - id: openwiki-source-71661d79da6d20d09e06bcfd
    resource: repo://VocabCraftApp/App/VocabCraftApp.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility and Ownership

`CraftUIKit` (`Packages/CraftUIKit`) is the design-system package that owns all visual primitives. `VocabCraftApp/Core/DesignSystem/VocabTheme.swift` bridges app-level theming to Views. No View should hardcode colors, fonts, spacing, or radii; styling flows through `CraftTheme` tokens and CraftUIKit components.

## Entrypoints

- **Theme protocol**: `CraftTheme` (`Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift`) is the single contract for tokens. It exposes `colors`, `typography`, `spacing`, `radii`, `shadows`, `gradients`, `animations`, `opacities`, `depths`, `glass`, and `journeySurfaceStyle`. The `depths`, `glass`, and `journeySurfaceStyle` members have protocol-extension defaults.
- **Theme manager**: `CraftThemeManager.shared` (`Tokens/CraftThemeManager.swift`) is a `@MainActor` observable that stores `currentPreset` in `UserDefaults` under `app_theme_preset` and derives `preferredColorScheme`. It falls back to `.editorial` when no preset is saved.
- **Preset catalog**: `CraftThemePreset` (`Tokens/CraftThemePreset.swift`) lists eleven presets: `kyotoMatcha`, `aiAcoustic`, `oxfordHeritage`, `solarMomentum`, `tactileClay`, `editorial`, `neoArcade`, `nordicZen`, `playfulOwl`, `smartCoach`, and `classic`. Each has a `displayName`, a `subtitle`, and a `theme` property that returns a `CraftTheme` instance.
- **Component catalog**: `CraftCatalogView` previews atoms and molecules for review.

## Mechanisms and Control Flow

- **Token hierarchy**: Semantic token types (`CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`, `CraftGradientTokens`, `CraftAnimationTokens`, `CraftOpacityTokens`, `CraftDepthTokens`, `CraftGlassTokens`) are value types resolved per theme. Each file in `Tokens/Themes/` (for example `CraftKyotoMatchaTheme`, `CraftNeoArcadeTheme`, `CraftSmartCoachTheme`) supplies one preset's values.
- **Surface styles**: `CraftSurfaceStyle` has five cases, `flat`, `elevated`, `outlined`, `tactile3D`, and `glass`. It is propagated through the `craftSurfaceStyle` environment key. `CraftTheme.surfaceStyle` resolves to `journeySurfaceStyle` by default.
- **Component groups**: Containers live under `Components/Containers/`:
  - `LearningPath/` holds `CraftLearningPath`, lesson nodes and rows, the snake path geometry, and the unlock surge animation.
  - `FluidJourney/` holds `CraftFluidJourney`, journey nodes, milestone pills, the pinned unit header, and the unit drawer sheet.
  - `Cards/` holds `CraftCard`, `CraftActionCard`, `CraftFlipCard`, `CraftListRow`, and `CraftEmptyState`.
  - `Streak/` holds `CraftStreakCard`, `CraftStreakBadge`, `CraftStreakCelebrationSheet`, and the streak models.
  - Other containers are `Activity/`, `Header/`, `Progress/`, and `VoiceMatch/`.
- **Modifiers**: `CraftSurfaceModifier`, `TypographyModifier`, `CraftMotionGuardModifier` (Reduce Motion compliance), `CraftSquashAndStretchModifier`, `PressEffectModifier`, and `ShimmerModifier` enforce token usage and motion rules.
- **App wiring**: `VocabCraftApp.body` applies `.craftTheme(themeManager.currentPreset.theme)` and `.preferredColorScheme(themeManager.preferredColorScheme)`.

## Upstream / Downstream Relationships

- **Upstream**: `CraftThemeManager` (backed by `UserDefaults`) selects the active preset. The app's settings screens write the preset through it.
- **Downstream**: Feature Views import `CraftUIKit` and compose its atoms and containers. Feature code should not define duplicate primitives. AGENTS.md requires discussion before creating app-level replacements for a missing CraftUIKit component.

## State, Persistence, Ordering

The selected preset is persisted by `CraftThemeManager` under `app_theme_preset`. `CraftThemeManager` is a `@MainActor` singleton observed at the root view, and changes propagate through the environment. Theme and surface values are read at render time, so switching presets does not require a restart.

## Invariants and Failure Behavior

- Hardcoded styling is rejected in review. SwiftLint custom rules flag raw values such as `Color.red`.
- An unknown or missing stored preset falls back to `.editorial`.
- Protocol-extension defaults keep `depths`, `glass`, and `journeySurfaceStyle` available for presets that do not override them.
- Motion-heavy modifiers must respect Reduce Motion through `CraftMotionGuardModifier`.

## Configuration

Presets are selected from `CraftThemePreset.allCases`, and each preset's `subtitle` documents its typography and palette pairing. Adding a preset means adding a `CraftTheme` implementation under `Tokens/Themes/`, a new enum case with `displayName`, `subtitle`, and `theme`, and a catalog entry.

## Extension Seams

- Add a preset by conforming a new type to `CraftTheme` and wiring it into `CraftThemePreset`.
- Add a component under `Components/Atoms`, `Containers`, `Controls`, `Feedback`, `Navigation`, or `Overlays`, and expose it in the catalog.
- Add a surface treatment by extending `CraftSurfaceStyle` and its rendering modifier.

## Representative Tests

- `ThemeTests.swift` and `TokenTests.swift` in `Packages/CraftUIKit/Tests/CraftUIKitTests` verify token resolution.
- `CraftStreakComponentTests.swift` and `CraftLearningPathTests.swift` verify component rendering for the streak and learning-path containers.
