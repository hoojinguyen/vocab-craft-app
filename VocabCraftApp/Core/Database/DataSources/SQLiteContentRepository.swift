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

    // MARK: - VocabularyDataSourceProtocol

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        let sql = "SELECT id, title_en, icon_key, theme_key, sort_order FROM decks ORDER BY sort_order;"
        return try query(sql) { [self] stmt in
            TopicDeckDTO(
                id: columnString(stmt, 0),
                title: columnString(stmt, 1),
                iconName: columnString(stmt, 2),
                badgeColorHex: columnString(stmt, 3),
                cefrLevel: "A1",
                sortOrder: columnInt(stmt, 4)
            )
        }
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        let sql = "SELECT id, deck_id, title_en, icon_key, sort_order FROM lessons WHERE deck_id = ? ORDER BY sort_order;"
        let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        return try query(sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, deckId, -1, sqliteTransient)
        }) { [self] stmt in
            SubTopicStageDTO(
                id: columnString(stmt, 0),
                deckId: columnString(stmt, 1),
                title: columnString(stmt, 2),
                iconName: columnString(stmt, 3),
                sortOrder: columnInt(stmt, 4)
            )
        }
    }

    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] { [] }
    public func searchWords(query: String) async throws -> [TopicWordDTO] { [] }
    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? { nil }
}
