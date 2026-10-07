# SQLite Content Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a SQLite-backed vocabulary data source to replace the mock JSON bundled catalog.

**Architecture:** Use Apple's native `SQLite3` C-API to run read-only queries against `vocab_content.sqlite`. Map SQLite tables to `VocabularyDataSourceProtocol` DTOs, using `rowid` for the `TopicWordDTO` integer ID. Inject this via `AppContainer.swift`.

**Tech Stack:** Swift, SQLite3

**Spec:** `docs/superpowers/specs/2026-10-06-sqlite-integration-design.md`

## Global Constraints

- Run native `sqlite3` API, no third-party ORMs.
- Zero errors or warnings on build.
- Follow existing Swift protocols exactly.

---

### Task 1: SQLiteContentRepository Initialization

**Files:**
- Create: `VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift`
- Create: `VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift`

**Interfaces:**
- Produces: `class SQLiteContentRepository: VocabularyDataSourceProtocol` with an initializer `init(url: URL) throws`.

- [ ] **Step 1: Write the failing test**

```swift
import XCTest
@testable import VocabCraftApp

final class SQLiteContentRepositoryTests: XCTestCase {
    func testInitializationThrowsOnMissingFile() {
        let missingURL = FileManager.default.temporaryDirectory.appendingPathComponent("missing.sqlite")
        XCTAssertThrowsError(try SQLiteContentRepository(url: missingURL))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftAppTests -only-testing:VocabCraftAppTests/SQLiteContentRepositoryTests/testInitializationThrowsOnMissingFile`
Expected: FAIL due to missing class.

- [ ] **Step 3: Write minimal implementation**

```swift
import Foundation
import SQLite3

public enum SQLiteContentError: Error {
    case missingDatabase(String)
    case sqliteError(String)
}

public final class SQLiteContentRepository: VocabularyDataSourceProtocol, Sendable {
    private let url: URL
    
    public init(url: URL) throws {
        self.url = url
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SQLiteContentError.missingDatabase(url.path)
        }
    }
    
    // Stub methods to satisfy protocol
    public func fetchTopicDecks() async throws -> [TopicDeckDTO] { [] }
    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] { [] }
    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] { [] }
    public func searchWords(query: String) async throws -> [TopicWordDTO] { [] }
    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? { nil }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftAppTests -only-testing:VocabCraftAppTests/SQLiteContentRepositoryTests/testInitializationThrowsOnMissingFile`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift
git commit -m "feat: add SQLiteContentRepository stub and init test"
```

### Task 2: Implement Deck & Stage Fetching

**Files:**
- Modify: `VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift`
- Modify: `VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift`

**Interfaces:**
- Consumes: `SQLiteContentRepository`
- Produces: `fetchTopicDecks() -> [TopicDeckDTO]` and `fetchSubTopicStages(deckId:) -> [SubTopicStageDTO]` implementation.

- [ ] **Step 1: Write the failing test**

```swift
func testFetchDecksAndStages() async throws {
    // Copy the bundled DB for testing
    let testBundle = Bundle(for: type(of: self))
    let originalURL = testBundle.url(forResource: "vocab_content", withExtension: "sqlite")!
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_vocab_content.sqlite")
    if FileManager.default.fileExists(atPath: tempURL.path) {
        try FileManager.default.removeItem(at: tempURL)
    }
    try FileManager.default.copyItem(at: originalURL, to: tempURL)
    
    let repo = try SQLiteContentRepository(url: tempURL)
    let decks = try await repo.fetchTopicDecks()
    XCTAssertFalse(decks.isEmpty)
    
    let stages = try await repo.fetchSubTopicStages(deckId: decks.first!.id)
    XCTAssertFalse(stages.isEmpty)
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftAppTests -only-testing:VocabCraftAppTests/SQLiteContentRepositoryTests/testFetchDecksAndStages`
Expected: FAIL since stub returns `[]`.

- [ ] **Step 3: Write minimal implementation**

```swift
// Add private helpers to open DB and run queries
private func query<T>(_ sql: String, bind: (OpaquePointer?) -> Void = { _ in }, rowMapper: (OpaquePointer?) -> T) throws -> [T] {
    var db: OpaquePointer?
    let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
    guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK else {
        throw SQLiteContentError.sqliteError("Failed to open DB")
    }
    defer { sqlite3_close(db) }
    
    var stmt: OpaquePointer?
    guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
        throw SQLiteContentError.sqliteError("Prepare failed: \(String(cString: sqlite3_errmsg(db)))")
    }
    defer { sqlite3_finalize(stmt) }
    
    bind(stmt)
    
    var results: [T] = []
    while sqlite3_step(stmt) == SQLITE_ROW {
        results.append(rowMapper(stmt))
    }
    return results
}

public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
    let sql = "SELECT id, title_en, icon_key, theme_key, sort_order FROM decks ORDER BY sort_order;"
    return try query(sql) { stmt in
        TopicDeckDTO(
            id: String(cString: sqlite3_column_text(stmt, 0)),
            title: String(cString: sqlite3_column_text(stmt, 1)),
            iconName: String(cString: sqlite3_column_text(stmt, 2)),
            badgeColorHex: String(cString: sqlite3_column_text(stmt, 3)),
            cefrLevel: "A1", // Default placeholder if missing
            sortOrder: Int(sqlite3_column_int(stmt, 4))
        )
    }
}

public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
    let sql = "SELECT id, deck_id, title_en, icon_key, sort_order FROM lessons WHERE deck_id = ? ORDER BY sort_order;"
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    return try query(sql, bind: { stmt in
        sqlite3_bind_text(stmt, 1, deckId, -1, SQLITE_TRANSIENT)
    }) { stmt in
        SubTopicStageDTO(
            id: String(cString: sqlite3_column_text(stmt, 0)),
            deckId: String(cString: sqlite3_column_text(stmt, 1)),
            title: String(cString: sqlite3_column_text(stmt, 2)),
            iconName: String(cString: sqlite3_column_text(stmt, 3)),
            sortOrder: Int(sqlite3_column_int(stmt, 4))
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftAppTests -only-testing:VocabCraftAppTests/SQLiteContentRepositoryTests/testFetchDecksAndStages`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift
git commit -m "feat: implement deck and stage fetching in SQLite repo"
```

### Task 3: Implement Words & Search Fetching

**Files:**
- Modify: `VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift`
- Modify: `VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift`

**Interfaces:**
- Consumes: `SQLiteContentRepository`
- Produces: `fetchWordsForStage`, `searchWords`, `fetchWordById` mapped to `TopicWordDTO`.

- [ ] **Step 1: Write the failing test**

```swift
func testFetchWordsAndSearch() async throws {
    let testBundle = Bundle(for: type(of: self))
    let url = testBundle.url(forResource: "vocab_content", withExtension: "sqlite")!
    let repo = try SQLiteContentRepository(url: url)
    
    let words = try await repo.searchWords(query: "hello")
    XCTAssertFalse(words.isEmpty)
    
    if let first = words.first {
        let fetched = try await repo.fetchWordById(id: first.id)
        XCTAssertEqual(first.id, fetched?.id)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme VocabCraftAppTests -only-testing:VocabCraftAppTests/SQLiteContentRepositoryTests/testFetchWordsAndSearch`
Expected: FAIL since search/fetch returns `[]` or `nil`.

- [ ] **Step 3: Write minimal implementation**

```swift
private func parseWord(stmt: OpaquePointer?) -> TopicWordDTO {
    let rowid = sqlite3_column_int64(stmt, 0)
    let lemma = String(cString: sqlite3_column_text(stmt, 1))
    let pos = String(cString: sqlite3_column_text(stmt, 2))
    let defEn = String(cString: sqlite3_column_text(stmt, 3))
    let defVi = String(cString: sqlite3_column_text(stmt, 4))
    let cefr = String(cString: sqlite3_column_text(stmt, 5))
    let ipa = sqlite3_column_type(stmt, 6) != SQLITE_NULL ? String(cString: sqlite3_column_text(stmt, 6)) : ""
    
    return TopicWordDTO(
        id: rowid,
        stageId: "N/A", // Handled elsewhere or not needed directly
        lemma: lemma,
        phonetic: ipa,
        pos: pos,
        cefrLevel: cefr,
        definitionVi: defVi,
        definitionEn: defEn,
        exampleEn: "",
        exampleVi: ""
    )
}

public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
    let sql = """
    SELECT s.rowid, e.headword, s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level,
           (SELECT p.ipa FROM pronunciations p WHERE p.sense_id = s.id LIMIT 1) as ipa
    FROM senses s
    JOIN lesson_senses ls ON ls.sense_id = s.id
    JOIN entries e ON s.entry_id = e.id
    WHERE ls.lesson_id = ?
    ORDER BY ls.sort_order;
    """
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    return try query(sql, bind: { stmt in
        sqlite3_bind_text(stmt, 1, stageId, -1, SQLITE_TRANSIENT)
    }) { stmt in
        parseWord(stmt: stmt)
    }
}

public func searchWords(query queryText: String) async throws -> [TopicWordDTO] {
    let sql = """
    SELECT s.rowid, e.headword, s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level,
           (SELECT p.ipa FROM pronunciations p WHERE p.sense_id = s.id LIMIT 1) as ipa
    FROM senses s
    JOIN entries e ON s.entry_id = e.id
    WHERE e.headword LIKE ? OR s.definition_en LIKE ? OR s.definition_vi LIKE ?
    LIMIT 50;
    """
    let pattern = "%\(queryText)%"
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    return try query(sql, bind: { stmt in
        sqlite3_bind_text(stmt, 1, pattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, pattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, pattern, -1, SQLITE_TRANSIENT)
    }) { stmt in
        parseWord(stmt: stmt)
    }
}

public func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
    let sql = """
    SELECT s.rowid, e.headword, s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level,
           (SELECT p.ipa FROM pronunciations p WHERE p.sense_id = s.id LIMIT 1) as ipa
    FROM senses s
    JOIN entries e ON s.entry_id = e.id
    WHERE s.rowid = ?;
    """
    let results = try query(sql, bind: { stmt in
        sqlite3_bind_int64(stmt, 1, id)
    }) { stmt in
        parseWord(stmt: stmt)
    }
    return results.first
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme VocabCraftAppTests -only-testing:VocabCraftAppTests/SQLiteContentRepositoryTests/testFetchWordsAndSearch`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Database/DataSources/SQLiteContentRepository.swift VocabCraftAppTests/Core/Database/SQLiteContentRepositoryTests.swift
git commit -m "feat: implement words and search fetching in SQLite repo"
```

### Task 4: Integrate in AppContainer

**Files:**
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`

**Interfaces:**
- Consumes: `SQLiteContentRepository`
- Produces: Modified data source injection.

- [ ] **Step 1: Write the failing test**
(No dedicated unit test for DI structure change; validation happens via build)

- [ ] **Step 2: Write minimal implementation**

```swift
// In VocabCraftApp/App/DI/AppContainer.swift, modify initialization
// Remove BundledVocabularyDataSource usage.

static func getProductionDataSource() -> VocabularyDataSourceProtocol {
    do {
        // Copy vocab_content.sqlite to Application Support if needed
        let fm = FileManager.default
        let appSupport = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSupport.appendingPathComponent("VocabCraft/Content/v4", isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let dest = dir.appendingPathComponent("vocab_content.sqlite")
        
        if !fm.fileExists(atPath: dest.path) {
            if let src = Bundle.main.url(forResource: "vocab_content", withExtension: "sqlite") {
                try fm.copyItem(at: src, to: dest)
            }
        }
        return try SQLiteContentRepository(url: dest)
    } catch {
        print("Failed to initialize SQLite content: \(error)")
        return BundledVocabularyDataSource() // Safe fallback
    }
}

// In the init(modelContainer:...) of AppContainer:
let resolvedDataSource: VocabularyDataSourceProtocol = vocabularyDataSource
    ?? Self.getProductionDataSource()
```

- [ ] **Step 3: Run full app tests**

Run: `xcodebuild test -scheme VocabCraftAppTests`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add VocabCraftApp/App/DI/AppContainer.swift
git commit -m "feat: wire up SQLiteContentRepository in AppContainer"
```
