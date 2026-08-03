import XCTest
import SQLite3
@testable import VocabCraftApp

final class DatasetEngineTests: XCTestCase {
    
    var testDbPath: String!

    override func setUpWithError() throws {
        try super.setUpWithError()
        let tempDir = FileManager.default.temporaryDirectory
        testDbPath = tempDir.appendingPathComponent("test_dataset_\(UUID().uuidString).db").path
        
        var db: OpaquePointer?
        guard sqlite3_open(testDbPath, &db) == SQLITE_OK else {
            XCTFail("Failed to create test database")
            return
        }
        defer { sqlite3_close(db) }

        let sqlStatements = [
            """
            CREATE TABLE words (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                lemma TEXT UNIQUE NOT NULL,
                pos TEXT NOT NULL,
                ipa_uk TEXT,
                ipa_us TEXT,
                frequency_rank INTEGER,
                cefr_level TEXT
            );
            """,
            """
            CREATE TABLE definitions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                word_id INTEGER NOT NULL,
                definition_en TEXT,
                definition_vi TEXT,
                example TEXT,
                source TEXT,
                FOREIGN KEY (word_id) REFERENCES words (id) ON DELETE CASCADE
            );
            """,
            """
            CREATE TABLE sentences (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                text_en TEXT UNIQUE NOT NULL,
                text_vi TEXT,
                difficulty_score REAL,
                cefr_level TEXT,
                audio_path TEXT,
                source TEXT
            );
            """,
            """
            CREATE TABLE reflex_drills (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sentence_id INTEGER NOT NULL,
                drill_type TEXT NOT NULL,
                prompt_text TEXT,
                correct_answer TEXT NOT NULL,
                distractors_json TEXT,
                target_time_ms INTEGER DEFAULT 2500,
                FOREIGN KEY (sentence_id) REFERENCES sentences (id) ON DELETE CASCADE
            );
            """,
            """
            INSERT INTO words (id, lemma, pos, ipa_uk, ipa_us, frequency_rank, cefr_level)
            VALUES (1, 'apple', 'noun', '/ˈæp.əl/', '/ˈæp.əl/', 100, 'A1');
            """,
            """
            INSERT INTO definitions (word_id, definition_en, definition_vi, example, source)
            VALUES (1, 'A round fruit with red or green skin.', 'Quả táo', 'I ate an apple.', 'dictionary');
            """,
            """
            INSERT INTO sentences (id, text_en, text_vi, difficulty_score, cefr_level, audio_path, source)
            VALUES (10, 'She eats an apple every morning.', 'Cô ấy ăn một quả táo mỗi sáng.', 1.5, 'B1', NULL, 'custom');
            """,
            """
            INSERT INTO reflex_drills (id, sentence_id, drill_type, prompt_text, correct_answer, distractors_json, target_time_ms)
            VALUES (100, 10, 'translate', 'Cô ấy ăn một quả táo mỗi sáng.', 'She eats an apple every morning.', '["She ate an apple", "He eats an apple"]', 2500);
            """
        ]

        for sql in sqlStatements {
            var errMsg: UnsafeMutablePointer<CChar>?
            let result = sqlite3_exec(db, sql, nil, nil, &errMsg)
            if result != SQLITE_OK {
                let message = errMsg.map { String(cString: $0) } ?? "Unknown error"
                XCTFail("sqlite3_exec failed for SQL: \(sql) with error: \(message)")
            }
        }
    }

    override func tearDownWithError() throws {
        if let path = testDbPath, FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        try super.tearDownWithError()
    }

    func testDatasetEngineInitializationSuccess() {
        let engine = DatasetEngine(dbPath: testDbPath)
        XCTAssertNotNil(engine, "DatasetEngine should initialize successfully with valid dbPath")
    }

    func testDatasetEngineInitializationFailureWithInvalidPath() {
        let engine = DatasetEngine(dbPath: "/invalid/path/does_not_exist.db")
        XCTAssertNil(engine, "DatasetEngine initialization should fail for non-existent dbPath")
    }

    func testDatasetEngineInitializationFailureWithNilPath() {
        let engine = DatasetEngine(dbPath: nil)
        XCTAssertNil(engine, "DatasetEngine initialization should fail when dbPath is nil")
    }

    func testGetWordDetailsSuccess() {
        guard let engine = DatasetEngine(dbPath: testDbPath) else {
            XCTFail("Failed to initialize DatasetEngine")
            return
        }

        let word = engine.getWordDetails(lemma: "apple")
        XCTAssertNotNil(word)
        XCTAssertEqual(word?.id, 1)
        XCTAssertEqual(word?.lemma, "apple")
        XCTAssertEqual(word?.pos, "noun")
        XCTAssertEqual(word?.ipaUs, "/ˈæp.əl/")
        XCTAssertEqual(word?.cefrLevel, "A1")
        XCTAssertEqual(word?.definitionEn, "A round fruit with red or green skin.")
        XCTAssertEqual(word?.definitionVi, "Quả táo")
        XCTAssertEqual(word?.example, "I ate an apple.")
    }

    func testGetWordDetailsNotFound() {
        guard let engine = DatasetEngine(dbPath: testDbPath) else {
            XCTFail("Failed to initialize DatasetEngine")
            return
        }

        let word = engine.getWordDetails(lemma: "nonexistentlemma")
        XCTAssertNil(word)
    }

    func testGetRandomReflexDrillSuccess() {
        guard let engine = DatasetEngine(dbPath: testDbPath) else {
            XCTFail("Failed to initialize DatasetEngine")
            return
        }

        let drill = engine.getRandomReflexDrill(cefrLevel: "B1")
        XCTAssertNotNil(drill)
        XCTAssertEqual(drill?.id, 100)
        XCTAssertEqual(drill?.drillType, "translate")
        XCTAssertEqual(drill?.promptText, "Cô ấy ăn một quả táo mỗi sáng.")
        XCTAssertEqual(drill?.correctAnswer, "She eats an apple every morning.")
        XCTAssertEqual(drill?.distractors, ["She ate an apple", "He eats an apple"])
        XCTAssertEqual(drill?.targetTimeMs, 2500)
        XCTAssertEqual(drill?.sentenceTextEn, "She eats an apple every morning.")
    }

    func testGetRandomReflexDrillNotFoundForDifferentCEFR() {
        guard let engine = DatasetEngine(dbPath: testDbPath) else {
            XCTFail("Failed to initialize DatasetEngine")
            return
        }

        let drill = engine.getRandomReflexDrill(cefrLevel: "C2")
        XCTAssertNil(drill)
    }

    func testGetRandomWordForWidgetSuccess() {
        guard let engine = DatasetEngine(dbPath: testDbPath) else {
            XCTFail("Failed to initialize DatasetEngine")
            return
        }

        let word = engine.getRandomWordForWidget()
        XCTAssertNotNil(word)
        XCTAssertEqual(word?.lemma, "apple")
    }

    func testDatasetEngineWithMainDatasetFileIfAvailable() {
        let mainDbPath = "/Users/hoojinguyen/Hooji/antigravity/EnglishDataset/data/output/english_dataset.db"
        if FileManager.default.fileExists(atPath: mainDbPath) {
            let engine = DatasetEngine(dbPath: mainDbPath)
            XCTAssertNotNil(engine)
            let word = engine?.getWordDetails(lemma: "dictionary")
            XCTAssertNotNil(word)
            XCTAssertEqual(word?.lemma, "dictionary")
        }
    }
}
