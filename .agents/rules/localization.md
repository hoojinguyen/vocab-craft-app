# Localization & Text Rendering Rules

## 1. Zero Hardcoded Strings Policy (Project-Wide)

> [!IMPORTANT]
> **Strict No-Hardcode Rule**: Never write raw literal English or Vietnamese string literals directly into SwiftUI view bodies, view models, controllers, component initializers, fallback logic, or Accessibility modifiers (`.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue`).
>
> All display text and accessibility content must be declared inside `Localizable.xcstrings` according to the designated layer and taxonomy format.

---

## 2. Two-Layer Localization Architecture

The project enforces a strict two-layer localization architecture with isolated root prefixes and resource scopes:

| Criteria | Layer 1: `CraftUIKit` (Design System Package) | Layer 2: `VocabCraftApp` (Main Application) |
| :--- | :--- | :--- |
| **Root Prefix** | `craft.*` | `app.*` |
| **Catalog Resource** | `CraftUIKit/Sources/CraftUIKit/Resources/Localizable.xcstrings` | `VocabCraftApp/Resources/Localizable.xcstrings` |
| **Bundle & Engine** | `Bundle.module` via `CraftLocalized.string/format` | `Bundle.main` / `LocalizedStringKey` / `String(localized:)` |
| **Content Scope** | UI controls, widget states, token labels, default component VoiceOver | Screen titles, business flows, vocabulary decks, SRS Reflex Drills, Onboarding, Profile, Settings, Notifications |

---

## 3. Key Taxonomy Standards

### 3.1 Layer 1: `CraftUIKit` (`craft.*`)
Format:
$$\text{craft} \ . \ \langle\text{scope}\rangle \ . \ \langle\text{element/context}\rangle \ . \ \langle\text{role/state/a11y}\rangle$$

- **`craft.common.action.*`**: Shared actions (`confirm`, `cancel`, `close`, `dismiss`, `continue`, `retry`, `action`).
- **`craft.common.state.*`**: Progression states (`loading`, `empty`, `on`, `off`, `completed`, `active`, `locked`, `upcoming`).
- **`craft.common.unit.*`**: Units & counts (`days_format`, `days_single`, `minutes_format`, `words_format`, `percent_format`, `percent_word_format`).
- **Component Scopes**:
  - `craft.button.*`, `craft.choice.*`, `craft.search.*`, `craft.stepper.*`, `craft.textfield.*`, `craft.toggle.*`
  - `craft.flipcard.*`, `craft.progress.*`, `craft.segmented_bar.*`, `craft.step_node.*`
  - `craft.streak.*`, `craft.learning_path.*`, `craft.tab_bar.*`, `craft.waveform.*`, `craft.countdown.*`, `craft.sparkle.*`

### 3.2 Layer 2: `VocabCraftApp` (`app.*`)
Format:
$$\text{app} \ . \ \langle\text{feature}\rangle \ . \ \langle\text{screen/flow}\rangle \ . \ \langle\text{element}\rangle \ . \ \langle\text{role/state/a11y}\rangle$$

- **`app.common.*`**:
  - `app.common.nav.*`: Tab bar items (`tab_home`, `tab_study`, `tab_practice`, `tab_profile`).
  - `app.common.error.*`: Network/system errors (`network_unavailable`, `speech_recognition_failed`, `save_failed`).
- **`app.onboarding.*`**: Welcome screens, level assessment, daily study goal selection (`app.onboarding.welcome.title`, `app.onboarding.level_picker.header`, `app.onboarding.daily_goal.cta`).
- **`app.study.*`**: Learning session, flashcards, session complete summary (`app.study.session.flip_hint`, `app.study.session.complete_title`, `app.study.summary.xp_earned_format`).
- **`app.reflex.*`**: SRS Engine, Speed drills, pronunciation checks (`app.reflex.drill.speed_round_title`, `app.reflex.card.listen_and_choose`, `app.reflex.result.accuracy_format`).
- **`app.deck.*` / `app.topic.*`**: Deck management, SubTopics, vocabulary lists (`app.deck.detail.total_words_format`, `app.deck.list.search_placeholder`, `app.deck.empty.title`).
- **`app.streak.*`**: App streak tracking, freeze token store (`app.streak.freeze_used_alert_title`, `app.streak.banner_subtitle`).
- **`app.profile.*` & `app.settings.*`**: Profile info, XP statistics, voice accent, dark mode (`app.settings.voice_accent.title`, `app.profile.stats.words_learned_format`).
- **`app.notification.*`**: Push notifications and local reminders (`app.notification.daily_reminder.title`, `app.notification.streak_freeze.body`).

---

## 4. Mandatory 100% Bilingual Parity (EN & VI)

Whenever adding or updating keys in any `Localizable.xcstrings` catalog (`CraftUIKit` or `VocabCraftApp`):
1. **Full Pair Completeness**: Both `en` and `vi` translations must be completely provided with accurate phrasing. No language branch may be left empty.
2. **Zero Cross-Language Mixup**: Never store Vietnamese text in `en` entries, and never leave English placeholders in `vi` entries.
3. **Format Specifier Parity**: Format tokens (`%lld`, `%@`, `%%`) must match exactly in type, sequence, and count between English and Vietnamese.
4. **Extraction State**: Always set `extractionState: "manual"` and `state: "translated"` for hand-curated keys to prevent Xcode String Catalog auto-extraction from generating duplicate un-namespaced keys.

---

## 5. Text Rendering Conventions

- **Inside `CraftUIKit`**: Use `CraftLocalized`:
  ```swift
  let buttonLabel = CraftLocalized.string("craft.common.action.confirm")
  let formattedTime = CraftLocalized.format("craft.common.unit.minutes_format", 15)
  ```
- **Inside `VocabCraftApp`**: Use `LocalizedStringKey` or `String(localized:)`:
  ```swift
  Text("app.study.session.complete_title")
  let progressText = String(localized: "app.study.summary.xp_earned_format", defaultValue: "Earned %lld XP")
  ```
- **Interaction Between App and CraftUIKit**:
  - When the App renders components from `CraftUIKit`, pass domain content (titles, subtitles, custom objectives) via `LocalizedStringKey` or `String` parameters.
  - `CraftUIKit` components will prioritize display of caller-provided text, only falling back to default localized `craft.*` keys when the parameter is `nil`.

---

## 6. Verification Gate
Before completing any task touching UI text or localization:
- Run `swift test --filter LocalizationTests` (for `CraftUIKit`).
- Run the full project test suite to verify 0 compilation errors and zero format specifier mismatches.
