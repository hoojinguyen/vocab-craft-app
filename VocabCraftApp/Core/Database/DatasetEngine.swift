import Foundation
import SQLite3

@MainActor
public final class DatasetEngine: DatasetDataSourceProtocol {
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

    // MARK: - Safe SQLite Extraction Helpers

    private func columnText(_ statement: OpaquePointer?, _ index: Int32) -> String {
        guard let cStr = sqlite3_column_text(statement, index) else { return "" }
        return String(cString: cStr)
    }

    private func optionalColumnText(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard let cStr = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: cStr)
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
            let drillType = columnText(statement, 1)
            let promptText = columnText(statement, 2)
            let correctAnswer = columnText(statement, 3)
            let distractorsJson = optionalColumnText(statement, 4) ?? "[]"
            let targetTimeMs = Int(sqlite3_column_int(statement, 5))
            let sentenceTextEn = optionalColumnText(statement, 6)

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
            let lemma = columnText(statement, 1)
            let pos = optionalColumnText(statement, 2)
            let ipaUs = optionalColumnText(statement, 3)
            let cefr = optionalColumnText(statement, 4)
            let defEn = optionalColumnText(statement, 5)
            let defVi = optionalColumnText(statement, 6)
            let example = optionalColumnText(statement, 7)

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

    public func fetchWordRecords(limit: Int = 50, cefrLevel: String? = nil) -> [WordRecord] {
        guard let db = db else { return [] }
        var query = """
            SELECT w.id, w.lemma, w.pos, w.ipa_us, w.cefr_level, d.definition_en, d.definition_vi, d.example
            FROM words w
            LEFT JOIN definitions d ON w.id = d.word_id
        """
        if let cefr = cefrLevel, !cefr.isEmpty {
            query += " WHERE w.cefr_level = ?"
        }
        query += " LIMIT ?;"

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        var paramIdx: Int32 = 1
        if let cefr = cefrLevel, !cefr.isEmpty {
            sqlite3_bind_text(statement, paramIdx, cefr, -1, SQLITE_TRANSIENT)
            paramIdx += 1
        }
        sqlite3_bind_int(statement, paramIdx, Int32(limit))

        var results: [WordRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let lemma = columnText(statement, 1)
            let pos = optionalColumnText(statement, 2)
            let ipaUs = optionalColumnText(statement, 3)
            let cefr = optionalColumnText(statement, 4)
            let defEn = optionalColumnText(statement, 5)
            let defVi = optionalColumnText(statement, 6)
            let example = optionalColumnText(statement, 7)

            results.append(WordRecord(
                id: id,
                lemma: lemma,
                pos: pos,
                ipaUs: ipaUs,
                cefrLevel: cefr,
                definitionEn: defEn,
                definitionVi: defVi,
                example: example
            ))
        }
        return results
    }

    public func searchWords(query searchQuery: String) -> [WordRecord] {
        guard let db = db, !searchQuery.isEmpty else { return [] }
        let sql = """
            SELECT w.id, w.lemma, w.pos, w.ipa_us, w.cefr_level, d.definition_en, d.definition_vi, d.example
            FROM words w
            LEFT JOIN definitions d ON w.id = d.word_id
            WHERE w.lemma LIKE ? OR d.definition_en LIKE ? OR d.definition_vi LIKE ?
            LIMIT 50;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(statement) }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let pattern = "%\(searchQuery)%"
        sqlite3_bind_text(statement, 1, pattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, pattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 3, pattern, -1, SQLITE_TRANSIENT)

        var results: [WordRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let lemma = columnText(statement, 1)
            let pos = optionalColumnText(statement, 2)
            let ipaUs = optionalColumnText(statement, 3)
            let cefr = optionalColumnText(statement, 4)
            let defEn = optionalColumnText(statement, 5)
            let defVi = optionalColumnText(statement, 6)
            let example = optionalColumnText(statement, 7)

            results.append(WordRecord(
                id: id,
                lemma: lemma,
                pos: pos,
                ipaUs: ipaUs,
                cefrLevel: cefr,
                definitionEn: defEn,
                definitionVi: defVi,
                example: example
            ))
        }
        return results
    }

    public func fetchWordById(id targetId: Int64) -> WordRecord? {
        guard let db = db else { return nil }
        let query = """
            SELECT w.id, w.lemma, w.pos, w.ipa_us, w.cefr_level, d.definition_en, d.definition_vi, d.example
            FROM words w
            LEFT JOIN definitions d ON w.id = d.word_id
            WHERE w.id = ? LIMIT 1;
        """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int64(statement, 1, targetId)

        if sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let lemma = columnText(statement, 1)
            let pos = optionalColumnText(statement, 2)
            let ipaUs = optionalColumnText(statement, 3)
            let cefr = optionalColumnText(statement, 4)
            let defEn = optionalColumnText(statement, 5)
            let defVi = optionalColumnText(statement, 6)
            let example = optionalColumnText(statement, 7)

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
        return fetchWordRecords(limit: 100).randomElement()
    }

    public func fetchTopicDecks() -> [TopicDeckRecord] {
        guard let db = db else { return [] }
        let query = """
            SELECT id, title, icon_name, badge_color_hex, sort_order
            FROM topic_decks
            ORDER BY sort_order ASC;
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            return []
        }
        defer { sqlite3_finalize(statement) }

        var results: [TopicDeckRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = columnText(statement, 0)
            let title = columnText(statement, 1)
            let iconName = columnText(statement, 2)
            let badgeColorHex = columnText(statement, 3)
            let sortOrder = Int(sqlite3_column_int(statement, 4))

            results.append(TopicDeckRecord(id: id, title: title, iconName: iconName, badgeColorHex: badgeColorHex, sortOrder: sortOrder))
        }
        return results
    }

    public func fetchSubTopicNodes(deckId: String) -> [SubTopicNodeRecord] {
        guard let db = db else { return [] }
        let query = """
            SELECT id, deck_id, title, icon_name, sort_order
            FROM topic_nodes
            WHERE deck_id = ?
            ORDER BY sort_order ASC;
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            return []
        }
        defer { sqlite3_finalize(statement) }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, deckId, -1, SQLITE_TRANSIENT)

        var results: [SubTopicNodeRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = columnText(statement, 0)
            let dId = columnText(statement, 1)
            let title = columnText(statement, 2)
            let iconName = columnText(statement, 3)
            let sortOrder = Int(sqlite3_column_int(statement, 4))

            results.append(SubTopicNodeRecord(id: id, deckId: dId, title: title, iconName: iconName, sortOrder: sortOrder))
        }
        return results
    }

    public func fetchWordsForNode(nodeId: String) -> [WordRecord] {
        guard let db = db else { return [] }
        let query = """
            SELECT w.id, w.lemma, w.pos, w.ipa_us, w.cefr_level, d.definition_en, d.definition_vi, d.example
            FROM words w
            JOIN node_words nw ON w.id = nw.word_id
            LEFT JOIN definitions d ON w.id = d.word_id
            WHERE nw.node_id = ?;
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) != SQLITE_OK {
            return []
        }
        defer { sqlite3_finalize(statement) }

        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        sqlite3_bind_text(statement, 1, nodeId, -1, SQLITE_TRANSIENT)

        var results: [WordRecord] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let lemma = columnText(statement, 1)
            let pos = optionalColumnText(statement, 2)
            let ipaUs = optionalColumnText(statement, 3)
            let cefr = optionalColumnText(statement, 4)
            let defEn = optionalColumnText(statement, 5)
            let defVi = optionalColumnText(statement, 6)
            let example = optionalColumnText(statement, 7)

            results.append(WordRecord(
                id: id,
                lemma: lemma,
                pos: pos,
                ipaUs: ipaUs,
                cefrLevel: cefr,
                definitionEn: defEn,
                definitionVi: defVi,
                example: example
            ))
        }
        return results
    }
}
