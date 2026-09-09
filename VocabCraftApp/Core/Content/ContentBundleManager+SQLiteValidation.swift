import Foundation
import SQLite3

// MARK: - SQLite Validation Extension

extension SQLiteContentRepository {
    public static func validateDatabase(
        at url: URL,
        expectedVersion: String? = nil
    ) throws -> (schemaVersion: Int, contentVersion: Int) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ContentBundleError.invalidDatabase(reason: "File not found at \(url.path)")
        }

        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        let openResult = sqlite3_open_v2(url.path, &dbPointer, flags, nil)
        guard openResult == SQLITE_OK, let db = dbPointer else {
            let message = dbPointer != nil ? String(cString: sqlite3_errmsg(dbPointer)) : "Unknown open error"
            if let dbPointer { sqlite3_close(dbPointer) }
            throw ContentBundleError.invalidDatabase(reason: "Cannot open SQLite database: \(message)")
        }
        defer { sqlite3_close(db) }

        try validateIntegrityCheck(db: db)
        try validateRequiredTables(db: db)
        try validateForeignKeyConstraints(db: db)
        return try validateMetadataVersion(db: db, expectedVersion: expectedVersion)
    }

    private static func validateIntegrityCheck(db: OpaquePointer) throws {
        var integrityStmt: OpaquePointer?
        let integrityResult = sqlite3_prepare_v2(db, "PRAGMA integrity_check;", -1, &integrityStmt, nil)
        guard integrityResult == SQLITE_OK, let stmt = integrityStmt else {
            throw ContentBundleError.invalidDatabase(reason: "Integrity check failed to prepare")
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW, let ptr = sqlite3_column_text(stmt, 0) else {
            throw ContentBundleError.invalidDatabase(reason: "Integrity check returned no rows")
        }

        let res = String(cString: ptr)
        if res != "ok" {
            throw ContentBundleError.invalidDatabase(reason: "Integrity check failed: \(res)")
        }
    }

    private static func validateRequiredTables(db: OpaquePointer) throws {
        let requiredTables: Set<String> = [
            "dataset_metadata", "entries", "senses", "pronunciations",
            "examples", "collocations", "decks", "lessons",
            "lesson_senses", "attributions", "sense_attributions", "retired_senses"
        ]

        var tablesStmt: OpaquePointer?
        let tablesResult = sqlite3_prepare_v2(db, "SELECT name FROM sqlite_master WHERE type='table';", -1, &tablesStmt, nil)
        guard tablesResult == SQLITE_OK, let stmt = tablesStmt else {
            throw ContentBundleError.invalidDatabase(reason: "Failed to query tables from database")
        }
        defer { sqlite3_finalize(stmt) }

        var existingTables: Set<String> = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let ptr = sqlite3_column_text(stmt, 0) {
                existingTables.insert(String(cString: ptr))
            }
        }

        let missingTables = requiredTables.subtracting(existingTables)
        if !missingTables.isEmpty {
            throw ContentBundleError.invalidDatabase(
                reason: "Missing required tables: \(missingTables.sorted().joined(separator: ", "))"
            )
        }
    }

    private static func validateForeignKeyConstraints(db: OpaquePointer) throws {
        var fkStmt: OpaquePointer?
        let fkResult = sqlite3_prepare_v2(db, "PRAGMA foreign_key_check;", -1, &fkStmt, nil)
        guard fkResult == SQLITE_OK, let stmt = fkStmt else {
            throw ContentBundleError.invalidDatabase(reason: "Foreign key check failed to prepare")
        }
        defer { sqlite3_finalize(stmt) }

        if sqlite3_step(stmt) == SQLITE_ROW {
            throw ContentBundleError.invalidDatabase(reason: "Foreign key constraint violation detected")
        }
    }

    private static func validateMetadataVersion(
        db: OpaquePointer,
        expectedVersion: String?
    ) throws -> (schemaVersion: Int, contentVersion: Int) {
        var metaStmt: OpaquePointer?
        let metaSql = "SELECT dataset_schema_version, content_version FROM dataset_metadata LIMIT 1;"
        let metaResult = sqlite3_prepare_v2(db, metaSql, -1, &metaStmt, nil)
        guard metaResult == SQLITE_OK, let stmt = metaStmt else {
            throw ContentBundleError.invalidDatabase(reason: "Failed to read dataset_metadata")
        }
        defer { sqlite3_finalize(stmt) }

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw ContentBundleError.invalidDatabase(reason: "dataset_metadata table is empty")
        }

        let schemaVersion = Int(sqlite3_column_int64(stmt, 0))
        let contentVersion = Int(sqlite3_column_int64(stmt, 1))

        if schemaVersion != 1 {
            throw ContentBundleError.unsupportedSchemaVersion(schemaVersion)
        }

        if let expectedVersion {
            let dbVersionString = "\(contentVersion)"
            if let expectedInt = Int(expectedVersion) {
                if contentVersion != expectedInt {
                    throw ContentBundleError.invalidDatabase(
                        reason: "Content version mismatch: database has \(contentVersion), expected \(expectedVersion)"
                    )
                }
            } else if dbVersionString != expectedVersion {
                throw ContentBundleError.invalidDatabase(
                    reason: "Content version mismatch: database has \(contentVersion), expected \(expectedVersion)"
                )
            }
        }

        return (schemaVersion, contentVersion)
    }
}
