# Design Spec: Widget Visual Redesign ("Deep Flashcard")

- **Date**: 2026-10-25
- **Status**: Draft — awaiting user review
- **Topic**: Give the VocabCraft widget a richer, more crafted visual design, plus the two data points the new design needs (part of speech, today's practice progress)
- **Branch**: `feat/home-widget-learning` (builds on the home widget learning work, spec `2026-10-23-home-widget-learning-design.md`)
- **Target Platforms**: iOS 17.0+ widget extension; macOS keeps compiling (systemSmall/systemMedium only)

---

## 1. Context & Goals

### 1.1 Intent (agreed with user)
The widget works but feels too plain. The user wants it to look intentionally designed, closer to a physical flashcard with depth, while staying glanceable. Direction chosen: **"Flashcard có chiều sâu"** (brand gradient background, large title-style lemma, part-of-speech chip, progress indicator, large pill buttons). Scope chosen: **UI + new data** (not UI-only).

### 1.2 Current state (verified in code, 2026-10-25)
- `VocabCraftWidgetExtension/VocabWidgetView.swift` renders every family on a flat `surfaceCard` background with small `CraftBadge` chips, caption-size text and small rounded-rect action buttons.
- `WidgetCard` (`VocabCraftApp/Core/Widget/WidgetDeck.swift`) has `wordId, lemma, ipa, definitionVi, exampleEn, source`. `WidgetDeck.currentVersion == 1`.
- `TopicWordDTO.pos` already carries the part of speech from `senses.part_of_speech` (values: `noun, verb, adjective, adverb, pronoun, preposition, conjunction, determiner`). `WidgetDeckComposer.card(...)` drops it today.
- `VocabWidgetEntry` has `date, card, mode, dueCount`. There is no per-day progress figure.
- `UserWordProgress.lastReviewDate` is set both when a word is first learned and on every review (`UserProgressModelActor+Mutations`, `WidgetReviewRecorder`).
- CraftUIKit exposes `theme.gradients.brandHero`, `surfaceGlass`, `fadeBottom` and color tokens incl. `textInverse`, `statusSuccess`, `statusDanger`.

### 1.3 Success criteria
1. Every family/mode in §3.2 renders with the new visual language in full-color mode and remains legible in accented (tinted) and vibrant (Lock Screen) modes.
2. The part-of-speech chip appears whenever the card has a part of speech, localized EN + VI.
3. Flashcard modes show today's progress (`practicedToday / (practicedToday + dueCount)`); the passive footer shows `practicedToday`.
4. Lemma text has WCAG AA contrast (≥ 4.5:1 for body, ≥ 3:1 for the large lemma) against the background in the Default, Oxford Heritage and Neo Arcade themes in light and dark.
5. Only CraftUIKit tokens and `app.widget.*` strings are used (AGENTS.md §3.2). No hardcoded colors, fonts, paddings or radii.
6. Existing widget behaviour (rotation, reveal, grade, deep links, reload policies) is unchanged; existing widget tests still pass.

### 1.4 Out of scope
New widget families, configurable widgets, audio pronunciation, streak display, changes to word selection or SRS scheduling.

---

## 2. Data Changes

### 2.1 Part of speech on the card
```swift
public struct WidgetCard {
    // existing fields…
    public var partOfSpeech: String?   // raw value from senses.part_of_speech; nil when empty
}
```
- `WidgetDeckComposer.card(...)` maps `word.pos` → `partOfSpeech` (empty string → `nil`).
- `WidgetDeck.currentVersion` becomes **2** and is what the app writes. `WidgetDeck.minimumSupportedVersion` is **1**: `WidgetDeckStore` still loads v1 decks (they only lack the optional `partOfSpeech`), so existing learners keep seeing their words until the app rewrites the deck. Versions below 1 or above `currentVersion` yield `nil`. (Rejecting v1 would have blanked the widget for returning learners with the first-lesson empty-state copy.)
- `partOfSpeech` is optional so decoding never fails on a missing key.

### 2.2 Today's practice count on the entry
```swift
public struct VocabWidgetEntry {
    // existing fields…
    public let practicedToday: Int
}
```
- New query `WidgetDueQuery.practicedCount(since: Date, in: ModelContext) -> Int` counts **all** `UserWordProgress` rows (not only deck words) with `lastReviewDate >= since` **and `totalReviews > 0`**, so bookmark-only rows (inserted with a default `lastReviewDate` and no reviews) do not count. Uses `fetchCount`.
- `VocabWidgetProvider.makeTimeline` passes `since = Calendar.current.startOfDay(for: now)` and forwards the count into `WidgetTimelineBuilder.build(…, practicedToday:)`, which stamps it on every entry. Errors or a `nil` container → `0`.
- Because `lastReviewDate` is also set when a word is first learned, the figure means "words practiced today" (learned or reviewed). UI copy says "practiced", not "reviewed".
- Entries carry a fixed count, so `WidgetTimelineBuilder` stops the passive timeline at the next local midnight and caps the flashcard refresh at midnight too (`reload = .after(min(…, midnight))`); the next reload rebuilds the count for the new day.

### 2.3 Progress helper
Pure static function on the view (unit-tested):
```swift
static func progress(practiced: Int, due: Int) -> (fraction: Double, filledDots: Int)
// total = practiced + due; total == 0 → (0, 0)
// fraction = practiced / total; filledDots = round(fraction * 5), clamped 0…5
```

---

## 3. UI

### 3.1 Visual language
| Element | Full-color | Accented / vibrant |
|---|---|---|
| Background | `containerBackground(theme.gradients.brandHero)`, plus `fadeBottom` scrim behind the text block if contrast check fails (§5) | system default (no gradient) |
| Depth glyph | First grapheme of the lemma in `theme.typography.displayHero`, enlarged with `scaleEffect` (×3 small, ×4 medium; no hardcoded point sizes), `textInverse` at 8% opacity, rotated −12°, anchored bottom-trailing, clipped. `accessibilityHidden(true)` | hidden |
| Lemma | `theme.typography.titleLarge` in small and medium (`displayLarge` did not fit a 158 pt-tall medium widget next to the button row), `titleMedium` on the flashcard back and when the small layout is compact, `textInverse`, `minimumScaleFactor(0.6)`, `widgetAccentable()` | accentable |
| POS chip | Capsule, `surfaceGlass` fill, caption text, localized abbreviation (`n.`, `v.`, `adj.`…) | stroke only |
| IPA | `theme.typography.phonetic`, `textInverse` 75% opacity, after the chip on the same line | default secondary |
| Accent bar | 24×3 capsule, `theme.colors.accent` | accentable |
| Source chip | Same capsule style as POS chip, with symbol (`sparkles` = New, `refresh` = Review) | stroke only |
| Buttons | Full-width capsules, min height 36 pt, `surfaceGlass` fill; Remembered uses `statusSuccess` icon/text, Forgot uses `statusDanger`, Reveal uses `textInverse` | stroke capsule, accentable icons |
| Progress dots | 5 dots, 6 pt, filled = `textInverse`, empty = `textInverse` 30% | accentable filled dots |

Motion: `.contentTransition(.numericText())` on counts; the card container gets `.id(card.wordId)` + `.transition(.push(from: .trailing))` so reveal/grade/rotation animate; masked→revealed definition uses `.transition(.opacity)`.

### 3.2 Layouts

**Fitting (small and medium).** Both layouts use `ViewThatFits(in: .vertical)` and drop decoration in a fixed order until the content fits a 158 pt-tall widget. Small: accent bar → IPA/POS row → (compact lemma) → the header row last, because the header carries the source chip and the progress. Medium: accent bar → source chip → one definition line. The definition and the progress indicators are the last things to go.


**systemSmall**
- *Passive*: top row source chip + a compact practice badge (checkmark and number; VoiceOver reads `app.widget.practiced_today_format`, "Hôm nay: %d từ"); lemma; POS chip · IPA; accent bar; definition (up to 3 lines).
- *Front*: top row source chip + progress dots; lemma; POS chip · IPA; accent bar; a redacted placeholder bar (two rounded capsules at 30% opacity) labelled for VoiceOver with `app.widget.hidden_meaning`; Reveal capsule.
- *Back*: lemma (one step smaller); accent bar; definition (3 lines); icon-only Forgot ✗ / Remembered ✓ capsules side by side.

**systemMedium** — two columns, 55 / 45.
- Left (all modes): source chip, lemma, POS chip · IPA, accent bar, definition (passive/back) or placeholder bar (front).
- Right: a `surfaceGlass` rounded card (radius `theme.radius.lg`) with the example in `bodySerif`. On the front, the masked lemma renders as a highlighted capsule (`accent` at 35%) instead of `_____`; VoiceOver keeps reading the masked form.
- Bottom row (flashcard only): front = Reveal capsule + `3/5` progress text; back = labelled Forgot / Remembered capsules.

**accessoryRectangular**
- Passive: lemma (headline, accentable); `n. · /ipa/`; definition (1 line).
- Flashcard: HStack of lemma + "Open to review" hint, with a trailing `Gauge(value: fraction)` `.gaugeStyle(.accessoryCircularCapacity)` showing `practicedToday` inside. Deep link unchanged.

**accessoryInline**
- Passive: `lemma (n.): definition`.
- Flashcard: `app.widget.inline_progress_format` → `3/5 · 2 to review`.

**Empty**: gradient background, large `sparkles` icon, title `app.widget.empty.title`, new subtitle `app.widget.empty.subtitle` ("Start your first lesson"). Deep link unchanged.

### 3.3 Code structure
`VocabWidgetView.swift` is already ~300 lines; the redesign splits it:
| File | Contents |
|---|---|
| `Views/VocabWidgetView.swift` | Entry point, family/mode switch, container background |
| `Views/WidgetCardComponents.swift` | `WidgetChip`, `WidgetAccentBar`, `WidgetDepthGlyph`, `WidgetProgressDots`, `WidgetPillButtonLabel`, `WidgetHiddenMeaningBar`, `MaskedExampleText` |
| `Views/WidgetSystemViews.swift` | Small and medium layouts |
| `Views/WidgetAccessoryViews.swift` | Rectangular and inline layouts (`#if os(iOS)`) |
| `Views/WidgetPartOfSpeech.swift` | Maps raw POS → localized abbreviation key |

Each component reads `widgetRenderingMode` itself to drop fills in non-full-color modes.

### 3.4 Strings (EN / VI) in `Localizable.xcstrings`
`app.widget.pos.noun|verb|adjective|adverb|pronoun|preposition|conjunction|determiner` (`n./v./adj./adv./pron./prep./conj./det.` — same abbreviations in VI), `app.widget.practiced_today_format` ("Today: %d words" / "Hôm nay: %d từ"), `app.widget.progress_format` ("%1$d/%2$d"), `app.widget.inline_progress_format` ("%1$d/%2$d · %3$d to review" / "%1$d/%2$d · %3$d từ cần ôn"), `app.widget.empty.subtitle`. Unknown POS values show no chip.

---

## 4. Error Handling
- Missing/old deck → empty state (existing behaviour).
- `practicedCount` throws or no container → `0`; dots and gauge render empty, never crash.
- `total == 0` → progress hidden in small/medium, gauge at 0 on Lock Screen.
- Very long lemmas: `minimumScaleFactor(0.6)` then truncation; glyph uses only the first grapheme.

---

## 5. Testing
- **Unit (Swift Testing)**: `WidgetDeck` v2 round-trip, v1 compatibility, and rejection of versions outside 1…2; composer maps `pos` (incl. empty → nil); `WidgetDueQuery.practicedCount` counts rows on/after start of day and ignores yesterday; timeline builder stamps `practicedToday` on all entries; `progress(practiced:due:)` table test (0/0, 0/5, 3/2, 5/0); `WidgetPartOfSpeech` maps all eight values and returns nil for unknown.
- **Existing tests**: update constructors for the new fields; all `VocabCraftAppTests/Features/Widget` and `WidgetIntentsTests` must pass.
- **Previews**: `#Preview(as: .systemSmall/.systemMedium/.accessoryRectangular/.accessoryInline)` with passive, front, back and empty entries.
- **Visual check**: build to the iOS Simulator, add small + medium + Lock Screen widgets, screenshot in light, dark and tinted, for Default, Oxford Heritage and Neo Arcade themes. If any lemma or definition fails the contrast criterion, add the `fadeBottom` scrim under the text block (one change, all themes) rather than per-theme colors.
- **Lint/build**: SwiftLint clean; app, widget and macOS targets build.

---

## 6. Risks
| Risk | Mitigation |
|---|---|
| Bright `brandHero` gradients make white text unreadable in some themes | Contrast screenshots in §5; scrim fallback |
| The widget may not receive the user's selected theme | Verify during implementation which theme the widget environment resolves; if it is always Default, record that and keep Default as the reference |
| Deck version bump blanks the widget once after update | Deck refreshes on next app background; acceptable |
| Memory limit (~30 MB) with large glyph text | Glyph is plain `Text`, no images |
