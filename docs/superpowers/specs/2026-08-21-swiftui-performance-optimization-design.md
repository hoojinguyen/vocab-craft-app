# SwiftUI & Data Layer Performance Optimization Design Spec

> **Status:** Draft  
> **Date:** 2026-08-21  
> **Author:** Antigravity Team  
> **Target Platforms:** iOS 17+, macOS 14+  
> **Frameworks:** SwiftUI, SwiftData, SQLite3, AVFoundation, Speech  

---

## 1. Executive Summary & Goals

### 1.1 Goal
Remediate the critical and moderate performance bottlenecks identified across VocabCraft's SwiftUI view hierarchy and SQLite/SwiftData repository layer to achieve:
- **Zero UI Hitching (60/120 fps ProMotion)** during active Reflex Blitz drills and microphone listening.
- **Instant Search & Filter response (< 1ms)** in Personal Vocabulary Bank by eliminating repeated $O(N)$ linear scans on every keystroke.
- **Smooth transitions & preserved view state** in `HomepageView` by stabilizing root view identity.
- **Zero Main Thread I/O blocking** by batching SQLite aggregations into single-roundtrip queries.

### 1.2 Tech Stack & Constraints
- **SwiftUI + Observation Framework (`@Observable`)**
- **Swift 5.10 / Swift 6 strict concurrency compliance (`@MainActor`, `Sendable`)**
- **SwiftData + C-SQLite3 (`DatasetEngine`)**
- **Instruments Target Metrics:** Long View Body Updates $< 8.3\text{ms}$ on 120Hz ProMotion screens, 0 hangs $> 100\text{ms}$.

---

## 2. Identified Bottlenecks & Remediation Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                                PERFORMANCE BOTTLENECKS                                    │
├──────────────────────────┬───────────────────────────────┬───────────────────────────────┤
│ 1. Dynamic Root `.id()`  │ 2. High-Frequency 120ms Timer │ 3. $O(N)$ Filter Invalidation │
│    Spurious view resets  │    Entire visualizer redraws  │    Scans array 7x / keystroke │
├──────────────────────────┼───────────────────────────────┼───────────────────────────────┤
│ 4. Regex in `body`       │ 5. N+1 SQLite on Main Thread  │ 6. Tab Switch Reload Storm    │
│    Pattern search on draw│    $1 + D + (D \times N)$ runs│    Uncached task invocations  │
└──────────────────────────┴───────────────────────────────┴───────────────────────────────┘
                                           │
                                           ▼
┌──────────────────────────────────────────────────────────────────────────────────────────┐
│                                 OPTIMIZED ARCHITECTURE                                   │
├──────────────────────────┬───────────────────────────────┬───────────────────────────────┤
│ Stable Identity Tree     │ Subview-Isolated Timer Scope  │ Precomputed Filter Dictionary │
│ Reactive phase switching │ Only 7 equalizer bars redraw  │ Computed on `wordItems` update│
├──────────────────────────┼───────────────────────────────┼───────────────────────────────┤
│ Precomputed Cloze Model  │ Single Aggregated SQL JOIN    │ Guarded `loadData()`          │
│ Parsed once on init      │ 1 SQLite query per deck audit │ `guard items.isEmpty`         │
└──────────────────────────┴───────────────────────────────┴───────────────────────────────┘
```

---

## 3. Detailed Component Specifications

### 3.1 Component 1: `HomepageView` Root Identity Stabilization

#### Problem
In `HomepageView.swift`, `reflexBlitzViewId` is computed dynamically as:
```swift
private var reflexBlitzViewId: String {
    guard let vm = reflexBlitzVM else { return "default" }
    return "\(vm.selectedMode.rawValue)-\(vm.phase)-\(vm.cardPhase)"
}
```
Applying `.id(reflexBlitzViewId)` to `ReflexBlitzView` forces SwiftUI to completely destroy and re-instantiate `ReflexBlitzView` on every card phase change (e.g. active countdown $\rightarrow$ reviewed, question advance, timeout). This causes:
- Drop of asymmetric slide/fade transitions.
- Focus and gesture state loss.
- Immediate firing of `onDisappear { viewModel.cancelSession() }`, interrupting audio pipelines.

#### Solution
1. Remove `.id(reflexBlitzViewId)` from `HomepageView.swift`.
2. Guard `viewModel.loadData()` inside `.task` so switching back to the Home tab does not reload SQLite data when `state.suggestedWords` is already loaded.

---

### 3.2 Component 2: `VocabSpeechVisualizerView` & Isolated `EqualizerBarsView`

#### Problem
`VocabSpeechVisualizerView` declares `@State private var barHeights: [CGFloat] = [12, 24, 18, 30, 16, 26, 14]`. When listening, `.task(id: isListening)` executes a loop mutating `barHeights` every `120ms`. Because `barHeights` belongs to `VocabSpeechVisualizerView`, the entire view hierarchy (header label, evaluation badge, tokens highlight view with `SpeechFlowLayout`, text display) undergoes body re-evaluation 8.3 times per second.

#### Solution
Extract the equalizer sound bars into an isolated subview `EqualizerBarsView`:
- Encapsulates its own `@State private var barHeights: [CGFloat]`.
- Houses `.task(id: isListening)`.
- Scopes 120ms state mutations exclusively to the 7 bar capsules.
- `VocabSpeechVisualizerView` body remains completely static during speech streaming unless text or evaluation changes.

---

### 3.3 Component 3: `VocabularyViewModel` & `VocabularyFilterService` Memoization

#### Problem
`VocabularyView` renders:
- 6 `filterPill(filter)` instances, each calling `vm.filterCount(for: filter)` which executes `.filter { ... }.count` on `wordItems`.
- `VocabularySummaryCard` which calls `vm.filterCount(for: .needsReview)`.
- `vm.filteredWords` which executes full substring matching across `lemma` and `definition`.
- Result: Typing a search query triggers 7+ full array iterations synchronously on `MainActor` per keystroke.

#### Solution
1. **Precomputed Counts Cache**:
   In `VocabularyViewModel`, maintain `private(set) var filterCounts: [VocabularyFilter: Int] = [:]`.
   Update `filterCounts` **only when `wordItems` changes** (on load, delete, or mastery toggle).
2. **O(1) Count Lookups**:
   `filterCount(for filter: VocabularyFilter) -> Int` returns `filterCounts[filter] ?? 0`.
3. **Optimized Search Filtering**:
   Keep `VocabularyFilterService.filter` pure and fast; pre-trim search text once rather than repeatedly inside closures.

---

### 3.4 Component 4: `ReflexBlitzCardView` Cloze Parsing Precomputation

#### Problem
`clozeParts` in `ReflexBlitzCardView` is a computed property executing regex matching (`firstMatch(in:options:range:)`) and substring splitting on every view evaluation (e.g. keyboard input, hint activation, animation ticks).

#### Solution
1. Precompute `clozeParts: ClozeSentenceParts?` on `ReflexBlitzWordItem` during its factory instantiation or in `ReflexClozeFormatter`.
2. `ReflexBlitzCardView` consumes the pre-split sentence parts directly without running regex evaluation during body evaluation.

---

### 3.5 Component 5: `VocabularyRepositoryImpl` Batch SQL Aggregation

#### Problem
`VocabularyRepositoryImpl.fetchTopicDecks()` executes an $N+1$ query pattern:
1. Query 1: `fetchTopicDecks()` $\rightarrow D$ decks.
2. Query 2..$D+1$: `fetchSubTopicNodes(deckId:)` $\rightarrow N$ nodes per deck.
3. Query $D+2$..$D \times N$: `fetchWordsForNode(nodeId:)` $\rightarrow$ words per node.
4. Total queries: $1 + D + (D \times N)$ queries run synchronously on `MainActor`.

#### Solution
1. Introduce a batch SQLite query `fetchTopicDecksSummary()` in `DatasetEngine`:
   ```sql
   SELECT d.id, d.title, d.icon_name, d.badge_color_hex, d.sort_order,
          COUNT(nw.word_id) AS total_words
   FROM topic_decks d
   LEFT JOIN topic_nodes n ON d.id = n.deck_id
   LEFT JOIN node_words nw ON n.id = nw.node_id
   GROUP BY d.id
   ORDER BY d.sort_order ASC;
   ```
2. Batch query word progress from `UserProgressModelActor` in a single pass to compute `learnedWords` without querying individual node words in nested loops.

---

### 3.6 Component 6: `SRSSparkleEffectView` Structured Concurrency & Lifecycle Cancellation

#### Problem
`SRSSparkleEffectView` uses `DispatchQueue.main.asyncAfter(0.3s)` and `DispatchQueue.main.asyncAfter(0.8s)` to clear particles. If the user navigates away before the delay expires, closures still execute and mutate state on orphaned views.

#### Solution
Adopt `.task(id: isEmitting)` with `Task.sleep` and automatic cancellation on view disappear:
```swift
.task(id: isEmitting) {
    guard isEmitting else { return }
    triggerBurst()
    try? await Task.sleep(for: .milliseconds(300))
    withAnimation(.easeOut(duration: 0.5)) { fadeParticles() }
    try? await Task.sleep(for: .milliseconds(500))
    particles.removeAll()
    isEmitting = false
}
```

---

## 4. Non-Functional Requirements & Safety

1. **Clean Architecture Integrity**: Domain entities and use-cases remain pure and platform-independent.
2. **Backward Compatibility**: Existing public initializers and methods remain compatible or use non-breaking defaults.
3. **Accessibility**: All accessibility labels (`.accessibilityLabel`, `.accessibilityElement`) must be preserved without regressions.
4. **Test Suite Guarantee**: All 386+ automated unit tests in `VocabCraftAppTests` must continue to pass with 0 failures.

---

## 5. Verification & Validation Plan

### 5.1 Automated Unit Tests
- Execute `swift test` ensuring 100% pass rate across domain, repository, viewmodel, and component tests.
- Add new test cases verifying:
  - `VocabularyViewModel` precomputed `filterCounts` accuracy when words are added, modified, and deleted.
  - `HomepageViewModel` idempotence when `loadData()` is called multiple times.
  - `ReflexBlitzCardView` cloze precomputation matching regex expectations.

### 5.2 Performance & Profiling Benchmarks
- Run Release build in Xcode Instruments with the **SwiftUI Template**:
  - Verify `Long View Body Updates` lane shows no hitches during live speech recognition.
  - Verify `Update Groups` frequency drops by $> 80\%$ during `VocabSpeechVisualizerView` rendering.
  - Verify typing in `VocabularyView` search bar produces smooth 60/120 fps keystroke rendering with zero dropped frames.
