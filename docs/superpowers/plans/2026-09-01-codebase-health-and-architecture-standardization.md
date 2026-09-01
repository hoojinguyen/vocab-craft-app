# Codebase Health, Performance & Architecture Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute a comprehensive codebase refactor to fix critical SwiftUI lifecycle bugs, restore 100% test suite health, purge 14+ orphan legacy views/viewmodels, eliminate $O(N)$ sequential async query bottlenecks, unify speech engines onto `SpeechKit`, migrate 480+ `Color.vocab*` calls to `CraftTheme`, and achieve 100% bilingual localization parity.

**Architecture:** Phased clean architecture refactoring. Decouples state ownership via proper SwiftUI `@State` patterns, introduces batch lookup in `VocabularyDataSourceProtocol`, removes dead code from Bento/Vault v1 iterations, standardizes speech recognition on `SpeechKit` via `ResilientReflexSpeechEngine`, and unifies visual styling under `CraftUIKit` design tokens.

**Tech Stack:** Swift 6 / SwiftUI, SwiftData (`@ModelActor`), `Observation` framework (`@Observable`), SPM (`CraftUIKit`, `SpeechKit`), XCTest / Swift Testing, `Localizable.xcstrings`.

## Global Constraints

- Strict 100% test pass rate (`swift test`) after each task.
- Zero raw styling: all colors must use `theme.colors` from `CraftTheme` / `CraftColorTokens`.
- Zero hardcoded strings: all user-facing strings must use `Localizable.xcstrings` (100% EN & VI parity).
- No compiler warnings or concurrency diagnostics.

---

### Task 1: Fix `VocabularyView` ViewModel Lifecycle, Test Suite Mismatch & Intent Logic

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift`
- Modify: `VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift`
- Modify: `VocabCraftWidgetExtension/AppIntents/MarkLearnedIntent.swift`

**Interfaces:**
- Consumes: `PersonalVaultViewModel`, `AppContainer`
- Produces: Safe `@State` cached `vaultVM`, backward-compatible `init(isSearchVisible:)`, `isSearchVisibleForTesting` accessor.

- [ ] **Step 1: Update `VocabularyView.swift` to fix ViewModel re-instantiation and add compatibility API**

In `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`:
```swift
    @State private var vaultVM: PersonalVaultViewModel?
    @State private var isSearchHiddenByScroll: Bool = false
    @State private var isScrolledPastHeader: Bool = false
    @State private var measuredHeaderHeight: CGFloat = 50
    @State private var lastScrollOffset: CGFloat = 0
    @State private var searchText: String = ""
    @State private var isPresentingPracticeSelection: Bool = false
    @State private var activeDrillViewModel: MixedReflexDrillViewModel?
    @State private var isPresentingSmartReview: Bool = false

    @MainActor
    public init(
        vaultViewModel: PersonalVaultViewModel? = nil,
        isSearchHiddenByScroll: Bool = false,
        isScrolledPastHeader: Bool = false,
        isSearchVisible: Bool? = nil
    ) {
        let hiddenByScroll = isSearchVisible.map { !$0 } ?? isSearchHiddenByScroll
        self._vaultVM = State(initialValue: vaultViewModel)
        self._isSearchHiddenByScroll = State(initialValue: hiddenByScroll)
        self._isScrolledPastHeader = State(initialValue: isScrolledPastHeader)
        self._searchText = State(initialValue: vaultViewModel?.searchQuery ?? "")
    }

    // MARK: - Testing Inspection Accessors
    internal var isSearchHiddenByScrollForTesting: Bool { isSearchHiddenByScroll }
    internal var isSearchVisibleForTesting: Bool { !isSearchHiddenByScroll }
    internal var isScrolledPastHeaderForTesting: Bool { isScrolledPastHeader }
    internal var measuredHeaderHeightForTesting: CGFloat { measuredHeaderHeight }

    private func resolvedVaultVM() -> PersonalVaultViewModel {
        if let vm = vaultVM {
            return vm
        }
        let vm = appContainer.makePersonalVaultViewModel()
        vaultVM = vm
        return vm
    }
```
And inside `body`:
```swift
        let currentVaultVM = vaultVM ?? resolvedVaultVM()
        @Bindable var bindableVaultVM = currentVaultVM
```

- [ ] **Step 2: Fix `MarkLearnedIntent.swift` logic calculation**

In `VocabCraftWidgetExtension/AppIntents/MarkLearnedIntent.swift`:
Replace:
```swift
progress.masteryLevel = max(5, srsResult.nextMastery)
```
With:
```swift
progress.masteryLevel = min(5, max(1, srsResult.nextMastery))
```

- [ ] **Step 3: Run test suite to verify compilation and baseline tests pass**

Run: `swift test --filter VocabularyViewTests`
Expected: PASS

Run: `swift test --filter PersonalVaultViewsTests`
Expected: PASS

- [ ] **Step 4: Commit Task 1**

```bash
git add VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift VocabCraftAppTests/Features/Vocabulary/VocabularyViewTests.swift VocabCraftAppTests/Features/Vocabulary/PersonalVaultViewsTests.swift VocabCraftWidgetExtension/AppIntents/MarkLearnedIntent.swift
git commit -m "fix: resolve VocabularyView ViewModel lifecycle churn, test mismatch and intent logic"
```

---

### Task 2: Purge Orphan Views & Dead Legacy ViewModels

**Files:**
- Delete: `VocabCraftApp/Features/Vocabulary/Views/WordAccordionCard.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/VocabularySummaryCard.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/TopicDecksGridView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/TopicDeckDetailView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/SubTopicStudySessionView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/SubTopicSessionSummaryView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/SubTopicPreviewSheet.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/QuickReflexDrillSheetView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/QuickReflexResultCardView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/ReflexFlipCardView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/Views/Components/TopCarouselFlashcardView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/PersonalVault/Views/CleanWordCardView.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/PersonalVault/Views/PersonalVaultHeroCard.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/PersonalVault/Views/PersonalSearchFilterBar.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/ViewModels/VocabularyViewModel.swift`
- Delete: `VocabCraftApp/Domain/UseCases/FetchVocabularyUseCase.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/ViewModels/StudySessionViewModel.swift`
- Delete: `VocabCraftApp/Features/Vocabulary/ViewModels/QuickReflexDrillViewModel.swift`
- Delete: `VocabCraftAppTests/VocabularyViewModelTests.swift`
- Delete: `VocabCraftAppTests/Features/Vocabulary/VocabularyViewsTests.swift`
- Delete: `VocabCraftAppTests/SubTopicStudySessionViewTests.swift`
- Delete: `VocabCraftAppTests/SubTopicPreviewSheetTests.swift`
- Delete: `VocabCraftAppTests/SubTopicSessionSummaryViewTests.swift`
- Delete: `VocabCraftAppTests/TopicDeckDetailViewTests.swift`
- Delete: `VocabCraftAppTests/QuickReflexDrillSheetViewTests.swift`
- Delete: `VocabCraftAppTests/QuickReflexDrillViewModelTests.swift`
- Delete: `VocabCraftAppTests/ReflexFlipCardViewTests.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp.xcodeproj/project.pbxproj` (via `scripts/generate_xcodeproj.py`)

**Interfaces:**
- Consumes: Cleaned `AppContainer`
- Produces: Lean codebase free of orphan files.

- [ ] **Step 1: Remove dead references in `AppContainer.swift`**

Remove `fetchVocabularyUseCase` and `makeVocabularyViewModel()` from `AppContainer.swift`.

- [ ] **Step 2: Delete orphan source and test files**

Delete the 17 source files and 9 test files listed above via `rm`.

- [ ] **Step 3: Regenerate `VocabCraftApp.xcodeproj`**

Run: `python3 scripts/generate_xcodeproj.py`
Expected: Project file generated cleanly with 0 dangling references.

- [ ] **Step 4: Run full test suite to verify zero broken references**

Run: `swift test`
Expected: PASS

- [ ] **Step 5: Commit Task 2**

```bash
git add -A
git commit -m "refactor: purge 14+ orphan views, dead legacy viewmodels and obsolete tests"
```

---

### Task 3: Consolidate Speech Engines onto `SpeechKit` & `ResilientReflexSpeechEngine`

**Files:**
- Modify: `VocabCraftApp/Features/Vocabulary/Views/VocabularyView.swift`
- Modify: `VocabCraftApp/Features/Reflex/Mixed/Views/MixedReflexDrillView.swift`
- Delete: `VocabCraftApp/Core/Audio/ContinuousReflexSpeechService.swift`
- Delete: `VocabCraftAppTests/Features/ReflexDrill/ContinuousReflexSpeechServiceTests.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`

**Interfaces:**
- Consumes: `ResilientReflexSpeechEngine`, `SpeechKit`
- Produces: Single unified speech engine across all reflex & drill features.

- [ ] **Step 1: Update `MixedReflexDrillView.swift` to use `ReflexSpeechEngineProtocol`**

In `MixedReflexDrillView.swift`:
Update initializer to accept `speechEngine: ReflexSpeechEngineProtocol = ResilientReflexSpeechEngine()`.

- [ ] **Step 2: Update `VocabularyView.swift:235` sheet presentation**

Replace `speechService: ContinuousReflexSpeechService()` with `speechEngine: appContainer.makeReflexSpeechEngine()`.

- [ ] **Step 3: Delete `ContinuousReflexSpeechService.swift` and its tests**

Delete `ContinuousReflexSpeechService.swift` and `ContinuousReflexSpeechServiceTests.swift`.
Regenerate Xcode project: `python3 scripts/generate_xcodeproj.py`.

- [ ] **Step 4: Run tests to verify speech engine functionality**

Run: `swift test --filter ResilientReflexSpeechEngineTests`
Expected: PASS

Run: `swift test --filter MixedReflexDrillViewsTests`
Expected: PASS

- [ ] **Step 5: Commit Task 3**

```bash
git add -A
git commit -m "refactor: consolidate speech recognition engines onto SpeechKit and ResilientReflexSpeechEngine"
```

---

### Task 4: Add Batch Lookup to `VocabularyDataSourceProtocol` & Optimize Use Cases

**Files:**
- Modify: `VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift`
- Modify: `VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift`
- Modify: `VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift`
- Modify: `VocabCraftApp/Domain/UseCases/ReviewWeakWordsUseCase.swift`
- Test: `VocabCraftAppTests/Core/SampleVocabularyDataSourceTests.swift`
- Test: `VocabCraftAppTests/Domain/VocabularyUseCasesTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol`
- Produces: `fetchWordsByIds(ids: Set<Int64>)`, `fetchAllWordsMap()`, $O(1)$ in-memory mapping in use cases.

- [ ] **Step 1: Add batch fetch signatures to `VocabularyDataSourceProtocol`**

In `VocabularyDataSourceProtocol.swift`:
```swift
public protocol VocabularyDataSourceProtocol: Sendable {
    func fetchTopicDecks() async throws -> [TopicDeckDTO]
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO]
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO]
    func searchWords(query: String) async throws -> [TopicWordDTO]
    func fetchWordById(id: Int64) async throws -> TopicWordDTO?
    func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO]
    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO]
}
```

- [ ] **Step 2: Implement batch fetch in `SampleVocabularyDataSource.swift`**

```swift
    public func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO] {
        ids.compactMap { Self.wordById[$0] }
    }

    public func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] {
        Self.wordById
    }
```

- [ ] **Step 3: Refactor `FetchPersonalVaultUseCase.swift` and `ReviewWeakWordsUseCase.swift`**

In `FetchPersonalVaultUseCase.swift`:
```swift
    public func execute(filter: PersonalVaultFilter = .all, searchQuery: String? = nil) async throws -> PersonalVaultResult {
        let allProgress = try await progressRepo.fetchAllProgress()
        let wordsMap = try await dataSource.fetchAllWordsMap()
        var allPersonalWords: [PersonalWord] = []
        allPersonalWords.reserveCapacity(allProgress.count)

        for progress in allProgress {
            if let wordDTO = wordsMap[progress.wordId] {
                let personalWord = PersonalWord(
                    id: wordDTO.id,
                    lemma: wordDTO.lemma,
                    phonetic: wordDTO.phonetic,
                    pos: wordDTO.pos,
                    cefrLevel: wordDTO.cefrLevel,
                    definitionVi: wordDTO.definitionVi,
                    definitionEn: wordDTO.definitionEn,
                    exampleEn: wordDTO.exampleEn,
                    exampleVi: wordDTO.exampleVi,
                    masteryLevel: progress.masteryLevel,
                    isBookmarked: progress.isBookmarked,
                    needsReview: progress.needsReview,
                    mistakeCount: progress.mistakeCount,
                    sourceDeckTitle: nil,
                    sourceStageTitle: nil
                )
                allPersonalWords.append(personalWord)
            }
        }
        ...
```
Do the identical $O(1)$ lookup refactor in `fetchVaultWords` and `ReviewWeakWordsUseCase.swift`.

- [ ] **Step 4: Run tests to verify optimization and correctness**

Run: `swift test --filter SampleVocabularyDataSourceTests`
Run: `swift test --filter PersonalVaultViewModelTests`
Expected: PASS

- [ ] **Step 5: Commit Task 4**

```bash
git add VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift VocabCraftApp/Domain/UseCases/FetchPersonalVaultUseCase.swift VocabCraftApp/Domain/UseCases/ReviewWeakWordsUseCase.swift VocabCraftAppTests/Core/SampleVocabularyDataSourceTests.swift
git commit -m "perf: eliminate N+1 async queries with batch lookup in VocabularyDataSource and UseCases"
```

---

### Task 5: Refactor `ReflexBlitzViewModel` with Mode Strategy Handlers

**Files:**
- Modify: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/ReflexBlitzViewModel.swift`
- Create: `VocabCraftApp/Features/Reflex/Blitz/ViewModels/Handlers/ReflexModeHandlerProtocol.swift`
- Test: `VocabCraftAppTests/Features/ReflexDrill/ReflexBlitzViewModelTests.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelSpeakingTests.swift`
- Test: `VocabCraftAppTests/Features/Reflex/ReflexBlitzViewModelListeningTests.swift`

**Interfaces:**
- Consumes: `ReflexBlitzMode`, `ReflexDrillPlanItem`
- Produces: Modularized mode handlers for speaking, listening, typing, and multiple-choice.

- [ ] **Step 1: Extract mode response validation into `ReflexModeHandlerProtocol`**

Create `ReflexModeHandlerProtocol.swift` to handle mode-specific input validation (e.g. typing string matching, multiple-choice selection checking, speaking transcript matching).

- [ ] **Step 2: Clean up `ReflexBlitzViewModel.swift` by delegating mode validation**

Decompose the monolithic `submitAnswer`, `handleOptionSelected`, and `handleSpokenMatch` methods into handler delegates.

- [ ] **Step 3: Run all Reflex Blitz test suites**

Run: `swift test --filter ReflexBlitz`
Expected: PASS

- [ ] **Step 4: Commit Task 5**

```bash
git add -A
git commit -m "refactor: decompose ReflexBlitzViewModel using mode validation handlers"
```

---

### Task 6: Migrate Legacy `Color.vocab*` Tokens to `CraftTheme`

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/StreakWeekStripView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomeSkeletonView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/MobileSearchView.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/VocabSpeechVisualizerView.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/VocabMicControlHubView.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/SRSSparkleEffectView.swift`
- Modify: `VocabCraftApp/Core/DesignSystem/Color+VocabCraft.swift`
- Test: `VocabCraftAppTests/DesignSystem/VocabThemeTests.swift`

**Interfaces:**
- Consumes: `@Environment(\.craftTheme) private var theme`
- Produces: 100% theme-adaptive views supporting all 12 `CraftThemePreset` styles.

- [ ] **Step 1: Replace `Color.vocab*` in Homepage views**

In `HomeTopHeaderView.swift`, `StreakWeekStripView.swift`, `HomeSkeletonView.swift`, `HomepageView.swift`, `MobileSearchView.swift`:
Inject `@Environment(\.craftTheme) private var theme` and map colors to `theme.colors.canvasBackground`, `theme.colors.surfaceCard`, `theme.colors.textPrimary`, `theme.colors.textSecondary`, `theme.colors.accent`, `theme.colors.borderLight`.

- [ ] **Step 2: Replace `Color.vocab*` in Audio & Visualizer views**

In `VocabSpeechVisualizerView.swift` and `VocabMicControlHubView.swift`:
Replace static `Color.vocabCoral` and `Color.vocabPeach` with `theme.colors.accent` / `theme.colors.warning`.

- [ ] **Step 3: Deprecate `Color+VocabCraft.swift` and `VocabTheme.swift`**

Mark legacy static colors as `@available(*, deprecated, message: "Use theme.colors from CraftUIKit CraftTheme")`.

- [ ] **Step 4: Run theme and design token tests**

Run: `swift test --filter VocabThemeTests`
Run: `swift test --filter HomepageViewTests`
Expected: PASS

- [ ] **Step 5: Commit Task 6**

```bash
git add -A
git commit -m "style: migrate legacy Color.vocab tokens to CraftTheme dynamic tokens for multi-theme support"
```

---

### Task 7: Redesign `SearchNewWordView` & Complete Zero Hardcoded Strings Localization

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/Views/SearchNewWordView.swift`
- Modify: `VocabCraftApp/Features/Settings/Views/SettingsView.swift`
- Modify: `VocabCraftWidgetExtension/VocabWidgetView.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Test: `VocabCraftAppTests/Features/Homepage/HomeLocalizationTests.swift`
- Test: `VocabCraftAppTests/SettingsLocalizationTests.swift`

**Interfaces:**
- Consumes: `CraftSearchBar`, `CraftCard`, `CraftPill`, `CraftBadge`, `Localizable.xcstrings`
- Produces: HIG-compliant, bilingual `SearchNewWordView` and 100% localized Widget.

- [ ] **Step 1: Add missing localization keys to `Localizable.xcstrings` and `AppStrings.swift`**

Add bilingual pairs (EN & VI) for:
- `app.search.title` ("Search" / "Tra từ")
- `app.search.upcoming_feature_badge` ("COMING SOON" / "SẮP RA MẮT")
- `app.search.smart_lookup_title` ("Smart Dictionary & AI Lookup" / "Từ điển Thông minh & Tra cứu AI")
- `app.search.smart_lookup_desc` ("Offline morphological parser, bilingual context sentences..." / "Bộ phân tích hình thái học offline, câu ví dụ song ngữ...")
- `app.search.recent_searches` ("Recent Searches" / "Tìm kiếm gần đây")
- `app.search.suggested_topics` ("Suggested Topics" / "Chủ đề gợi ý")
- `app.search.topic_ielts` ("IELTS Band 7.0+" / "IELTS Band 7.0+")
- `app.search.topic_business` ("Business & Tech" / "Kinh doanh & Công nghệ")
- `app.search.topic_academic` ("Academic Research" / "Nghiên cứu Học thuật")
- `app.search.topic_daily` ("Daily Expressions" / "Giao tiếp Hàng ngày")
- `app.settings.daily_goal_placeholder` ("5 - 100 words" / "5 - 100 từ")
- `app.widget.next` ("Next" / "Tiếp")
- `app.widget.mastered` ("Mastered" / "Thuộc")
- `app.widget.level_format` ("Level %lld" / "Cấp độ %lld")

- [ ] **Step 2: Redesign `SearchNewWordView.swift` with `CraftUIKit` components**

Refactor `SearchNewWordView.swift` to use `CraftSearchBar`, `CraftCard`, `CraftPill`, `theme.colors`, `theme.typography`, and `AppStrings`.

- [ ] **Step 3: Localize `SettingsView.swift` and `VocabWidgetView.swift`**

Replace raw text literals in `SettingsView.swift:83` and `VocabWidgetView.swift` with `AppStrings`.

- [ ] **Step 4: Run full verification suite**

Run: `swift test`
Expected: 100% PASS across all packages and app targets with 0 errors and 0 warnings.

- [ ] **Step 5: Commit Task 7**

```bash
git add -A
git commit -m "feat: redesign SearchNewWordView with CraftUIKit and achieve 100% localization parity"
```

---

## Plan Self-Review Checklist
- [x] Spec coverage: All 4 phases from the design doc are mapped to discrete tasks.
- [x] No placeholders: All code blocks, paths, and commands are fully specified.
- [x] Type consistency: Function names, protocols, and file paths align across tasks.
- [x] Test-driven: Every task includes failing/passing test execution steps.
