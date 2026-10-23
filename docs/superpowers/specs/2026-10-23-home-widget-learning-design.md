# Design Spec: Home Widget Learning (Path-Aware Rotation + Widget Flashcards)

- **Date**: 2026-10-23
- **Status**: Draft — awaiting user review
- **Topic**: Rebuild the VocabCraft WidgetKit experience so learners pick up and retain vocabulary from the Home Screen and Lock Screen
- **Target Platforms**: iOS 17.0+ (widget extension); macOS out of scope
- **Architecture**: Clean Architecture / SwiftData / App Group file store / CraftUIKit-first

---

## 1. Context & Goals

### 1.1 Intent (agreed with user)
Learners should see and remember new words quickly from a widget on their Home Screen. Words must come from the learner's **active learning path** and **SRS schedule**, not an arbitrary catalog. The widget should feel like "a new word every time I pick up the phone".

### 1.2 Current state (verified in code, 2026-10-23)
- `VocabCraftWidgetExtension` exists (small, medium, accessoryCircular, accessoryInline) and shares the SwiftData store via App Group `group.com.hoojinguyen.vocabcraft`.
- `NextWordIntent` cycles sequentially through `vocabulary_catalog.json` (32 KB, a few dozen words). It ignores the learning path and SRS due dates. The real curriculum lives in `Content/vocab_content.sqlite` (8.3 MB), which the widget cannot read.
- `MarkLearnedIntent` grades `isCorrect: true` with a fixed `responseTimeMs: 1500` on every tap, inflating mastery without any recall.
- The main app never writes `WidgetCurrentState` nor calls `WidgetCenter`, so the widget never reflects in-app progress.
- `VocabWidgetView` hardcodes colors, fonts, padding and corner radii, violating AGENTS.md §3.2.
- `openwiki/features/widgets-and-intents.md` describes behaviour that does not exist; it must be corrected after implementation.

### 1.3 Decisions made during brainstorming
| # | Decision |
|---|---|
| D1 | **Hybrid mode**: passive rotation by default; switch to an active-recall flashcard when an SRS word is due. |
| D2 | **Rotation cadence**: WidgetKit has no "device unlocked" event. Approximate "new word per unlock" with a dense timeline — one entry every **5 minutes** (code constant) — plus a deck refresh whenever the app goes to background. User accepted this approximation. |
| D3 | **Passive word source**: ~60% recently learned words, ~40% words from the next upcoming lesson; 100% first-lesson words for learners with no completed lessons. |
| D4 | **Families**: `systemSmall`, `systemMedium`, `accessoryRectangular`, `accessoryInline`. Drop `accessoryCircular`. |
| D5 | **Architecture**: the app precomputes a "widget deck" and writes it to the App Group; the widget only reads it (Approach 1 of 3). |

### 1.4 Success criteria
1. Words shown on the widget belong to the active learning path (recent + upcoming) or are SRS-due.
2. Passive rotation advances every 5 minutes without consuming the WidgetKit reload budget per word.
3. When at least one word is due, the widget shows a flashcard; grading is only possible after reveal and writes a real SRS result.
4. After the user backgrounds the app, the widget reflects their latest progress (subject to iOS reload scheduling).
5. Widget views use only CraftUIKit tokens and `app.widget.*` localized strings.

---

## 2. Architecture

### 2.1 Approaches considered
1. **App-built deck in App Group (chosen).** One place owns word-selection logic; reuses existing use cases; widget stays small and does not embed the 8.3 MB SQLite. Risk: a stale deck if the app is not opened for days — mitigated by recomputing "due" from `UserWordProgress` inside the widget on each reload.
2. **Widget selects words itself.** Always fresh, but requires opening the large SQLite and pulling learning-path domain code into an extension with ~30 MB memory and short execution limits; duplicates selection logic.
3. **App writes candidate IDs, widget resolves details from SQLite.** Still embeds SQLite with little complexity saved.

### 2.2 Data model (App Group files, not SwiftData)
The deck is disposable, reconstructible data, so it is stored as JSON files instead of a new `@Model` (avoids a `SchemaV4` migration).

```swift
struct WidgetDeck: Codable, Sendable, Equatable {
    static let currentVersion = 1
    let version: Int
    let generatedAt: Date
    let pathId: String?
    let cards: [WidgetCard]          // ≤ 36, unique wordId, due-first order
}

struct WidgetCard: Codable, Sendable, Equatable {
    enum Source: String, Codable, Sendable { case due, recent, upcoming }
    let wordId: Int64
    let lemma: String
    let ipa: String
    let definitionVi: String
    let exampleEn: String
    let source: Source
}

struct WidgetInteractionState: Codable, Sendable, Equatable {
    var revealedWordId: Int64?
    var revealedAt: Date?
}
```

Files: `<AppGroup>/widget/widget_deck.json`, `<AppGroup>/widget/widget_interaction.json`. Writes are atomic (`Data.write(options: .atomic)`).

`WidgetCurrentState` stays in the schema (removing it needs a migration) but is no longer read or written.

### 2.3 Units
| Unit | Target(s) | Responsibility |
|---|---|---|
| `WidgetDeck`, `WidgetCard`, `WidgetInteractionState` | App + Widget | Value types above. |
| `WidgetDeckStore` | App + Widget | Read/write the two JSON files; returns `nil` on missing, corrupt or version-mismatched files. Injectable base URL for tests. |
| `WidgetDeckComposer` | App | Pure function: `(dueWords, recentWords, upcomingWords, now) -> WidgetDeck`. Due words first; fill remainder 60/40 recent/upcoming; backfill from the other source when one is short; dedupe; cap 36. |
| `RefreshWidgetDeckUseCase` | App | Gathers inputs (active path via `FetchLearningPathUseCase`, `UserWordProgress` via progress repository, word details via `SQLiteContentRepository`), calls the composer, writes the deck, calls a `WidgetReloading` abstraction (`WidgetCenter` in production, mock in tests). |
| `WidgetTimelineBuilder` | Widget | Pure function: `(deck, dueWordIds, interaction, now) -> [VocabWidgetEntry] + policy`. |
| `WidgetReviewRecorder` | Widget (+ tests) | Applies an SRS grade to an existing `UserWordProgress` via `SRSEngine`. |
| `RevealCardIntent`, `GradeCardIntent` | Widget | Interactive App Intents. |

### 2.4 Data flow
1. **App → deck.** `RefreshWidgetDeckUseCase` runs when `scenePhase` becomes `.background`, and after `CompleteLessonUseCase` / `EvaluateSRSUseCase` succeed. It writes the deck and requests `reloadTimelines(ofKind: "VocabWidget")`. Failures are logged and swallowed — they must never break the lesson flow.
2. **Deck → timeline.** `VocabWidgetProvider.getTimeline` reads the deck, the interaction state and the `UserWordProgress` rows for the deck's word IDs (`nextReviewDate <= now`). Due status is recomputed here, so a stale deck still follows the real schedule.
   - **Passive**: no due words → one entry per non-due card, every 5 minutes, starting at a rotation offset derived from `now` so consecutive reloads continue rather than restart; policy `.atEnd`. The timeline is capped at the earliest upcoming `nextReviewDate` among deck words (or 36 entries ≈ 3 h, whichever is sooner), so a word that becomes due mid-timeline switches the widget to flashcard mode on the next reload.
   - **Flashcard**: ≥1 due word → a single entry for the first due card; policy `.never` (the intents trigger the reload).
3. **Reveal.** `RevealCardIntent(wordId)` writes `revealedWordId` and `revealedAt`, then reloads.
4. **Grade.** `GradeCardIntent(wordId, remembered)` is valid only if `revealedWordId == wordId`. It calls `WidgetReviewRecorder`, clears the interaction state and reloads. The next due card is shown, or passive rotation resumes.
5. **Deep link.** The Lock Screen flashcard and the empty placeholder use `widgetURL(vocabcraft://review)` / `vocabcraft://home`. `AppRouter.handleDeepLink` gains a `review` host that opens the existing weak-word review flow (exact destination confirmed during planning).

### 2.5 Removed
`NextWordIntent`, `MarkLearnedIntent`, their tests (`NextWordIntentTests`, widget parts of `WidgetIntentsTests`), the `BundledVocabularyDataSource` dependency of the widget target, and the `accessoryCircular` family.

---

## 3. UI

All styling uses `CraftColor`/`CraftFont`/`CraftSpacingTokens`/`CraftRadiusTokens`; badges reuse `CraftBadge`. All text uses new `app.widget.*` keys in `VocabCraftApp/Resources/Localizable.xcstrings` (EN + VI). If the widget target does not yet link `CraftUIKit`, the plan adds it. In tinted/vibrant rendering modes, accents use `widgetAccentable()` and no custom fills.

| Family | Passive | Flashcard |
|---|---|---|
| `systemSmall` | Lemma, IPA, definition (2 lines), source badge (New / Review) | Front: lemma, IPA, hidden meaning, **Reveal** button. Back: meaning, icon buttons **Forgot ✗ / Remembered ✓** |
| `systemMedium` | Lemma, IPA, definition, example, source badge, "N words to review" line | Front: lemma, IPA, example with the target word masked, **Reveal**. Back: meaning, labelled **Forgot / Remembered** buttons |
| `accessoryRectangular` | Lemma, IPA, definition (1 line) | Lemma + "Open to review" hint; taps deep-link to review (no buttons on Lock Screen) |
| `accessoryInline` | `lemma: definition` | `N words to review` |
| Empty / error | "Open VocabCraft to start" placeholder, deep-links to home | — |

Accessibility: buttons get localized `accessibilityLabel`s; the masked example exposes the masked form to VoiceOver, not the answer.

---

## 4. SRS Semantics from the Widget

- **Remembered** → `SRSEngine.calculateNextInterval(isCorrect: true, responseTimeMs:)`, where `responseTimeMs = clamp(now - revealedAt, 1_000...10_000)`. This is an approximation: the learner may have looked at the card before tapping Reveal.
- **Forgot** → `isCorrect: false`; set `needsReview = true`, increment `mistakeCount`.
- Updates `easeFactor`, `intervalDays`, `masteryLevel` (clamped per existing invariants), `lastReviewDate`, `nextReviewDate`, `totalReviews`.
- Grading requires a prior reveal of the same word; otherwise the intent is a no-op.
- Only due words are gradable. Passive cards have no grade buttons, so mastery is never inflated by glancing.
- The widget never creates `UserWordProgress`. Upcoming words enter SRS only through in-app lessons (per the 2026-10-20 unified lexical ecosystem spec).

---

## 5. Error Handling

| Case | Behaviour |
|---|---|
| Deck missing / corrupt / version mismatch | Placeholder entry; wait for the app to rebuild the deck. |
| App Group unavailable | Existing in-memory fallback in `SharedAppGroupContainer`; placeholder shown. |
| SRS write fails in `GradeCardIntent` | Throw; interaction state is left untouched so the user can retry. |
| Stale grade (word no longer due or no longer revealed) | No-op; reload. |
| `RefreshWidgetDeckUseCase` fails in-app | Log and swallow; never block lesson completion or backgrounding. |
| Deck has fewer cards than one hour of rotation | Rotate through the available cards cyclically. |

---

## 6. Testing (Swift Testing, `VocabCraftAppTests/Features/Widget/`)

- **`WidgetDeckComposerTests`** — due words first; 60/40 split when both sources suffice; backfill when one source is short; new learner → 100% first-lesson words; no duplicates; cap 36; empty path → empty deck.
- **`WidgetTimelineBuilderTests`** — passive entries 5 minutes apart with `.atEnd`; rotation offset continues across reloads; a due word yields a single flashcard entry with `.never`; due status comes from progress, not the deck's `source`; reveal state is applied only to the matching word.
- **`WidgetReviewRecorderTests`** (in-memory SwiftData) — remembered/forgot field updates; `responseTimeMs` clamping; grading without reveal rejected; missing progress → no insert.
- **`WidgetDeckStoreTests`** — round-trip; corrupt JSON and wrong version → `nil`.
- **`RefreshWidgetDeckUseCaseTests`** — with mock repositories and a mock `WidgetReloading`: writes the deck and requests a reload; a repository failure does not throw to the caller.
- **`AppRouter` deep-link test** for `vocabcraft://review`.
- **Localization** — extend `WidgetLocalizationTests` for the new keys (EN + VI).
- **Manual verification on Simulator** — add small/medium/Lock Screen widgets; observe rotation; complete Reveal → Grade; confirm the SRS change in-app; background the app after a lesson and confirm the deck refresh.

---

## 7. Scope

**In scope:** app-built deck, 5-minute timeline, Reveal → Remembered/Forgot flashcards, four widget families, `vocabcraft://review` deep link, CraftUIKit token migration of widget views, removal of the legacy intents and `accessoryCircular`, correction of `openwiki/features/widgets-and-intents.md`.

**Out of scope (YAGNI):** widget configuration (path or cadence picker), TTS from the widget, macOS widgets, StandBy-specific layouts, Live Activities, Control Center widgets, widget-specific stats or streaks, deleting `WidgetCurrentState` from the schema.

**Known risks:** a deck goes stale if the app is not opened for days (due status stays correct; "recent" drifts); iOS may delay background-triggered reloads; the measured response time is an approximation.
