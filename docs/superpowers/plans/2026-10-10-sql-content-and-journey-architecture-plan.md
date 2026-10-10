# SQL Content Examples Fix & Multi-Path Journey Architecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore missing bilingual examples from the SQLite database across all vocabulary experiences and implement a domain-centric multi-path journey architecture connected to SQLite `learning_paths` and user preferences.

**Architecture:** Extend SQLite queries in `SQLiteContentRepository` with subqueries for `examples`, `learning_paths`, and `path_decks`. Connect `UserSettingsStore` to track the user's active learning path ID, and upgrade `FetchLearningPathUseCase` and `HomepageViewModel` to resolve and render path-specific curriculums with defensive fallbacks.

**Tech Stack:** Swift 6, SQLite3 C-API, SwiftData, CraftUIKit, SwiftUI, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-10-sql-content-and-journey-architecture-design.md`

## Global Constraints
- Pure Swift domain entities and DTOs must be `Sendable`, `Equatable`, and immutable.
- SQLite access must use `SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX` for multi-threaded concurrency safety.
- Zero raw strings in views: all UI text must use `Localizable.xcstrings` with 100% EN and VI parity.
- CraftUIKit-first design token discipline: use `CraftFont`, `CraftColor`, `CraftBadge`, `CraftSpacingTokens`.
- Quality gates: zero compiler warnings, zero SwiftLint errors, 100% test pass rate.

---

### Task 1: Fix SQLite Missing Examples in `SQLiteContentRepository`

**Files:**
- Modify: `VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift:89-102,141-193`
- Modify: `VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift:38-95`

**Interfaces:**
- Consumes: `examples` table in `vocab_content.sqlite` (`sense_id`, `text_en`, `text_vi`, `sort_order`).
- Produces: `TopicWordDTO` with populated `exampleEn: String` and `exampleVi: String`.

- [ ] **Step 1: Write failing unit test in `SQLiteContentRepositoryTests.swift`**

Add assertion in `testFetchWordsForStage` and `testFetchWordsAndSearch` verifying that sample words have non-empty `exampleEn` and `exampleVi`:

```swift
    func testFetchWordsReturnBilingualExamples() async throws {
        let originalURL = try resolveBundledDatabaseURL()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_vocab_content_examples.sqlite")
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        try FileManager.default.copyItem(at: originalURL, to: tempURL)

        let repo = try SQLiteContentRepository(url: tempURL)
        let words = try await repo.searchWords(query: "hello")
        XCTAssertFalse(words.isEmpty)

        guard let first = words.first else { return }
        let fetched = try await repo.fetchWordById(id: first.id)
        XCTAssertNotNil(fetched)
        XCTAssertFalse(fetched?.exampleEn.isEmpty ?? true, "Expected exampleEn not to be empty")
        XCTAssertFalse(fetched?.exampleVi.isEmpty ?? true, "Expected exampleVi not to be empty")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SQLiteContentRepositoryTests/testFetchWordsReturnBilingualExamples`
Expected: FAIL with `"Expected exampleEn not to be empty"` because `exampleEn` is currently `""`.

- [ ] **Step 3: Update `SQLiteContentRepository.swift` to subquery examples and parse them**

1. In `SQLiteContentRepository.swift`, update `fetchWordsForStage(stageId:)`:
```swift
    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        let sql = """
        SELECT s.rowid, e.headword, s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level,
               (SELECT p.ipa FROM pronunciations p WHERE p.sense_id = s.id LIMIT 1) as ipa,
               (SELECT ex.text_en FROM examples ex WHERE ex.sense_id = s.id ORDER BY ex.sort_order LIMIT 1) as example_en,
               (SELECT ex.text_vi FROM examples ex WHERE ex.sense_id = s.id ORDER BY ex.sort_order LIMIT 1) as example_vi
        FROM senses s
        JOIN lesson_senses ls ON ls.sense_id = s.id
        JOIN entries e ON s.entry_id = e.id
        WHERE ls.lesson_id = ?
        ORDER BY ls.sort_order;
        """
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        return try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, stageId, -1, sqliteTransient)
        }) { [self] stmt in
            parseWord(stmt: stmt, stageId: stageId)
        }
    }
```

2. Update `searchWords(query queryText:)`:
```swift
    public func searchWords(query queryText: String) async throws -> [TopicWordDTO] {
        let sql = """
        SELECT s.rowid, e.headword, s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level,
               (SELECT p.ipa FROM pronunciations p WHERE p.sense_id = s.id LIMIT 1) as ipa,
               (SELECT ex.text_en FROM examples ex WHERE ex.sense_id = s.id ORDER BY ex.sort_order LIMIT 1) as example_en,
               (SELECT ex.text_vi FROM examples ex WHERE ex.sense_id = s.id ORDER BY ex.sort_order LIMIT 1) as example_vi
        FROM senses s
        JOIN entries e ON s.entry_id = e.id
        WHERE e.headword LIKE ? OR s.definition_en LIKE ? OR s.definition_vi LIKE ?
        LIMIT 50;
        """
        let pattern = "%\(queryText)%"
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        return try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, pattern, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 2, pattern, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 3, pattern, -1, sqliteTransient)
        }) { [self] stmt in
            parseWord(stmt: stmt)
        }
    }
```

3. Update `fetchWordById(id:)`:
```swift
    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        let sql = """
        SELECT s.rowid, e.headword, s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level,
               (SELECT p.ipa FROM pronunciations p WHERE p.sense_id = s.id LIMIT 1) as ipa,
               (SELECT ex.text_en FROM examples ex WHERE ex.sense_id = s.id ORDER BY ex.sort_order LIMIT 1) as example_en,
               (SELECT ex.text_vi FROM examples ex WHERE ex.sense_id = s.id ORDER BY ex.sort_order LIMIT 1) as example_vi
        FROM senses s
        JOIN entries e ON s.entry_id = e.id
        WHERE s.rowid = ?;
        """
        let results = try query(sql, bind: { stmt in
            sqlite3_bind_int64(stmt, 1, id)
        }) { [self] stmt in
            parseWord(stmt: stmt)
        }
        return results.first
    }
```

4. Update `parseWord(stmt:stageId:)`:
```swift
    private func parseWord(stmt: OpaquePointer?, stageId: String = "N/A") -> TopicWordDTO {
        TopicWordDTO(
            id: columnInt64(stmt, 0),
            stageId: stageId,
            lemma: columnString(stmt, 1),
            phonetic: columnString(stmt, 6),
            pos: columnString(stmt, 2),
            cefrLevel: columnString(stmt, 5),
            definitionVi: columnString(stmt, 4),
            definitionEn: columnString(stmt, 3),
            exampleEn: columnString(stmt, 7),
            exampleVi: columnString(stmt, 8)
        )
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SQLiteContentRepositoryTests`
Expected: PASS with 5 passing tests.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift
git commit -m "fix(database): subquery and parse bilingual examples in SQLiteContentRepository"
```

---

### Task 2: Data Layer: `LearningPathDTO` and `VocabularyDataSourceProtocol` Extension

**Files:**
- Modify: `VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift:1-50`
- Modify: `VocabCraftApp/Data/Local/Mock/MockVocabularyDataSource.swift:1-50`

**Interfaces:**
- Consumes: None.
- Produces: `LearningPathDTO`, `VocabularyDataSourceProtocol.fetchLearningPaths()`, `VocabularyDataSourceProtocol.fetchTopicDecks(for:)`.

- [ ] **Step 1: Write failing test in `VocabularyDataSourceProtocolTests.swift`**

Create `VocabCraftAppTests/Core/Database/VocabularyDataSourceProtocolTests.swift`:
```swift
@testable import VocabCraftApp
import XCTest

final class VocabularyDataSourceProtocolTests: XCTestCase {
    func testDefaultLearningPathProtocolExtensions() async throws {
        let mock = MockVocabularyDataSource()
        let paths = try await mock.fetchLearningPaths()
        XCTAssertFalse(paths.isEmpty)
        XCTAssertEqual(paths.first?.code, "essential-english-mastery")

        let decks = try await mock.fetchTopicDecks(for: "essential-english-mastery")
        XCTAssertEqual(decks.count, mock.decks.count)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter VocabularyDataSourceProtocolTests`
Expected: FAIL because `LearningPathDTO` and `fetchLearningPaths()` do not exist yet.

- [ ] **Step 3: Define `LearningPathDTO` and extend `VocabularyDataSourceProtocol`**

1. In `VocabularyDataSourceProtocol.swift`, declare `LearningPathDTO`:
```swift
public struct LearningPathDTO: Identifiable, Sendable, Equatable, Codable {
    public let id: String
    public let code: String
    public let titleEn: String
    public let titleVi: String
    public let descriptionEn: String?
    public let descriptionVi: String?
    public let goalCategory: String
    public let targetLevelMin: String
    public let targetLevelMax: String
    public let iconKey: String
    public let themeKey: String
    public let sortOrder: Int

    public init(
        id: String,
        code: String,
        titleEn: String,
        titleVi: String,
        descriptionEn: String? = nil,
        descriptionVi: String? = nil,
        goalCategory: String,
        targetLevelMin: String,
        targetLevelMax: String,
        iconKey: String,
        themeKey: String,
        sortOrder: Int
    ) {
        self.id = id
        self.code = code
        self.titleEn = titleEn
        self.titleVi = titleVi
        self.descriptionEn = descriptionEn
        self.descriptionVi = descriptionVi
        self.goalCategory = goalCategory
        self.targetLevelMin = targetLevelMin
        self.targetLevelMax = targetLevelMax
        self.iconKey = iconKey
        self.themeKey = themeKey
        self.sortOrder = sortOrder
    }
}
```

2. Add methods to `VocabularyDataSourceProtocol`:
```swift
public protocol VocabularyDataSourceProtocol: Sendable {
    func fetchTopicDecks() async throws -> [TopicDeckDTO]
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO]
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO]
    func searchWords(query: String) async throws -> [TopicWordDTO]
    func fetchWordById(id: Int64) async throws -> TopicWordDTO?
    func fetchLearningPaths() async throws -> [LearningPathDTO]
    func fetchTopicDecks(for pathId: String) async throws -> [TopicDeckDTO]
}

public extension VocabularyDataSourceProtocol {
    func fetchLearningPaths() async throws -> [LearningPathDTO] {
        [
            LearningPathDTO(
                id: "7147ba7e-0728-471d-97af-f3e2262a6d23",
                code: "essential-english-mastery",
                titleEn: "Core Curriculum: Comprehensive English",
                titleVi: "Lộ Trình Cốt Lõi: Tiếng Anh Giao Tiếp",
                goalCategory: "general",
                targetLevelMin: "A1",
                targetLevelMax: "C2",
                iconKey: "compass",
                themeKey: "ocean_blue",
                sortOrder: 0
            )
        ]
    }

    func fetchTopicDecks(for pathId: String) async throws -> [TopicDeckDTO] {
        try await fetchTopicDecks()
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter VocabularyDataSourceProtocolTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/DataSources/VocabularyDataSourceProtocol.swift VocabCraftAppTests/Core/Database/VocabularyDataSourceProtocolTests.swift
git commit -m "feat(datasource): define LearningPathDTO and extend VocabularyDataSourceProtocol with default fallbacks"
```

---

### Task 3: Data Layer: Implement Learning Paths Queries in `SQLiteContentRepository`

**Files:**
- Modify: `VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift:105-195`
- Modify: `VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift`

**Interfaces:**
- Consumes: `learning_paths` and `path_decks` tables in `vocab_content.sqlite`.
- Produces: `SQLiteContentRepository.fetchLearningPaths()`, `SQLiteContentRepository.fetchTopicDecks(for pathId: String)`.

- [ ] **Step 1: Write failing unit test in `SQLiteContentRepositoryTests.swift`**

```swift
    func testFetchLearningPathsAndPathDecks() async throws {
        let originalURL = try resolveBundledDatabaseURL()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_vocab_content_paths.sqlite")
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        try FileManager.default.copyItem(at: originalURL, to: tempURL)

        let repo = try SQLiteContentRepository(url: tempURL)
        let paths = try await repo.fetchLearningPaths()
        XCTAssertFalse(paths.isEmpty)
        guard let firstPath = paths.first else { return }
        XCTAssertEqual(firstPath.code, "essential-english-mastery")
        XCTAssertFalse(firstPath.titleEn.isEmpty)
        XCTAssertFalse(firstPath.titleVi.isEmpty)

        let pathDecks = try await repo.fetchTopicDecks(for: firstPath.id)
        XCTAssertFalse(pathDecks.isEmpty)

        // Test defensive fallback on unknown path id
        let fallbackDecks = try await repo.fetchTopicDecks(for: "invalid-path-id")
        XCTAssertFalse(fallbackDecks.isEmpty, "Unknown path id must fallback to all decks")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter SQLiteContentRepositoryTests/testFetchLearningPathsAndPathDecks`
Expected: FAIL because `fetchTopicDecks(for: "invalid-path-id")` executes the default protocol implementation which doesn't check SQLite `path_decks` table yet.

- [ ] **Step 3: Implement `fetchLearningPaths` and `fetchTopicDecks(for:)` in `SQLiteContentRepository.swift`**

Add to `SQLiteContentRepository.swift`:
```swift
    public func fetchLearningPaths() async throws -> [LearningPathDTO] {
        let sql = """
        SELECT id, code, title_en, title_vi, description_en, description_vi,
               goal_category, target_level_min, target_level_max, icon_key, theme_key, sort_order
        FROM learning_paths
        ORDER BY sort_order;
        """
        return try query(sql) { [self] stmt in
            LearningPathDTO(
                id: columnString(stmt, 0),
                code: columnString(stmt, 1),
                titleEn: columnString(stmt, 2),
                titleVi: columnString(stmt, 3),
                descriptionEn: columnString(stmt, 4).isEmpty ? nil : columnString(stmt, 4),
                descriptionVi: columnString(stmt, 5).isEmpty ? nil : columnString(stmt, 5),
                goalCategory: columnString(stmt, 6),
                targetLevelMin: columnString(stmt, 7),
                targetLevelMax: columnString(stmt, 8),
                iconKey: columnString(stmt, 9),
                themeKey: columnString(stmt, 10),
                sortOrder: columnInt(stmt, 11)
            )
        }
    }

    public func fetchTopicDecks(for pathId: String) async throws -> [TopicDeckDTO] {
        let sql = """
        SELECT d.id, d.title_en, d.icon_key, d.theme_key, pd.sort_order, d.ios_sf_symbol
        FROM decks d
        JOIN path_decks pd ON pd.deck_id = d.id
        WHERE pd.path_id = ?
        ORDER BY pd.sort_order;
        """
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let decks = try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, pathId, -1, sqliteTransient)
        }) { [self] stmt in
            let sfSymbol = columnString(stmt, 5)
            let finalIconName = sfSymbol.isEmpty ? "star.fill" : sfSymbol
            return TopicDeckDTO(
                id: columnString(stmt, 0),
                title: columnString(stmt, 1),
                iconName: finalIconName,
                themeKey: columnString(stmt, 3),
                cefrLevel: "A1",
                sortOrder: columnInt(stmt, 4)
            )
        }

        // Defensive fallback: if pathId is empty or no decks assigned, fallback to all decks
        if decks.isEmpty {
            return try await fetchTopicDecks()
        }
        return decks
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter SQLiteContentRepositoryTests`
Expected: PASS with all tests green.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift
git commit -m "feat(database): implement fetchLearningPaths and fetchTopicDecks in SQLiteContentRepository"
```

---

### Task 4: Storage Layer: Active Learning Path Preference in `UserSettingsStore`

**Files:**
- Modify: `VocabCraftApp/Domain/Protocols/UserRoadmapSettingsProtocol.swift`
- Modify: `VocabCraftApp/Core/Database/UserSettingsStore.swift`
- Modify: `VocabCraftAppTests/UserSettingsStoreTests.swift`

**Interfaces:**
- Consumes: `UserDefaults`.
- Produces: `UserRoadmapSettingsProtocol.selectedLearningPathId`, `UserSettingsStore.saveLearningPathPreference(pathId:)`.

- [ ] **Step 1: Write failing unit test in `UserSettingsStoreTests.swift`**

In `VocabCraftAppTests/UserSettingsStoreTests.swift`, add:
```swift
    func testSelectedLearningPathPersistence() {
        let defaults = UserDefaults(suiteName: "test_path_persistence_\(UUID().uuidString)")!
        let store = UserSettingsStore(userDefaults: defaults)

        XCTAssertNil(store.selectedLearningPathId)
        store.saveLearningPathPreference(pathId: "path-123")
        XCTAssertEqual(store.selectedLearningPathId, "path-123")

        let reloaded = UserSettingsStore(userDefaults: defaults)
        XCTAssertEqual(reloaded.selectedLearningPathId, "path-123")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter UserSettingsStoreTests/testSelectedLearningPathPersistence`
Expected: FAIL because `selectedLearningPathId` and `saveLearningPathPreference` do not exist.

- [ ] **Step 3: Implement `selectedLearningPathId` in `UserSettingsStore` and `UserRoadmapSettingsProtocol`**

1. In `VocabCraftApp/Domain/Protocols/UserRoadmapSettingsProtocol.swift`:
```swift
public protocol UserRoadmapSettingsProtocol: Sendable {
    var selectedGoalDeckId: String { get }
    var assessedCefrLevel: String { get }
    var dailyGoalCount: Int { get }
    var notificationTimeInterval: Double { get }
    var selectedLearningPathId: String? { get set }
    func saveRoadmapPreferences(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    )
    func saveLearningPathPreference(pathId: String)
}

public extension UserRoadmapSettingsProtocol {
    var selectedLearningPathId: String? {
        get { nil }
        set {}
    }
    func saveLearningPathPreference(pathId: String) {}
}
```

2. In `VocabCraftApp/Core/Database/UserSettingsStore.swift`:
```swift
    public var selectedLearningPathId: String? {
        get { defaults.string(forKey: "selected_learning_path_id") }
        set { defaults.set(newValue, forKey: "selected_learning_path_id") }
    }

    public func saveLearningPathPreference(pathId: String) {
        self.selectedLearningPathId = pathId
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter UserSettingsStoreTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/UserRoadmapSettingsProtocol.swift VocabCraftApp/Core/Database/UserSettingsStore.swift VocabCraftAppTests/UserSettingsStoreTests.swift
git commit -m "feat(settings): add selectedLearningPathId and saveLearningPathPreference to UserSettingsStore"
```

---

### Task 5: Domain Layer: Multi-Path Support in `LearningPathCurriculum` and `FetchLearningPathUseCase`

**Files:**
- Modify: `VocabCraftApp/Domain/Models/LearningPathCurriculum.swift`
- Modify: `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift`
- Modify: `VocabCraftAppTests/Domain/LearningPathUseCasesTests.swift`

**Interfaces:**
- Consumes: `VocabularyDataSourceProtocol`, `StageProgressRepositoryProtocol`, `UserRoadmapSettingsProtocol`.
- Produces: `LearningPathCurriculum` with `activePath: LearningPathDTO?`, `FetchLearningPathUseCaseProtocol.execute(pathId:forceRefresh:)`.

- [ ] **Step 1: Write failing unit test in `LearningPathUseCasesTests.swift`**

Add tests in `VocabCraftAppTests/Domain/LearningPathUseCasesTests.swift`:
```swift
    func testFetchLearningPathResolvesActivePath() async throws {
        let mockDataSource = MockVocabularyDataSource()
        let mockStageRepo = MockStageProgressRepository()
        let useCase = FetchLearningPathUseCase(
            dataSource: mockDataSource,
            stageRepo: mockStageRepo
        )

        let curriculum = try await useCase.execute(pathId: "7147ba7e-0728-471d-97af-f3e2262a6d23")
        XCTAssertNotNil(curriculum.activePath)
        XCTAssertEqual(curriculum.activePath?.code, "essential-english-mastery")
        XCTAssertFalse(curriculum.decks.isEmpty)
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LearningPathUseCasesTests/testFetchLearningPathResolvesActivePath`
Expected: FAIL because `LearningPathCurriculum` does not expose `activePath` and `execute(pathId:)` does not exist.

- [ ] **Step 3: Update `LearningPathCurriculum.swift` and `FetchLearningPathUseCase.swift`**

1. In `VocabCraftApp/Domain/Models/LearningPathCurriculum.swift`:
```swift
public struct LearningPathCurriculum: Sendable, Equatable {
    public let activePath: LearningPathDTO?
    public let decks: [TopicDeckDTO]
    public let stages: [SubTopicStageDTO]
    public let words: [TopicWordDTO]
    public let progressList: [UserStageProgressData]

    public init(
        activePath: LearningPathDTO? = nil,
        decks: [TopicDeckDTO],
        stages: [SubTopicStageDTO],
        words: [TopicWordDTO],
        progressList: [UserStageProgressData]
    ) {
        self.activePath = activePath
        self.decks = decks
        self.stages = stages
        self.words = words
        self.progressList = progressList
    }
}
```

2. In `VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift`:
Extend protocol and implementation to accept `pathId: String?`:
```swift
public protocol FetchLearningPathUseCaseProtocol: Sendable {
    func execute(pathId: String?, forceRefresh: Bool) async throws -> LearningPathCurriculum
    func execute(forceRefresh: Bool) async throws -> LearningPathCurriculum
    func execute() async throws -> LearningPathCurriculum
}

public extension FetchLearningPathUseCaseProtocol {
    func execute() async throws -> LearningPathCurriculum {
        try await execute(pathId: nil, forceRefresh: false)
    }

    func execute(forceRefresh: Bool) async throws -> LearningPathCurriculum {
        try await execute(pathId: nil, forceRefresh: forceRefresh)
    }
}
```

In `FetchLearningPathUseCase`:
```swift
public final class FetchLearningPathUseCase: FetchLearningPathUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol
    private let userSettings: (any UserRoadmapSettingsProtocol)?
    private let curriculumCache = StaticCurriculumCache()

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol,
        userSettings: (any UserRoadmapSettingsProtocol)? = nil
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
        self.userSettings = userSettings
    }

    public func execute(pathId: String? = nil, forceRefresh: Bool = false) async throws -> LearningPathCurriculum {
        async let progressTask = stageRepo.fetchAllStageProgress()

        let paths = (try? await dataSource.fetchLearningPaths()) ?? []
        let targetId = pathId ?? userSettings?.selectedLearningPathId
        let activePath = paths.first(where: { $0.id == targetId }) ?? paths.first

        let staticData: StaticCurriculumData
        if !forceRefresh, let cached = await curriculumCache.get() {
            staticData = cached
        } else {
            let loaded = try await loadStaticCurriculum(pathId: activePath?.id)
            await curriculumCache.set(loaded)
            staticData = loaded
        }

        let progressList = try await progressTask
        return LearningPathCurriculum(
            activePath: activePath,
            decks: staticData.decks,
            stages: staticData.stages,
            words: staticData.words,
            progressList: progressList
        )
    }

    private func loadStaticCurriculum(pathId: String?) async throws -> StaticCurriculumData {
        let decks: [TopicDeckDTO]
        if let pathId {
            decks = try await dataSource.fetchTopicDecks(for: pathId)
        } else {
            decks = try await dataSource.fetchTopicDecks()
        }

        // Parallel fetch stages & words
        ...
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LearningPathUseCasesTests`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Models/LearningPathCurriculum.swift VocabCraftApp/Domain/UseCases/FetchLearningPathUseCase.swift VocabCraftAppTests/Domain/LearningPathUseCasesTests.swift
git commit -m "feat(domain): integrate active LearningPathDTO into FetchLearningPathUseCase and LearningPathCurriculum"
```

---

### Task 6: Presentation Layer: Wire Active Journey to `HomepageViewModel`, Header Badge & Localization

**Files:**
- Modify: `VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift`
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftAppTests/Features/Homepage/HomepageViewModelTests.swift`

**Interfaces:**
- Consumes: `FetchLearningPathUseCaseProtocol`, `UserSettingsStore`, `CraftUIKit`.
- Produces: `HomepageViewModel.activeLearningPath`, `HomepageViewModel.switchLearningPath(to:)`, UI Badge in `HomeTopHeaderView`.

- [ ] **Step 1: Write failing unit test in `HomepageViewModelTests.swift`**

```swift
    func testHomepageViewModelLoadsActiveLearningPath() async throws {
        let mockUseCase = MockFetchLearningPathUseCase()
        let defaults = UserDefaults(suiteName: "test_hp_vm_\(UUID().uuidString)")!
        let settings = UserSettingsStore(userDefaults: defaults)
        let viewModel = HomepageViewModel(
            fetchLearningPathUseCase: mockUseCase,
            userSettings: settings
        )

        await viewModel.loadLearningPath()
        XCTAssertNotNil(viewModel.activeLearningPath)
        XCTAssertEqual(viewModel.activeLearningPath?.code, "essential-english-mastery")
    }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HomepageViewModelTests/testHomepageViewModelLoadsActiveLearningPath`
Expected: FAIL because `activeLearningPath` is not declared on `HomepageViewModel`.

- [ ] **Step 3: Update `HomepageViewModel.swift`**

1. Expose `activeLearningPath`:
```swift
    public private(set) var activeLearningPath: LearningPathDTO?
```
2. In `loadLearningPath()`:
```swift
    public func loadLearningPath() async {
        refreshDailyProgress()
        guard let useCase = fetchLearningPathUseCase else { return }
        isLoading = true
        errorMessage = nil
        do {
            let curriculum = try await useCase.execute(pathId: userSettings?.selectedLearningPathId, forceRefresh: false)
            self.activeLearningPath = curriculum.activePath
            self.sections = LearningPathDataMapper.map(curriculum: curriculum)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public func switchLearningPath(to pathId: String) async {
        userSettings?.saveLearningPathPreference(pathId: pathId)
        await loadLearningPath()
    }
```

- [ ] **Step 4: Add Localized Strings in `Localizable.xcstrings`**

Add bilingual parity entries:
- `app.home.learning_path.badge`:
  - EN: "Active Journey"
  - VI: "Lộ trình hiện tại"
- `app.home.learning_path.level_format`:
  - EN: "Level %@"
  - VI: "Trình độ %@"

- [ ] **Step 5: Integrate Roadmap Badge in `HomeTopHeaderView.swift`**

In `HomeTopHeaderView.swift`, if `viewModel.activeLearningPath` is available:
Render a subtle `CraftBadge` or indicator showing the active path's title (`activeLearningPath.titleVi` / `activeLearningPath.titleEn` based on app locale) and target levels with zero hardcoded colors or fonts.

- [ ] **Step 6: Run tests to verify they pass**

Run: `swift test --filter HomepageViewModelTests`
Run: `swift test --filter LocalizationTests`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add VocabCraftApp/Features/Homepage/ViewModels/HomepageViewModel.swift VocabCraftApp/Features/Homepage/Views/HomeTopHeaderView.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/Features/Homepage/HomepageViewModelTests.swift
git commit -m "feat(ui): display active learning path in Homepage and expose switchLearningPath"
```

---

### Task 7: Full Verification Gate: Tests, SwiftLint & Xcode Build Verification

**Files:** None (Repository-wide verification).

- [ ] **Step 1: Run full unit test suite**

Run: `swift test`
Expected: 100% tests pass.

- [ ] **Step 2: Run SwiftLint check**

Run: `swiftlint`
Expected: 0 errors, 0 warnings.

- [ ] **Step 3: Run Xcode build / xcodebuild**

Run: `xcodebuild -scheme VocabCraftApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
Expected: BUILD SUCCEEDED with 0 compiler warnings.

- [ ] **Step 4: Inspect Git status**

Run: `git status`
Expected: Working tree clean, everything committed.
