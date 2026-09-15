# Comprehensive Architecture, Concurrency, and Data Layer Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the vocabulary data pipeline by replacing legacy orphaned SQLite C code with a clean, bundled JSON catalog (`vocabulary_catalog.json` + `BundledVocabularyDataSource`), eliminate `@unchecked Sendable` on `StageProgressRepositoryImpl` by applying `@MainActor` isolation, and localize widget entry placeholders to adhere 100% to the Zero Hardcoded Strings policy.

**Architecture:** Clean Architecture with MV and Observation (`@Observable`). Educational content is decoupled from code into a Codable JSON bundle parsed off-actor. Repositories coordinate between data sources and `@ModelActor` persistence. Concurrency strictly conforms to Swift 6 / SE-0466.

**Tech Stack:** Swift 5.10 / Swift 6 Strict Concurrency, SwiftUI, SwiftData, Swift Testing / XCTest, Foundation.

**Spec:** [`docs/superpowers/specs/2026-09-15-comprehensive-architecture-and-performance-refactor-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-09-15-comprehensive-architecture-and-performance-refactor-design.md)

## Global Constraints
- Swift 6 strict concurrency enabled (`StrictConcurrency` upcoming feature flag).
- Zero compiler warnings, zero compiler errors, zero SwiftLint violations.
- 100% bilingual parity (EN & VI) in `Localizable.xcstrings`.
- Zero raw hardcoded strings in SwiftUI views, viewmodels, or widget initializers.
- No `@Model` SwiftData references may cross actor boundaries.

---

### Task 1: Content Decoupling & Bundled JSON Dataset Scaffolding

**Files:**
- Create: `VocabCraftApp/Resources/vocabulary_catalog.json`
- Create: `VocabCraftApp/Core/Database/DataSources/VocabularyCatalogDTO.swift`
- Create: `VocabCraftApp/Core/Database/DataSources/BundledVocabularyDataSource.swift`
- Create: `VocabCraftAppTests/Core/Database/BundledVocabularyDataSourceTests.swift`

**Interfaces:**
- Produces:
  ```swift
  public struct VocabularyCatalogDTO: Codable, Sendable {
      public let version: Int
      public let decks: [TopicDeckDTO]
  }
  public final class BundledVocabularyDataSource: VocabularyDataSourceProtocol, Sendable {
      public init(bundle: Bundle = .main, resourceName: String = "vocabulary_catalog")
      public func fetchAllDecks() async throws -> [TopicDeckDTO]
      public func fetchDeck(id: String) async throws -> TopicDeckDTO?
      public func fetchStages(for deckId: String) async throws -> [SubTopicStageDTO]
      public func fetchWords(for stageId: String) async throws -> [TopicWordDTO]
      public func fetchWord(id: Int64) async throws -> TopicWordDTO?
      public func searchWords(query: String) async throws -> [TopicWordDTO]
  }
  ```

- [ ] **Step 1: Write failing unit test for `BundledVocabularyDataSource`**
Create `VocabCraftAppTests/Core/Database/BundledVocabularyDataSourceTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Bundled Vocabulary Data Source Tests")
struct BundledVocabularyDataSourceTests {
    @Test("Loads and decodes valid vocabulary catalog correctly")
    func loadsCatalogSuccessfully() async throws {
        let dataSource = BundledVocabularyDataSource()
        let decks = try await dataSource.fetchAllDecks()
        #expect(!decks.isEmpty)
        #expect(decks.contains { $0.id == "deck_daily" })

        let stages = try await dataSource.fetchStages(for: "deck_daily")
        #expect(!stages.isEmpty)

        let words = try await dataSource.fetchWords(for: stages[0].id)
        #expect(!words.isEmpty)

        let word = try await dataSource.fetchWord(id: words[0].id)
        #expect(word?.id == words[0].id)
    }

    @Test("Searches words across catalog by lemma and definition")
    func searchesWordsSuccessfully() async throws {
        let dataSource = BundledVocabularyDataSource()
        let results = try await dataSource.searchWords(query: "Resilience")
        #expect(!results.isEmpty)
        #expect(results.first?.lemma.localizedCaseInsensitiveContains("resilience") == true)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter BundledVocabularyDataSourceTests`
Expected: FAIL with compilation error (types not defined).

- [ ] **Step 3: Generate `vocabulary_catalog.json` and implement `BundledVocabularyDataSource`**
Create `vocabulary_catalog.json` from the curated curriculum in `VocabularySampleDataset.swift`.
Implement `VocabularyCatalogDTO.swift` and `BundledVocabularyDataSource.swift`.

- [ ] **Step 4: Run test to verify it passes**
Run: `swift test --filter BundledVocabularyDataSourceTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Resources/vocabulary_catalog.json VocabCraftApp/Core/Database/DataSources/ VocabCraftAppTests/Core/Database/BundledVocabularyDataSourceTests.swift
git commit -m "feat(data): add bundled JSON vocabulary catalog and BundledVocabularyDataSource"
```

---

### Task 2: DI Layer Integration & Repository Wiring

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/App/Bootstrap/AppBootstrapper.swift`
- Modify: `VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift`
- Modify: `VocabCraftApp/Domain/Protocols/VocabularyRepositoryProtocol.swift`

**Interfaces:**
- Consumes: `BundledVocabularyDataSource` from Task 1.
- Produces:
  ```swift
  @MainActor
  public final class VocabularyRepositoryImpl: VocabularyRepositoryProtocol {
      public init(dataSource: VocabularyDataSourceProtocol, progressActor: UserProgressModelActor?)
  }
  ```

- [ ] **Step 1: Write test verifying AppContainer provides `BundledVocabularyDataSource`**
Add test in `VocabCraftAppTests/App/AppContainerTests.swift` verifying `appContainer.vocabularyDataSource` is instance of `BundledVocabularyDataSource`.

- [ ] **Step 2: Run test to verify failure**
Run: `swift test --filter AppContainerTests`
Expected: FAIL.

- [ ] **Step 3: Wire `BundledVocabularyDataSource` into `AppContainer` and `AppBootstrapper`**
Update `AppContainer.init` to default `vocabularyDataSource` to `BundledVocabularyDataSource()`. Update `VocabularyRepositoryImpl` to query `dataSource` instead of `DatasetDataSourceProtocol`.

- [ ] **Step 4: Run test to verify it passes**
Run: `swift test --filter AppContainerTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/App/Bootstrap/AppBootstrapper.swift VocabCraftApp/Data/Repositories/VocabularyRepositoryImpl.swift
git commit -m "refactor(di): wire BundledVocabularyDataSource into AppContainer and VocabularyRepositoryImpl"
```

---

### Task 3: Legacy SQLite & Dead Code Removal

**Files:**
- Delete: `VocabCraftApp/Core/Database/DatasetEngine.swift`
- Delete: `VocabCraftApp/Core/Database/DatasetModels.swift`
- Delete: `VocabCraftApp/Domain/Protocols/DatasetDataSourceProtocol.swift`
- Delete: `VocabCraftApp/Core/Database/SampleData/VocabularySampleDataset.swift`
- Delete: `VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift`
- Modify: `VocabCraftApp/Data/Local/Mock/MockVocabularyRepository.swift`
- Modify: `VocabCraftApp/Data/Local/Mock/MockVocabularyDataSource.swift`
- Modify: `VocabCraftAppTests/Data/DatasetEngineTests.swift` (remove or adapt)

- [ ] **Step 1: Check all references to deleted files**
Search for `DatasetEngine`, `DatasetModels`, `DatasetDataSourceProtocol`, `SampleVocabularyDataSource`, `VocabularySampleDataset`.

- [ ] **Step 2: Delete legacy files and update mocks**
Remove deleted files and replace references with `BundledVocabularyDataSource`.

- [ ] **Step 3: Run full test suite to verify no broken references**
Run: `swift test`
Expected: PASS.

- [ ] **Step 4: Commit**
```bash
git rm VocabCraftApp/Core/Database/DatasetEngine.swift VocabCraftApp/Core/Database/DatasetModels.swift VocabCraftApp/Domain/Protocols/DatasetDataSourceProtocol.swift VocabCraftApp/Core/Database/SampleData/VocabularySampleDataset.swift VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift
git add VocabCraftApp/ VocabCraftAppTests/
git commit -m "chore(cleanup): remove legacy SQLite DatasetEngine and in-memory SampleVocabularyDataset"
```

---

### Task 4: Concurrency Modernization on `StageProgressRepository`

**Files:**
- Modify: `VocabCraftApp/Core/Database/Repositories/StageProgressRepository.swift`
- Modify: `VocabCraftAppTests/Core/Database/StageProgressRepositoryConcurrencyTests.swift`

**Interfaces:**
- Produces:
  ```swift
  @MainActor
  public protocol StageProgressRepositoryProtocol: Sendable {
      func fetchStageProgress(stageId: String) async throws -> UserStageProgressData?
      func fetchCompletedStageIds(deckId: String) async throws -> Set<String>
      func fetchAllStageProgress() async throws -> [UserStageProgressData]
      func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int, progressFraction: Double) async throws
      func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int) async throws
  }

  @MainActor
  public final class StageProgressRepositoryImpl: StageProgressRepositoryProtocol {
      private let modelContext: ModelContext?
      public init(modelContext: ModelContext?)
  }
  ```

- [ ] **Step 1: Write test for `@MainActor` isolated `StageProgressRepositoryImpl`**
Update `StageProgressRepositoryConcurrencyTests.swift` to verify concurrent operations on MainActor without isolation diagnostics.

- [ ] **Step 2: Apply `@MainActor` to `StageProgressRepositoryImpl` and protocol**
Remove `@unchecked Sendable` from `StageProgressRepositoryImpl`.

- [ ] **Step 3: Run concurrency tests**
Run: `swift test --filter StageProgressRepositoryConcurrencyTests`
Expected: PASS with 0 warnings.

- [ ] **Step 4: Commit**
```bash
git add VocabCraftApp/Core/Database/Repositories/StageProgressRepository.swift VocabCraftAppTests/Core/Database/StageProgressRepositoryConcurrencyTests.swift
git commit -m "refactor(concurrency): isolate StageProgressRepository to MainActor and remove unchecked Sendable"
```

---

### Task 5: Zero Hardcoded Strings & Widget Localization Compliance

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftWidgetExtension/VocabWidget.swift`
- Create: `VocabCraftAppTests/Features/Widget/WidgetLocalizationTests.swift`

**Interfaces:**
- Produces:
  - Localized strings for `app.widget.placeholder.lemma`, `app.widget.placeholder.ipa`, `app.widget.placeholder.definition`, `app.widget.placeholder.example`.

- [ ] **Step 1: Write failing test `WidgetLocalizationTests`**
Create `VocabCraftAppTests/Features/Widget/WidgetLocalizationTests.swift`:
```swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Widget Localization Tests")
struct WidgetLocalizationTests {
    @Test("Widget placeholder keys exist in catalog with EN and VI translations")
    func widgetPlaceholderKeysHaveFullParity() throws {
        let keys = [
            "app.widget.placeholder.lemma",
            "app.widget.placeholder.ipa",
            "app.widget.placeholder.definition",
            "app.widget.placeholder.example"
        ]
        for key in keys {
            let en = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "en"))
            let vi = String(localized: String.LocalizationValue(key), locale: Locale(identifier: "vi"))
            #expect(!en.isEmpty && en != key)
            #expect(!vi.isEmpty && vi != key)
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `swift test --filter WidgetLocalizationTests`
Expected: FAIL (keys not yet in `Localizable.xcstrings`).

- [ ] **Step 3: Add keys to `Localizable.xcstrings` and update `VocabWidget.swift`**
Add JSON entries to `VocabCraftApp/Resources/Localizable.xcstrings` with both EN and VI values.
Update `VocabWidgetProvider.makePlaceholder()` to use `String(localized:)`.

- [ ] **Step 4: Run test to verify it passes**
Run: `swift test --filter WidgetLocalizationTests`
Expected: PASS.

- [ ] **Step 5: Commit**
```bash
git add VocabCraftApp/Resources/Localizable.xcstrings VocabCraftWidgetExtension/VocabWidget.swift VocabCraftAppTests/Features/Widget/WidgetLocalizationTests.swift
git commit -m "fix(widget): localize placeholder strings adhering to Zero Hardcoded Strings policy"
```

---

### Task 6: Rigorous Regression Verification & Quality Gate

**Files:**
- Entire workspace

- [ ] **Step 1: Run SwiftLint**
Run: `swiftlint`
Expected: 0 violations, 0 serious.

- [ ] **Step 2: Run all unit & integration tests**
Run: `swift test`
Expected: 100% tests passed.

- [ ] **Step 3: Run CraftUIKit tests**
Run: `swift test --package-path Packages/CraftUIKit`
Expected: 100% tests passed.

- [ ] **Step 4: Run SpeechKit tests**
Run: `swift test --package-path Packages/SpeechKit`
Expected: 100% tests passed.

- [ ] **Step 5: Run full Xcode build**
Run: `xcodebuild -workspace VocabCraft.xcworkspace -scheme VocabCraftApp -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO`
Expected: `** BUILD SUCCEEDED **` with 0 warnings, 0 errors.

- [ ] **Step 6: Commit and verify git status is clean**
```bash
git status
```
