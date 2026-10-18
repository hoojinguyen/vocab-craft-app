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

    // MARK: - Migration

    public static func readContentVersion(at url: URL) -> Int? {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        let path = url.standardizedFileURL.path
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT content_version FROM dataset_metadata LIMIT 1;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return nil
    }

    public static func readLearningPathCount(at url: URL) -> Int {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        let path = url.standardizedFileURL.path
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_close(db) }

        var stmt: OpaquePointer?
        let sql = "SELECT COUNT(*) FROM learning_paths;"
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            return Int(sqlite3_column_int(stmt, 0))
        }
        return 0
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
            exampleEn: columnString(stmt, 7),
            exampleVi: columnString(stmt, 8)
        )
    }

    // MARK: - VocabularyDataSourceProtocol

    public func fetchLearningPaths() async throws -> [LearningPathDTO] {
        let sql = """
        SELECT id, code, title_en, title_vi, description_en, description_vi,
               goal_category, target_level_min, target_level_max, icon_key, theme_key, sort_order
        FROM learning_paths
        ORDER BY sort_order;
        """
        return try query(sql) { [self] stmt in
            let descEn = columnString(stmt, 4)
            let descVi = columnString(stmt, 5)
            return LearningPathDTO(
                id: columnString(stmt, 0),
                code: columnString(stmt, 1),
                titleEn: columnString(stmt, 2),
                titleVi: columnString(stmt, 3),
                descriptionEn: descEn.isEmpty ? nil : descEn,
                descriptionVi: descVi.isEmpty ? nil : descVi,
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
        SELECT d.id, d.title_en, d.title_vi, d.description_en, d.description_vi,
               d.icon_key, d.theme_key, pd.sort_order, d.ios_sf_symbol,
               COALESCE(
                 (SELECT s.cefr_level FROM senses s
                  JOIN lesson_senses ls ON ls.sense_id = s.id
                  JOIN lessons l ON l.id = ls.lesson_id
                  WHERE l.deck_id = d.id
                  GROUP BY s.cefr_level
                  ORDER BY count(*) DESC, s.cefr_level ASC LIMIT 1),
                 'A1'
               ) AS computed_cefr
        FROM decks d
        JOIN path_decks pd ON pd.deck_id = d.id
        JOIN learning_paths lp ON lp.id = pd.path_id
        WHERE pd.path_id = ? OR lp.code = ?
        ORDER BY pd.sort_order;
        """
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let decks = try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, pathId, -1, sqliteTransient)
            sqlite3_bind_text(stmt, 2, pathId, -1, sqliteTransient)
        }) { [self] stmt in
            let descEn = columnString(stmt, 3)
            let descVi = columnString(stmt, 4)
            let sfSymbol = columnString(stmt, 8)
            let finalIconName = sfSymbol.isEmpty ? "star.fill" : sfSymbol
            let cefr = columnString(stmt, 9)
            return TopicDeckDTO(
                id: columnString(stmt, 0),
                titleEn: columnString(stmt, 1),
                titleVi: columnString(stmt, 2),
                descriptionEn: descEn.isEmpty ? nil : descEn,
                descriptionVi: descVi.isEmpty ? nil : descVi,
                iconName: finalIconName,
                themeKey: columnString(stmt, 6),
                cefrLevel: cefr.isEmpty ? "A1" : cefr,
                sortOrder: columnInt(stmt, 7)
            )
        }

        // Defensive fallback: if pathId is empty or no decks assigned, fallback to all decks
        if decks.isEmpty {
            return try await fetchTopicDecks()
        }
        return decks
    }

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        let sql = """
        SELECT d.id, d.title_en, d.title_vi, d.description_en, d.description_vi,
               d.icon_key, d.theme_key, d.sort_order, d.ios_sf_symbol,
               COALESCE(
                 (SELECT s.cefr_level FROM senses s
                  JOIN lesson_senses ls ON ls.sense_id = s.id
                  JOIN lessons l ON l.id = ls.lesson_id
                  WHERE l.deck_id = d.id
                  GROUP BY s.cefr_level
                  ORDER BY count(*) DESC, s.cefr_level ASC LIMIT 1),
                 'A1'
               ) AS computed_cefr
        FROM decks d
        ORDER BY d.sort_order;
        """
        return try query(sql) { [self] stmt in
            let descEn = columnString(stmt, 3)
            let descVi = columnString(stmt, 4)
            let sfSymbol = columnString(stmt, 8)
            let finalIconName = sfSymbol.isEmpty ? "star.fill" : sfSymbol
            let cefr = columnString(stmt, 9)
            return TopicDeckDTO(
                id: columnString(stmt, 0),
                titleEn: columnString(stmt, 1),
                titleVi: columnString(stmt, 2),
                descriptionEn: descEn.isEmpty ? nil : descEn,
                descriptionVi: descVi.isEmpty ? nil : descVi,
                iconName: finalIconName,
                themeKey: columnString(stmt, 6),
                cefrLevel: cefr.isEmpty ? "A1" : cefr,
                sortOrder: columnInt(stmt, 7)
            )
        }
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        let sql = "SELECT id, deck_id, title_en, title_vi, icon_key, sort_order, ios_sf_symbol FROM lessons WHERE deck_id = ? ORDER BY sort_order;"
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        return try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, deckId, -1, sqliteTransient)
        }) { [self] stmt in
            let sfSymbol = columnString(stmt, 6)
            let finalIconName = sfSymbol.isEmpty ? "star.fill" : sfSymbol
            return SubTopicStageDTO(
                id: columnString(stmt, 0),
                deckId: columnString(stmt, 1),
                titleEn: columnString(stmt, 2),
                titleVi: columnString(stmt, 3),
                iconName: finalIconName,
                sortOrder: columnInt(stmt, 5)
            )
        }
    }

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
}
