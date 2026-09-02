---
type: feature
title: Settings and Profile
description: SettingsViewModel, UserSettingsStore, theme control, HeroProfileCard, and progress reset.
tags: ["settings", "profile", "themes", "feature"]
verified:
  - by: openwiki/0.5.0
    at: 2026-09-02T08:37:35.164Z
sources:
  - id: openwiki-source-370f9c966918439f3edd8b1a
    resource: repo://VocabCraftApp/Core/Database/UserSettingsStore.swift
  - id: openwiki-source-bcf4f9c842cb478e4eecab25
    resource: repo://VocabCraftApp/Features/Settings/ViewModels/SettingsViewModel.swift
  - id: openwiki-source-616335c18d21111f0df9318d
    resource: repo://VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift
generated: { by: "opencode", at: "2026-09-02T08:32:17.625Z" }
---

## Responsibility

Manages user preferences (theme, accent, TTS voice, notifications), displays profile hero and stats, and allows resetting progress.

## Entrypoints

- **View**: `Features/Settings/Views/SettingsView.swift` + `Components/{HeroProfileCard, ProfileStatsSheet}.swift`.
- **ViewModel**: `Features/Settings/ViewModels/SettingsViewModel.swift` — `@Observable`.
- **Store**: `Core/Database/UserSettingsStore.swift`.
- **Theme**: `Core/DesignSystem/VocabTheme.swift`, `CraftUIKit/Tokens/CraftThemeManager.swift`.
- **Use case**: `Domain/UseCases/ResetUserProgressUseCase.swift`.

## Mechanisms

- **Store**: `UserSettingsStore` wraps `UserDefaults` + `@AppStorage` for themePreset, accent, speech rate, streak, onboardingCompleted, etc.; publishes via `@Observable`.
- **ViewModel**: Exposes store bindings plus `ttsService` preview (speak sample phrase) and `resetProgressUseCase.execute()` which clears `UserWordProgress` / `UserStageProgress` via `SRSRepository` / actor.
- **Hero card**: `HeroProfileCard` displays avatar, streak flame, XP, level derived from total mastered words + completed stages; taps show `ProfileStatsSheet` with `CraftStreakCard` + activity tracker.
- **Theming**: Settings row lists all `CraftThemePreset` values; selection updates `CraftThemeManager.currentPreset` which triggers root view recomposition.
- **Localization**: Strings via `AppStrings+Profile` etc., using `String(localized: "app.settings...")`.

## Relationships

- **Upstream**: `UserSettingsStore` → ViewModel → Views; `UserProgressModelActor` → stats.
- **Downstream**: Theme change propagates via environment to all CraftUIKit components.

## State and Lifecycle

ViewModel observed by View; store persists across launches. Reset is confirmed via `CraftDialog`; on success shows toast and resets streak.

## Invariants

- `UserSettingsStore` defaults safe without prior launch; unknown preset falls back to default.
- Reset is destructive and requires explicit confirmation; afterwards homepage reflects empty progress.

## Failure

- Store decode failure resets to defaults; TTS preview failure silent.
- Repository reset failure surfaces as error toast, not crash.

## Configuration

Themes enumerated in `CraftThemePreset`; adding theme auto-appears in settings picker.

## Extension

Add setting row by extending store property + ViewModel binding + SettingsView section.

## Tests

- `SettingsViewTests.swift`, `SettingsViewModelTests.swift`, `SettingsLocalizationTests.swift`, `UserSettingsStoreTests.swift`, `DesignSystem/VocabThemeTests.swift`.
