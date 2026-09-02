---
type: architecture
title: Design System — CraftUIKit
description: CraftUIKit tokens, themes, and reusable components that enforce the CraftUIKit-first UI discipline.
tags: ["design-system", "craftuikit", "tokens", "swiftui"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-d85caf347254e99d90bcb93d
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Components/Atoms/CraftBadge.swift
  - id: openwiki-source-736f69100069b5d60cb8047c
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Components/Containers/Cards/CraftCard.swift
  - id: openwiki-source-e91d13f778505d16cab6a89c
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift
  - id: openwiki-source-71661d79da6d20d09e06bcfd
    resource: repo://VocabCraftApp/App/VocabCraftApp.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility and Ownership

`CraftUIKit` (`Packages/CraftUIKit`) is the design-system package owning all visual primitives. `VocabCraftApp/Core/DesignSystem/VocabTheme.swift` bridges app-level theming (`CraftThemeManager`) to Views. No View should hardcode colors, fonts, spacing, or radii; all styling flows through `CraftTheme` tokens.

## Entrypoints

- **Theme protocol**: `CraftTheme` (`Tokens/CraftTheme.swift`) exposes `colors`, `typography`, `spacing`, `radii`, `shadows`, `gradients`, `animations`, `opacities`, `depths`, `glass`.
- **Theme manager**: `CraftThemeManager.shared` (Observable) holds `currentPreset` (`CraftThemePreset`) and publishes `preferredColorScheme`.
- **Component catalog**: `CraftCatalogView.swift` previews every atom/molecule.

## Mechanisms and Control Flow

- **Token hierarchy**: Semantic tokens (e.g., `CraftColorTokens`, `CraftTypographyTokens`, `CraftSpacingTokens`, `CraftRadiusTokens`, `CraftShadowTokens`, `CraftGlassTokens`, `CraftDepthTokens`, `CraftGradientTokens`) are value types resolved per theme. Implementations like `CraftDefaultTheme`, `CraftAIAcousticTheme`, `CraftKyotoMatchaTheme` etc. provide preset values.
- **Component reuse**: Atoms (`CraftBadge`, `CraftIcon`, `CraftButton`, `CraftCard`, `CraftFlipCard`, `CraftProgressRing`, `CraftStreakCard`, `CraftLearningPath`, etc.) consume tokens directly. Containers (`CraftLearningPath`, `CraftStreakCard`, `CraftStepProgressIndicator`) encapsulate layout + animation.
- **Modifiers**: `CraftSurfaceModifier`, `TypographyModifier`, `CraftMotionGuardModifier` enforce token usage and Reduce-Motion compliance.
- **App wiring**: `VocabCraftApp.body` applies `.craftTheme(themeManager.currentPreset.theme)` and `.preferredColorScheme`.

## Upstream / Downstream Relationships

- **Upstream**: `CraftThemeManager` + `UserSettingsStore` drive theme selection.
- **Downstream**: All feature Views import `CraftUIKit` and compose atoms; no feature defines duplicate components. If a design requires a missing component, AGENTS.md mandates human discussion before creating app-level Views.

## State, Persistence, Ordering

Theme selection is persisted via `UserSettingsStore`. `CraftThemeManager` is a singleton (`@MainActor`) observed by root view; changes propagate via environment.

## Invariants and Failure Behavior

- Zero raw styling enforced by review rule; SwiftLint custom rules flag hardcoded `Color.red` etc.
- Missing theme preset falls back to default; unknown token access returns sensible defaults via protocol extension defaults (`depths`, `glass`).

## Configuration

Ten theme presets (Default, AI Acoustic, Editorial, Kyoto Matcha, NeoArcade, Nordic Zen, Oxford Heritage, Playful Owl, Smart Coach, Solar Momentum, Tactile Clay) are defined under `Tokens/Themes/`. Selecting a preset swaps entire token set.

## Extension Seams

Add new preset by conforming to `CraftTheme`; add component under `Components/Atoms|Containers|Controls|Feedback|Navigation|Overlays` and expose via catalog.

## Representative Tests

- `ColorTokensTests.swift`, `ThemeTests.swift`, `TokenTests.swift`, `CraftStreakComponentTests.swift`, `CraftLearningPathTests.swift` verify token resolution and component rendering.
