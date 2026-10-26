# Widget Visual Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restyle every widget family as a "deep flashcard" (brand gradient, large lemma, part-of-speech chip, progress dots, pill buttons) and add the two data points it needs: part of speech on each card and today's practice count on each entry.

**Architecture:** `WidgetCard` gains `partOfSpeech` (deck version 2), filled by the app-side composer. The widget provider counts today's practiced `UserWordProgress` rows and stamps `practicedToday` on each entry. The 300-line `VocabWidgetView.swift` is split into an entry point, shared components, system layouts and accessory layouts; pure helpers (progress, POS mapping, meta row, masked example) are unit-tested, layouts are checked with previews and simulator screenshots.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, WidgetKit, SwiftData, Swift Testing, CraftUIKit.

**Spec:** `docs/superpowers/specs/2026-10-25-widget-visual-redesign-design.md`

## Global Constraints

- iOS 17.0+ widget extension; keep `swift build` (SPM, macOS) green — accessory code stays inside `#if os(iOS)`.
- Work on branch `feat/home-widget-learning` in `.worktrees/home-widget-learning`.
- `WidgetDeck.currentVersion = 2`. `WidgetCard.partOfSpeech: String?` (empty → `nil`). `VocabWidgetEntry.practicedToday: Int` (init default `0`).
- Progress: `total = practiced + due`; `total == 0 → (fraction 0, dots 0)`; `fraction = practiced / total`; `filledDots = round(fraction * 5)` clamped `0...5`.
- "Practiced today" = `UserWordProgress.lastReviewDate >= Calendar.current.startOfDay(for: now)`, across all rows. Copy says "practiced", never "reviewed".
- Styling only via `@Environment(\.craftTheme) private var theme` tokens: background `theme.gradients.brandHero`, glass `theme.gradients.surfaceGlass`, scrim `theme.gradients.fadeBottom`, text `theme.colors.textInverse`, accents `theme.colors.accent`, `statusSuccess`, `statusDanger`; fonts `titleLarge` (small lemma), `displayLarge` (medium lemma), `displayHero` (depth glyph, `scaleEffect` ×3 small / ×4 medium), `phonetic` (IPA), `bodySerif` (example), `caption` (chips). No raw colors, fonts, paddings, radii or point sizes, except: accent bar 24×3, progress dot 6, pill min height 36, glyph opacity 0.08, glyph rotation −12°, IPA opacity 0.75, empty-dot opacity 0.30, mask highlight `accent.opacity(0.35)` (all fixed by the spec).
- In `widgetRenderingMode != .fullColor`: no gradient, no glass fills (stroke capsules instead), depth glyph hidden, lemma / filled dots / icons use `widgetAccentable()`.
- The widget does not inject a theme, so it renders `CraftDefaultTheme` (`CraftThemeEnvironment.defaultValue`). Contrast checks use Default (light + dark) on device and Oxford Heritage + Neo Arcade through `#Preview` with `.environment(\.craftTheme, …)`.
- Strings: new `app.widget.*` keys in `VocabCraftApp/Resources/Localizable.xcstrings`, EN + VI, `"extractionState": "manual"`, `"state": "translated"`.
- **Xcode project is hand-edited.** Never run `scripts/generate_xcodeproj.py`. For each new file add one `PBXFileReference`, one `PBXBuildFile` per target, a group child and a build-phase entry. Use ID prefix `3B71` (unused): file refs `20003B71000100NN`, Widget Sources `30003B71000200NN`, Test Sources `30003B71000300NN`, groups `40003B71000100NN`. Widget files (`VocabCraftWidgetExtension/**`) → Widget Sources + Test Sources, exactly like `VocabWidgetView.swift` (refs `200075A9C43B4E98CD5D`, `300075A9C43B4E98CD5D`, `30022A3804DB171F946C`). Test files → Test Sources.
- Test command: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/<Suite> -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.
- Commits: `feat(widget): …` / `test(widget): …`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Card with no IPA and no part of speech** (some catalog senses have empty phonetics): the meta row must disappear entirely, with no stray "·" or empty chip → test in Task 3 (`WidgetCardMeta`).
2. **Lemma appears more than once or inside an inflection** ("Run, run! She runs."): every occurrence is masked and highlighted, and VoiceOver never hears the answer → test in Task 4 (`maskedAttributed`).
3. **Brand-new learner, nothing practiced today, passive mode**: no "Today: 0 words" footer → test in Task 3 (`showsPracticedFooter`).
4. **Card with an empty example in medium**: the glass example card is omitted and the left column takes the full width, not an empty glass box → Task 5 preview `mediumNoExample` + visual check in Task 7.
5. **Very long lemma** ("responsibility", "internationalization") in small: scales down to 0.6 then truncates on one line, never wraps or pushes buttons off → Task 7 preview `longLemma` + screenshot.

---

## File Structure

| File | Responsibility | Task |
|---|---|---|
| `VocabCraftApp/Core/Widget/WidgetDeck.swift` (modify) | `partOfSpeech`, version 2 | 1 |
| `VocabCraftApp/Domain/Widget/WidgetDeckComposer.swift` (modify) | map `TopicWordDTO.pos` | 1 |
| `VocabCraftWidgetExtension/Review/WidgetDueQuery.swift` (modify) | `practicedCount(since:in:)` | 2 |
| `VocabCraftWidgetExtension/Timeline/WidgetTimelineBuilder.swift` (modify) | `practicedToday` on entry + builder param | 2 |
| `VocabCraftWidgetExtension/VocabWidget.swift` (modify) | provider passes the count | 2 |
| `VocabCraftWidgetExtension/Views/WidgetPresentation.swift` (create) | pure helpers: `WidgetProgress`, `WidgetPartOfSpeech`, `WidgetCardMeta`, `showsPracticedFooter` | 3 |
| `VocabCraftWidgetExtension/Views/WidgetCardComponents.swift` (create) | chips, accent bar, depth glyph, dots, pill label, hidden-meaning bar, masked example | 4 |
| `VocabCraftWidgetExtension/Views/WidgetSystemViews.swift` (create) | small + medium layouts | 5 |
| `VocabCraftWidgetExtension/Views/WidgetAccessoryViews.swift` (create) | rectangular + inline (`#if os(iOS)`) | 6 |
| `VocabCraftWidgetExtension/VocabWidgetView.swift` → `Views/VocabWidgetView.swift` (move + slim) | entry point, background, empty state, family switch | 5 |
| `VocabCraftWidgetExtension/Views/VocabWidgetPreviews.swift` (create) | `#Preview(as:)` sets | 7 |

---

### Task 1: Part of speech on widget cards (deck v2)

**Files:**
- Modify: `VocabCraftApp/Core/Widget/WidgetDeck.swift`
- Modify: `VocabCraftApp/Domain/Widget/WidgetDeckComposer.swift:55-62`
- Test: `VocabCraftAppTests/Features/Widget/WidgetDeckStoreTests.swift`, `WidgetDeckComposerTests.swift`

**Interfaces:**
- Produces: `WidgetCard.partOfSpeech: String?`; `WidgetCard.init(…, source: Source, partOfSpeech: String? = nil)` (new last param with default, so existing call sites compile); `WidgetDeck.currentVersion == 2`.

- [ ] **Step 1: Write the failing tests**

In `WidgetDeckStoreTests`:
```swift
@Test func partOfSpeechRoundTrips() throws {
    // save a deck whose first card has partOfSpeech "noun"; load → first card partOfSpeech == "noun"
}
@Test func versionOneDeckIsRejected() throws {
    // write makeDeck(version: 1); #expect(store.loadDeck() == nil)
}
@Test func cardWithoutPartOfSpeechKeyDecodes() throws {
    // JSON for a v2 deck whose card object omits "partOfSpeech" → loads, card.partOfSpeech == nil
}
```
In `WidgetDeckComposerTests` (extend the `word(_:)` helper with a `pos:` parameter, default `"noun"`):
```swift
@Test("cards carry part of speech")
func cardsCarryPartOfSpeech() { /* pos "verb" → card.partOfSpeech == "verb" */ }
@Test("empty part of speech becomes nil")
func emptyPartOfSpeechIsNil() { /* pos "" → card.partOfSpeech == nil */ }
```

- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/WidgetDeckStoreTests` and `/WidgetDeckComposerTests`. Expected: compile failure on `partOfSpeech`.

- [ ] **Step 3: Implement** the field (optional, `Codable` synthesized — a missing key decodes as `nil`), bump `currentVersion` to `2`, and map `partOfSpeech: word.pos.isEmpty ? nil : word.pos` in `WidgetDeckComposer.card(...)`.

- [ ] **Step 4: Run** both suites plus `RefreshWidgetDeckUseCaseTests`. Expected: PASS.

- [ ] **Step 5: Commit** `feat(widget): carry part of speech on widget cards`.

---

### Task 2: Today's practice count on timeline entries

**Files:**
- Modify: `VocabCraftWidgetExtension/Review/WidgetDueQuery.swift`
- Modify: `VocabCraftWidgetExtension/Timeline/WidgetTimelineBuilder.swift`
- Modify: `VocabCraftWidgetExtension/VocabWidget.swift` (`makeTimeline`)
- Test: `VocabCraftAppTests/Features/Widget/WidgetDueQueryTests.swift` (create), `WidgetTimelineBuilderTests.swift`

**Interfaces:**
- Produces:
  - `@MainActor static func WidgetDueQuery.practicedCount(since: Date, in context: ModelContext) throws -> Int` (uses `fetchCount`).
  - `VocabWidgetEntry.practicedToday: Int`; `init(date:card:mode:dueCount:practicedToday: Int = 0)`; `placeholder(at:)` keeps `practicedToday == 0`.
  - `WidgetTimelineBuilder.build(deck:dueWordIds:nextDueDate:interaction:practicedToday: Int = 0, now:)` — every entry built from a deck carries `practicedToday`.

- [ ] **Step 1: Write the failing tests**

`WidgetDueQueryTests` (`@MainActor`, in-memory `SharedAppGroupContainer.createContainer(inMemory: true)`, `now = Date(timeIntervalSince1970: 1_800_000_000)`, `start = Calendar.current.startOfDay(for: now)`):
```swift
@Test func countsRowsPracticedSinceStartOfDay() throws {
    // rows with lastReviewDate: start, now, start - 1s, now - 86_400
    #expect(try WidgetDueQuery.practicedCount(since: start, in: context) == 2)
}
@Test func emptyStoreCountsZero() throws {
    #expect(try WidgetDueQuery.practicedCount(since: start, in: context) == 0)
}
```
`WidgetTimelineBuilderTests`:
```swift
@Test func passiveEntriesCarryPracticedToday() { /* deck(3), practicedToday: 7 → all entries .practicedToday == 7 */ }
@Test func flashcardEntryCarriesPracticedToday() { /* due [1], practicedToday: 4 → entry.practicedToday == 4 */ }
@Test func placeholderHasZeroPracticed() { /* deck nil, practicedToday: 9 → entry.practicedToday == 0 */ }
```

- [ ] **Step 2: Run** `WidgetDueQueryTests` and `WidgetTimelineBuilderTests`. Expected: compile failure.

- [ ] **Step 3: Implement** the query, the entry field and the builder parameter. In `VocabWidgetProvider.makeTimeline`, inside the existing `if let container` scope (and independent of `deck`), compute `(try? WidgetDueQuery.practicedCount(since: Calendar.current.startOfDay(for: now), in: context)) ?? 0` and pass it to `build`. No container → `0`.

- [ ] **Step 4: Run** both suites plus `WidgetIntentsTests`. Expected: PASS.

- [ ] **Step 5: Add** `WidgetDueQueryTests.swift` to the Xcode project (Test Sources, IDs per Global Constraints) and **commit** `feat(widget): stamp today's practice count on widget entries`.

---

### Task 3: Presentation helpers and strings

**Files:**
- Create: `VocabCraftWidgetExtension/Views/WidgetPresentation.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Test: `VocabCraftAppTests/Features/Widget/WidgetPresentationTests.swift` (create), `WidgetLocalizationTests.swift`

**Interfaces:**
- Produces (all `nonisolated`, `public` not required — internal is enough since tests use `@testable`):
  - `enum WidgetProgress { static func make(practiced: Int, due: Int) -> (fraction: Double, filledDots: Int, total: Int) }`
  - `enum WidgetPartOfSpeech { static func abbreviationKey(for raw: String?) -> String? }` → `"app.widget.pos.<raw>"` for the eight values, `nil` otherwise.
  - `enum WidgetCardMeta { static func parts(partOfSpeech: String?, ipa: String) -> (posKey: String?, ipa: String?) }` — empty/whitespace IPA → `nil`; meta row is shown only if either part is non-nil.
  - `static func showsPracticedFooter(_ practicedToday: Int) -> Bool` on `WidgetProgress` (`> 0`).

- [ ] **Step 1: Write the failing tests** in `WidgetPresentationTests`:
```swift
@Test(arguments: [(0, 0, 0.0, 0), (0, 5, 0.0, 0), (3, 2, 0.6, 3), (5, 0, 1.0, 5), (1, 2, 1.0/3, 2)])
func progress(practiced: Int, due: Int, fraction: Double, dots: Int) { … total == practiced + due }
@Test func posMapsAllEightValues() // noun…determiner → "app.widget.pos.<raw>"
@Test func posUnknownOrNilIsNil()  // "interjection", "", nil → nil
@Test func metaHidesEmptyParts()   // (nil, "") → (nil, nil); (nil, "  ") → (nil, nil); ("noun", "") → ("app.widget.pos.noun", nil)
@Test func footerHiddenWhenNothingPracticed() // 0 → false, 1 → true
```
In `WidgetLocalizationTests`, add to the key list: `app.widget.pos.noun`, `.verb`, `.adjective`, `.adverb`, `.pronoun`, `.preposition`, `.conjunction`, `.determiner`, `app.widget.practiced_today_format`, `app.widget.progress_format`, `app.widget.inline_progress_format`, `app.widget.empty.subtitle`.

- [ ] **Step 2: Run** `WidgetPresentationTests` and `WidgetLocalizationTests`. Expected: FAIL.

- [ ] **Step 3: Implement** the helpers and add the strings:

| Key | EN | VI |
|---|---|---|
| `app.widget.pos.noun/verb/adjective/adverb/pronoun/preposition/conjunction/determiner` | `n.` `v.` `adj.` `adv.` `pron.` `prep.` `conj.` `det.` | same |
| `app.widget.practiced_today_format` | `Today: %d words` | `Hôm nay: %d từ` |
| `app.widget.progress_format` | `%1$d/%2$d` | `%1$d/%2$d` |
| `app.widget.inline_progress_format` | `%1$d/%2$d · %3$d to review` | `%1$d/%2$d · %3$d từ cần ôn` |
| `app.widget.empty.subtitle` | `Start your first lesson` | `Bắt đầu bài học đầu tiên` |

- [ ] **Step 4: Run** both suites. Expected: PASS.

- [ ] **Step 5: Add** both new files to the Xcode project and **commit** `feat(widget): add widget presentation helpers and strings`.

---

### Task 4: Shared card components

**Files:**
- Create: `VocabCraftWidgetExtension/Views/WidgetCardComponents.swift`
- Modify: `VocabCraftWidgetExtension/VocabWidgetView.swift` (move `maskToken` and `maskedExample` into `MaskedExampleText` as `nonisolated static`; update the two existing tests to call `MaskedExampleText.maskedExample`)
- Test: `VocabCraftAppTests/Features/Widget/VocabWidgetViewTests.swift`

**Interfaces:**
- Consumes: `WidgetPartOfSpeech`, `WidgetCardMeta` (Task 3).
- Produces (all `struct … : View`, each reads `theme` and `widgetRenderingMode` itself):
  - `WidgetChip(titleKey: LocalizedStringKey, symbol: CraftSymbol?)`
  - `WidgetSourceChip(source: WidgetCard.Source)` — `.upcoming` → `app.widget.badge.new` + `.sparkles`; `.recent/.due` → `app.widget.badge.review` + `.refresh`.
  - `WidgetMetaRow(card: WidgetCard)` — POS chip + IPA; renders nothing when both parts are nil.
  - `WidgetAccentBar()`, `WidgetDepthGlyph(lemma: String, scale: CGFloat)`, `WidgetProgressDots(filled: Int)`
  - `WidgetPillLabel(titleKey: LocalizedStringKey, symbol: CraftSymbol, tint: Color, showsTitle: Bool)` — keeps today's `accessibilityLabel(Text(key))`.
  - `WidgetHiddenMeaningBar()` — two capsules at 30% opacity, `accessibilityLabel("app.widget.hidden_meaning")`.
  - `MaskedExampleText(example: String, lemma: String)` with `nonisolated static func maskedAttributed(_ example: String, lemma: String, highlight: Color) -> AttributedString` — every case-insensitive occurrence becomes `maskToken` with `backgroundColor = highlight`; the view's `accessibilityLabel` is the plain `maskedExample` string.

- [ ] **Step 1: Write the failing tests** in `VocabWidgetViewTests`:
```swift
@Test func maskedAttributedHighlightsEveryOccurrence() {
    let a = MaskedExampleText.maskedAttributed("Run, run! She runs.", lemma: "run", highlight: .red)
    #expect(String(a.characters) == "_____, _____! She _____s.")
    #expect(a.runs.filter { $0.backgroundColor != nil }.count == 3)
}
@Test func maskedAttributedWithoutMatchHasNoHighlight() { /* "She walks", "run" → 0 highlighted runs */ }
```

- [ ] **Step 2: Run** `VocabWidgetViewTests`. Expected: compile failure.

- [ ] **Step 3: Implement** the components per the spec §3.1 table and Global Constraints values. Glyph: first `Character` of the lemma, `accessibilityHidden(true)`, not rendered outside full-color.

- [ ] **Step 4: Run** `VocabWidgetViewTests`, then build the scheme. Expected: PASS, build succeeds.

- [ ] **Step 5: Add** the file to the Xcode project and **commit** `feat(widget): add deep-flashcard widget components`.

---

### Task 5: Small and medium layouts + entry point

**Files:**
- Create: `VocabCraftWidgetExtension/Views/WidgetSystemViews.swift`
- Move: `VocabCraftWidgetExtension/VocabWidgetView.swift` → `VocabCraftWidgetExtension/Views/VocabWidgetView.swift` (`git mv`; update the `PBXFileReference` path and move its group child into the `Views` group)
- Modify: `Package.swift` only if the SPM target lists files explicitly (it uses `path: "VocabCraftWidgetExtension"`, so subfolders are picked up — verify with `swift build`)

**Interfaces:**
- Consumes: Task 3 helpers, Task 4 components, `RevealCardIntent(wordId:)`, `GradeCardIntent(wordId:remembered:)`.
- Produces: `WidgetSmallView(entry: VocabWidgetEntry, card: WidgetCard)`, `WidgetMediumView(entry: VocabWidgetEntry, card: WidgetCard)`. `VocabWidgetView` keeps its public `init(entry:)`, applies `containerBackground` (gradient in full-color, `theme.colors.surfaceCard` otherwise), renders the empty state, and switches on family.

- [ ] **Step 1: Implement** `VocabWidgetView` as the slim entry point: family switch, background, `.id(card.wordId)` + `.transition(.push(from: .trailing))` on the card content, empty state (`sparkles` icon, `app.widget.empty.title`, `app.widget.empty.subtitle`, `widgetURL(vocabcraft://home)`).

- [ ] **Step 2: Implement** `WidgetSmallView` exactly per spec §3.2 systemSmall (passive / front / back). Passive footer uses `practiced_today_format` and only when `WidgetProgress.showsPracticedFooter`. Front shows `WidgetProgressDots(filled: WidgetProgress.make(…).filledDots)` when `total > 0`. Back lemma uses `titleMedium`; the definition appears with `.transition(.opacity)`.

- [ ] **Step 3: Implement** `WidgetMediumView` per spec §3.2 systemMedium: `HStack` with left column `.frame(maxWidth: .infinity)` and right glass example card sized with `.containerRelativeFrame(.horizontal) { width, _ in width * 0.45 }`; when `card.exampleEn.isEmpty` the right card is omitted (Review Focus 4). Front bottom row: Reveal pill + `progress_format` text (only when `total > 0`) with `.contentTransition(.numericText())`; back: labelled Forgot / Remembered pills.

- [ ] **Step 4: Run** `swift build` and the scheme build, then `VocabWidgetViewTests`, `WidgetIntentsTests`. Expected: all green, no new SwiftLint warnings.

- [ ] **Step 5: Commit** `feat(widget): redesign small and medium widget layouts`.

---

### Task 6: Lock Screen layouts

**Files:**
- Create: `VocabCraftWidgetExtension/Views/WidgetAccessoryViews.swift` (whole file inside `#if os(iOS)`)
- Modify: `VocabCraftWidgetExtension/Views/VocabWidgetView.swift` (route accessory families)

**Interfaces:**
- Produces: `WidgetRectangularView(entry:card:)`, `WidgetInlineView(entry:card:)`.

- [ ] **Step 1: Implement** rectangular per spec §3.2: passive = lemma (headline, accentable) / meta line as plain text (`n. · /ipa/`, using `WidgetCardMeta`) / definition 1 line; flashcard = lemma + `app.widget.lock.open_to_review` with trailing `Gauge(value: fraction) { } currentValueLabel: { Text(practicedToday) }.gaugeStyle(.accessoryCircularCapacity)`; keep `widgetURL(vocabcraft://review)` in flashcard mode.

- [ ] **Step 2: Implement** inline: passive `lemma (n.): definition` (omit `(n.)` when no POS); flashcard `inline_progress_format` with `(practiced, total, dueCount)`.

- [ ] **Step 3: Run** `swift build` and the scheme build. Expected: green on both.

- [ ] **Step 4: Add** the file to the Xcode project and **commit** `feat(widget): redesign lock screen widget layouts`.

---

### Task 7: Previews, visual verification, wrap-up

**Files:**
- Create: `VocabCraftWidgetExtension/Views/VocabWidgetPreviews.swift`
- Modify: `openwiki/features/widgets-and-intents.md` (UI section only)

- [ ] **Step 1: Write previews** with `#Preview(as: .systemSmall)` / `.systemMedium` / `.accessoryRectangular` / `.accessoryInline` timelines covering: passive, front (practiced 3, due 2), back, empty, `longLemma` ("internationalization"), `noMeta` (no POS, empty IPA), `mediumNoExample`. Add Oxford Heritage and Neo Arcade variants of the small front entry via `.environment(\.craftTheme, CraftOxfordHeritageTheme())` / `CraftNeoArcadeTheme()`. Wrap the file in `#if DEBUG`.

- [ ] **Step 2: Visual check on the simulator.** Build and run on iPhone 17 Pro, add small, medium and Lock Screen rectangular widgets, screenshot light, dark and tinted (Home Screen customization → Tinted). Inspect the preview canvas for the two extra themes. Pass criteria: spec §1.3 items 1 and 4, plus Review Focus 4 and 5. If any lemma/definition fails contrast, add `theme.gradients.fadeBottom` behind the text block in `VocabWidgetView` (one change for all themes), rebuild and re-screenshot.

- [ ] **Step 3: Update** the UI section of `openwiki/features/widgets-and-intents.md` to describe the new layouts, POS chip and practice progress.

- [ ] **Step 4: Run** the full suite `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` and `swift build`. Expected: all green; report any failure verbatim.

- [ ] **Step 5: Add** the previews file to the Xcode project and **commit** `feat(widget): add widget previews and docs for redesign`, attaching the screenshots to the hand-off message.
