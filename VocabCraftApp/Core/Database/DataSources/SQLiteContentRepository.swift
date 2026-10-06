import Foundation
import SQLite3

public enum SQLiteContentError: Error, Equatable, Sendable {
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

    // MARK: - Query Helpers

    private func query<T>(
        _ sql: String,
        bind: (OpaquePointer?) -> Void = { _ in },
        rowMapper: (OpaquePointer?) -> T
    ) throws -> [T] {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK else {
            let msg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Failed to open DB"
            sqlite3_close(db)
            throw SQLiteContentError.sqliteError(msg)
        }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw SQLiteContentError.sqliteError("Prepare failed: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        bind(stmt)

        var results: [T] = []
        var stepResult = sqlite3_step(stmt)
        while stepResult == SQLITE_ROW {
            results.append(rowMapper(stmt))
            stepResult = sqlite3_step(stmt)
        }
        guard stepResult == SQLITE_DONE else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw SQLiteContentError.sqliteError("Step failed: \(msg)")
        }
        return results
    }

    private func columnString(_ stmt: OpaquePointer?, _ index: Int32) -> String {
        guard let cStr = sqlite3_column_text(stmt, index) else { return "" }
        return String(cString: cStr)
    }

    private func columnInt(_ stmt: OpaquePointer?, _ index: Int32) -> Int {
        Int(sqlite3_column_int(stmt, index))
    }

    private func columnInt64(_ stmt: OpaquePointer?, _ index: Int32) -> Int64 {
        sqlite3_column_int64(stmt, index)
    }

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
            exampleEn: "",
            exampleVi: ""
        )
    }

    // MARK: - VocabularyDataSourceProtocol

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        let sql = "SELECT id, title_en, icon_key, theme_key, sort_order, ios_sf_symbol FROM decks ORDER BY sort_order;"
        return try query(sql) { [self] stmt in
            let sfSymbol = columnString(stmt, 5)
            // Fallback to star.fill if missing, though schema expects it
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
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        let sql = "SELECT id, deck_id, title_en, icon_key, sort_order, ios_sf_symbol FROM lessons WHERE deck_id = ? ORDER BY sort_order;"
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        return try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, deckId, -1, sqliteTransient)
        }) { [self] stmt in
            let sfSymbol = columnString(stmt, 5)
            let finalIconName = sfSymbol.isEmpty ? "star.fill" : sfSymbol
            return SubTopicStageDTO(
                id: columnString(stmt, 0),
                deckId: columnString(stmt, 1),
                title: columnString(stmt, 2),
                iconName: finalIconName,
                sortOrder: columnInt(stmt, 4)
            )
        }
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
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        return try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, stageId, -1, sqliteTransient)
        }) { [self] stmt in
            parseWord(stmt: stmt, stageId: stageId)
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
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        return try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, pattern, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 2, pattern, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 3, pattern, -1, sqliteTransient)
        }) { [self] stmt in
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
        }) { [self] stmt in
            parseWord(stmt: stmt)
        }
        return results.first
    }
}
