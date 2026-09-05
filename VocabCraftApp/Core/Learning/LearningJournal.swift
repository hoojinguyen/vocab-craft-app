// swiftlint:disable file_length
import CryptoKit
import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

// MARK: - AppendResult

public enum AppendResult: String, Codable, Sendable, Equatable {
    case inserted
    case duplicate
}

// MARK: - SenseCapabilityCounter

public struct SenseCapabilityCounter: Equatable, Sendable {
    public let capability: Capability
    public let totalCount: Int
    public let correctCount: Int

    public init(capability: Capability, totalCount: Int, correctCount: Int) {
        self.capability = capability
        self.totalCount = totalCount
        self.correctCount = correctCount
    }
}

// MARK: - LearningJournalError

public enum LearningJournalError: Error, LocalizedError, Equatable {
    case conflict(String)
    case profileNotFound(ProfileID)
    case sqliteError(Int32, String)
    case diskFailure(String)
    case serializationError(String)
    case invalidState(String)

    public var errorDescription: String? {
        switch self {
        case .conflict(let msg):
            return "Journal conflict: \(msg)"
        case .profileNotFound(let id):
            return "Profile not found: \(id)"
        case .sqliteError(let code, let msg):
            return "SQLite error (\(code)): \(msg)"
        case .diskFailure(let msg):
            return "Disk failure: \(msg)"
        case .serializationError(let msg):
            return "Serialization error: \(msg)"
        case .invalidState(let msg):
            return "Invalid journal state: \(msg)"
        }
    }
}

// MARK: - LearningJournal Actor

// swiftlint:disable:next type_body_length
public actor LearningJournal {
    public let url: URL
    public let deviceID: DeviceID

    private var db: OpaquePointer?

    private static let embeddedSchemaSQL = """
    CREATE TABLE IF NOT EXISTS profiles (id TEXT PRIMARY KEY, kind TEXT NOT NULL, created_at TEXT NOT NULL, account_binding TEXT);
    CREATE TABLE IF NOT EXISTS attempts (
        attempt_id TEXT PRIMARY KEY, profile_id TEXT NOT NULL REFERENCES profiles(id),
        payload_json TEXT NOT NULL, submission_hash TEXT NOT NULL, created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS completions (
        event_id TEXT PRIMARY KEY, profile_id TEXT NOT NULL REFERENCES profiles(id),
        lesson_id TEXT NOT NULL, payload_json TEXT NOT NULL, created_at TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS counters (
        profile_id TEXT NOT NULL, sense_id TEXT NOT NULL, capability TEXT NOT NULL,
        total_count INTEGER NOT NULL, correct_count INTEGER NOT NULL,
        PRIMARY KEY (profile_id, sense_id, capability), FOREIGN KEY (profile_id) REFERENCES profiles(id)
    );
    CREATE TABLE IF NOT EXISTS profile_device_sequences (
        profile_id TEXT NOT NULL, device_id TEXT NOT NULL, last_sequence INTEGER NOT NULL,
        PRIMARY KEY (profile_id, device_id), FOREIGN KEY (profile_id) REFERENCES profiles(id)
    );
    CREATE TABLE IF NOT EXISTS bookmarks (
        profile_id TEXT NOT NULL, sense_id TEXT NOT NULL, created_at TEXT NOT NULL,
        PRIMARY KEY (profile_id, sense_id), FOREIGN KEY (profile_id) REFERENCES profiles(id)
    );
    CREATE INDEX IF NOT EXISTS idx_attempts_profile_created ON attempts(profile_id, created_at);
    CREATE INDEX IF NOT EXISTS idx_attempts_profile_hash ON attempts(profile_id, submission_hash);
    CREATE INDEX IF NOT EXISTS idx_attempts_profile_sense ON attempts(profile_id, json_extract(payload_json, '$.sense_id'));
    CREATE INDEX IF NOT EXISTS idx_completions_profile_created ON completions(profile_id, created_at);
    CREATE INDEX IF NOT EXISTS idx_counters_profile_sense ON counters(profile_id, sense_id);
    CREATE INDEX IF NOT EXISTS idx_bookmarks_profile ON bookmarks(profile_id);
    """

    public init(url: URL, deviceID: DeviceID = LearningJournal.defaultDeviceID()) throws {
        self.url = url
        self.deviceID = deviceID

        let parentDir = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }

        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX
        let openResult = sqlite3_open_v2(url.path, &dbPointer, flags, nil)
        guard openResult == SQLITE_OK, let dbPointer else {
            let message = dbPointer != nil ? String(cString: sqlite3_errmsg(dbPointer)) : "Unknown SQLite open error"
            if let dbPointer { sqlite3_close(dbPointer) }
            throw LearningJournalError.sqliteError(openResult, message)
        }

        self.db = dbPointer

        do {
            try Self.configurePragmas(db: dbPointer)
            try Self.bootstrapSchema(db: dbPointer)
        } catch {
            sqlite3_close(dbPointer)
            self.db = nil
            throw error
        }
    }

    deinit {
        if let db { sqlite3_close(db) }
    }

    public func close() {
        if let db {
            sqlite3_close(db)
            self.db = nil
        }
    }

    // MARK: - Device ID Management

    public static func defaultDeviceID() -> DeviceID {
        let key = "vocab_craft_journal_device_id"
        if let existing = UserDefaults.standard.string(forKey: key),
           let parsed = DeviceID(uuidString: existing) {
            return parsed
        }
        let generated = DeviceID(rawValue: UUID())
        UserDefaults.standard.set(generated.description, forKey: key)
        return generated
    }

    // MARK: - Testing Hooks

    public func simulateDiskFailure(_ enabled: Bool) throws {
        let sql = enabled ? "PRAGMA query_only = ON;" : "PRAGMA query_only = OFF;"
        let database = try getDB()
        var err: UnsafeMutablePointer<CChar>?
        let resultCode = sqlite3_exec(database, sql, nil, nil, &err)
        if resultCode != SQLITE_OK {
            let msg = err.map { String(cString: $0) } ?? "Failed to toggle query_only"
            sqlite3_free(err)
            throw LearningJournalError.sqliteError(resultCode, msg)
        }
    }

    // MARK: - Profile Management

    public static let defaultGuestProfileID = ProfileID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID())

    @discardableResult
    public func ensureDefaultGuestProfile(id: ProfileID = defaultGuestProfileID) async throws -> ProfileID {
        let checkSQL = "SELECT id FROM profiles WHERE id = ?;"
        let checkStmt = try prepare(sql: checkSQL)
        sqlite3_bind_text(checkStmt, 1, id.description, -1, SQLITE_TRANSIENT)
        let checkResult = sqlite3_step(checkStmt)
        sqlite3_finalize(checkStmt)

        if checkResult == SQLITE_ROW {
            try ensureDeviceSequenceTracked(profileID: id)
            return id
        }

        let nowISO = ISO8601DateFormatter().string(from: Date())
        try executeTransaction {
            let insertProfileSQL = "INSERT OR IGNORE INTO profiles (id, kind, created_at) VALUES (?, 'guest', ?);"
            let stmt = try self.prepare(sql: insertProfileSQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, id.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, nowISO, -1, SQLITE_TRANSIENT)

            let stepResult = sqlite3_step(stmt)
            guard stepResult == SQLITE_DONE else {
                let database = try self.getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }

            try self.ensureDeviceSequenceTracked(profileID: id)
        }

        return id
    }

    public func activeGuestProfileID() async throws -> ProfileID? {
        let sql = "SELECT id FROM profiles WHERE kind = 'guest' ORDER BY created_at ASC LIMIT 1;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }

        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW {
            let idText = try columnRequiredText(stmt, 0, field: "id")
            guard let profileID = ProfileID(uuidString: idText) else {
                throw LearningJournalError.invalidState("Corrupted profile ID: \(idText)")
            }
            return profileID
        }
        if stepResult == SQLITE_DONE { return nil }
        let database = try getDB()
        throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
    }

    public func createGuestProfile(forceNew: Bool = false) async throws -> ProfileID {
        if !forceNew, let existing = try await activeGuestProfileID() {
            try ensureDeviceSequenceTracked(profileID: existing)
            return existing
        }
        return try await createProfile(kind: "guest")
    }

    public func createProfile(kind: String) async throws -> ProfileID {
        let newProfileID = ProfileID(rawValue: UUID())
        let nowISO = ISO8601DateFormatter().string(from: Date())

        try executeTransaction {
            let insertProfileSQL = "INSERT INTO profiles (id, kind, created_at) VALUES (?, ?, ?);"
            let stmt = try self.prepare(sql: insertProfileSQL)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, newProfileID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, kind, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, nowISO, -1, SQLITE_TRANSIENT)

            let stepResult = sqlite3_step(stmt)
            guard stepResult == SQLITE_DONE else {
                let database = try self.getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }

            try self.ensureDeviceSequenceTracked(profileID: newProfileID)
        }

        return newProfileID
    }

    private func ensureDeviceSequenceTracked(profileID: ProfileID) throws {
        let sql = """
        INSERT INTO profile_device_sequences (profile_id, device_id, last_sequence)
        VALUES (?, ?, 0)
        ON CONFLICT(profile_id, device_id) DO NOTHING;
        """
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, deviceID.description, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        guard stepResult == SQLITE_DONE else {
            let database = try getDB()
            throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
        }
    }

    // MARK: - Append Attempt

    public func append(_ attempt: AttemptSubmission, profileID: ProfileID) async throws -> AppendResult {
        var appendResult: AppendResult = .inserted

        try executeTransaction {
            try self.assertProfileExists(profileID: profileID)

            let incomingHash = try attempt.submissionHash()
            if let existingHash = try self.fetchExistingAttemptHash(attemptID: attempt.attemptID) {
                if existingHash == incomingHash {
                    appendResult = .duplicate
                    return
                } else {
                    let msg = "Attempt ID \(attempt.attemptID) already exists with different payload"
                    throw LearningJournalError.conflict(msg)
                }
            }

            let nextSeq = try self.advanceDeviceSequence(profileID: profileID)
            let enrichedAttempt = attempt.enrich(
                originProfileID: profileID,
                deviceID: self.deviceID,
                deviceSequence: nextSeq
            )

            let payloadData = try enrichedAttempt.canonicalData()
            guard let payloadJSON = String(data: payloadData, encoding: .utf8) else {
                throw LearningJournalError.serializationError("Failed to encode attempt JSON")
            }

            try self.insertAttemptRecord(
                attemptID: attempt.attemptID,
                profileID: profileID,
                payloadJSON: payloadJSON,
                submissionHash: incomingHash,
                createdAt: attempt.occurredAt
            )

            if let capability = attempt.capability {
                let isCorrect = (attempt.outcome == .correct)
                try self.updateCapabilityCounter(
                    profileID: profileID,
                    senseID: attempt.senseID,
                    capability: capability,
                    isCorrect: isCorrect
                )
            }

            appendResult = .inserted
        }

        return appendResult
    }

    // MARK: - Complete Lesson

    public func complete(_ completion: LessonCompletion, profileID: ProfileID) async throws {
        try executeTransaction {
            try self.assertProfileExists(profileID: profileID)

            let finalCompletion = self.normalizeCompletion(completion, profileID: profileID)
            if let existingPayload = try self.fetchExistingCompletionPayload(eventID: completion.eventID) {
                guard let decoded = try? JSONDecoder().decode(LessonCompletion.self, from: Data(existingPayload.utf8)),
                      decoded == finalCompletion else {
                    let msg = "Completion event \(completion.eventID) already exists with conflicting data"
                    throw LearningJournalError.conflict(msg)
                }
                return
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.sortedKeys]
            let payloadData = try encoder.encode(finalCompletion)
            guard let payloadJSON = String(data: payloadData, encoding: .utf8) else {
                throw LearningJournalError.serializationError("Failed to encode completion JSON")
            }

            let sql = "INSERT INTO completions (event_id, profile_id, lesson_id, payload_json, created_at) VALUES (?, ?, ?, ?, ?);"
            let stmt = try self.prepare(sql: sql)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, finalCompletion.eventID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, profileID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, finalCompletion.lessonID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 4, payloadJSON, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 5, finalCompletion.completedAt, -1, SQLITE_TRANSIENT)

            let stepResult = sqlite3_step(stmt)
            guard stepResult == SQLITE_DONE else {
                let database = try self.getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
        }
    }

    private func normalizeCompletion(_ completion: LessonCompletion, profileID: ProfileID) -> LessonCompletion {
        guard completion.originProfileID != profileID else { return completion }
        return LessonCompletion(
            eventID: completion.eventID,
            originProfileID: profileID,
            deviceID: completion.deviceID,
            deviceSequence: completion.deviceSequence,
            eventSchemaVersion: completion.eventSchemaVersion,
            lessonID: completion.lessonID,
            lessonRevision: completion.lessonRevision,
            contentVersion: completion.contentVersion,
            completedAt: completion.completedAt
        )
    }

    // MARK: - Queries

    public func attempts(profileID: ProfileID, senseID: SenseID) async throws -> [PracticeAttempt] {
        let sql = """
        SELECT payload_json
        FROM attempts
        WHERE profile_id = ? AND json_extract(payload_json, '$.sense_id') = ?
        ORDER BY created_at ASC, rowid ASC;
        """
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, senseID.description, -1, SQLITE_TRANSIENT)

        var attempts: [PracticeAttempt] = []
        let decoder = JSONDecoder()

        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                let jsonText = try columnRequiredText(stmt, 0, field: "payload_json")
                let attempt = try decoder.decode(PracticeAttempt.self, from: Data(jsonText.utf8))
                attempts.append(attempt)
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
        }

        return attempts
    }

    public func completedLessons(profileID: ProfileID) async throws -> [LessonCompletion] {
        let sql = "SELECT payload_json FROM completions WHERE profile_id = ? ORDER BY created_at ASC, rowid ASC;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)

        var completions: [LessonCompletion] = []
        let decoder = JSONDecoder()

        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                let jsonText = try columnRequiredText(stmt, 0, field: "payload_json")
                let completion = try decoder.decode(LessonCompletion.self, from: Data(jsonText.utf8))
                completions.append(completion)
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
        }

        return completions
    }

    public func counter(
        profileID: ProfileID,
        senseID: SenseID,
        capability: Capability
    ) async throws -> (total: Int, correct: Int)? {
        let sql = "SELECT total_count, correct_count FROM counters WHERE profile_id = ? AND sense_id = ? AND capability = ?;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, senseID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, capability.rawValue, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW {
            let total = Int(sqlite3_column_int(stmt, 0))
            let correct = Int(sqlite3_column_int(stmt, 1))
            return (total: total, correct: correct)
        } else if stepResult == SQLITE_DONE {
            return nil
        } else {
            let database = try getDB()
            throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
        }
    }

    public func counters(profileID: ProfileID, senseID: SenseID) async throws -> [SenseCapabilityCounter] {
        let sql = "SELECT capability, total_count, correct_count FROM counters WHERE profile_id = ? AND sense_id = ? ORDER BY capability ASC;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, senseID.description, -1, SQLITE_TRANSIENT)

        var list: [SenseCapabilityCounter] = []
        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                let rawCap = try columnRequiredText(stmt, 0, field: "capability")
                guard let capability = Capability(rawValue: rawCap) else {
                    continue
                }
                let total = Int(sqlite3_column_int(stmt, 1))
                let correct = Int(sqlite3_column_int(stmt, 2))
                list.append(SenseCapabilityCounter(capability: capability, totalCount: total, correctCount: correct))
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
        }
        return list
    }

    // MARK: - Bookmarks

    @discardableResult
    public func toggleBookmark(profileID: ProfileID, senseID: SenseID) async throws -> Bool {
        try assertProfileExists(profileID: profileID)
        let isCurrentlyBookmarked = try await isBookmarked(profileID: profileID, senseID: senseID)

        if isCurrentlyBookmarked {
            let sql = "DELETE FROM bookmarks WHERE profile_id = ? AND sense_id = ?;"
            let stmt = try prepare(sql: sql)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, senseID.description, -1, SQLITE_TRANSIENT)
            let stepResult = sqlite3_step(stmt)
            guard stepResult == SQLITE_DONE else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
            return false
        } else {
            let nowISO = ISO8601DateFormatter().string(from: Date())
            let sql = "INSERT INTO bookmarks (profile_id, sense_id, created_at) VALUES (?, ?, ?);"
            let stmt = try prepare(sql: sql)
            defer { sqlite3_finalize(stmt) }
            sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 2, senseID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, 3, nowISO, -1, SQLITE_TRANSIENT)
            let stepResult = sqlite3_step(stmt)
            guard stepResult == SQLITE_DONE else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
            return true
        }
    }

    public func isBookmarked(profileID: ProfileID, senseID: SenseID) async throws -> Bool {
        let sql = "SELECT 1 FROM bookmarks WHERE profile_id = ? AND sense_id = ? LIMIT 1;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, senseID.description, -1, SQLITE_TRANSIENT)
        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW { return true }
        if stepResult == SQLITE_DONE { return false }
        let database = try getDB()
        throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
    }

    public func bookmarkedSenseIDs(profileID: ProfileID) async throws -> Set<SenseID> {
        let sql = "SELECT sense_id FROM bookmarks WHERE profile_id = ? ORDER BY created_at DESC;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)

        var set = Set<SenseID>()
        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                let text = try columnRequiredText(stmt, 0, field: "sense_id")
                if let senseID = SenseID(uuidString: text) {
                    set.insert(senseID)
                }
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
        }
        return set
    }

    public func practicedSenseIDs(profileID: ProfileID) async throws -> Set<SenseID> {
        let sql = "SELECT DISTINCT sense_id FROM counters WHERE profile_id = ?;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)

        var set = Set<SenseID>()
        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                let text = try columnRequiredText(stmt, 0, field: "sense_id")
                if let senseID = SenseID(uuidString: text) {
                    set.insert(senseID)
                }
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
        }
        return set
    }

    public func weakSenseIDs(profileID: ProfileID, accuracyThreshold: Double = 0.7) async throws -> Set<SenseID> {
        let sql = """
        SELECT sense_id, SUM(total_count) as total, SUM(correct_count) as correct
        FROM counters
        WHERE profile_id = ?
        GROUP BY sense_id
        HAVING total > 0 AND (CAST(correct AS REAL) / total) < ?;
        """
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_double(stmt, 2, accuracyThreshold)

        var set = Set<SenseID>()
        while true {
            let stepResult = sqlite3_step(stmt)
            if stepResult == SQLITE_ROW {
                let text = try columnRequiredText(stmt, 0, field: "sense_id")
                if let senseID = SenseID(uuidString: text) {
                    set.insert(senseID)
                }
            } else if stepResult == SQLITE_DONE {
                break
            } else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
            }
        }
        return set
    }
}

// MARK: - Internal Database Helpers

extension LearningJournal {
    private static func configurePragmas(db: OpaquePointer) throws {
        let pragmaSQL = "PRAGMA journal_mode = WAL; PRAGMA foreign_keys = ON; PRAGMA busy_timeout = 5000; PRAGMA synchronous = NORMAL;"
        try executePragma(db: db, sql: pragmaSQL)
    }

    private static func executePragma(db: OpaquePointer, sql: String) throws {
        var err: UnsafeMutablePointer<CChar>?
        let resultCode = sqlite3_exec(db, sql, nil, nil, &err)
        if resultCode != SQLITE_OK {
            let msg = err.map { String(cString: $0) } ?? "Failed to execute pragma"
            sqlite3_free(err)
            throw LearningJournalError.sqliteError(resultCode, msg)
        }
    }

    private static func bootstrapSchema(db: OpaquePointer) throws {
        var schemaString = embeddedSchemaSQL
        if let fileURL = Bundle.main.url(forResource: "JournalSchema", withExtension: "sql"),
           let loaded = try? String(contentsOf: fileURL, encoding: .utf8) {
            schemaString = loaded
        }

        var err: UnsafeMutablePointer<CChar>?
        let resultCode = sqlite3_exec(db, schemaString, nil, nil, &err)
        if resultCode != SQLITE_OK {
            let msg = err.map { String(cString: $0) } ?? "Failed to execute bootstrap schema"
            sqlite3_free(err)
            throw LearningJournalError.sqliteError(resultCode, msg)
        }
    }

    private func getDB() throws -> OpaquePointer {
        guard let db else {
            throw LearningJournalError.invalidState("Database connection closed")
        }
        return db
    }

    private func prepare(sql: String) throws -> OpaquePointer {
        let database = try getDB()
        var stmt: OpaquePointer?
        let resultCode = sqlite3_prepare_v2(database, sql, -1, &stmt, nil)
        guard resultCode == SQLITE_OK, let stmt else {
            let msg = String(cString: sqlite3_errmsg(database))
            throw LearningJournalError.sqliteError(resultCode, msg)
        }
        return stmt
    }

    private func executeTransaction(_ block: () throws -> Void) throws {
        let database = try getDB()
        let beginResult = sqlite3_exec(database, "BEGIN IMMEDIATE;", nil, nil, nil)
        guard beginResult == SQLITE_OK else {
            let msg = String(cString: sqlite3_errmsg(database))
            throw LearningJournalError.sqliteError(beginResult, msg)
        }

        do {
            try block()
            let commitResult = sqlite3_exec(database, "COMMIT;", nil, nil, nil)
            guard commitResult == SQLITE_OK else {
                let msg = String(cString: sqlite3_errmsg(database))
                sqlite3_exec(database, "ROLLBACK;", nil, nil, nil)
                throw LearningJournalError.sqliteError(commitResult, msg)
            }
        } catch {
            sqlite3_exec(database, "ROLLBACK;", nil, nil, nil)
            throw error
        }
    }

    private func assertProfileExists(profileID: ProfileID) throws {
        let sql = "SELECT id FROM profiles WHERE id = ?;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW { return }
        if stepResult == SQLITE_DONE { throw LearningJournalError.profileNotFound(profileID) }
        let database = try getDB()
        throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
    }

    private func fetchExistingAttemptHash(attemptID: AttemptID) throws -> String? {
        let sql = "SELECT submission_hash FROM attempts WHERE attempt_id = ?;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, attemptID.description, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW { return try columnRequiredText(stmt, 0, field: "submission_hash") }
        if stepResult == SQLITE_DONE { return nil }
        let database = try getDB()
        throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
    }

    private func advanceDeviceSequence(profileID: ProfileID) throws -> Int {
        let querySQL = "SELECT last_sequence FROM profile_device_sequences WHERE profile_id = ? AND device_id = ?;"
        let queryStmt = try prepare(sql: querySQL)
        defer { sqlite3_finalize(queryStmt) }
        sqlite3_bind_text(queryStmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(queryStmt, 2, deviceID.description, -1, SQLITE_TRANSIENT)

        let queryStep = sqlite3_step(queryStmt)
        if queryStep == SQLITE_ROW {
            let current = Int(sqlite3_column_int(queryStmt, 0))
            let next = current + 1

            let updateSQL = "UPDATE profile_device_sequences SET last_sequence = ? WHERE profile_id = ? AND device_id = ?;"
            let updateStmt = try prepare(sql: updateSQL)
            defer { sqlite3_finalize(updateStmt) }
            sqlite3_bind_int(updateStmt, 1, Int32(next))
            sqlite3_bind_text(updateStmt, 2, profileID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(updateStmt, 3, deviceID.description, -1, SQLITE_TRANSIENT)

            let updateStep = sqlite3_step(updateStmt)
            guard updateStep == SQLITE_DONE else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(updateStep, String(cString: sqlite3_errmsg(database)))
            }
            return next
        } else if queryStep == SQLITE_DONE {
            let insertSQL = "INSERT INTO profile_device_sequences (profile_id, device_id, last_sequence) VALUES (?, ?, 1);"
            let insertStmt = try prepare(sql: insertSQL)
            defer { sqlite3_finalize(insertStmt) }
            sqlite3_bind_text(insertStmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(insertStmt, 2, deviceID.description, -1, SQLITE_TRANSIENT)

            let insertStep = sqlite3_step(insertStmt)
            guard insertStep == SQLITE_DONE else {
                let database = try getDB()
                throw LearningJournalError.sqliteError(insertStep, String(cString: sqlite3_errmsg(database)))
            }
            return 1
        } else {
            let database = try getDB()
            throw LearningJournalError.sqliteError(queryStep, String(cString: sqlite3_errmsg(database)))
        }
    }

    private func insertAttemptRecord(
        attemptID: AttemptID,
        profileID: ProfileID,
        payloadJSON: String,
        submissionHash: String,
        createdAt: String
    ) throws {
        let sql = "INSERT INTO attempts (attempt_id, profile_id, payload_json, submission_hash, created_at) VALUES (?, ?, ?, ?, ?);"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, attemptID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, payloadJSON, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 4, submissionHash, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 5, createdAt, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        guard stepResult == SQLITE_DONE else {
            let database = try getDB()
            throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
        }
    }

    private func updateCapabilityCounter(
        profileID: ProfileID,
        senseID: SenseID,
        capability: Capability,
        isCorrect: Bool
    ) throws {
        let sql = """
        INSERT INTO counters (profile_id, sense_id, capability, total_count, correct_count)
        VALUES (?, ?, ?, 1, ?)
        ON CONFLICT(profile_id, sense_id, capability) DO UPDATE SET
            total_count = total_count + 1,
            correct_count = correct_count + excluded.correct_count;
        """
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, profileID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, senseID.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, capability.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 4, isCorrect ? 1 : 0)

        let stepResult = sqlite3_step(stmt)
        guard stepResult == SQLITE_DONE else {
            let database = try getDB()
            throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
        }
    }

    private func fetchExistingCompletionPayload(eventID: EventID) throws -> String? {
        let sql = "SELECT payload_json FROM completions WHERE event_id = ?;"
        let stmt = try prepare(sql: sql)
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, eventID.description, -1, SQLITE_TRANSIENT)

        let stepResult = sqlite3_step(stmt)
        if stepResult == SQLITE_ROW { return try columnRequiredText(stmt, 0, field: "payload_json") }
        if stepResult == SQLITE_DONE { return nil }
        let database = try getDB()
        throw LearningJournalError.sqliteError(stepResult, String(cString: sqlite3_errmsg(database)))
    }

    private func columnRequiredText(_ stmt: OpaquePointer, _ index: Int32, field: String) throws -> String {
        guard sqlite3_column_type(stmt, index) != SQLITE_NULL,
              let ptr = sqlite3_column_text(stmt, index) else {
            throw LearningJournalError.invalidState("Missing required column '\(field)'")
        }
        return String(cString: ptr)
    }
}

// MARK: - Internal Serialization Extensions

extension AttemptSubmission {
    func canonicalData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }

    func submissionHash() throws -> String {
        let data = try canonicalData()
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}

extension PracticeAttempt {
    func canonicalData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }
}
