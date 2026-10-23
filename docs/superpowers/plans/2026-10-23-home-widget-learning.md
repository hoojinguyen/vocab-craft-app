# Home Widget Learning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the catalog-cycling widget with a path-aware widget: passive 5-minute rotation of recent/upcoming lesson words, switching to Reveal → Remembered/Forgot flashcards that write real SRS results when a word is due.

**Architecture:** The app composes a ≤36-card `WidgetDeck` from the active learning path and SRS progress and writes it as JSON into the App Group. The widget reads that deck, recomputes due status from SwiftData `UserWordProgress`, and builds its timeline with a pure builder. Interactive App Intents reveal and grade cards.

**Tech Stack:** Swift 6 strict concurrency, SwiftUI, WidgetKit, AppIntents, SwiftData, Swift Testing, CraftUIKit.

**Spec:** `docs/superpowers/specs/2026-10-23-home-widget-learning-design.md`

## Global Constraints

- iOS 17.0+ widget extension; macOS widgets out of scope (keep the existing `#if os(iOS)` guards compiling on macOS for the SPM build).
- App Group: `group.com.hoojinguyen.vocabcraft`. Deck files: `<AppGroup>/widget/widget_deck.json` and `<AppGroup>/widget/widget_interaction.json`, written with `.atomic`.
- Constants: `WidgetDeckComposer.maxCards = 36`, `WidgetDeckComposer.recentShare = 0.6`, `WidgetTimelineBuilder.rotationInterval: TimeInterval = 300`, response-time clamp `1_000...10_000` ms, `WidgetDeck.currentVersion = 1`, widget kind `"VocabWidget"`.
- **Due definition (both app and widget): `nextReviewDate <= now`.** `needsReview` does NOT make a word due. This prevents a "Forgot" word from looping forever: after Forgot, SRS sets `nextReviewDate` to tomorrow.
- The widget never inserts `UserWordProgress`; it only updates existing rows.
- Styling uses only CraftUIKit tokens via `@Environment(\.craftTheme) private var theme` (`theme.colors.*`, `theme.typography.*`, `theme.spacing.*`, `theme.radius.*`) and CraftUIKit components (`CraftBadge`, `CraftSymbol`). No raw colors, fonts, padding or radii.
- No hardcoded user-facing strings: every string uses an `app.widget.*` key in `VocabCraftApp/Resources/Localizable.xcstrings` with EN + VI values (`"extractionState": "manual"`, `"state": "translated"`).
- Shared types that live in `VocabCraftApp/` and are used by the widget must be `public` (the SPM `VocabCraftWidgetExtension` target reaches them through `import VocabCraftApp`). Widget-side files use the existing header guard `#if !WIDGET_EXTENSION && canImport(VocabCraftApp) import VocabCraftApp #endif`.
- **Xcode project is hand-edited.** Do NOT run `scripts/generate_xcodeproj.py`; it is out of sync with the committed `project.pbxproj`. Add every new file by hand: one `PBXFileReference`, one `PBXBuildFile` per target that compiles it, one group child entry, and one entry in each target's build phase. Use ID prefix `3B70` (unused today):
  - file refs `20003B70000100NN`, app Sources `30003B70000100NN`, Widget Sources `30003B70000200NN`, Test Sources `30003B70000300NN`, new groups `40003B70000100NN` (NN increments per file, hex).
  - Shared app files (`VocabCraftApp/Core/Widget/*`) → app Sources + Widget Sources. Widget files (`VocabCraftWidgetExtension/**`) → Widget Sources + Test Sources (matching how `VocabWidget.swift` is wired today). Test files → Test Sources.
- Test command (substitute the suite): `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -only-testing:VocabCraftAppTests/<Suite> -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`. Also keep `swift build` green (SPM).
- Commits use conventional style `feat(widget): …` / `test(widget): …` and end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Remembered on a word that was revealed, then the deck was rebuilt and that word is gone.** The grade must still apply to the existing `UserWordProgress` row (grading keys on `wordId`, not the deck) → test in Task 6.
2. **Clock-boundary rotation.** Two reloads in the same 5-minute slot must show the same card, and a reload in the next slot must show the next card (not restart at index 0) → test in Task 5.
3. **Every deck card is due** (a learner returns after a week). The widget stays in flashcard mode card by card, the count decreases after each grade, and it never falls into an empty passive timeline → test in Task 5.
4. **Deck shorter than the timeline** (a new learner whose first lesson has 6 words). Passive entries cycle the 6 cards; no crash, no empty entries → test in Task 5.
5. **App backgrounded while lesson completion is still saving.** The deck refresh must never throw into or delay lesson completion → tests in Task 4 (the result returns before the fire-and-forget refresh; no refresh after a failed lesson) and Task 3 (`failureDoesNotThrowOrWrite`).

---

## File Structure

| File | Responsibility |
|---|---|
| `VocabCraftApp/Core/Widget/WidgetDeck.swift` (new, shared) | `WidgetDeck`, `WidgetCard`, `WidgetInteractionState` value types + `WidgetKind.vocab` constant |
| `VocabCraftApp/Core/Widget/WidgetDeckStore.swift` (new, shared) | JSON persistence of deck + interaction state |
| `VocabCraftApp/Domain/Widget/WidgetDeckComposer.swift` (new) | Pure deck composition |
| `VocabCraftApp/Domain/Widget/RefreshWidgetDeckUseCase.swift` (new) | Gathers inputs, composes, writes, reloads |
| `VocabCraftApp/Domain/Widget/WidgetReloading.swift` (new) | `WidgetReloading` protocol + `WidgetCenterReloader` |
| `VocabCraftApp/Domain/Widget/WidgetRefreshingCompleteLessonUseCase.swift` (new) | Decorator that refreshes the deck after a lesson completes |
| `VocabCraftWidgetExtension/Timeline/WidgetTimelineBuilder.swift` (new) | Pure timeline construction + `VocabWidgetEntry` |
| `VocabCraftWidgetExtension/Review/WidgetDueQuery.swift` (new) | Reads due status for deck words from SwiftData |
| `VocabCraftWidgetExtension/Review/WidgetReviewRecorder.swift` (new) | Applies SRS grade |
| `VocabCraftWidgetExtension/AppIntents/RevealCardIntent.swift`, `GradeCardIntent.swift` (new) | Interactive intents |
| `VocabCraftWidgetExtension/VocabWidget.swift`, `VocabWidgetView.swift` (rewrite) | Provider + views |
| `VocabCraftWidgetExtension/AppIntents/NextWordIntent.swift`, `MarkLearnedIntent.swift` (delete) | Legacy |

---

### Task 1: Shared deck model and store

**Files:**
- Create: `VocabCraftApp/Core/Widget/WidgetDeck.swift`, `VocabCraftApp/Core/Widget/WidgetDeckStore.swift`
- Test: `VocabCraftAppTests/Features/Widget/WidgetDeckStoreTests.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj` (new `Widget` group under `Core`; both files in app + Widget Sources; test in Test Sources)

**Interfaces:**
- Produces:
  - `public enum WidgetKind { public static let vocab = "VocabWidget" }`
  - `public struct WidgetCard: Codable, Sendable, Equatable, Identifiable { wordId: Int64; lemma, ipa, definitionVi, exampleEn: String; source: Source; var id: Int64 { wordId } }` with `public enum Source: String, Codable, Sendable { case due, recent, upcoming }`
  - `public struct WidgetDeck: Codable, Sendable, Equatable { static let currentVersion = 1; version: Int; generatedAt: Date; pathId: String?; cards: [WidgetCard] }`
  - `public struct WidgetInteractionState: Codable, Sendable, Equatable { var revealedWordId: Int64?; var revealedAt: Date?; static let empty }`
  - `public struct WidgetDeckStore: Sendable { init(directoryURL: URL); static func appGroup(fileManager: FileManager = .default) -> WidgetDeckStore; func loadDeck() -> WidgetDeck?; func saveDeck(_: WidgetDeck) throws; func loadInteraction() -> WidgetInteractionState; func saveInteraction(_: WidgetInteractionState) throws }`

- [ ] **Step 1: Write failing tests** in `WidgetDeckStoreTests` (`@Suite("WidgetDeckStore")`, each test uses a fresh `FileManager.default.temporaryDirectory/UUID()` directory):
  - `deckRoundTrips`: save a 2-card deck, `#expect(store.loadDeck() == deck)`.
  - `missingDeckReturnsNil`: `#expect(store.loadDeck() == nil)` on an empty directory.
  - `corruptDeckReturnsNil`: write `Data("not json".utf8)` to `widget_deck.json`, `#expect(store.loadDeck() == nil)`.
  - `wrongVersionReturnsNil`: save a deck with `version: 99`, `#expect(store.loadDeck() == nil)`.
  - `interactionDefaultsToEmpty`: `#expect(store.loadInteraction() == .empty)`; after saving `revealedWordId: 7`, it loads back with `7`.
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/WidgetDeckStoreTests`. Expected: build failure (types undefined).
- [ ] **Step 3: Implement** both files. `saveDeck`/`saveInteraction` create the directory if needed and use `JSONEncoder` with `.iso8601` dates and `write(to:options: .atomic)`. `appGroup()` resolves `containerURL(forSecurityApplicationGroupIdentifier: SharedAppGroupContainer.appGroupID)/widget`, falling back to `applicationSupportDirectory/VocabCraft/widget`, the same fallback style as `SharedAppGroupContainer.persistedStoreURL`.
- [ ] **Step 4: Run** the suite. Expected: 5 tests pass. Run `swift build`. Expected: success.
- [ ] **Step 5: Commit** `feat(widget): add shared widget deck model and store`.

---

### Task 2: WidgetDeckComposer

**Files:**
- Create: `VocabCraftApp/Domain/Widget/WidgetDeckComposer.swift`
- Test: `VocabCraftAppTests/Features/Widget/WidgetDeckComposerTests.swift`
- Modify: `project.pbxproj` (new `Widget` group under `Domain`; app Sources; test in Test Sources)

**Interfaces:**
- Consumes: `WidgetDeck`, `WidgetCard` (Task 1); `TopicWordDTO` (existing: `id`, `lemma`, `phonetic`, `definitionVi`, `exampleEn`).
- Produces: `public enum WidgetDeckComposer { static let maxCards = 36; static let recentShare = 0.6; static func compose(due: [TopicWordDTO], recent: [TopicWordDTO], upcoming: [TopicWordDTO], pathId: String?, now: Date) -> WidgetDeck }`. Inputs are already ordered by priority. `WidgetCard` maps `phonetic → ipa`.

- [ ] **Step 1: Write failing tests** (helper `word(_ id: Int64)` builds a `TopicWordDTO`):
  - `dueWordsComeFirst`: due `[1,2]`, recent `[3]`, upcoming `[4]` → card ids `[1,2,3,4]`, sources `[.due,.due,.recent,.upcoming]`.
  - `splitsRemainderSixtyForty`: due `[]`, recent ids `100...149`, upcoming `200...249` → 36 cards, `filter { $0.source == .recent }.count == 22` (`(36 * 0.6).rounded() = 22`), upcoming count `14`.
  - `interleavesSources`: same input → the first 5 sources are `[.recent, .recent, .upcoming, .recent, .upcoming]`. Running ratio rule: pick recent while `recentTaken < (taken + 1) * 0.6`.
  - `backfillsWhenRecentShort`: recent `[1,2]`, upcoming `100...149` → 36 cards, 2 recent and 34 upcoming.
  - `newLearnerUsesUpcomingOnly`: recent `[]`, upcoming `[1...6]` → 6 cards, all `.upcoming`.
  - `deduplicatesAcrossSources`: due `[1]`, recent `[1,2]`, upcoming `[2,3]` → ids `[1,2,3]`.
  - `capsDueAtMaxCards`: 40 due → 36 cards, all `.due`.
  - `emptyInputsGiveEmptyDeck`: `cards.isEmpty`, `version == WidgetDeck.currentVersion`, `generatedAt == now`.
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/WidgetDeckComposerTests`. Expected: build failure.
- [ ] **Step 3: Implement `compose`** with this algorithm, which the tests do not fully determine:

```swift
// 1. seen = []; cards = due (dedup, prefix maxCards) as .due
// 2. slots = maxCards - cards.count; recentTarget = Int((Double(slots) * recentShare).rounded())
// 3. r = recent minus seen, u = upcoming minus seen (dedup, preserve order)
// 4. while cards.count < maxCards && (!r.isEmpty || !u.isEmpty):
//      takenRecent / taken count only non-due cards
//      wantRecent = takenRecent < recentTarget && Double(takenRecent) < Double(taken + 1) * recentShare
//      pick from r if (wantRecent && !r.isEmpty) || u.isEmpty, else from u
```

- [ ] **Step 4: Run** the suite. Expected: 8 pass.
- [ ] **Step 5: Commit** `feat(widget): compose path-aware widget decks`.

---

### Task 3: RefreshWidgetDeckUseCase

**Files:**
- Create: `VocabCraftApp/Domain/Widget/WidgetReloading.swift`, `VocabCraftApp/Domain/Widget/RefreshWidgetDeckUseCase.swift`
- Test: `VocabCraftAppTests/Features/Widget/RefreshWidgetDeckUseCaseTests.swift`
- Modify: `project.pbxproj`

**Interfaces:**
- Consumes: `WidgetDeckComposer.compose` (Task 2), `WidgetDeckStore` (Task 1), existing `FetchLearningPathUseCaseProtocol.execute() -> LearningPathCurriculum` (`decks`, `stages`, `words`, `progressList: [UserStageProgressData]` with `stageId`, `isCompleted`, `completedAt`), `UserProgressRepositoryProtocol.fetchAllProgress() -> [UserWordProgressData]` (`wordId`, `nextReviewDate`), `VocabularyDataSourceProtocol.fetchWordsByIds(ids:)`.
- Produces:
  - `public protocol WidgetReloading: Sendable { func reloadTimelines(ofKind kind: String) }` and `public struct WidgetCenterReloader: WidgetReloading` (calls `WidgetCenter.shared.reloadTimelines`; guard with `#if canImport(WidgetKit)`).
  - `public protocol RefreshWidgetDeckUseCaseProtocol: Sendable { func execute() async }` (non-throwing: failures are logged with `print("[RefreshWidgetDeck] …")`, matching the codebase's existing logging, and swallowed).
  - `public final class RefreshWidgetDeckUseCase: RefreshWidgetDeckUseCaseProtocol { init(fetchLearningPath: FetchLearningPathUseCaseProtocol, progressRepository: any UserProgressRepositoryProtocol, dataSource: VocabularyDataSourceProtocol, store: WidgetDeckStore, reloader: WidgetReloading, now: @escaping @Sendable () -> Date = Date.init) }`

Input rules:
- **due** = progress rows with `nextReviewDate <= now`, sorted by `nextReviewDate` ascending, resolved via `fetchWordsByIds`. Order follows the sorted ids; ids the data source cannot resolve are skipped.
- **recent** = words (from `curriculum.words`, grouped by `stageId`) of stages whose `progressList` entry `isCompleted`, ordered by `completedAt` descending, then by word order within the stage.
- **upcoming** = words of the FIRST incomplete stage in path order (deck `sortOrder`, then stage `sortOrder`), falling through only to the next incomplete stage that has words (spec D3). It does not continue into later stages to fill 36 words.
- `pathId` = `curriculum.activePath?.id`.

- [ ] **Step 1: Write failing tests** with in-file mocks `MockFetchLearningPath`, `MockProgressRepo` (only `fetchAllProgress` is meaningful; other requirements `fatalError` or no-op), the existing test data source mock if one exists in `VocabCraftAppTests/Mocks` (check first), and `MockReloader` recording kinds:
  - `writesDeckAndReloads`: curriculum with stage A completed (words 1,2) and stage B incomplete (words 3,4); progress for word 1 has `nextReviewDate` in the past → saved deck ids `[1,2,3,4]` with word 1 `.due` and word 2 `.recent`; `reloader.kinds == ["VocabWidget"]`.
  - `recentOrderedByCompletionDate`: stages A (completed yesterday) and C (completed today) → C's words come before A's.
  - `upcomingFollowsPathOrder`: two incomplete stages in different decks → words of the lower deck `sortOrder` first.
  - `failureDoesNotThrowOrWrite`: fetch path throws → `execute()` returns, `store.loadDeck() == nil`, no reload.
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/RefreshWidgetDeckUseCaseTests`. Expected: build failure.
- [ ] **Step 3: Implement** both files per the interfaces and input rules.
- [ ] **Step 4: Run** the suite. Expected: 4 pass.
- [ ] **Step 5: Commit** `feat(widget): refresh widget deck from learning path and SRS`.

---

### Task 4: Wire deck refresh into the app

**Files:**
- Create: `VocabCraftApp/Domain/Widget/WidgetRefreshingCompleteLessonUseCase.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift` (add `public let refreshWidgetDeckUseCase: RefreshWidgetDeckUseCaseProtocol`; wrap `self.completeLessonUseCase` around line 145 in the decorator), `VocabCraftApp/App/VocabCraftApp.swift` (add `@Environment(\.scenePhase)`; `.onChange(of: scenePhase)` → when `.background`, `Task { await bootstrapper.appContainer?.refreshWidgetDeckUseCase.execute() }`)
- Test: `VocabCraftAppTests/Features/Widget/WidgetRefreshingCompleteLessonUseCaseTests.swift`
- Modify: `project.pbxproj`

**Interfaces:**
- Consumes: `RefreshWidgetDeckUseCaseProtocol` (Task 3), existing `CompleteLessonUseCaseProtocol` (both `execute` overloads).
- Produces: `public final class WidgetRefreshingCompleteLessonUseCase: CompleteLessonUseCaseProtocol { init(wrapped: CompleteLessonUseCaseProtocol, refresh: RefreshWidgetDeckUseCaseProtocol) }`. Forward both overloads; after a successful `execute`, start `Task { await refresh.execute() }` (fire-and-forget, so it never delays the result). On error, rethrow without refreshing.

Note: `EvaluateSRSUseCase` has no production call site today, so it needs no hook. Backgrounding covers every other path.

- [ ] **Step 1: Write failing tests** using a spy refresh that completes a `CheckedContinuation` or an `AsyncStream` when called:
  - `refreshesAfterSuccessfulLesson`: wrapped returns a result → the decorator returns the same result and the spy is called once (await the stream with a 1 s timeout).
  - `doesNotRefreshWhenLessonFails`: wrapped throws → the error propagates and the spy is never called (wait 200 ms, then `#expect(spy.count == 0)`).
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/WidgetRefreshingCompleteLessonUseCaseTests`. Expected: build failure.
- [ ] **Step 3: Implement** the decorator, then wire `AppContainer`: construct `RefreshWidgetDeckUseCase(fetchLearningPath: self.fetchLearningPathUseCase, progressRepository: resolvedUserProgressRepo, dataSource: resolvedDataSource, store: .appGroup(), reloader: WidgetCenterReloader())`. Then add the `scenePhase` hook.
- [ ] **Step 4: Run** the suite plus `-only-testing:VocabCraftAppTests/AppContainerAITests` (DI smoke). Expected: pass.
- [ ] **Step 5: Commit** `feat(widget): refresh widget deck on background and lesson completion`.

---

### Task 5: WidgetTimelineBuilder

**Files:**
- Create: `VocabCraftWidgetExtension/Timeline/WidgetTimelineBuilder.swift`
- Test: `VocabCraftAppTests/Features/Widget/WidgetTimelineBuilderTests.swift`
- Modify: `project.pbxproj` (new `Timeline` group in the widget group; Widget + Test Sources). Remove `VocabWidgetEntry` from `VocabWidgetView.swift`, since it moves here.

**Interfaces:**
- Consumes: `WidgetDeck`, `WidgetCard`, `WidgetInteractionState` (Task 1).
- Produces:
  - `public enum WidgetEntryMode: Equatable, Sendable { case placeholder, passive, flashcardFront, flashcardBack }`
  - `public struct VocabWidgetEntry: TimelineEntry, Equatable { date: Date; card: WidgetCard?; mode: WidgetEntryMode; dueCount: Int; static func placeholder(at: Date) -> VocabWidgetEntry }`
  - `public enum WidgetReloadPlan: Equatable, Sendable { case atEnd, after(Date), never }`
  - `public enum WidgetTimelineBuilder { static let rotationInterval: TimeInterval = 300; static let maxEntries = 36; static func build(deck: WidgetDeck?, dueWordIds: Set<Int64>, nextDueDate: Date?, interaction: WidgetInteractionState, now: Date) -> (entries: [VocabWidgetEntry], reload: WidgetReloadPlan) }`

Rules: placeholder when the deck is nil or empty → one `.placeholder` entry, `.after(now + 3600)`. Flashcard when any deck card id is in `dueWordIds` → one entry for the first due card in deck order; mode `.flashcardBack` iff `interaction.revealedWordId == card.wordId`, else `.flashcardFront`; `dueCount` = number of deck cards that are due; `.never`. Passive otherwise: `slot = Int(now.timeIntervalSince1970 / 300)`, card index `(slot + i) % passive.count`, entry `i` dated `i == 0 ? now : Date(timeIntervalSince1970: Double(slot + i) * 300)`, `i` in `0..<maxEntries`. Drop entries dated `>= nextDueDate`. Reload is `.after(nextDueDate)` if any entry was dropped, else `.atEnd`. Passive entries have `dueCount = 0`.

- [ ] **Step 1: Write failing tests** (fixed `now = Date(timeIntervalSince1970: 1_800_000_000)`, which is divisible by 300):
  - `nilDeckGivesPlaceholder`: one entry, mode `.placeholder`, reload `.after(now + 3600)`.
  - `passiveEntriesFiveMinutesApart`: 3-card deck, no due → 36 entries; `entries[1].date.timeIntervalSince(entries[0].date) == 300`; reload `.atEnd`.
  - `rotationContinuesAcrossReloads` (Review Focus 2): `build(now)` and `build(now + 120)` have the same first card; `build(now + 300)` has the first card equal to `build(now).entries[1].card`.
  - `shortDeckCycles` (Review Focus 4): 6 cards → 36 entries, all with a non-nil card, and `entries[6].card == entries[0].card`.
  - `dueWordGivesSingleFlashcard`: card 2 due → one entry, card id 2, `.flashcardFront`, `dueCount == 1`, `.never`.
  - `revealStateFlipsOnlyMatchingCard`: revealed id 2 with card 2 due → `.flashcardBack`; revealed id 9 → `.flashcardFront`.
  - `allCardsDueStaysInFlashcard` (Review Focus 3): 3 cards all due → `dueCount == 3`, mode flashcard; same deck with the first card removed from `dueWordIds` → `dueCount == 2`, card is the second card.
  - `passiveCappedAtNextDueDate`: `nextDueDate = now + 1000` → entries dated `< now + 1000` only (4 entries), reload `.after(now + 1000)`.
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/WidgetTimelineBuilderTests`. Expected: build failure.
- [ ] **Step 3: Implement** per the rules.
- [ ] **Step 4: Run** the suite. Expected: 8 pass.
- [ ] **Step 5: Commit** `feat(widget): build passive and flashcard timelines`.

---

### Task 6: Due query and review recorder

**Files:**
- Create: `VocabCraftWidgetExtension/Review/WidgetDueQuery.swift`, `VocabCraftWidgetExtension/Review/WidgetReviewRecorder.swift`
- Test: `VocabCraftAppTests/Features/Widget/WidgetReviewRecorderTests.swift`
- Modify: `project.pbxproj` (new `Review` group; Widget + Test Sources)

**Interfaces:**
- Consumes: `UserWordProgress` (SwiftData), `SRSEngine.calculateNextInterval(currentMastery:easeFactor:isCorrect:responseTimeMs:) -> SRSResult` (`nextMastery`, `easeFactor`, `intervalDays`), `WidgetInteractionState` (Task 1).
- Produces:
  - `public enum WidgetDueQuery { @MainActor static func dueStatus(for wordIds: [Int64], in context: ModelContext, now: Date) throws -> (due: Set<Int64>, nextDueDate: Date?) }`. `nextDueDate` = the earliest `nextReviewDate > now` among those ids.
  - `public enum WidgetReviewRecorder { static let responseTimeRange = 1_000...10_000; @MainActor @discardableResult static func grade(wordId: Int64, remembered: Bool, interaction: WidgetInteractionState, now: Date, in context: ModelContext) throws -> Bool }`. Returns `false` (no write) when `interaction.revealedWordId != wordId` or no progress row exists.

Grade effects on the existing row: `responseTimeMs = clamp(Int(now - revealedAt) * 1000)`; apply the `SRSResult` to `masteryLevel` (clamped `0...5`), `easeFactor`, `intervalDays`; `nextReviewDate = now + intervalDays days`; `lastReviewDate = now`; `totalReviews += 1`. Remembered → `needsReview = false`, `consecutiveCorrectStreak += 1`. Forgot → `needsReview = true`, `mistakeCount += 1`, `consecutiveCorrectStreak = 0`. Then `context.save()`.

- [ ] **Step 1: Write failing tests** (in-memory `SharedAppGroupContainer.createContainer(inMemory: true)`, `@MainActor`):
  - `dueStatusSplitsDueAndNext`: rows for ids 1 (past) and 2 (now + 1 h); id 3 has no row → `due == [1]`, `nextDueDate == now + 1h`.
  - `rememberedAdvancesSchedule`: a mastery-1 row, revealed 3 s earlier → returns `true`; `masteryLevel == 2`, `nextReviewDate > now`, `needsReview == false`, `totalReviews` incremented.
  - `forgotResetsAndFlags`: → `masteryLevel == 0`, `needsReview == true`, `mistakeCount` +1, `nextReviewDate == now + 1 day`.
  - `responseTimeIsClamped`: revealed 0 s earlier vs 60 s earlier produce the same `easeFactor` as passing `1_000` and `10_000` directly to `SRSEngine`.
  - `gradeWithoutRevealIsRejected`: `interaction.revealedWordId == nil` → returns `false`, row unchanged.
  - `missingProgressInsertsNothing`: id 99 revealed → returns `false`, row count unchanged.
  - `gradeAppliesAfterDeckRebuilt` (Review Focus 1): grade word 1 with a revealed state while no deck exists → returns `true` and the row is updated.
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/WidgetReviewRecorderTests`. Expected: build failure.
- [ ] **Step 3: Implement** both files.
- [ ] **Step 4: Run** the suite. Expected: 7 pass.
- [ ] **Step 5: Commit** `feat(widget): query due words and record widget reviews`.

---

### Task 7: Intents and provider; remove legacy intents

**Files:**
- Create: `VocabCraftWidgetExtension/AppIntents/RevealCardIntent.swift`, `VocabCraftWidgetExtension/AppIntents/GradeCardIntent.swift`
- Rewrite: `VocabCraftWidgetExtension/VocabWidget.swift` (provider)
- Delete: `VocabCraftWidgetExtension/AppIntents/NextWordIntent.swift`, `MarkLearnedIntent.swift`, `VocabCraftAppTests/Features/Widget/NextWordIntentTests.swift`, `VocabCraftAppTests/WidgetIntentsTests.swift` (all of its tests target removed types). Remove their `project.pbxproj` entries (file ref, build files, group children, phase entries) and the `BundledVocabularyDataSource.swift` / `vocabulary_catalog.json` **Widget** build entries only (the app still uses them).
- Test: `VocabCraftAppTests/Features/Widget/WidgetIntentsTests.swift` (new file, same suite name `"Widget Intents"`)

**Interfaces:**
- Consumes: Tasks 1, 5, 6.
- Produces:
  - `public struct RevealCardIntent: AppIntent { @Parameter var wordId: Int; init(); init(wordId: Int64); @MainActor func perform(store: WidgetDeckStore, now: Date) throws }`. `perform()` calls this with `.appGroup()` and `Date()`, then `WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.vocab)`. AppIntent parameters cannot be `Int64`, so convert.
  - `public struct GradeCardIntent: AppIntent { @Parameter var wordId: Int; @Parameter var remembered: Bool; init(); init(wordId: Int64, remembered: Bool); @MainActor func perform(store: WidgetDeckStore, context: ModelContext, now: Date) throws }`. Calls `WidgetReviewRecorder.grade`. If it returns `true`, it saves `.empty` interaction state. If grading throws, the interaction is left as is and the error rethrows.
  - `VocabWidgetProvider: TimelineProvider` using `WidgetDeckStore.appGroup()`, `WidgetDueQuery.dueStatus` (on a `ModelContext(WidgetContainerHolder.sharedContainer)`; nil container → empty due set) and `WidgetTimelineBuilder.build`, mapping `WidgetReloadPlan` → `TimelineReloadPolicy`. `placeholder`/`getSnapshot` use `VocabWidgetEntry.placeholder(at:)` when there is no deck. Keep `WidgetContainerHolder`.
  - Titles/descriptions: `app.widget.intent.reveal.title|description`, `app.widget.intent.grade.title|description` (strings are added in Task 8; until then the keys resolve to themselves, which is fine for tests).

- [ ] **Step 1: Write failing tests** in the new `WidgetIntentsTests` (temp-dir store, in-memory container):
  - `revealStoresWordAndTime`: `perform(store:now:)` with wordId 5 → `store.loadInteraction() == .init(revealedWordId: 5, revealedAt: now)`.
  - `gradeClearsInteractionOnSuccess`: reveal 5, then grade remembered on an existing row 5 → interaction is `.empty`, row updated.
  - `gradeKeepsInteractionWhenRejected`: reveal 5, grade wordId 6 → interaction still has 5.
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/WidgetIntentsTests`. Expected: build failure.
- [ ] **Step 3: Implement** the intents and the provider, delete the legacy files, and fix the pbxproj.
- [ ] **Step 4: Run** the suite, then the full `VocabCraftAppTests` and `swift build`. Expected: all pass. (Task 8 rewrites the view; `VocabWidgetView` must compile against the new entry now, so do a minimal adaptation here that renders `entry.card?.lemma`.)
- [ ] **Step 5: Commit** `feat(widget): reveal and grade intents with deck-driven provider`.

---

### Task 8: Widget views, CraftUIKit, strings, families

**Files:**
- Rewrite: `VocabCraftWidgetExtension/VocabWidgetView.swift`
- Modify: `VocabCraftWidgetExtension/VocabWidget.swift` (families `[.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline]` on iOS, `[.systemSmall, .systemMedium]` otherwise; `.contentMarginsDisabled()` is not needed)
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`, `VocabCraftApp/Core/Localization/AppStrings.swift` (drop `next`, `nextText`, `mastered`, `masteredText`, `level*` from `AppStrings.Widget`)
- Modify: `project.pbxproj`: link CraftUIKit to the widget target. Add `90000000000000000000000A /* CraftUIKit in Frameworks */ = {isa = PBXBuildFile; productRef = 900000000000000000000002 /* CraftUIKit */; };`, add it to the widget Frameworks phase `100000402D50000000000000`, and add `packageProductDependencies = ( 900000000000000000000002 /* CraftUIKit */, );` to target `600000022D50000000000000`.
- Test: `VocabCraftAppTests/Features/Widget/WidgetLocalizationTests.swift`, `VocabCraftAppTests/Features/Homepage/HomeLocalizationTests.swift` (`testAppStringsWidgetAccessors` → only `displayNameText`/`descriptionText`)

**Strings** (add; EN / VI):

| Key | EN | VI |
|---|---|---|
| `app.widget.description` (update) | Learn words from your path right on your Home Screen. | Học từ trong lộ trình ngay trên màn hình chính. |
| `app.widget.badge.new` | New | Mới |
| `app.widget.badge.review` | Review | Ôn |
| `app.widget.action.reveal` | Reveal | Hiện nghĩa |
| `app.widget.action.remembered` | Remembered | Nhớ |
| `app.widget.action.forgot` | Forgot | Quên |
| `app.widget.hidden_meaning` | Recall the meaning, then reveal | Nhớ lại nghĩa rồi bấm hiện |
| `app.widget.due_count_format` | %lld words to review | %lld từ cần ôn |
| `app.widget.lock.open_to_review` | Open to review | Mở để ôn |
| `app.widget.empty.title` | Open VocabCraft to start | Mở VocabCraft để bắt đầu |
| `app.widget.intent.reveal.title` / `.description` | Reveal meaning / Shows the meaning of the current card | Hiện nghĩa / Hiện nghĩa của thẻ hiện tại |
| `app.widget.intent.grade.title` / `.description` | Grade card / Records whether you remembered the word | Chấm thẻ / Ghi lại bạn có nhớ từ hay không |

Remove: `app.widget.next`, `app.widget.mastered`, `app.widget.level_format`, `app.widget.placeholder.*`, `app.widget.intent.next_word.*`, `app.widget.intent.mark_learned.*`.

**Interfaces:**
- Consumes: `VocabWidgetEntry`, `WidgetEntryMode` (Task 5), `RevealCardIntent(wordId:)`, `GradeCardIntent(wordId:remembered:)` (Task 7), `CraftBadge(_:symbol:variant:tone:size:)`, `CraftSymbol` (`.eye`, `.checkmarkCircle`, `.wrongCircle`, `.sparkles`, `.refresh`).
- Produces: `public struct VocabWidgetView: View { init(entry: VocabWidgetEntry) }` with one private subview per family × mode, laid out per spec §3. Badge: `.upcoming` → `app.widget.badge.new` / `.sparkles` / tone `.primary`; `.recent`/`.due` → `app.widget.badge.review` / `.refresh` / tone `.success`. Medium front masks the lemma in `exampleEn` (case-insensitive) as `"_____"` via `static func maskedExample(_ example: String, lemma: String) -> String`. Lock rectangular in flashcard modes and the placeholder use `.widgetURL(URL(string: "vocabcraft://review"))` / `"vocabcraft://home"`. Use `.containerBackground(theme.colors.surfaceCard, for: .widget)` and `.widgetAccentable()` on lemma text and badges. The `app.widget.due_count_format` line appears only in flashcard modes. Passive mode implies zero due words, which corrects the spec §3 table's passive-medium cell. Buttons reuse their action keys as `accessibilityLabel`. The masked example sets its `.accessibilityLabel` to the masked sentence with the mask token replaced by the localized word `app.widget.accessibility.blank`, so VoiceOver never reads the answer. The `WidgetInteractionState` and `VocabWidgetEntry` initialisers used by intents and views must be explicit `public init`s.

- [ ] **Step 1: Write failing tests:**
  - `WidgetLocalizationTests.widgetKeysHaveFullParity`: every key in the table above resolves to a non-key value in `en` and `vi`, using the existing loop pattern.
  - `WidgetLocalizationTests.removedKeysAreGone`: load the catalog JSON (same helper approach as `HomeLocalizationTests.loadCatalogStrings`) and `#expect` none of the removed keys are present.
  - `VocabWidgetViewTests.maskedExampleHidesLemma`: `maskedExample("I Run every day", lemma: "run") == "I _____ every day"`; with no match the example is unchanged.
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/WidgetLocalizationTests -only-testing:VocabCraftAppTests/VocabWidgetViewTests`. Expected: FAIL.
- [ ] **Step 3: Implement** the strings, the views and the pbxproj link. Update `HomeLocalizationTests`.
- [ ] **Step 4: Run** those suites plus `HomeLocalizationTests`, then build the `VocabCraftWidgetExtension` target: `xcodebuild build -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`. Expected: pass, and no new SwiftLint warnings in the widget files.
- [ ] **Step 5: Commit** `feat(widget): CraftUIKit widget views with flashcard states`.

---

### Task 9: `vocabcraft://review` deep link

**Files:**
- Modify: `VocabCraftApp/App/Navigation/AppRouter.swift` (add `public var pendingSmartReview: Bool = false`; in `handleDeepLink`, add `else if host == "review" { pendingSmartReview = true; selectTab(.vocabulary) }` before the final `else`)
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift` (`.onChange(of: appRouter.pendingSmartReview)` and `.onAppear`: if true → `isPresentingSmartReview = true; appRouter.pendingSmartReview = false`. Get `appRouter` from `@Environment(\.appRouter)` as `HomepageView` does)
- Test: `VocabCraftAppTests/AppRouterTests.swift`

- [ ] **Step 1: Write failing test** `reviewDeepLinkOpensSmartReview`: `handleDeepLink(url: URL(string: "vocabcraft://review")!)` → `selectedTab == .vocabulary`, `pendingSmartReview == true`.
- [ ] **Step 2: Run** `-only-testing:VocabCraftAppTests/AppRouterTests`. Expected: FAIL.
- [ ] **Step 3: Implement** the router branch and the view hook.
- [ ] **Step 4: Run** `AppRouterTests`. Expected: pass.
- [ ] **Step 5: Commit** `feat(widget): route review deep link to smart review`.

Note: cold-launch replay (a link that arrives before the app container exists) is handled in `AppBootstrapper.handleDeepLink(_:)`, which stores a pending URL and routes it once `bootstrap()` succeeds; `.onOpenURL` calls it instead of the router directly.

---

### Task 10: Docs and end-to-end verification

**Files:**
- Modify: `openwiki/features/widgets-and-intents.md`: rewrite Entrypoints, Mechanisms, Invariants, Failure and Tests to match the shipped design (deck file, composer, timeline builder, reveal/grade intents, due definition, families). Remove the claims about `FetchPersonalVaultUseCase`, `ToggleWordBookmarkUseCase` and `ModelActor` intents.

- [ ] **Step 1: Run** the full suite: `xcodebuild test -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` and `swift build`. Expected: all green. Report any failure verbatim.
- [ ] **Step 2: Manual check on the iPhone 17 Pro Simulator.** Install the app and complete a lesson, then background the app. Add small, medium and Lock Screen rectangular widgets. Confirm that: a passive word from the lesson shows with a badge; advancing the simulator clock by 5 minutes changes the word; setting a word's `nextReviewDate` in the past (complete a lesson, then advance the clock 1 day) shows the flashcard front; Reveal → back; Remembered → the next card or passive mode; the word's progress in Personal Vault reflects the review; tapping the Lock Screen flashcard opens Smart Review. Capture screenshots of each state.
- [ ] **Step 3: Update** the wiki page.
- [ ] **Step 4: Commit** `docs(widget): document path-aware widget learning`.
