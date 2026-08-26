# Localization & Text Rendering Rules

> [!IMPORTANT]
> **Zero Hardcoded Strings Policy**: Never hardcode raw user-facing English or Vietnamese string literals directly in SwiftUI view bodies, component initializers, fallback logic, or Accessibility modifiers (`.accessibilityLabel`, `.accessibilityHint`, `.accessibilityValue`). All displayed text must be defined in `Localizable.xcstrings`.

## 1. Key Naming Taxonomy Standard
All localization keys must strictly adhere to the hierarchical, dot-separated lowercase `snake_case` format:

$$\text{craft} \ . \ \langle\text{scope}\rangle \ . \ \langle\text{element/context}\rangle \ . \ \langle\text{role/state/a11y}\rangle$$

### Key Scopes:
1. **`craft.common.action.*`**: Shared user actions (`confirm`, `cancel`, `close`, `dismiss`, `continue`, `retry`, `action`).
2. **`craft.common.state.*`**: Generic component and progression states (`loading`, `empty`, `on`, `off`, `completed`, `active`, `locked`, `upcoming`).
3. **`craft.common.unit.*`**: Quantities and units (`days_format`, `days_single`, `minutes_format`, `words_format`, `percent_format`, `percent_word_format`).
4. **Component Scopes**:
   - `craft.button.*`: Button-specific strings (`loading_a11y`).
   - `craft.choice.*`: Choice card states (`selected_a11y`, `correct_a11y`, `wrong_a11y`, `disabled_a11y`).
   - `craft.search.*`: Search bar elements (`placeholder`, `clear_a11y`, `trailing_action_a11y`).
   - `craft.stepper.*`: Stepper controls (`decrease_a11y`, `increase_a11y`, `default_label`).
   - `craft.textfield.*`: Text fields (`show_password_a11y`, `hide_password_a11y`).
   - `craft.flipcard.*`: Flip cards (`flip_to_front_action`, `flip_to_back_action`, `front_side_hint`, `back_side_hint`).
   - `craft.progress.*`: Progress bar / ring labels (`label`).
   - `craft.segmented_bar.*`: Segmented metric bars (`label_a11y`, `segment_fallback`).
   - `craft.step_node.*`: Step progression nodes (`step_format`, `tap_hint`).
   - `craft.streak.*`: Streak tiers, counters, and celebration modals (`tier_starter`, `tier_blaze`, `tier_legendary`, `best_record_format`, `freeze_shield_format`, `day_inspect_hint`, `celebration_title`, etc.).
   - `craft.learning_path.*`: Learning paths & journey nodes (`empty_title`, `empty_desc`, `continue_callout`, `start_lesson`, `continue_lesson_format`, `review_lesson_format`, `node_completed_a11y`, `tap_to_start_hint`, `default_objective_1/2/3`, etc.).
   - `craft.tab_bar.*`: Floating tab bars (`badge_count_format`, `center_action_fallback`).
   - `craft.waveform.*`: Audio visualizer (`recording_active_a11y`, `visualizer_a11y`, `audio_level_format`).
   - `craft.countdown.*`: Countdown overlays (`label_format`, `go_text`).
   - `craft.sparkle.*`: Particle bursts in reduce-motion mode (`sparkle_label`, `celebration_label`).

---

## 2. Mandatory 100% Bilingual Parity (EN & VI)
Whenever creating or updating strings in `Localizable.xcstrings`:
- **Both `en` and `vi` MUST be populated** with accurate translations.
- **No cross-language pollution**: Never place Vietnamese text under `en` or leave English placeholder text under `vi`.
- **Format specifier parity**: Format tokens (`%lld`, `%@`, `%%`) must match exactly between languages.
- **Maintain manual extraction**: Ensure entries use `extractionState: "manual"` and `state: "translated"` to prevent Xcode String Catalog auto-extraction from creating un-namespaced duplicate keys.

---

## 3. How to Render Text in Code
- In `CraftUIKit`, access localized text programmatically using `CraftLocalized`:
  ```swift
  // Simple string
  let label = CraftLocalized.string("craft.common.action.confirm")

  // Formatted string with specifiers
  let duration = CraftLocalized.format("craft.common.unit.minutes_format", 15)
  ```
- For SwiftUI views supporting `LocalizedStringKey`, pass keys with `bundle: .module` or resolve via `CraftLocalized`.
- For domain content (titles, subtitles, custom objectives), allow caller injection via properties while providing `CraftLocalized` defaults as fallback.

---

## 4. Verification Requirement
Before finalizing any code change:
- Run `swift test --filter LocalizationTests` and verify 0 failures.
- Run `swift test` across all suites to confirm no regressions.
