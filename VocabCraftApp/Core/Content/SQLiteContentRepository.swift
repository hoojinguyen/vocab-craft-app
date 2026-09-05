import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - Search Cursor Payload

private struct SQLiteSearchCursorPayload: Codable {
    let version: Int
    let offset: Int

    enum CodingKeys: String, CodingKey {
        case version = "v"
        case offset
    }
}

// MARK: - SQLite Content Repository

public actor SQLiteContentRepository: ContentRepository {
    public let url: URL
    public let manifest: ContentManifest

    private var db: OpaquePointer?

    public init(url: URL, manifest: ContentManifest) throws {
        self.url = url
        self.manifest = manifest

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ContentRepositoryError.missingDatabase(url.path)
        }

        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        let openResult = sqlite3_open_v2(url.path, &dbPointer, flags, nil)
        guard openResult == SQLITE_OK, let dbPointer else {
            let message = dbPointer != nil ? String(cString: sqlite3_errmsg(dbPointer)) : "Unknown open error"
            if let dbPointer { sqlite3_close(dbPointer) }
            throw ContentRepositoryError.corruptedDatabase("Failed to open SQLite database: \(message)")
        }

        self.db = dbPointer

        do {
            try Self.validateIntegrity(db: dbPointer)
            try Self.validateMetadata(db: dbPointer, manifest: manifest)
        } catch {
            sqlite3_close(dbPointer)
            self.db = nil
            throw error
        }
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    public func close() {
        if let db {
            sqlite3_close(db)
            self.db = nil
        }
    }

    // MARK: - Validation

    private static func validateIntegrity(db: OpaquePointer) throws {
        var stmt: OpaquePointer?
        let resultCode = sqlite3_prepare_v2(db, "PRAGMA integrity_check;", -1, &stmt, nil)
        guard resultCode == SQLITE_OK, let stmt else {
            throw ContentRepositoryError.corruptedDatabase("Integrity check failed to prepare")
        }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            let result = String(cString: sqlite3_column_text(stmt, 0))
            if result != "ok" {
                throw ContentRepositoryError.corruptedDatabase("Integrity check reported: \(result)")
            }
        } else {
            throw ContentRepositoryError.corruptedDatabase("Integrity check returned no rows")
        }
    }

    private static func validateMetadata(db: OpaquePointer, manifest: ContentManifest) throws {
        var stmt: OpaquePointer?
        let sql = "SELECT dataset_schema_version, content_version FROM dataset_metadata LIMIT 1;"
        let resultCode = sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        guard resultCode == SQLITE_OK, let stmt else {
            throw ContentRepositoryError.corruptedDatabase("Failed to read dataset_metadata")
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw ContentRepositoryError.corruptedDatabase("dataset_metadata table is empty")
        }

        let dbSchemaVersion = Int(sqlite3_column_int64(stmt, 0))
        let dbContentVersion = Int(sqlite3_column_int64(stmt, 1))

        if dbSchemaVersion != 1 || dbSchemaVersion != manifest.datasetSchemaVersion {
            throw ContentRepositoryError.unsupportedSchema(expected: 1, actual: manifest.datasetSchemaVersion)
        }

        if dbContentVersion != manifest.contentVersion {
            throw ContentRepositoryError.corruptedDatabase(
                "Content version mismatch: database has \(dbContentVersion), manifest has \(manifest.contentVersion)"
            )
        }
    }

    // MARK: - Statement Execution Helpers

    fileprivate func getDB() throws -> OpaquePointer {
        guard let db else {
            throw ContentRepositoryError.missingDatabase("Database connection has been closed")
        }
        return db
    }

    fileprivate func prepare(sql: String) throws -> OpaquePointer {
        let database = try getDB()
        var stmt: OpaquePointer?
        let resultCode = sqlite3_prepare_v2(database, sql, -1, &stmt, nil)
        guard resultCode == SQLITE_OK, let stmt else {
            let msg = String(cString: sqlite3_errmsg(database))
            throw ContentRepositoryError.sqliteError(code: resultCode, message: msg)
        }
        return stmt
    }

    fileprivate func queryRows<T>(sql: String, bind: (OpaquePointer) -> Void = { _ in }, transform: (OpaquePointer) throws -> T) throws -> [T] {
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        bind(stmt)

        var results: [T] = []
        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                results.append(try transform(stmt))
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw ContentRepositoryError.sqliteError(code: stepResult, message: String(cString: sqlite3_errmsg(database)))
            }
        }
        return results
    }

    // MARK: - ContentRepository Implementation

    public func fetchDecks() async throws -> [DeckSummary] {
        let sql = """
        SELECT id, title_en, title_vi, description_en, description_vi, icon_key, theme_key, sort_order, revision
        FROM decks
        ORDER BY sort_order, id;
        """
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }

        var decks: [DeckSummary] = []
        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                guard let idString = columnOptionalText(stmt, 0), let deckID = DeckID(uuidString: idString) else {
                    throw ContentRepositoryError.corruptedDatabase("Invalid deck ID")
                }
                let levels = try fetchCefrLevels(for: deckID)
                decks.append(DeckSummary(
                    id: deckID,
                    titleEN: columnText(stmt, 1),
                    titleVI: columnText(stmt, 2),
                    descriptionEN: columnOptionalText(stmt, 3),
                    descriptionVI: columnOptionalText(stmt, 4),
                    iconKey: columnText(stmt, 5),
                    themeKey: columnText(stmt, 6),
                    sortOrder: Int(sqlite3_column_int(stmt, 7)),
                    revision: Int(sqlite3_column_int(stmt, 8)),
                    cefrLevels: levels
                ))
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw ContentRepositoryError.sqliteError(code: stepResult, message: String(cString: sqlite3_errmsg(database)))
            }
        }
        return decks
    }

    public func fetchLessons(deckID: DeckID) async throws -> [LessonDetail] {
        let sql = """
        SELECT id, deck_id, title_en, title_vi, icon_key, sort_order, revision
        FROM lessons
        WHERE deck_id = ?
        ORDER BY sort_order, id;
        """
        return try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, deckID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            guard let idString = columnOptionalText(stmt, 0), let lessonID = LessonID(uuidString: idString) else {
                throw ContentRepositoryError.corruptedDatabase("Invalid lesson ID")
            }
            let senses = try fetchLessonSenses(lessonID: lessonID)
            return LessonDetail(
                id: lessonID, deckID: deckID, titleEN: columnText(stmt, 2),
                titleVI: columnText(stmt, 3), iconKey: columnText(stmt, 4),
                sortOrder: Int(sqlite3_column_int(stmt, 5)),
                revision: Int(sqlite3_column_int(stmt, 6)), senses: senses
            )
        })
    }

    public func fetchLessonContent(lessonID: LessonID) async throws -> LessonDetail {
        let sql = """
        SELECT id, deck_id, title_en, title_vi, icon_key, sort_order, revision
        FROM lessons
        WHERE id = ?;
        """
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, lessonID.description, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW {
            guard let deckIDString = columnOptionalText(stmt, 1), let deckID = DeckID(uuidString: deckIDString) else {
                throw ContentRepositoryError.corruptedDatabase("Invalid deck ID for lesson")
            }
            let senses = try fetchLessonSenses(lessonID: lessonID)
            return LessonDetail(
                id: lessonID, deckID: deckID, titleEN: columnText(stmt, 2),
                titleVI: columnText(stmt, 3), iconKey: columnText(stmt, 4),
                sortOrder: Int(sqlite3_column_int(stmt, 5)),
                revision: Int(sqlite3_column_int(stmt, 6)), senses: senses
            )
        } else if stepResult == SQLITE_DONE {
            throw ContentRepositoryError.entityNotFound("Lesson \(lessonID.description) not found")
        } else {
            let database = try getDB()
            throw ContentRepositoryError.sqliteError(code: stepResult, message: String(cString: sqlite3_errmsg(database)))
        }
    }

    public func fetchSense(senseID: SenseID) async throws -> SenseDetail? {
        let sql = """
        SELECT s.id, s.entry_id, e.headword, e.entry_kind,
               s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level,
               s.usage_note_en, s.usage_note_vi, s.sort_order, s.revision
        FROM senses s
        JOIN entries e ON e.id = s.entry_id
        WHERE s.id = ?;
        """
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, senseID.description, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW {
            guard let entryIDString = columnOptionalText(stmt, 1), let entryID = EntryID(uuidString: entryIDString),
                  let entryKind = EntryKind(rawValue: columnText(stmt, 3)),
                  let partOfSpeech = PartOfSpeech(rawValue: columnText(stmt, 4)),
                  let cefrLevel = CEFRLevel(rawValue: columnText(stmt, 7)) else {
                throw ContentRepositoryError.corruptedDatabase("Invalid sense fields")
            }

            let pronunciations = try fetchPronunciations(senseID: senseID, entryID: entryID)
            return SenseDetail(
                id: senseID, entryID: entryID, headword: columnText(stmt, 2),
                entryKind: entryKind, partOfSpeech: partOfSpeech,
                definitionEN: columnText(stmt, 5), definitionVI: columnText(stmt, 6),
                cefrLevel: cefrLevel, usageNoteEN: columnOptionalText(stmt, 8),
                usageNoteVI: columnOptionalText(stmt, 9),
                ipa: resolveIPA(pronunciations: pronunciations),
                pronunciations: pronunciations,
                examples: try fetchExamples(senseID: senseID),
                collocations: try fetchCollocations(senseID: senseID),
                attributions: try fetchAttributions(senseID: senseID),
                sortOrder: Int(sqlite3_column_int(stmt, 10)),
                revision: Int(sqlite3_column_int(stmt, 11))
            )
        } else if stepResult == SQLITE_DONE {
            return nil
        } else {
            let database = try getDB()
            throw ContentRepositoryError.sqliteError(code: stepResult, message: String(cString: sqlite3_errmsg(database)))
        }
    }

    public func fetchEntry(entryID: EntryID) async throws -> EntryDetail? {
        let sql = "SELECT id, headword, lookup_key, entry_kind, revision FROM entries WHERE id = ?;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, entryID.description, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW {
            let headword = columnText(stmt, 1)
            let lookupKey = columnText(stmt, 2)
            guard let entryKind = EntryKind(rawValue: columnText(stmt, 3)) else {
                throw ContentRepositoryError.corruptedDatabase("Invalid entry_kind")
            }
            let revision = Int(sqlite3_column_int(stmt, 4))
            let pronunciations = try fetchPronunciationsForEntry(entryID: entryID)
            let senses = try fetchSensesForEntry(entryID: entryID, headword: headword, entryKind: entryKind)

            return EntryDetail(
                id: entryID, headword: headword, lookupKey: lookupKey,
                entryKind: entryKind, revision: revision,
                senses: senses, pronunciations: pronunciations
            )
        } else if stepResult == SQLITE_DONE {
            return nil
        } else {
            let database = try getDB()
            throw ContentRepositoryError.sqliteError(code: stepResult, message: String(cString: sqlite3_errmsg(database)))
        }
    }

    public func fetchSenses(ids: [SenseID]) async throws -> [SenseDetail] {
        var results: [SenseDetail] = []
        for id in ids {
            if let detail = try await fetchSense(senseID: id) {
                results.append(detail)
            }
        }
        return results
    }

    public func search(query: String, limit: Int, cursor: String?) async throws -> ContentSearchResult {
        let boundedLimit = max(1, min(limit, 100))
        let offset = parseCursorOffset(cursor: cursor)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasFilter = !trimmed.isEmpty

        let sql = buildSearchSQL(hasFilter: hasFilter)
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }

        bindSearchParams(stmt: stmt, trimmed: trimmed, hasFilter: hasFilter, limit: boundedLimit, offset: offset)

        var candidateSenses: [SenseSummary] = []
        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                candidateSenses.append(try parseSenseSummaryRow(stmt, index: candidateSenses.count))
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw ContentRepositoryError.sqliteError(code: stepResult, message: String(cString: sqlite3_errmsg(database)))
            }
        }

        let hasMore = candidateSenses.count > boundedLimit
        let finalSenses = hasMore ? Array(candidateSenses.prefix(boundedLimit)) : candidateSenses
        let nextCursor = hasMore ? encodeCursor(offset: offset + boundedLimit) : nil

        return ContentSearchResult(
            senses: finalSenses, nextCursor: nextCursor,
            hasMore: hasMore, contentVersion: manifest.contentVersion
        )
    }
}

// MARK: - Search & Relational Extensions

extension SQLiteContentRepository {
    private func buildSearchSQL(hasFilter: Bool) -> String {
        if hasFilter {
            return """
            SELECT s.id, s.entry_id, e.headword, e.entry_kind,
                   s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level, s.revision
            FROM senses s
            JOIN entries e ON e.id = s.entry_id
            WHERE (e.headword LIKE ? ESCAPE '\\'
               OR e.lookup_key LIKE ? ESCAPE '\\'
               OR s.definition_en LIKE ? ESCAPE '\\'
               OR s.definition_vi LIKE ? ESCAPE '\\')
            ORDER BY e.lookup_key, e.id, s.sort_order, s.id
            LIMIT ? OFFSET ?;
            """
        }
        return """
        SELECT s.id, s.entry_id, e.headword, e.entry_kind,
               s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level, s.revision
        FROM senses s
        JOIN entries e ON e.id = s.entry_id
        ORDER BY e.lookup_key, e.id, s.sort_order, s.id
        LIMIT ? OFFSET ?;
        """
    }

    private func bindSearchParams(stmt: OpaquePointer, trimmed: String, hasFilter: Bool, limit: Int, offset: Int) {
        if hasFilter {
            let pattern = "%\(escapeLikeWildcards(trimmed))%"
            sqlite3_bind_text(stmt, 1, pattern, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, pattern, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, pattern, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 4, pattern, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(stmt, 5, Int32(limit + 1))
            sqlite3_bind_int(stmt, 6, Int32(offset))
        } else {
            sqlite3_bind_int(stmt, 1, Int32(limit + 1))
            sqlite3_bind_int(stmt, 2, Int32(offset))
        }
    }

    fileprivate func parseSenseSummaryRow(_ stmt: OpaquePointer, index: Int) throws -> SenseSummary {
        guard let senseIDString = columnOptionalText(stmt, 0), let senseID = SenseID(uuidString: senseIDString),
              let entryIDString = columnOptionalText(stmt, 1), let entryID = EntryID(uuidString: entryIDString),
              let entryKind = EntryKind(rawValue: columnText(stmt, 3)),
              let partOfSpeech = PartOfSpeech(rawValue: columnText(stmt, 4)),
              let cefrLevel = CEFRLevel(rawValue: columnText(stmt, 7)) else {
            throw ContentRepositoryError.corruptedDatabase("Invalid sense summary row")
        }
        let pronunciations = try fetchPronunciations(senseID: senseID, entryID: entryID)
        return SenseSummary(
            senseID: senseID, entryID: entryID, headword: columnText(stmt, 2),
            entryKind: entryKind, partOfSpeech: partOfSpeech,
            definitionEN: columnText(stmt, 5), definitionVI: columnText(stmt, 6),
            cefrLevel: cefrLevel, ipa: resolveIPA(pronunciations: pronunciations),
            sortOrder: index, revision: Int(sqlite3_column_int(stmt, 8))
        )
    }

    fileprivate func fetchCefrLevels(for deckID: DeckID) throws -> [CEFRLevel] {
        let sql = """
        SELECT DISTINCT s.cefr_level
        FROM senses s
        JOIN lesson_senses ls ON ls.sense_id = s.id
        JOIN lessons l ON l.id = ls.lesson_id
        WHERE l.deck_id = ?;
        """
        let rawLevels: [String] = try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, deckID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            columnText(stmt, 0)
        })
        let set = Set(rawLevels.compactMap { CEFRLevel(rawValue: $0) })
        return set.sorted()
    }

    fileprivate func fetchLessonSenses(lessonID: LessonID) throws -> [SenseSummary] {
        let sql = """
        SELECT s.id, s.entry_id, e.headword, e.entry_kind,
               s.part_of_speech, s.definition_en, s.definition_vi, s.cefr_level, s.revision
        FROM lesson_senses ls
        JOIN senses s ON s.id = ls.sense_id
        JOIN entries e ON e.id = s.entry_id
        WHERE ls.lesson_id = ?
        ORDER BY ls.sort_order, s.id;
        """
        return try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, lessonID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            try parseSenseSummaryRow(stmt, index: 0)
        })
    }

    fileprivate func fetchExamples(senseID: SenseID) throws -> [ExampleSnapshot] {
        let sql = "SELECT id, sense_id, text_en, text_vi, sort_order FROM examples WHERE sense_id = ? ORDER BY sort_order, id;"
        return try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, senseID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            ExampleSnapshot(
                id: columnText(stmt, 0), senseID: senseID,
                textEN: columnText(stmt, 2), textVI: columnText(stmt, 3),
                sortOrder: Int(sqlite3_column_int(stmt, 4))
            )
        })
    }

    fileprivate func fetchCollocations(senseID: SenseID) throws -> [CollocationSnapshot] {
        let sql = "SELECT id, sense_id, text_en, text_vi, example_id, sort_order FROM collocations WHERE sense_id = ? ORDER BY sort_order, id;"
        return try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, senseID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            CollocationSnapshot(
                id: columnText(stmt, 0), senseID: senseID,
                textEN: columnText(stmt, 2), textVI: columnText(stmt, 3),
                exampleID: columnOptionalText(stmt, 4),
                sortOrder: Int(sqlite3_column_int(stmt, 5))
            )
        })
    }

    fileprivate func fetchPronunciations(senseID: SenseID, entryID: EntryID) throws -> [PronunciationSnapshot] {
        let sql = """
        SELECT id, entry_id, sense_id, accent, ipa, sort_order
        FROM pronunciations
        WHERE sense_id = ? OR (entry_id = ? AND sense_id IS NULL)
        ORDER BY sort_order, id;
        """
        return try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, senseID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, entryID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            try parsePronunciationRow(stmt, defaultEntryID: entryID)
        })
    }

    fileprivate func fetchPronunciationsForEntry(entryID: EntryID) throws -> [PronunciationSnapshot] {
        let sql = "SELECT id, entry_id, sense_id, accent, ipa, sort_order FROM pronunciations WHERE entry_id = ? ORDER BY sort_order, id;"
        return try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, entryID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            try parsePronunciationRow(stmt, defaultEntryID: entryID)
        })
    }

    private func parsePronunciationRow(_ stmt: OpaquePointer, defaultEntryID: EntryID) throws -> PronunciationSnapshot {
        let rawSense = columnOptionalText(stmt, 2)
        let rowSenseID = rawSense != nil ? SenseID(uuidString: rawSense ?? "") : nil
        guard let accent = Accent(rawValue: columnText(stmt, 3)) else {
            throw ContentRepositoryError.corruptedDatabase("Invalid accent")
        }
        return PronunciationSnapshot(
            id: columnText(stmt, 0), entryID: defaultEntryID,
            senseID: rowSenseID, accent: accent,
            ipa: columnText(stmt, 4), sortOrder: Int(sqlite3_column_int(stmt, 5))
        )
    }

    fileprivate func fetchSensesForEntry(entryID: EntryID, headword: String, entryKind: EntryKind) throws -> [SenseSummary] {
        let sql = """
        SELECT id, entry_id, part_of_speech, definition_en, definition_vi, cefr_level, sort_order, revision
        FROM senses
        WHERE entry_id = ?
        ORDER BY sort_order, id;
        """
        return try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, entryID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            guard let senseIDString = columnOptionalText(stmt, 0), let senseID = SenseID(uuidString: senseIDString),
                  let partOfSpeech = PartOfSpeech(rawValue: columnText(stmt, 2)),
                  let cefrLevel = CEFRLevel(rawValue: columnText(stmt, 5)) else {
                throw ContentRepositoryError.corruptedDatabase("Invalid sense in entry")
            }
            let pronunciations = try fetchPronunciations(senseID: senseID, entryID: entryID)
            return SenseSummary(
                senseID: senseID, entryID: entryID, headword: headword,
                entryKind: entryKind, partOfSpeech: partOfSpeech,
                definitionEN: columnText(stmt, 3), definitionVI: columnText(stmt, 4),
                cefrLevel: cefrLevel, ipa: resolveIPA(pronunciations: pronunciations),
                sortOrder: Int(sqlite3_column_int(stmt, 6)), revision: Int(sqlite3_column_int(stmt, 7))
            )
        })
    }

    fileprivate func fetchAttributions(senseID: SenseID) throws -> [AttributionSnapshot] {
        let sql = """
        SELECT a.id, a.text, a.source_url, a.license_identifier
        FROM attributions a
        JOIN sense_attributions sa ON sa.attribution_id = a.id
        WHERE sa.sense_id = ?
        ORDER BY a.id;
        """
        return try queryRows(sql: sql, bind: { stmt in
            sqlite3_bind_text(stmt, 1, senseID.description, -1, SQLITE_TRANSIENT)
        }, transform: { stmt in
            AttributionSnapshot(
                id: columnText(stmt, 0), text: columnText(stmt, 1),
                sourceURL: columnOptionalText(stmt, 2), licenseIdentifier: columnOptionalText(stmt, 3)
            )
        })
    }

    fileprivate func resolveIPA(pronunciations: [PronunciationSnapshot], preferredAccent: Accent = .us) -> String? {
        let fallbackAccent: Accent = (preferredAccent == .us) ? .uk : .us
        if let match = pronunciations.first(where: { $0.senseID != nil && $0.accent == preferredAccent }) {
            return match.ipa
        }
        if let match = pronunciations.first(where: { $0.senseID == nil && $0.accent == preferredAccent }) {
            return match.ipa
        }
        if let match = pronunciations.first(where: { $0.senseID != nil && $0.accent == fallbackAccent }) {
            return match.ipa
        }
        if let match = pronunciations.first(where: { $0.senseID == nil && $0.accent == fallbackAccent }) {
            return match.ipa
        }
        return nil
    }

    private func parseCursorOffset(cursor: String?) -> Int {
        guard let cursor,
              let data = Data(base64Encoded: cursor),
              let payload = try? JSONDecoder().decode(SQLiteSearchCursorPayload.self, from: data) else {
            return 0
        }
        if payload.version == manifest.contentVersion {
            return max(0, payload.offset)
        }
        return 0
    }

    private func encodeCursor(offset: Int) -> String? {
        let payload = SQLiteSearchCursorPayload(version: manifest.contentVersion, offset: offset)
        guard let data = try? JSONEncoder().encode(payload) else {
            return nil
        }
        return data.base64EncodedString()
    }

    private func escapeLikeWildcards(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    fileprivate func columnText(_ stmt: OpaquePointer, _ index: Int32) -> String {
        guard let ptr = sqlite3_column_text(stmt, index) else { return "" }
        return String(cString: ptr)
    }

    fileprivate func columnOptionalText(_ stmt: OpaquePointer, _ index: Int32) -> String? {
        if sqlite3_column_type(stmt, index) == SQLITE_NULL { return nil }
        guard let ptr = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: ptr)
    }
}
