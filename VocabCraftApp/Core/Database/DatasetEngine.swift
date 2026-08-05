import Foundation
import SQLite3

public final class DatasetEngine: @unchecked Sendable {
    private var db: OpaquePointer?

    public init?(dbPath: String? = Bundle.main.path(forResource: "english_dataset", ofType: "db")) {
        guard let path = dbPath, !path.isEmpty else { return nil }
        guard FileManager.default.fileExists(atPath: path) else { return nil }

        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX, nil) != SQLITE_OK {
            if let db = db {
                sqlite3_close(db)
            }
            return nil
        }
    }

    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }

    public func getRandomReflexDrill(cefrLevel: String) -> ReflexDrillRecord? {
        guard let db = db else { return nil }
        let query = """
            SELECT r.id, r.drill_type, r.prompt_text, r.correct_answer, r.distractors_json, r.target_time_ms, s.text_en
            FROM reflex_drills r
            JOIN sentences s ON r.sentence_id = s.id
            WHERE s.cefr_level = ?
            ORDER BY RANDOM() LIMIT 1;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, cefrLevel, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let drillType = String(cString: sqlite3_column_text(statement, 1))
            let promptText = sqlite3_column_text(statement, 2).map { String(cString: $0) } ?? ""
            let correctAnswer = String(cString: sqlite3_column_text(statement, 3))
            let distractorsJson = sqlite3_column_text(statement, 4).map { String(cString: $0) } ?? "[]"
            let targetTimeMs = Int(sqlite3_column_int(statement, 5))
            let sentenceTextEn = sqlite3_column_text(statement, 6).map { String(cString: $0) }

            let data = distractorsJson.data(using: .utf8) ?? Data()
            let distractors = (try? JSONSerialization.jsonObject(with: data) as? [String]) ?? []

            return ReflexDrillRecord(
                id: id,
                drillType: drillType,
                promptText: promptText,
                correctAnswer: correctAnswer,
                distractors: distractors,
                targetTimeMs: targetTimeMs,
                sentenceTextEn: sentenceTextEn
            )
        }
        return nil
    }

    public func getWordDetails(lemma: String) -> WordRecord? {
        guard let db = db else { return nil }
        let query = """
            SELECT w.id, w.lemma, w.pos, w.ipa_us, w.cefr_level, d.definition_en, d.definition_vi, d.example
            FROM words w
            LEFT JOIN definitions d ON w.id = d.word_id
            WHERE w.lemma = ? LIMIT 1;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, lemma, -1, SQLITE_TRANSIENT)

        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let lemma = String(cString: sqlite3_column_text(statement, 1))
            let pos = sqlite3_column_text(statement, 2).map { String(cString: $0) }
            let ipaUs = sqlite3_column_text(statement, 3).map { String(cString: $0) }
            let cefr = sqlite3_column_text(statement, 4).map { String(cString: $0) }
            let defEn = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let defVi = sqlite3_column_text(statement, 6).map { String(cString: $0) }
            let example = sqlite3_column_text(statement, 7).map { String(cString: $0) }

            return WordRecord(
                id: id,
                lemma: lemma,
                pos: pos,
                ipaUs: ipaUs,
                cefrLevel: cefr,
                definitionEn: defEn,
                definitionVi: defVi,
                example: example
            )
        }
        return nil
    }

    public func getRandomWordForWidget() -> WordRecord? {
        guard let db = db else { return nil }
        let query = """
            SELECT w.id, w.lemma, w.pos, w.ipa_us, w.cefr_level, d.definition_en, d.definition_vi, d.example
            FROM words w
            LEFT JOIN definitions d ON w.id = d.word_id
            ORDER BY RANDOM() LIMIT 1;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let lemma = String(cString: sqlite3_column_text(statement, 1))
            let pos = sqlite3_column_text(statement, 2).map { String(cString: $0) }
            let ipaUs = sqlite3_column_text(statement, 3).map { String(cString: $0) }
            let cefr = sqlite3_column_text(statement, 4).map { String(cString: $0) }
            let defEn = sqlite3_column_text(statement, 5).map { String(cString: $0) }
            let defVi = sqlite3_column_text(statement, 6).map { String(cString: $0) }
            let example = sqlite3_column_text(statement, 7).map { String(cString: $0) }

            return WordRecord(
                id: id,
                lemma: lemma,
                pos: pos,
                ipaUs: ipaUs,
                cefrLevel: cefr,
                definitionEn: defEn,
                definitionVi: defVi,
                example: example
            )
        }
        return nil
    }
}
