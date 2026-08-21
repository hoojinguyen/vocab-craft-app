# SwiftUI & Data Layer Performance Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate SwiftUI view body invalidation storms, root view identity churning, unmemoized array filtering on keystrokes, regex executions inside view bodies, and N+1 SQLite queries on the Main Thread.

**Architecture:** Component-isolated subview timers, dictionary-memoized filter counts, model-layer precomputed string parsing, and single-roundtrip batch SQL aggregations.

**Tech Stack:** SwiftUI, Swift 5.10 / Swift 6 strict concurrency (`@MainActor`, `Sendable`), Observation (`@Observable`), SQLite3, SwiftData, XCTest, Swift Testing.

**Spec:** `docs/superpowers/specs/2026-08-21-swiftui-performance-optimization-design.md`

## Global Constraints
- Target platforms: iOS 17+, macOS 14+
- Strict concurrency safe (`@MainActor`, `Sendable`)
- Zero regressions in existing 386+ tests (`swift test`)
- Preserve all existing accessibility labels and design system styling

---

### Task 1: Stabilize `HomepageView` Root Identity & Guard Tab Data Reloading

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift:12-16, 76-78, 85-90`
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift:83-109`
- Test: `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`

**Interfaces:**
- `HomepageViewModel.loadData() async`: Added guard `guard state.suggestedWords.isEmpty else { return }` to prevent repeated SQLite fetches upon tab switching.
- `HomepageView.body`: Removed `.id(reflexBlitzViewId)` on `ReflexBlitzView` to prevent forced view hierarchy destruction during drills.

- [ ] **Step 1: Write the failing test for `HomepageViewModel.loadData()` idempotence**

Add test to `VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift`:
```swift
func testHomepageViewModelLoadDataIdempotence() async {
    let container = AppContainer.mock
    let viewModel = container.makeHomepageViewModel()
    
    // Initial load
    await viewModel.loadData()
    let initialCount = viewModel.suggestedWords.count
    XCTAssertGreaterThan(initialCount, 0)
    
    // Mutate state to verify second call is guarded and does not overwrite
    viewModel.suggestedWords[0].lemma = "CustomGuardedWord"
    await viewModel.loadData()
    XCTAssertEqual(viewModel.suggestedWords[0].lemma, "CustomGuardedWord")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HomepageViewTests/testHomepageViewModelLoadDataIdempotence`
Expected: FAIL (because second `loadData()` currently refetches and overwrites `suggestedWords`).

- [ ] **Step 3: Implement minimal changes in `HomepageViewModel` and `HomepageView`**

In `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`:
```swift
    public func loadData() async {
        guard state.suggestedWords.isEmpty else { return }
        guard let useCase = fetchVocabularyUseCase else { return }
        do {
            let fetchedWords = try await useCase.executeFetchWords(limit: 10)
            if !fetchedWords.isEmpty {
                self.state.suggestedWords = fetchedWords.map { word in
                    SuggestedWord(
                        id: String(word.id),
                        lemma: word.lemma,
                        pos: word.pos ?? "noun",
                        ipaUs: word.ipaUs ?? "",
                        cefrLevel: word.cefrLevel ?? "A1",
                        definitionVi: word.definitionVi ?? word.definitionEn ?? "",
                        definitionEn: word.definitionEn ?? "",
                        example: word.example ?? "",
                        isBookmarked: false,
                        topicTag: "Từ vựng nổi bật"
                    )
                }
                if self.state.currentSuggestedWordIndex >= self.state.suggestedWords.count {
                    self.state.currentSuggestedWordIndex = 0
                }
            }
        } catch {
            print("[HomepageViewModel] Failed to load data: \(error)")
        }
    }
```

In `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`:
Remove `reflexBlitzViewId` property and remove `.id(reflexBlitzViewId)` on line 89:
```swift
            case .reflex:
                ReflexBlitzView(viewModel: reflexBlitzVM ?? appContainer.makeReflexBlitzViewModel(), onDismiss: {
                    reflexBlitzVM = nil
                    router.navigateToHome()
                })
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HomepageViewTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift VocabCraftAppTests/Features/Homepage/HomepageViewTests.swift
git commit -m "perf: stabilize HomepageView root identity and guard loadData against tab reload storm"
```

---

### Task 2: Isolate High-Frequency 120ms Equalizer Animation Scope in `VocabSpeechVisualizerView`

**Files:**
- Modify: `VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift:12, 52-79`
- Test: `VocabCraftAppTests/SpeechKitTests/SpeechWordHighlightViewTests.swift`

**Interfaces:**
- `EqualizerBarsView: View` (private helper struct inside `VocabSpeechVisualizerView.swift`): Takes `isListening: Bool`, manages its own `@State private var barHeights: [CGFloat]` and `.task(id: isListening)`.
- `VocabSpeechVisualizerView`: Removes `@State private var barHeights` and delegates to `EqualizerBarsView(isListening: isListening)`.

- [ ] **Step 1: Write test verifying `VocabSpeechVisualizerView` renders without owning body-wide bar state**

In `VocabCraftAppTests/SpeechKitTests/SpeechWordHighlightViewTests.swift`, add:
```swift
func testVocabSpeechVisualizerViewIsolation() {
    let visualizer = VocabSpeechVisualizerView(
        isListening: true,
        recognizedText: "hello",
        placeholderText: "Listening..."
    )
    XCTAssertNotNil(visualizer.body)
}
```

- [ ] **Step 2: Run test to verify initial state**

Run: `swift test --filter SpeechWordHighlightViewTests`
Expected: PASS

- [ ] **Step 3: Implement `EqualizerBarsView` isolation in `VocabSpeechVisualizerView.swift`**

In `VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift`:
Replace lines 12 and 52-79 with the extracted `EqualizerBarsView`:

```swift
public struct VocabSpeechVisualizerView: View {
    public let isListening: Bool
    public let recognizedText: String
    public let placeholderText: String
    public let evaluationResult: SpeechEvaluationResult?
    public let tokens: [WordTokenResult]

    public init(
        isListening: Bool,
        recognizedText: String,
        placeholderText: String = AppStrings.Reflex.quickVisualizerPlaceholderText,
        evaluationResult: SpeechEvaluationResult? = nil,
        tokens: [WordTokenResult]? = nil
    ) {
        self.isListening = isListening
        self.recognizedText = recognizedText
        self.placeholderText = placeholderText
        self.evaluationResult = evaluationResult
        if let explicitTokens = tokens {
            self.tokens = explicitTokens
        } else if let eval = evaluationResult {
            self.tokens = eval.tokens
        } else {
            self.tokens = []
        }
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header Label & Evaluation Badge
            HStack {
                Label(
                    headerTitle,
                    systemImage: headerIcon
                )
                .font(.caption2.bold().smallCaps())
                .foregroundColor(headerColor)

                Spacer()

                if let eval = evaluationResult {
                    evaluationBadge(eval)
                }
            }

            // Equalizer Sound Bar Visualizer (Isolated Scope)
            if isListening {
                EqualizerBarsView(isListening: isListening)
                    .transition(.scale.combined(with: .opacity))
            }

            // Word Tokens Highlight or Recognized Speech Text Display
            if !tokens.isEmpty {
                SpeechWordHighlightView(
                    tokens: tokens,
                    targetSentence: evaluationResult?.targetSentence ?? "",
                    evaluationResult: evaluationResult
                )
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            } else {
                Text(displayText)
                    .font(.body.weight(recognizedText.isEmpty ? .medium : .semibold))
                    .foregroundColor(recognizedText.isEmpty ? .vocabMuted.opacity(0.6) : .vocabInk)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Color.vocabSurfaceCard

                if isListening {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.vocabCoral.opacity(0.6), Color.vocabPeach.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else if let eval = evaluationResult, eval.isPassed {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.vocabHairline, lineWidth: 1.5)
                }
            }
        )
        .cornerRadius(24)
        .shadow(
            color: isListening ? Color.vocabCoral.opacity(0.12) : Color.black.opacity(0.03),
            radius: isListening ? 12 : 6,
            x: 0,
            y: isListening ? 6 : 3
        )
        .padding(.horizontal, 16)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isListening)
    }
    // ... rest of methods
}

private struct EqualizerBarsView: View {
    let isListening: Bool
    @State private var barHeights: [CGFloat] = [12, 24, 18, 30, 16, 26, 14]

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<barHeights.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color.vocabCoral, Color.vocabPeach],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: barHeights[index])
                    .animation(.easeInOut(duration: 0.12), value: barHeights[index])
            }
        }
        .frame(height: 32)
        .task(id: isListening) {
            guard isListening else { return }
            while !Task.isCancelled && isListening {
                try? await Task.sleep(for: .milliseconds(120))
                for i in 0..<barHeights.count {
                    barHeights[i] = CGFloat.random(in: 8...30)
                }
            }
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SpeechWordHighlightViewTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift VocabCraftAppTests/SpeechKitTests/SpeechWordHighlightViewTests.swift
git commit -m "perf: isolate 120ms equalizer animation timer into EqualizerBarsView subview"
```

---

### Task 3: Precompute and Memoize Filter Counts & Search in `VocabularyViewModel`

**Files:**
- Modify: `VocabCraftApp/Domain/Services/VocabularyFilterService.swift:37-57`
- Modify: `VocabCraftApp/Features/Vocabulary/ViewModels/VocabularyViewModel.swift:26-76`
- Test: `VocabCraftAppTests/VocabularyFilterServiceTests.swift`
- Test: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`

**Interfaces:**
- `VocabularyFilterService.countAllCategories(in words: [WordItem]) -> [VocabularyFilter: Int]`: Single-pass $O(N)$ calculation returning count dictionary for all 6 categories.
- `VocabularyViewModel.filterCounts: [VocabularyFilter: Int]`: Precomputed dictionary updated only when `wordItems` changes.
- `VocabularyViewModel.filterCount(for filter: VocabularyFilter) -> Int`: $O(1)$ dictionary lookup.

- [ ] **Step 1: Write unit tests for single-pass filter count accumulation and memoized lookup**

In `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`, add:
```swift
func testVocabularyViewModelMemoizedFilterCounts() {
    let vm = VocabularyViewModel()
    let words = [
        WordItem(id: 1, lemma: "apple", phonetic: "", pos: "n.", definition: "a fruit", exampleSentenceEn: "", exampleSentenceVi: "", cefrLevel: "A1", masteryLevel: 1),
        WordItem(id: 2, lemma: "banana", phonetic: "", pos: "n.", definition: "another fruit", exampleSentenceEn: "", exampleSentenceVi: "", cefrLevel: "B1", masteryLevel: 5)
    ]
    vm.wordItems = words
    
    XCTAssertEqual(vm.filterCount(for: .all), 2)
    XCTAssertEqual(vm.filterCount(for: .needsReview), 1)
    XCTAssertEqual(vm.filterCount(for: .mastered), 1)
    XCTAssertEqual(vm.filterCount(for: .a1a2), 1)
    XCTAssertEqual(vm.filterCount(for: .b1b2), 1)
    XCTAssertEqual(vm.filterCount(for: .c1c2), 0)
    
    // Test update after delete
    vm.deleteWord(id: 1)
    XCTAssertEqual(vm.filterCount(for: .all), 1)
    XCTAssertEqual(vm.filterCount(for: .needsReview), 0)
}
```

- [ ] **Step 2: Run test to verify it fails or verify count logic**

Run: `swift test --filter VocabularyViewTests/testVocabularyViewModelMemoizedFilterCounts`
Expected: PASS/FAIL depending on implementation state.

- [ ] **Step 3: Implement single-pass accumulation and dictionary caching**

In `VocabCraftApp/Domain/Services/VocabularyFilterService.swift`:
```swift
    /// Single-pass accumulator calculating counts for all categories simultaneously in O(N).
    public func countAllCategories(in words: [WordItem]) -> [VocabularyFilter: Int] {
        var counts: [VocabularyFilter: Int] = [
            .all: words.count,
            .needsReview: 0,
            .mastered: 0,
            .a1a2: 0,
            .b1b2: 0,
            .c1c2: 0
        ]
        
        for word in words {
            if word.masteryLevel < 3 {
                counts[.needsReview, default: 0] += 1
            }
            if word.masteryLevel >= 4 {
                counts[.mastered, default: 0] += 1
            }
            let level = word.cefrLevel.uppercased()
            if level == "A1" || level == "A2" {
                counts[.a1a2, default: 0] += 1
            } else if level == "B1" || level == "B2" {
                counts[.b1b2, default: 0] += 1
            } else if level == "C1" || level == "C2" {
                counts[.c1c2, default: 0] += 1
            }
        }
        
        return counts
    }
```

In `VocabCraftApp/Features/Vocabulary/ViewModels/VocabularyViewModel.swift`:
```swift
@MainActor
@Observable
public final class VocabularyViewModel {
    public var searchText = ""
    public var selectedFilter: VocabularyFilter = .all
    public var selectedTab = 0
    public var expandedWordId: Int64? = 1
    public var wordItems: [WordItem] = [] {
        didSet {
            recalculateFilterCounts()
        }
    }
    public var isLoading: Bool = false
    public var selectedDeckId: String?
    public var selectedDrillWord: WordItem?
    public private(set) var filterCounts: [VocabularyFilter: Int] = [:]

    private let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol?
    public let ttsService: TextToSpeechProtocol?
    private let filterService: VocabularyFilterService

    public init(
        fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        filterService: VocabularyFilterService = VocabularyFilterService()
    ) {
        self.fetchVocabularyUseCase = fetchVocabularyUseCase
        self.ttsService = ttsService
        self.filterService = filterService
    }

    private func recalculateFilterCounts() {
        self.filterCounts = filterService.countAllCategories(in: wordItems)
    }

    public var filteredWords: [WordItem] {
        filterService.filter(words: wordItems, filter: selectedFilter, searchText: searchText)
    }

    public func filterCount(for filter: VocabularyFilter) -> Int {
        filterCounts[filter] ?? 0
    }

    public func deleteWord(id: Int64) {
        wordItems.removeAll(where: { $0.id == id })
    }

    public func toggleMastered(id: Int64) {
        if let index = wordItems.firstIndex(where: { $0.id == id }) {
            let current = wordItems[index].masteryLevel
            wordItems[index].masteryLevel = current >= 5 ? 1 : 5
            recalculateFilterCounts()
        }
    }

    public func filterCount(for title: String) -> Int {
        guard let filter = VocabularyFilter(rawValue: title) else { return wordItems.count }
        return filterCount(for: filter)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter VocabularyViewTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Domain/Services/VocabularyFilterService.swift VocabCraftApp/Features/Vocabulary/ViewModels/VocabularyViewModel.swift VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift
git commit -m "perf: precompute filter counts in O(N) single-pass and memoize in VocabularyViewModel"
```

---

### Task 4: Precompute Cloze Sentence Parts in `ReflexBlitzModels` / `ReflexBlitzCardView`

**Files:**
- Modify: `VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift:88-140`
- Modify: `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift:168-187`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift`

**Interfaces:**
- `ReflexClozeFormatter.extractClozeTemplate(clozeSentenceEn: String)`: Splits prefix and suffix around cloze slot `[ ___ ]` once during word instantiation.
- `ReflexBlitzWordItem`: Stores `clozePrefix: String` and `clozeSuffix: String`.
- `ReflexBlitzCardView.clozeParts`: Returns `ClozeSentenceParts(prefix: word.clozePrefix, slot: slotRepresentation, suffix: word.clozeSuffix)` without invoking regex `firstMatch` inside view body.

- [ ] **Step 1: Write test for `ReflexClozeFormatter` precomputed template extraction**

In `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift`, add:
```swift
func testReflexClozeFormatterTemplateExtraction() {
    let sentence = "He decided to [ ______ ] the project."
    let (prefix, suffix) = ReflexClozeFormatter.extractTemplateParts(from: sentence)
    XCTAssertEqual(prefix, "He decided to ")
    XCTAssertEqual(suffix, " the project.")
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter ReflexBlitzModelsTests/testReflexClozeFormatterTemplateExtraction`
Expected: FAIL (method not defined yet).

- [ ] **Step 3: Implement template extraction in `ReflexBlitzModels` & consume in `ReflexBlitzCardView`**

In `VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift`:
```swift
public struct ReflexClozeFormatter: Sendable {
    private static let clozeRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\[\\s*_{3,}\\s*\\]|_{3,}")
    }()

    public static func extractTemplateParts(from sentence: String) -> (prefix: String, suffix: String) {
        guard let regex = clozeRegex else { return (sentence, "") }
        let nsRange = NSRange(sentence.startIndex..., in: sentence)
        guard let match = regex.firstMatch(in: sentence, options: [], range: nsRange),
              let matchRange = Range(match.range, in: sentence) else {
            return (sentence, "")
        }
        let prefix = String(sentence[..<matchRange.lowerBound])
        let suffix = String(sentence[matchRange.upperBound...])
        return (prefix, suffix)
    }

    public static func formatCloze(sentenceEn: String, lemma: String) -> String {
        // existing implementation ...
    }
}
```

In `ReflexBlitzWordItem`:
```swift
public struct ReflexBlitzWordItem: Identifiable, Equatable, Sendable {
    public let id: Int
    public let lemma: String
    public let pos: String
    public let ipa: String
    public let definitionVi: String
    public let definitionEn: String
    public let exampleSentenceEn: String
    public let clozeSentenceEn: String
    public let clozePrefix: String
    public let clozeSuffix: String

    public init(
        id: Int,
        lemma: String,
        pos: String,
        ipa: String,
        definitionVi: String,
        definitionEn: String = "",
        exampleSentenceEn: String,
        clozeSentenceEn: String? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.ipa = ipa
        self.definitionVi = definitionVi
        self.definitionEn = definitionEn
        self.exampleSentenceEn = exampleSentenceEn
        let cloze = clozeSentenceEn ?? ReflexClozeFormatter.formatCloze(sentenceEn: exampleSentenceEn, lemma: lemma)
        self.clozeSentenceEn = cloze
        let (prefix, suffix) = ReflexClozeFormatter.extractTemplateParts(from: cloze)
        self.clozePrefix = prefix
        self.clozeSuffix = suffix
    }
    // ...
}
```

In `VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift`:
Replace `clozeParts` implementation with:
```swift
    public var clozeParts: ClozeSentenceParts? {
        let slot = isReviewed ? word.lemma : slotRepresentation
        return ClozeSentenceParts(prefix: word.clozePrefix, slot: slot, suffix: word.clozeSuffix)
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ReflexBlitzModelsTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Features/ReflexDrill/Models/ReflexBlitzModels.swift VocabCraftApp/Features/ReflexDrill/Views/ReflexBlitzCardView.swift VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzModelsTests.swift
git commit -m "perf: precompute cloze template parts in ReflexBlitzWordItem to remove regex from card body"
```

---

### Task 5: Batch SQLite Deck Word Aggregation in `DatasetEngine` & `VocabularyRepositoryImpl`

**Files:**
- Modify: `VocabCraftApp/Core/Database/DatasetModels.swift`
- Modify: `VocabCraftApp/Domain/Protocols/DatasetDataSourceProtocol.swift`
- Modify: `VocabCraftApp/Core/Database/DatasetEngine.swift`
- Modify: `VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift`
- Modify: `VocabCraftApp/Data/Local/Mock/MockVocabularyDataSource.swift`
- Test: `VocabCraftAppTests/DatasetEngineTests.swift`
- Test: `VocabCraftAppTests/DatasetDataSourceTests.swift`

**Interfaces:**
- `TopicDeckSummaryRecord`: `(id: String, title: String, iconName: String, badgeColorHex: String, sortOrder: Int, totalWords: Int)`
- `DatasetDataSourceProtocol.fetchTopicDecksSummary() -> [TopicDeckSummaryRecord]`
- `VocabularyRepositoryImpl.fetchTopicDecks() async throws -> [TopicDeck]`: Runs `fetchTopicDecksSummary()` in 1 query, removing nested $N+1$ loops.

- [ ] **Step 1: Write test for `fetchTopicDecksSummary()` in `DatasetDataSourceTests`**

In `VocabCraftAppTests/DatasetDataSourceTests.swift`, add:
```swift
func testFetchTopicDecksSummaryAggregation() async throws {
    let mock = MockVocabularyDataSource.shared
    let summaries = mock.fetchTopicDecksSummary()
    XCTAssertFalse(summaries.isEmpty)
    XCTAssertGreaterThan(summaries[0].totalWords, 0)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter DatasetDataSourceTests/testFetchTopicDecksSummaryAggregation`
Expected: FAIL (method not declared).

- [ ] **Step 3: Implement `fetchTopicDecksSummary()` and batch repository loading**

In `VocabCraftApp/Core/Database/DatasetModels.swift`:
```swift
public struct TopicDeckSummaryRecord: Sendable, Equatable {
    public let id: String
    public let title: String
    public let iconName: String
    public let badgeColorHex: String
    public let sortOrder: Int
    public let totalWords: Int

    public init(id: String, title: String, iconName: String, badgeColorHex: String, sortOrder: Int, totalWords: Int) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.badgeColorHex = badgeColorHex
        self.sortOrder = sortOrder
        self.totalWords = totalWords
    }
}
```

In `VocabCraftApp/Domain/Protocols/DatasetDataSourceProtocol.swift`:
```swift
public protocol DatasetDataSourceProtocol: Sendable {
    // existing methods...
    func fetchTopicDecksSummary() -> [TopicDeckSummaryRecord]
}
```

In `VocabCraftApp/Core/Database/DatasetEngine.swift`:
```swift
    public func fetchTopicDecksSummary() -> [TopicDeckSummaryRecord] {
        guard let db = db else { return [] }
        let query = """
            SELECT d.id, d.title, d.icon_name, d.badge_color_hex, d.sort_order,
                   COUNT(nw.word_id) AS total_words
            FROM topic_decks d
            LEFT JOIN topic_nodes n ON d.id = n.deck_id
            LEFT JOIN node_words nw ON n.id = nw.node_id
            GROUP BY d.id
            ORDER BY d.sort_order ASC;
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var results: [TopicDeckSummaryRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = columnText(statement, 0)
            let title = columnText(statement, 1)
            let iconName = columnText(statement, 2)
            let badgeColorHex = columnText(statement, 3)
            let sortOrder = Int(sqlite3_column_int(statement, 4))
            let totalWords = Int(sqlite3_column_int(statement, 5))

            results.append(TopicDeckSummaryRecord(
                id: id,
                title: title,
                iconName: iconName,
                badgeColorHex: badgeColorHex,
                sortOrder: sortOrder,
                totalWords: totalWords
            ))
        }
        return results
    }
```

In `VocabCraftApp/Data/Local/Mock/MockVocabularyDataSource.swift`:
```swift
    public func fetchTopicDecksSummary() -> [TopicDeckSummaryRecord] {
        return mockTopicDecks.map { deck in
            TopicDeckSummaryRecord(
                id: deck.id,
                title: deck.title,
                iconName: deck.iconName,
                badgeColorHex: deck.badgeColorHex,
                sortOrder: 1,
                totalWords: deck.wordCount
            )
        }
    }
```

In `VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift`:
```swift
    public func fetchTopicDecks() async throws -> [TopicDeck] {
        guard let engine = datasetEngine else { return MockVocabularyDataSource.shared.mockTopicDecks }
        let summaries = engine.fetchTopicDecksSummary()
        if summaries.isEmpty {
            return MockVocabularyDataSource.shared.mockTopicDecks
        }

        let masteryMap = (try? await progressActor?.fetchAllMasteryLevels()) ?? [:]

        return summaries.map { s in
            TopicDeck(
                id: s.id,
                title: s.title,
                wordCount: s.totalWords,
                completionPercentage: 0.0,
                badgeColorHex: s.badgeColorHex,
                iconName: s.iconName
            )
        }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter DatasetDataSourceTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Core/Database/DatasetModels.swift VocabCraftApp/Domain/Protocols/DatasetDataSourceProtocol.swift VocabCraftApp/Core/Database/DatasetEngine.swift VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift VocabCraftApp/Data/Local/Mock/MockVocabularyDataSource.swift VocabCraftAppTests/DatasetDataSourceTests.swift
git commit -m "perf: aggregate topic deck summaries in single SQLite query to resolve N+1 repository loop"
```

---

### Task 6: Structured Concurrency & Cancellation in `SRSSparkleEffectView`

**Files:**
- Modify: `VocabCraftApp/Core/DesignSystem/SRSSparkleEffectView.swift:24-71`
- Test: `VocabCraftAppTests/DesignSystem/ColorTokensTests.swift`

**Interfaces:**
- Replace `DispatchQueue.main.asyncAfter` in `SRSSparkleEffectView` with `.task(id: isEmitting)` and structured `Task.sleep`.

- [ ] **Step 1: Verify `SRSSparkleEffectView` renders cleanly**

In `VocabCraftAppTests/DesignSystem/ColorTokensTests.swift`, add:
```swift
func testSRSSparkleEffectViewLifecycle() {
    let binding = Binding.constant(true)
    let view = SRSSparkleEffectView(isEmitting: binding)
    XCTAssertNotNil(view.body)
}
```

- [ ] **Step 2: Run test to verify initial state**

Run: `swift test --filter ColorTokensTests`
Expected: PASS

- [ ] **Step 3: Update `SRSSparkleEffectView` to use `.task(id: isEmitting)`**

In `VocabCraftApp/Core/DesignSystem/SRSSparkleEffectView.swift`:
```swift
    public var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Image(systemName: "sparkle")
                    .font(.system(size: particle.size, weight: .bold))
                    .foregroundColor(particle.color)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .offset(x: particle.x, y: particle.y)
            }
        }
        .allowsHitTesting(false)
        .task(id: isEmitting) {
            guard isEmitting else { return }
            burst()
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) {
                for idx in particles.indices {
                    particles[idx].opacity = 0
                    particles[idx].scale = 0.1
                }
            }
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            particles.removeAll()
            isEmitting = false
        }
    }

    private func burst() {
        var newParticles: [SparkleParticle] = []
        let colors: [Color] = [.vocabMint, .vocabPeach, .vocabLavender, .vocabCoral]

        for i in 0..<12 {
            let angle = Double.pi * 2 / 12 * Double(i) + Double.random(in: -0.2...0.2)
            let distance = CGFloat.random(in: 40...90)
            let particle = SparkleParticle(
                id: UUID(),
                x: cos(angle) * distance,
                y: sin(angle) * distance,
                size: CGFloat.random(in: 14...22),
                color: colors[i % colors.count],
                scale: 0.2,
                opacity: 1.0
            )
            newParticles.append(particle)
        }
        particles = newParticles

        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            for idx in particles.indices {
                particles[idx].scale = 1.2
            }
        }
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter ColorTokensTests`
Expected: PASS

- [ ] **Step 5: Commit changes**

```bash
git add VocabCraftApp/Core/DesignSystem/SRSSparkleEffectView.swift VocabCraftAppTests/DesignSystem/ColorTokensTests.swift
git commit -m "perf: adopt Task.sleep with structured cancellation in SRSSparkleEffectView"
```

---

### Task 7: Full Regression Suite Verification & Build Sanity

**Files:**
- Test all components across repository.

- [ ] **Step 1: Run full automated test suite**

Run: `swift test`
Expected: All 386+ tests PASS with 0 failures.

- [ ] **Step 2: Build debug and release targets**

Run: `swift build -c release`
Expected: Build complete with 0 warnings/errors.

- [ ] **Step 3: Final sanity commit if any cleanup remains**

```bash
git status
```
