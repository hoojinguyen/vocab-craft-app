---
type: operations
title: Localization and Theming
description: Two-layer xcstrings architecture, key taxonomy, bilingual parity, and CraftUIKit token theming.
tags: ["localization", "theming", "l10n", "craftuikit"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-8c3760bc6b7d8ceb5c767277
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Environment/CraftLocalized.swift
  - id: openwiki-source-fa8d6cb00d00a73d3caf2a29
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings
  - id: openwiki-source-e91d13f778505d16cab6a89c
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftTheme.swift
  - id: openwiki-source-abf3e845abe198398a45f49f
    resource: repo://VocabCraftApp/Core/DesignSystem/VocabTheme.swift
  - id: openwiki-source-7c8d1c1bea26fb13282b1400
    resource: repo://VocabCraftApp/Core/Localization/AppStrings.swift
  - id: openwiki-source-5709eb0ab358a7a151ff3edd
    resource: repo://VocabCraftApp/Resources/Localizable.xcstrings
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Manages bilingual EN+VI strings across design system and app, and bridges localization to theming via tokens.

## Entrypoints

- **Layer 1 — CraftUIKit**: `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` + `CraftUIKit/Environment/CraftLocalized.swift` (via `Bundle.module`, `CraftLocalized.string/format`).
- **Layer 2 — VocabCraftApp**: `VocabCraftApp/Resources/Localizable.xcstrings` + `Core/Localization/{AppStrings, AppStrings+*}.swift` (via `Bundle.main`, `String(localized:)`).
- **Tokens**: `Tokens/{CraftColorTokens, CraftTypographyTokens, CraftSpacingTokens, CraftRadiusTokens, CraftShadowTokens, CraftGlassTokens, ...}` + `CraftTheme` presets.

## Mechanisms

- **Taxonomy**:
  - `craft.*`: `craft.<scope>.<element>.<role>` e.g., `craft.common.action.confirm`, `craft.button.*`, `craft.flipcard.*`, `craft.streak.*`.
  - `app.*`: `app.<feature>.<screen>.<element>.<role>` e.g., `app.onboarding.*`, `app.study.*`, `app.reflex.*`, `app.settings.*`.
- **Rendering**:
  - Inside CraftUIKit: `CraftLocalized.string("craft.button.confirm")`.
  - Inside VocabCraftApp: `LocalizedStringKey` or `String(localized: "app.settings.theme.title")` (facaded via `AppStrings`).
- **Bilingual parity** (AGENTS.md §4.4): Both `en` and `vi` must exist, non-empty, not mixed; format specifiers (`%lld`, `%@`) match exactly; `extractionState: manual`, `state: translated`.
- **Theming**: `CraftTheme` aggregates all tokens; `CraftThemeManager` holds `currentPreset`; `VocabTheme.swift` maps `UserSettingsStore.themePreset` to `CraftTheme`.

## Relationships

- **Upstream**: Design tokens feed both layers; string keys referenced directly in Views for VoiceOver too (`.accessibilityLabel` must be localized).
- **Downstream**: `Forge` scripts and lint verify taxonomy; missing key fallback shows key string rather than crash.

## State and Lifecycle

Strings are bundled resources, loaded at launch; theme preset persisted in `UserSettingsStore`. Changing language requires app relaunch; theme change is live via environment.

## Invariants

- Zero hardcoded strings in View bodies, ViewModels, component initializers, or accessibility modifiers — enforced by lint/review.
- No cross-language mixup; every key has EN and VI entry.
- Format specifiers parity strictly checked.

## Failure

- Lint test `LocalizationTests` fails if taxonomy violated or parity broken.
- Missing translation shows key; malformed format specifier crashes at runtime → prevented by parity check.

## Configuration

Edit `*.xcstrings` directly or via Xcode Strings Catalog; never invent raw literal. Add new preset by adding theme file under `Tokens/Themes/`.

## Extension

Add feature strings under `app.<feature>.*`; add component strings under `craft.<component>.*`. Add theme by conforming to `CraftTheme`.

## Tests

- `LocalizationTests.swift` (CraftUIKit), `PracticeSelectionLocalizationTests.swift`, `PersonalVaultLocalizationTests.swift`, `ReflexLocalizationTests.swift`, `SettingsLocalizationTests.swift` all assert bilingual completeness and no hardcoded literals.
