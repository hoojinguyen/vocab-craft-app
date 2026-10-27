---
type: feature
title: Settings and Profile
description: The settings tab's sections (learning goals, audio and speech, AI configuration, appearance, data and storage, about), the UserSettingsStore keys behind them, the profile hero card and stats sheet, and the reset actions.
tags: ["settings", "profile", "user-settings", "userdefaults", "preferences"]
verified:
  - by: openwiki/0.7.2
    at: 2026-10-26T17:49:24.607Z
sources:
  - id: openwiki-source-370f9c966918439f3edd8b1a
    resource: repo://VocabCraftApp/Core/Database/UserSettingsStore.swift
  - id: openwiki-source-bcf4f9c842cb478e4eecab25
    resource: repo://VocabCraftApp/Features/Settings/ViewModels/SettingsViewModel.swift
  - id: openwiki-source-616335c18d21111f0df9318d
    resource: repo://VocabCraftApp/Features/Settings/Views/Components/HeroProfileCard.swift
generated: { by: "claude-code", at: "2026-10-26T17:49:24.607Z" }
---

## Responsibility

The settings tab lets the learner set goals and reminders, choose the voice and speech options, pick the AI provider and keys, choose the theme and language, and reset data. The profile card at the top summarizes progress and opens a stats sheet.

## Entrypoints

- **Screen**: `SettingsView` (`VocabCraftApp/Features/Settings/Views/SettingsView.swift`) groups its content into sections: learning and goals, audio and speech, AI configuration, appearance and feedback, data and storage, and about and system. The AI section and the data section are private computed views in the same file.
- **Profile**: `HeroProfileCard` and `ProfileStatsSheet` (`Features/Settings/Views/Components`). They compose CraftUIKit streak and activity components.
- **ViewModel**: `SettingsViewModel` (`Features/Settings/ViewModels/SettingsViewModel.swift`) is `@Observable`. It is created by `AppContainer.makeSettingsViewModel()`.
- **Store**: `UserSettingsStore` (`VocabCraftApp/Core/Database/UserSettingsStore.swift`) is the single place where settings are read and written.
- **Supporting models**: `AppPermissionNotice` (`VocabCraftApp/Core/Models`) describes permission messages shown in settings, such as for notifications and the microphone.

## Settings Keys

`UserSettingsStore` wraps `UserDefaults`. Each property writes its value in `didSet` or in its setter. Notable properties:

- **Learning**: `dailyGoalCount`, `isNotificationEnabled`, `notificationTimeInterval`, `notificationTime`, `selectedGoalDeckId`, `assessedCefrLevel`, `selectedLearningPathId`, and `saveRoadmapPreferences(...)`.
- **Streak and today**: `currentStreak`, `todayWordsLearnedDate`, and `todayWordsLearned`.
- **Audio and speech**: `ttsVoiceGender`, `ttsSpeed`, `roleplayVoiceId`, `roleplaySpeechRate`, and `roleplaySpeechPitch` (stored as `roleplay_speech_pitch`). `isHapticsEnabled` and `isSoundEffectsEnabled` control feedback.
- **AI**: `selectedAIPackId` (default `AIPackIdentifier.appleDefault`), `geminiApiKey`, and `groqApiKey`. The `isGeminiApiKeyConfigured` and `isGroqApiKeyConfigured` properties check that a trimmed key is not empty.
- **Appearance**: `themePreset` (a `CraftThemePreset`), `appTheme`, `appearanceMode` (a `CraftAppearanceMode`), and `colorScheme`.
- **Language**: `appLanguage` and `appLocale`.
- **Onboarding**: `hasCompletedOnboarding`.

`resetAllSettings()` clears the stored values for these settings.

## Mechanisms

1. **Binding** — Views bind to the store's properties through `$store`, for example `Picker("", selection: $store.themePreset)` and `Picker("", selection: $store.appLanguage)`. Changes write to `UserDefaults` immediately.
2. **Voice preview** — `playAudioPreview()` plays a TTS sample, and `playRoleplayVoicePreview()` plays a roleplay voice sample. `stopRoleplayVoicePreview()` cancels it. Voices are chosen in `RoleplayVoicePickerSheet`.
3. **AI configuration** — The AI section shows the status of the selected AI pack, such as ready, needs an API key, needs a download, or unavailable. The API key fields write to the store, and `AIConfigSheet` is available from the AI tab.
4. **Reset progress** — `resetSRSProgress()` sets `dailyGoalCount` back to 15 and calls the reset use case's `executeResetAllProgress()`. This removes learning progress.
5. **Cache** — `clearCache()` resets the displayed cache size. It does not delete any files.
6. **Profile** — `HeroProfileCard` shows the streak and today's progress. `ProfileStatsSheet` shows longer-term stats from the activity components.

## Relationships

- **Upstream**: `AppContainer` owns the `UserSettingsStore` and passes it to `SettingsViewModel`. Some views also get it through the environment.
- **Downstream**: The theme preset feeds `CraftThemeManager` ([Design System](../architecture/design-system.md)). Speech settings feed [Audio and Speech](../core/audio-and-speech.md). Learning path choices feed [Homepage and Learning Path](homepage-and-learning-path.md).
- **Localization**: The language setting is described in [Localization and Theming](../operations/localization-and-theming.md).

## State and Lifecycle

- Each change is written to `UserDefaults` as soon as it is set. There is no separate save step.
- `UserSettingsStore` also takes `hasPersistedAppData` when it is created. See [Persistence](../core/persistence.md).

## Invariants

- The theme and language values always resolve to a valid preset or locale. An unknown stored value falls back to the default.
- Reset actions are explicit and separate from normal setting changes.

## Failure

- A failed reset is ignored, since the reset use case call uses `try?`.
- Missing API keys do not block the app. The AI section shows the setup state instead.

## Security Notes

- The Gemini and Groq API keys are written to `UserDefaults` under `gemini_api_key` and `groq_api_key`. `UserDefaults` is not encrypted storage. The codebase does not use the Keychain for these values.
- Anyone with access to the app's preferences file can read these keys.

## Configuration

- The default AI pack is `AIPackIdentifier.appleDefault`.
- `resetSRSProgress()` sets the daily goal to 15.
- The theme preset and language are stored by their raw values.

## Extension

- Add a setting by adding a key and a computed property to `UserSettingsStore`, then bind it in a `SettingsView` section.
- Add a profile metric by extending `ProfileStatsSheet`.

## Tests

- `VocabCraftAppTests/App/AppContainerAITests.swift` covers the AI container wiring that the settings AI section depends on.
