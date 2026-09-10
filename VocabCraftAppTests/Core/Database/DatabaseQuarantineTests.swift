#if canImport(SwiftDataMacros) || canImport(SwiftData)
import Foundation
import SwiftData
@testable import VocabCraftApp
import XCTest

final class DatabaseQuarantineTests: XCTestCase {
    private var tempDirectory: URL!
    private var corruptStoreURL: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        corruptStoreURL = tempDirectory.appendingPathComponent("corrupt.sqlite")
        // Write corrupt junk data
        try "CORRUPT_INVALID_SQLITE_HEADER".write(to: corruptStoreURL, atomically: true, encoding: .utf8)
    }

    override func tearDownWithError() throws {
        if let tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        try super.tearDownWithError()
    }

    func test_corrupt_store_triggers_quarantine_and_throws_typed_error() {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, url: corruptStoreURL)

        XCTAssertThrowsError(
            try SharedAppGroupContainer.createContainer(configuration: config, storeURL: corruptStoreURL)
        ) { error in
            guard let dbError = error as? DatabaseStoreError else {
                XCTFail("Expected DatabaseStoreError, got \(error)")
                return
            }
            switch dbError {
            case .storeInitializationFailed(_, let backupURL):
                XCTAssertNotNil(backupURL)
                if let backupURL {
                    XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
                }
            default:
                XCTFail("Unexpected error case: \(dbError)")
            }
        }

        // Original file must NOT be deleted on initialization failure
        XCTAssertTrue(FileManager.default.fileExists(atPath: corruptStoreURL.path))
    }

    @MainActor
    func test_reset_store_with_quarantine_removes_corrupt_files_and_creates_fresh_container() throws {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, url: corruptStoreURL)

        // Ensure corrupt file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: corruptStoreURL.path))

        // Explicit reset creates backup and returns fresh working container
        let freshContainer = try SharedAppGroupContainer.resetStoreWithQuarantine(
            storeURL: corruptStoreURL,
            configuration: config
        )

        // Fresh container should have valid context
        XCTAssertNotNil(freshContainer.mainContext)
        // Store file at corruptStoreURL should now be a valid SwiftData SQLite file, not original junk
        let content = try? String(contentsOf: corruptStoreURL, encoding: .utf8)
        XCTAssertNotEqual(content, "CORRUPT_INVALID_SQLITE_HEADER")
    }

    func test_quarantine_copies_shm_and_wal_files_when_present() throws {
        let walURL = corruptStoreURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        let shmURL = corruptStoreURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
        try "WAL_DUMMY_DATA".write(to: walURL, atomically: true, encoding: .utf8)
        try "SHM_DUMMY_DATA".write(to: shmURL, atomically: true, encoding: .utf8)

        let backupURL = SharedAppGroupContainer.quarantineCorruptStoreFiles(from: corruptStoreURL)
        XCTAssertNotNil(backupURL)

        if let backupURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
            let backupWal = backupURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
            let backupShm = backupURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
            XCTAssertTrue(FileManager.default.fileExists(atPath: backupWal.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: backupShm.path))
        }
    }

    func test_database_store_error_localized_descriptions() {
        let dummyBackupURL = URL(fileURLWithPath: "/tmp/backup_test.sqlite")
        let initErrorWithBackup = DatabaseStoreError.storeInitializationFailed(
            description: "Corrupt header",
            backupURL: dummyBackupURL
        )
        XCTAssertNotNil(initErrorWithBackup.errorDescription)
        XCTAssertTrue(initErrorWithBackup.errorDescription?.contains("backup_test.sqlite") == true)
        XCTAssertTrue(initErrorWithBackup.errorDescription?.contains("Corrupt header") == true)
        XCTAssertFalse(initErrorWithBackup.errorDescription?.contains("%@") == true)
        XCTAssertEqual(
            initErrorWithBackup.errorDescription,
            "Failed to load database. Backup created at backup_test.sqlite: Corrupt header"
        )

        let initErrorNoBackup = DatabaseStoreError.storeInitializationFailed(
            description: "Disk full",
            backupURL: nil
        )
        XCTAssertNotNil(initErrorNoBackup.errorDescription)
        XCTAssertTrue(initErrorNoBackup.errorDescription?.contains("Disk full") == true)
        XCTAssertFalse(initErrorNoBackup.errorDescription?.contains("%@") == true)
        XCTAssertEqual(
            initErrorNoBackup.errorDescription,
            "Failed to load database: Disk full"
        )

        let backupError = DatabaseStoreError.quarantineBackupFailed(description: "Permission denied")
        XCTAssertNotNil(backupError.errorDescription)
        XCTAssertTrue(backupError.errorDescription?.contains("Permission denied") == true)
        XCTAssertFalse(backupError.errorDescription?.contains("%@") == true)
        XCTAssertEqual(
            backupError.errorDescription,
            "Failed to create quarantine backup: Permission denied"
        )

        let resetError = DatabaseStoreError.manualResetFailed(description: "Lock failure")
        XCTAssertNotNil(resetError.errorDescription)
        XCTAssertTrue(resetError.errorDescription?.contains("Lock failure") == true)
        XCTAssertFalse(resetError.errorDescription?.contains("%@") == true)
        XCTAssertEqual(
            resetError.errorDescription,
            "Failed to reset database: Lock failure"
        )
    }

    func test_reset_store_throws_quarantine_backup_failed_when_quarantine_fails() throws {
        let protectedDirectory = tempDirectory.appendingPathComponent("protected_store_dir", isDirectory: true)
        try FileManager.default.createDirectory(at: protectedDirectory, withIntermediateDirectories: true)
        let protectedStoreURL = protectedDirectory.appendingPathComponent("protected.sqlite")
        try "IMPORTANT_USER_DATA".write(to: protectedStoreURL, atomically: true, encoding: .utf8)

        // Make directory read-only so new backup files cannot be created in it
        try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: protectedDirectory.path)
        defer {
            // Restore write permissions so cleanup succeeds
            try? FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: protectedDirectory.path)
        }

        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, url: protectedStoreURL)

        XCTAssertThrowsError(
            try SharedAppGroupContainer.resetStoreWithQuarantine(
                storeURL: protectedStoreURL,
                configuration: config
            )
        ) { error in
            guard let dbError = error as? DatabaseStoreError else {
                XCTFail("Expected DatabaseStoreError, got \(error)")
                return
            }
            switch dbError {
            case .quarantineBackupFailed(let description):
                XCTAssertFalse(description.isEmpty)
            default:
                XCTFail("Expected quarantineBackupFailed, got \(dbError)")
            }
        }

        // Original file must NOT be deleted when quarantine fails
        XCTAssertTrue(FileManager.default.fileExists(atPath: protectedStoreURL.path))
        let remainingContent = try? String(contentsOf: protectedStoreURL, encoding: .utf8)
        XCTAssertEqual(remainingContent, "IMPORTANT_USER_DATA")
    }

    func test_reset_store_with_quarantine_aborts_and_preserves_originals_when_wal_backup_fails() throws {
        let storeURL = tempDirectory.appendingPathComponent("wal_protected.sqlite")
        let walURL = tempDirectory.appendingPathComponent("wal_protected.sqlite-wal")
        try "MAIN_STORE_DATA".write(to: storeURL, atomically: true, encoding: .utf8)
        try "UNCHECKPOINTED_WAL_DATA".write(to: walURL, atomically: true, encoding: .utf8)

        let customFM = FailingWalCopyFileManager()

        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, url: storeURL)

        XCTAssertThrowsError(
            try SharedAppGroupContainer.resetStoreWithQuarantine(
                storeURL: storeURL,
                configuration: config,
                fileManager: customFM
            )
        ) { error in
            guard let dbError = error as? DatabaseStoreError else {
                XCTFail("Expected DatabaseStoreError, got \(error)")
                return
            }
            switch dbError {
            case .quarantineBackupFailed(let description):
                XCTAssertFalse(description.isEmpty)
            default:
                XCTFail("Expected quarantineBackupFailed, got \(dbError)")
            }
        }

        // Both original sqlite AND wal files must NOT be deleted when WAL copy fails
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: walURL.path))
        XCTAssertEqual(try? String(contentsOf: storeURL, encoding: .utf8), "MAIN_STORE_DATA")
        XCTAssertEqual(try? String(contentsOf: walURL, encoding: .utf8), "UNCHECKPOINTED_WAL_DATA")
    }
}

private final class FailingWalCopyFileManager: FileManager {
    var shouldFailWalCopy = true

    override func copyItem(at srcURL: URL, to dstURL: URL) throws {
        if shouldFailWalCopy && srcURL.path.hasSuffix("-wal") {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteUnknownError, userInfo: [NSLocalizedDescriptionKey: "Simulated WAL copy failure"])
        }
        try super.copyItem(at: srcURL, to: dstURL)
    }
}
#endif
