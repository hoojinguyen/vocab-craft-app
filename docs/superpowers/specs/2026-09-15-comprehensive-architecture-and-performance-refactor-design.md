# Comprehensive Architecture, Concurrency, and Data Layer Refactor Design Spec

## Executive Summary

An exhaustive audit of the `VocabCraft` repository across architectural patterns, concurrency safety, SwiftUI performance, design token discipline, and localization policies confirmed strong foundations (457 tests passing, 0 SwiftLint violations, 0 compiler warnings under Strict Concurrency). However, three architectural misalignments and areas of technical debt were identified:
1. **Data Layer Duality & Orphaned Engine**: The active application uses `VocabularyDataSourceProtocol` with hardcoded in-memory structs (`VocabularySampleDataset.swift`), while a legacy, orphaned SQLite layer (`DatasetEngine.swift` pointing to a non-existent `english_dataset.db`) and `VocabularyRepositoryProtocol` remain unlinked from feature workflows.
2. **Concurrency & Repository Isolation Gaps**: `StageProgressRepositoryImpl` uses an `@unchecked Sendable` wrapper around `ModelContext?` despite all methods executing on `@MainActor`. Under Swift 6 / SE-0466, isolating the class to `@MainActor` eliminates the need for `@unchecked Sendable`.
3. **Zero Hardcoded Strings Policy Violation in Widget**: `VocabWidgetProvider.makePlaceholder()` contains raw Vietnamese and English strings directly in Swift code bodies instead of querying `Localizable.xcstrings`.

This design outlines a unified, production-grade refactor to resolve all three issues while preserving 100% test pass rate, strict concurrency guarantees, and zero-warning compliance.

---

## 1. Data Layer Consolidation & Codable JSON Catalog

### 1.1 Architecture & Boundaries
The data layer will be restructured into a single source of truth for static educational content, completely separated from Swift source code:
- **Content Resource**: `VocabCraftApp/Resources/vocabulary_catalog.json` containing the hierarchical catalog of Decks, SubTopicStages, Words, and Distractor/Reflex seed data.
- **Data Source Engine**: `BundledVocabularyDataSource`, conforming to `VocabularyDataSourceProtocol` and `Sendable`. It loads and decodes JSON lazily on a background cooperative executor, caches decoded collections in memory, and provides O(1) indexed lookups for words, stages, and decks.
- **Clean Architecture Facade**: `VocabularyRepositoryImpl` is updated to depend on `VocabularyDataSourceProtocol` and `UserProgressModelActor`, eliminating the raw SQLite C-API pointer layer entirely.

### 1.2 Data Contract & Schema (`vocabulary_catalog.json`)
```json
{
  "version": 1,
  "decks": [
    {
      "id": "deck_daily",
      "title": "Giao Tiếp Hằng Ngày",
      "iconName": "bubble.left.and.bubble.right.fill",
      "stages": [
        {
          "id": "stage_daily_1",
          "deckId": "deck_daily",
          "title": "Thói quen & Cảm xúc",
          "iconName": "heart.fill",
          "sortOrder": 1,
          "words": [
            {
              "id": 1,
              "lemma": "Resilience",
              "ipaUs": "/rɪˈzɪl.jəns/",
              "pos": "noun",
              "cefrLevel": "B2",
              "definitionEn": "The capacity to recover quickly from difficulties",
              "definitionVi": "Khả năng phục hồi, kiên cường",
              "exampleEn": "Her resilience helped her overcome difficulties.",
              "exampleVi": "Sự kiên cường giúp cô ấy vượt qua khó khăn."
            }
          ]
        }
      ]
    }
  ]
}
```

### 1.3 Target DTOs & Models
- `VocabularyCatalogDTO: Codable, Sendable`: Root schema wrapping catalog version and decks.
- `TopicDeckDTO: Identifiable, Codable, Sendable`: Topic decks representing overarching learning themes.
- `SubTopicStageDTO: Identifiable, Codable, Sendable`: Stages containing specific word sequences.
- `TopicWordDTO: Identifiable, Codable, Sendable`: Rich vocabulary entry with CEFR levels, phonetic IPA, bilingual definitions, and bilingual example sentences.

### 1.4 Code Deletions & Deprecations
The following legacy SQLite C-API files and in-memory sample files will be permanently deleted:
- `VocabCraftApp/Core/Database/DatasetEngine.swift`
- `VocabCraftApp/Core/Database/DatasetModels.swift`
- `VocabCraftApp/Domain/Protocols/DatasetDataSourceProtocol.swift`
- `VocabCraftApp/Core/Database/SampleData/VocabularySampleDataset.swift`
- `VocabCraftApp/Core/Database/SampleData/SampleVocabularyDataSource.swift` (superseded by `BundledVocabularyDataSource`)

---

## 2. Concurrency & Repository Isolation Modernization

### 2.1 Eliminating `@unchecked Sendable` on `StageProgressRepositoryImpl`
- **Protocol Definition**:
  ```swift
  @MainActor
  public protocol StageProgressRepositoryProtocol: Sendable {
      func fetchStageProgress(stageId: String) async throws -> UserStageProgressData?
      func fetchCompletedStageIds(deckId: String) async throws -> Set<String>
      func fetchAllStageProgress() async throws -> [UserStageProgressData]
      func saveStageProgress(stageId: String, deckId: String, isCompleted: Bool, score: Int, progressFraction: Double) async throws
  }
  ```
- **Implementation**:
  ```swift
  @MainActor
  public final class StageProgressRepositoryImpl: StageProgressRepositoryProtocol {
      private let modelContext: ModelContext?

      public init(modelContext: ModelContext?) {
          self.modelContext = modelContext
      }
  }
  ```
- **Rationale**: Under Swift 6 / SE-0466, a class isolated to `@MainActor` is implicitly `Sendable` because its mutable stored properties are protected by the MainActor serial executor. This completely eliminates `@unchecked Sendable` while maintaining safety.

### 2.2 Preserving SwiftData Actor Boundaries
- `UserProgressModelActor` remains the primary `@ModelActor` responsible for background state mutations.
- No `PersistentModel` instances (`UserWordProgress`, `UserStageProgress`, `QuickReflexAttemptRecord`) may cross actor boundaries. Only `Sendable` value types (`UserWordProgressData`, `UserStageProgressData`, `UserProgressSummary`) or `PersistentIdentifier` are transferred across isolation boundaries.

---

## 3. Zero Hardcoded Strings & Widget Localization Compliance

### 3.1 Widget Placeholder Localization
In `VocabCraftWidgetExtension/VocabWidget.swift`, replace raw literal strings in `makePlaceholder()` with localized string lookups:
```swift
public func makePlaceholder() -> VocabWidgetEntry {
    VocabWidgetEntry(
        date: Date(),
        lemma: String(localized: "app.widget.placeholder.lemma"),
        ipaUs: String(localized: "app.widget.placeholder.ipa"),
        definitionVi: String(localized: "app.widget.placeholder.definition"),
        exampleEn: String(localized: "app.widget.placeholder.example"),
        masteryLevel: 0
    )
}
```

### 3.2 Catalog Entries in `VocabCraftApp/Resources/Localizable.xcstrings`
Add the following keys with full English and Vietnamese parity (`extractionState: "manual"`, `state: "translated"`):
- `app.widget.placeholder.lemma`:
  - `en`: `"Abandon"`
  - `vi`: `"Abandon"`
- `app.widget.placeholder.ipa`:
  - `en`: `"/əˈbæn.dən/"`
  - `vi`: `"/əˈbæn.dən/"`
- `app.widget.placeholder.definition`:
  - `en`: `"To give up completely"`
  - `vi`: `"Từ bỏ, ruồng bỏ"`
- `app.widget.placeholder.example`:
  - `en`: `"He decided to abandon the plan."`
  - `vi`: `"Anh ấy quyết định từ bỏ kế hoạch."`

---

## 4. Error Handling, Resilience & Recovery

1. **`VocabularyCatalogError`**:
   ```swift
   public enum VocabularyCatalogError: LocalizedError, Sendable {
       case resourceNotFound(name: String, bundle: String)
       case decodingFailed(description: String)
   }
   ```
2. **App Bootstrapper Integration**:
   - If `BundledVocabularyDataSource` fails to load or parse `vocabulary_catalog.json` during app startup, `AppBootstrapper` catches the error and transitions to `AppBootstrapper.State.error(.storeInitializationFailed(...))`.
   - The user is presented with `DatabaseRecoveryView` rather than suffering an unhandled fatal runtime crash.
3. **Test Fallback**:
   - For isolated test targets executing without access to `Bundle.main`, `BundledVocabularyDataSource` provides an embedded fallback dataset so unit tests do not require manual bundle synthesis.

---

## 5. Verification & Testing Plan

### 5.1 Automated Unit Tests
1. **`BundledVocabularyDataSourceTests`**:
   - Verify decoding of `vocabulary_catalog.json`.
   - Verify deck, stage, and word count invariants.
   - Verify word lookup by identifier (`fetchWord(id:)`) and search query.
   - Verify error throwing on invalid/corrupted JSON payloads.
2. **`StageProgressRepositoryTests`**:
   - Verify stage progress persistence and retrieval on `@MainActor`.
   - Verify clean conformance without `@unchecked Sendable`.
3. **`WidgetLocalizationTests`**:
   - Verify that all `app.widget.placeholder.*` keys exist and contain both EN and VI values.
4. **Regression Test Suite**:
   - Run `swift test` across all targets (`VocabCraftAppTests`, `CraftUIKitTests`, `SpeechKitTests`) ensuring 100% pass rate.
5. **Quality Gates**:
   - `swiftlint`: 0 warnings, 0 errors.
   - `xcodebuild`: 0 warnings, 0 errors.
