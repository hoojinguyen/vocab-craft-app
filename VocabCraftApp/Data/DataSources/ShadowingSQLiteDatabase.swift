import Foundation
import SQLite3

public enum ShadowingSQLiteError: Error, Equatable, Sendable {
    case databaseNotFound(String)
    case sqliteError(String)
}

public final class ShadowingSQLiteDatabase: Sendable {
    public let url: URL
    private static let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private struct VideoRow {
        let id: String
        let youtubeVideoId: String
        let title: String
        let topicId: String
        let level: String
        let duration: Double
        let thumbnailUrl: String?
        let accent: String
    }

    private struct SentenceRow {
        let id: String
        let orderIndex: Int
        let startTime: Double
        let endTime: Double
        let textEn: String
        let textVi: String
        let wordsJson: String?
    }

    public init(fileURL: URL) throws {
        self.url = fileURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw ShadowingSQLiteError.databaseNotFound(fileURL.path)
        }
    }

    public convenience init(bundle: Bundle = .main) throws {
        if let directURL = bundle.url(forResource: "ShadowingCatalog", withExtension: "sqlite") {
            try self.init(fileURL: directURL)
            return
        }
        if let subURL = bundle.url(
            forResource: "ShadowingCatalog",
            withExtension: "sqlite",
            subdirectory: "VocabCraftApp_VocabCraftApp.bundle"
        ) {
            try self.init(fileURL: subURL)
            return
        }
        throw ShadowingSQLiteError.databaseNotFound("ShadowingCatalog.sqlite in bundle \(bundle)")
    }

    // MARK: - Core Execution Helper

    private func withDatabase<T>(_ block: (OpaquePointer) throws -> T) throws -> T {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &db, flags, nil) == SQLITE_OK, let db else {
            let msg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Failed to open database at \(url.path)"
            if let db { sqlite3_close(db) }
            throw ShadowingSQLiteError.sqliteError(msg)
        }
        defer { sqlite3_close(db) }
        return try block(db)
    }

    // MARK: - Query APIs

    public func fetchTopics() throws -> [ShadowingTopicItem] {
        try withDatabase { db in
            let sql = "SELECT id, title_en, title_vi, icon_name, display_order FROM topics ORDER BY display_order ASC;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(db))
                throw ShadowingSQLiteError.sqliteError("Prepare topics failed: \(msg)")
            }
            defer { sqlite3_finalize(stmt) }

            var topics: [ShadowingTopicItem] = []
            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = columnString(stmt, 0)
                let titleEn = columnString(stmt, 1)
                let titleVi = columnString(stmt, 2)
                let iconName = columnString(stmt, 3)
                let order = Int(sqlite3_column_int(stmt, 4))
                topics.append(ShadowingTopicItem(
                    id: id,
                    titleEn: titleEn,
                    titleVi: titleVi,
                    iconName: iconName,
                    displayOrder: order
                ))
            }
            return topics
        }
    }

    public func fetchVideos(topicId: String?, level: String?) throws -> [ShadowingVideo] {
        try withDatabase { db in
            var query = "SELECT id, youtube_video_id, title, topic_id, level, duration_seconds, thumbnail_url, accent, display_order FROM videos"
            var whereClauses: [String] = []
            var bindParams: [String] = []

            if let topicId, !topicId.isEmpty {
                whereClauses.append("topic_id = ?")
                bindParams.append(topicId)
            }

            if let level, !level.isEmpty, level.lowercased() != "all" {
                whereClauses.append("level = ?")
                bindParams.append(level)
            }

            if !whereClauses.isEmpty {
                query += " WHERE " + whereClauses.joined(separator: " AND ")
            }
            query += " ORDER BY display_order ASC;"

            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(db))
                throw ShadowingSQLiteError.sqliteError("Prepare videos failed: \(msg)")
            }
            defer { sqlite3_finalize(stmt) }

            for (index, param) in bindParams.enumerated() {
                sqlite3_bind_text(stmt, Int32(index + 1), param, -1, Self.sqliteTransient)
            }

            var videoRecords: [VideoRow] = []

            while sqlite3_step(stmt) == SQLITE_ROW {
                let id = columnString(stmt, 0)
                let ytId = columnString(stmt, 1)
                let title = columnString(stmt, 2)
                let topicId = columnString(stmt, 3)
                let level = columnString(stmt, 4)
                let duration = sqlite3_column_double(stmt, 5)
                let thumb = columnOptionalString(stmt, 6)
                let accent = columnOptionalString(stmt, 7) ?? "American"

                videoRecords.append(VideoRow(
                    id: id,
                    youtubeVideoId: ytId,
                    title: title,
                    topicId: topicId,
                    level: level,
                    duration: duration,
                    thumbnailUrl: thumb,
                    accent: accent
                ))
            }

            return try videoRecords.map { record in
                let sentences = try fetchSentences(forVideoId: record.id, in: db)
                let topic = ShadowingTopic(rawValue: record.topicId) ?? .dailyLife
                return ShadowingVideo(
                    id: record.id,
                    youtubeVideoId: record.youtubeVideoId,
                    title: record.title,
                    topic: topic,
                    level: record.level,
                    durationSeconds: record.duration,
                    sentences: sentences,
                    thumbnailUrl: record.thumbnailUrl,
                    accent: record.accent
                )
            }
        }
    }

    public func fetchVideo(byId id: String) throws -> ShadowingVideo? {
        try withDatabase { db in
            let query = "SELECT id, youtube_video_id, title, topic_id, level, duration_seconds, thumbnail_url, accent, display_order FROM videos WHERE id = ? LIMIT 1;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(db))
                throw ShadowingSQLiteError.sqliteError("Prepare video by id failed: \(msg)")
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_text(stmt, 1, id, -1, Self.sqliteTransient)

            guard sqlite3_step(stmt) == SQLITE_ROW else {
                return nil
            }

            let videoId = columnString(stmt, 0)
            let ytId = columnString(stmt, 1)
            let title = columnString(stmt, 2)
            let topicId = columnString(stmt, 3)
            let level = columnString(stmt, 4)
            let duration = sqlite3_column_double(stmt, 5)
            let thumb = columnOptionalString(stmt, 6)
            let accent = columnOptionalString(stmt, 7) ?? "American"

            let sentences = try fetchSentences(forVideoId: videoId, in: db)
            let topic = ShadowingTopic(rawValue: topicId) ?? .dailyLife

            return ShadowingVideo(
                id: videoId,
                youtubeVideoId: ytId,
                title: title,
                topic: topic,
                level: level,
                durationSeconds: duration,
                sentences: sentences,
                thumbnailUrl: thumb,
                accent: accent
            )
        }
    }

    // MARK: - Sentence & Keyword Sub-Queries

    private func fetchSentences(forVideoId videoId: String, in db: OpaquePointer) throws -> [ShadowingSentence] {
        let sql = "SELECT id, order_index, start_time, end_time, text_en, text_vi, words_json FROM sentences WHERE video_id = ? ORDER BY order_index ASC;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw ShadowingSQLiteError.sqliteError("Prepare sentences failed: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, videoId, -1, Self.sqliteTransient)

        var sentenceRows: [SentenceRow] = []

        while sqlite3_step(stmt) == SQLITE_ROW {
            let sId = columnString(stmt, 0)
            let order = Int(sqlite3_column_int(stmt, 1))
            let start = sqlite3_column_double(stmt, 2)
            let end = sqlite3_column_double(stmt, 3)
            let textEn = columnString(stmt, 4)
            let textVi = columnString(stmt, 5)
            let wordsJson = columnOptionalString(stmt, 6)
            sentenceRows.append(SentenceRow(
                id: sId,
                orderIndex: order,
                startTime: start,
                endTime: end,
                textEn: textEn,
                textVi: textVi,
                wordsJson: wordsJson
            ))
        }

        return try sentenceRows.map { row in
            let keyWords = try fetchKeyWords(forSentenceId: row.id, in: db)
            let words = parseWords(from: row.wordsJson)
            return ShadowingSentence(
                id: row.id,
                orderIndex: row.orderIndex,
                startTime: row.startTime,
                endTime: row.endTime,
                textEn: row.textEn,
                textVi: row.textVi,
                keyWords: keyWords,
                words: words
            )
        }
    }

    private func fetchKeyWords(forSentenceId sentenceId: String, in db: OpaquePointer) throws -> [ShadowingKeyWord] {
        let sql = "SELECT lemma, phonetic, definition_vi, definition_en, linked_word_id FROM sentence_keywords WHERE sentence_id = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw ShadowingSQLiteError.sqliteError("Prepare sentence_keywords failed: \(msg)")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, sentenceId, -1, Self.sqliteTransient)

        var keywords: [ShadowingKeyWord] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let lemma = columnString(stmt, 0)
            let phonetic = columnString(stmt, 1)
            let defVi = columnString(stmt, 2)
            let defEn = columnOptionalString(stmt, 3)
            let linkedId = columnOptionalInt64(stmt, 4)

            keywords.append(ShadowingKeyWord(
                lemma: lemma,
                phonetic: phonetic,
                definitionVi: defVi,
                definitionEn: defEn,
                linkedWordId: linkedId
            ))
        }
        return keywords
    }

    private func parseWords(from jsonString: String?) -> [ShadowingWordTimestamp] {
        guard let jsonString, !jsonString.isEmpty, let data = jsonString.data(using: .utf8) else {
            return []
        }
        return (try? JSONDecoder().decode([ShadowingWordTimestamp].self, from: data)) ?? []
    }

    // MARK: - Column Extraction Helpers

    private func columnString(_ stmt: OpaquePointer?, _ index: Int32) -> String {
        guard let cStr = sqlite3_column_text(stmt, index) else { return "" }
        return String(cString: cStr)
    }

    private func columnOptionalString(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        if sqlite3_column_type(stmt, index) == SQLITE_NULL { return nil }
        guard let cStr = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: cStr)
    }

    private func columnOptionalInt64(_ stmt: OpaquePointer?, _ index: Int32) -> Int64? {
        if sqlite3_column_type(stmt, index) == SQLITE_NULL { return nil }
        return sqlite3_column_int64(stmt, index)
    }
}
