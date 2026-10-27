---
type: operations
title: Localization and Theming
description: How user-facing text is localized (two string catalogs, the AppStrings accessor layer, English and Vietnamese parity) and how the app theme is chosen and bridged to CraftUIKit tokens (theme presets, color scheme, and VocabTheme).
tags: ["localization", "xcstrings", "i18n", "theming", "tokens", "appstrings"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-8c3760bc6b7d8ceb5c767277
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Environment/CraftLocalized.swift
  - id: openwiki-source-d4bbcd823cc1f1055b920417
    resource: repo://Packages/CraftUIKit/Sources/CraftUIKit/Tokens/CraftThemeManager.swift
  - id: openwiki-source-71661d79da6d20d09e06bcfd
    resource: repo://VocabCraftApp/App/VocabCraftApp.swift
  - id: openwiki-source-40f1f51183c08786fc4e0faa
    resource: repo://VocabCraftApp/Core/Localization/AppStrings%2BGuidedPractice.swift
  - id: openwiki-source-5709eb0ab358a7a151ff3edd
    resource: repo://VocabCraftApp/Resources/Localizable.xcstrings
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

Two rules apply across the app. All user-facing text comes from a localized string catalog, never from a hardcoded literal, and all color, font, spacing, and radius values come from theme tokens. This page describes the mechanism behind both rules. The policy is in `AGENTS.md` sections 3 and 4.

## Entrypoints

**Localization**

- **String catalogs**:
  - `VocabCraftApp/Resources/Localizable.xcstrings` is the app catalog. It holds several hundred keys, mostly `app.*` and feature keys, each with `en` and `vi` values.
  - `Packages/CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` is the CraftUIKit catalog, which holds the `craft.*` keys.
- **Accessors**:
  - `AppStrings` (`VocabCraftApp/Core/Localization/AppStrings.swift`) is an enum of static properties and functions. It has feature extensions: `AppStrings+GuidedPractice`, `AppStrings+Lesson`, `AppStrings+Practice`, `AppStrings+Profile`, `AppStrings+ReflexBlitz`, and `AppStrings+Vault`. Each value is read with `String(localized:defaultValue:bundle: .module)`.
  - `AppLocalized` (`VocabCraftApp/Core/Localization/AppLocalized.swift`) reads the catalog directly for a given language or locale. It uses the module bundle when present and the main bundle otherwise.
  - `CraftLocalized` (`Packages/CraftUIKit/Sources/CraftUIKit/Environment/CraftLocalized.swift`) reads the CraftUIKit catalog from its own module bundle. It offers `string(_:)`, language- and locale-specific variants, and `format(_:_:)` helpers.

**Theming**

- **Theme protocol**: `CraftTheme` and its token types live in `Packages/CraftUIKit/Sources/CraftUIKit/Tokens`. See [Design System](../architecture/design-system.md).
- **Presets**: `CraftThemePreset` in CraftUIKit lists eleven presets, and each one returns its `CraftTheme`.
- **Selection**: `CraftThemeManager` (CraftUIKit) stores the chosen preset in `UserDefaults` under `app_theme_preset`, and it exposes `preferredColorScheme`.
- **App bridge**: `VocabTheme`, `VocabColorTokens`, and `VocabGradientTokens` (`VocabCraftApp/Core/DesignSystem/VocabTheme.swift`) let the app supply its own token values to the CraftUIKit environment.
- **Root wiring**: `VocabCraftApp` applies `.craftTheme(themeManager.currentPreset.theme)` and `.preferredColorScheme(themeManager.preferredColorScheme)`.

## Key Naming

- **AppStrings keys** mostly follow `<feature>.<element>`, for example `common.confirm`, `vocabulary.wordsMasteredCountLabel`, and `reflex.quickProgressSegment`. Placeholders use format specifiers (`%lld`, `%%`).
- **Newer keys** follow `app.<feature>.<screen>.<element>`, for example `app.ai_assistant.guided.hub.title`. The Guided Practice strings use this form.
- **CraftUIKit keys** use the `craft.<scope>.<element>` form.
- The string catalogs record `extractionState` as `manual` and keep `en` and `vi` entries. The source language is `vi`.

## Mechanisms

1. **Read a string** — A view calls an `AppStrings` property, which calls `String(localized:)` against the module bundle. The catalog returns the value for the current language.
2. **Format a string** — Parameterized strings use `String(format:)` with a localized format key, such as `vocabulary.wordsMasteredCountLabel` with `%lld/%lld`.
3. **Pick the theme** — The learner chooses a preset in settings. `CraftThemeManager` saves it and publishes the new `CraftTheme`. The root view applies it to the environment, and every CraftUIKit component reads its tokens from there.
4. **Color scheme** — `preferredColorScheme` follows the learner's appearance setting. Presets provide light and dark token values.

## Relationships

- **Upstream**: Settings chooses the language (`appLanguage`) and the theme (`themePreset`). See [Settings and Profile](../features/settings-and-profile.md).
- **Downstream**: All feature views consume strings and tokens. Lint rules flag hardcoded strings and raw colors. See [Build, Test and Quality](build-test-and-quality.md).

## State and Lifecycle

- The theme choice is stored in `UserDefaults`, and the root view reads it when the app starts.

## Invariants

- Catalog entries are kept in English and Vietnamese. `AppStringsParityTests` checks that the two languages match.
- Optional token groups such as `depths` and `glass` fall back to protocol defaults.

## Failure

- A missing key falls back to the `defaultValue` passed to `String(localized:)`.
- An unknown stored preset falls back to `.editorial`.

## Configuration

- The source language is Vietnamese (`sourceLanguage: vi`), with English as the second language.
- The stored theme key is `app_theme_preset`.

## Extension

- Add text by adding a key to `AppStrings` (or a feature extension), then adding its `en` and `vi` values to the catalog.
- Add a preset by implementing `CraftTheme`, then adding a `CraftThemePreset` case with its name, subtitle, and theme.

## Tests

- `VocabCraftAppTests/Localization/AppStringsParityTests.swift` checks that the English and Vietnamese catalogs have matching keys.
- Feature localization tests live beside each feature, for example `VocabCraftAppTests/Features/PersonalVaultLocalizationTests.swift`, `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`, and `VocabCraftAppTests/Reflex/ReflexLocalizationTests.swift`.
- `VocabCraftAppTests/Localization/ShadowingLocalizationTests.swift` and `VocabCraftAppTests/Resources/LocalizationTests.swift` cover the shadowing and general strings.
