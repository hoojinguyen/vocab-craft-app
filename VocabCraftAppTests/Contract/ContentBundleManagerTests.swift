import CryptoKit
import Foundation
import SQLite3
@testable import VocabCraftApp
import XCTest

final class ContentBundleManagerTests: XCTestCase {
    private var tempDirectories: [URL] = []

    override func tearDown() {
        for directory in tempDirectories {
            try? FileManager.default.removeItem(at: directory)
        }
        tempDirectories.removeAll()
        super.tearDown()
    }

    private func makeTemporaryDirectory(prefix: String = "ContentBundleManagerTests") throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        tempDirectories.append(directory)
        return directory
    }

    private func makeFixtureBundleManager(
        rootURL: URL? = nil,
        baselineURL: URL? = nil,
        baselineManifest: PublishedManifest? = nil
    ) throws -> ContentBundleManager {
        let resolvedRoot = try rootURL ?? makeTemporaryDirectory(prefix: "Root")
        let resolvedBaseline = try baselineURL ?? ContractFixture.bundleURL()
        let resolvedManifest = try baselineManifest ?? ContractFixture.publishedManifest()
        return ContentBundleManager(
            rootURL: resolvedRoot,
            baselineURL: resolvedBaseline,
            baselineManifest: resolvedManifest
        )
    }

    private func corruptFixtureURL() throws -> URL {
        let tempDir = try makeTemporaryDirectory(prefix: "CorruptFixture")
        let targetURL = tempDir.appendingPathComponent("corrupt.sqlite")
        let originalData = try Data(contentsOf: ContractFixture.bundleURL())
        var corruptedData = originalData
        if corruptedData.count > 100 {
            for index in 0..<16 {
                corruptedData[index] = 0xFF
            }
        }
        try corruptedData.write(to: targetURL)
        return targetURL
    }

    private func makeModifiedVersionBundle(
        contentVersion: Int,
        schemaVersion: Int = 1
    ) throws -> (fileURL: URL, manifest: PublishedManifest) {
        let tempDir = try makeTemporaryDirectory(prefix: "ModifiedVersion-\(contentVersion)")
        let dbURL = tempDir.appendingPathComponent("content_v\(contentVersion).sqlite")
        try FileManager.default.copyItem(at: ContractFixture.bundleURL(), to: dbURL)

        var dbPointer: OpaquePointer?
        guard sqlite3_open_v2(dbURL.path, &dbPointer, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK, let dbPointer else {
            throw XCTSkip("Failed to open sqlite copy for modification")
        }
        defer { sqlite3_close(dbPointer) }

        if schemaVersion != 1 {
            let recreateSQL = """
            CREATE TABLE dataset_metadata_unsupported (
                dataset_schema_version INTEGER NOT NULL,
                content_version INTEGER NOT NULL,
                published_at TEXT NOT NULL,
                content_language TEXT NOT NULL DEFAULT 'en',
                explanation_language TEXT NOT NULL DEFAULT 'vi'
            );
            INSERT INTO dataset_metadata_unsupported SELECT \(schemaVersion), \(contentVersion), published_at, content_language, explanation_language FROM dataset_metadata;
            DROP TABLE dataset_metadata;
            ALTER TABLE dataset_metadata_unsupported RENAME TO dataset_metadata;
            """
            guard sqlite3_exec(dbPointer, recreateSQL, nil, nil, nil) == SQLITE_OK else {
                throw XCTSkip("Failed to recreate table with unsupported schema")
            }
        } else {
            let updateSQL = "UPDATE dataset_metadata SET content_version = ?, dataset_schema_version = ?;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(dbPointer, updateSQL, -1, &stmt, nil) == SQLITE_OK, let stmt else {
                throw XCTSkip("Failed to prepare update sql")
            }
            defer { sqlite3_finalize(stmt) }

            sqlite3_bind_int64(stmt, 1, Int64(contentVersion))
            sqlite3_bind_int64(stmt, 2, Int64(schemaVersion))
            guard sqlite3_step(stmt) == SQLITE_DONE else {
                throw XCTSkip("Failed to execute update sql")
            }
        }

        let data = try Data(contentsOf: dbURL)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let manifest = PublishedManifest(
            contentVersion: String(contentVersion),
            datasetSchemaVersion: schemaVersion,
            bundle: PublishedBundleInfo(
                sha256: hash,
                bytesLength: Int64(data.count),
                url: "/v1/content/releases/\(contentVersion)/bundle"
            )
        )
        return (dbURL, manifest)
    }

    func testBadDownloadDoesNotReplaceActiveBundle() async throws {
        let manager = try makeFixtureBundleManager()
        let before = try await manager.openActive()
        let badURL = try corruptFixtureURL()

        do {
            _ = try await manager.install(fileURL: badURL, manifest: ContractFixture.manifest())
            XCTFail("Corrupt content must fail")
        } catch let error as ContentBundleError {
            let matchesExpected: Bool
            switch error {
            case .checksumMismatch, .invalidDatabase, .fileLengthMismatch:
                matchesExpected = true
            default:
                matchesExpected = false
            }
            XCTAssertTrue(matchesExpected, "Unexpected error: \(error)")
        }
        let after = try await manager.openActive()
        XCTAssertEqual(after.contentVersion, before.contentVersion)
    }

    func testUnsupportedSchemaDoesNotReplaceActiveBundle() async throws {
        let manager = try makeFixtureBundleManager()
        let before = try await manager.openActive()
        let (unsupportedURL, unsupportedManifest) = try makeModifiedVersionBundle(contentVersion: 2, schemaVersion: 99)

        do {
            _ = try await manager.install(fileURL: unsupportedURL, manifest: unsupportedManifest)
            XCTFail("Unsupported schema must fail install")
        } catch let error as ContentBundleError {
            XCTAssertEqual(error, .unsupportedSchemaVersion(99))
        }

        let after = try await manager.openActive()
        XCTAssertEqual(after.contentVersion, before.contentVersion)
    }

    func testCorruptSQLiteFileDoesNotReplaceActiveBundle() async throws {
        let manager = try makeFixtureBundleManager()
        let before = try await manager.openActive()

        let tempDir = try makeTemporaryDirectory(prefix: "CorruptSQLite")
        let dummyURL = tempDir.appendingPathComponent("corrupt.sqlite")
        let dummyBytes = Data(repeating: 0x42, count: 1024)
        try dummyBytes.write(to: dummyURL)
        let hash = SHA256.hash(data: dummyBytes).map { String(format: "%02x", $0) }.joined()
        let manifest = PublishedManifest(
            contentVersion: "2",
            datasetSchemaVersion: 1,
            bundle: PublishedBundleInfo(sha256: hash, bytesLength: Int64(dummyBytes.count))
        )

        do {
            _ = try await manager.install(fileURL: dummyURL, manifest: manifest)
            XCTFail("Non-SQLite file must fail install")
        } catch let error as ContentBundleError {
            if case .invalidDatabase = error {
                // Expected
            } else {
                XCTFail("Expected .invalidDatabase, got \(error)")
            }
        }

        let after = try await manager.openActive()
        XCTAssertEqual(after.contentVersion, before.contentVersion)
    }

    func testActiveHandleRetainsOldVersionWhenNewBundleInstalled() async throws {
        let manager = try makeFixtureBundleManager()
        let handle1 = try await manager.openActive()
        XCTAssertEqual(handle1.contentVersion, "1")

        let (v2URL, v2Manifest) = try makeModifiedVersionBundle(contentVersion: 2)
        let installResult = try await manager.install(fileURL: v2URL, manifest: v2Manifest)
        XCTAssertEqual(installResult, .installed(version: "2"))

        let handle2 = try await manager.openActive()
        XCTAssertEqual(handle2.contentVersion, "2")
        XCTAssertEqual(handle1.contentVersion, "1")

        let decks1 = try await handle1.reader.fetchDecks()
        XCTAssertFalse(decks1.isEmpty)

        let decks2 = try await handle2.reader.fetchDecks()
        XCTAssertFalse(decks2.isEmpty)
    }

    func testOpenActiveFallbackToBaselineWhenPointerMissing() async throws {
        let rootURL = try makeTemporaryDirectory(prefix: "EmptyRoot")
        let manager = try makeFixtureBundleManager(rootURL: rootURL)

        let handle = try await manager.openActive()
        XCTAssertEqual(handle.contentVersion, "1")
        XCTAssertTrue(FileManager.default.fileExists(atPath: rootURL.appendingPathComponent("active.json").path))
    }

    func testNoBaselineAndNoActivePointerThrowsExplicitError() async throws {
        let rootURL = try makeTemporaryDirectory(prefix: "NoBaselineRoot")
        let manager = ContentBundleManager(rootURL: rootURL, baselineURL: nil)

        do {
            _ = try await manager.openActive()
            XCTFail("Should have thrown missingBaseline")
        } catch let error as ContentBundleError {
            XCTAssertEqual(error, .missingBaseline)
        }
    }

    func testRemoteRollbackVersionIsIgnored() async throws {
        let manager = try makeFixtureBundleManager()
        let (v2URL, v2Manifest) = try makeModifiedVersionBundle(contentVersion: 2)
        _ = try await manager.install(fileURL: v2URL, manifest: v2Manifest)

        let activeHandle = try await manager.openActive()
        XCTAssertEqual(activeHandle.contentVersion, "2")

        let v1Manifest = try ContractFixture.publishedManifest()
        let rollbackResult = try await manager.install(fileURL: ContractFixture.bundleURL(), manifest: v1Manifest)
        XCTAssertEqual(rollbackResult, .ignoredOlderVersion(activeVersion: "2", candidateVersion: "1"))

        let afterHandle = try await manager.openActive()
        XCTAssertEqual(afterHandle.contentVersion, "2")
    }

    func testReinstallingCurrentVersionReturnsAlreadyActive() async throws {
        let manager = try makeFixtureBundleManager()
        _ = try await manager.openActive()

        let v1Manifest = try ContractFixture.publishedManifest()
        let result = try await manager.install(fileURL: ContractFixture.bundleURL(), manifest: v1Manifest)
        XCTAssertEqual(result, .alreadyActive(version: "1"))
    }

    func testCorruptActivePointerFallsBackToPreviousPointer() async throws {
        let rootURL = try makeTemporaryDirectory(prefix: "PointerFallback")
        let manager = try makeFixtureBundleManager(rootURL: rootURL)
        _ = try await manager.openActive()

        let (v2URL, v2Manifest) = try makeModifiedVersionBundle(contentVersion: 2)
        _ = try await manager.install(fileURL: v2URL, manifest: v2Manifest)

        let activeURL = rootURL.appendingPathComponent("active.json")
        try Data("corrupt json string".utf8).write(to: activeURL)

        let fallbackHandle = try await manager.openActive()
        XCTAssertEqual(fallbackHandle.contentVersion, "1")
    }

    func testCorruptedPointersFallbackToBaseline() async throws {
        let rootURL = try makeTemporaryDirectory(prefix: "PointersCorruptFallbackBaseline")
        let manager = try makeFixtureBundleManager(rootURL: rootURL)
        _ = try await manager.openActive()

        let activeURL = rootURL.appendingPathComponent("active.json")
        let prevURL = rootURL.appendingPathComponent("previous.json")
        try Data("corrupt active".utf8).write(to: activeURL)
        try Data("corrupt prev".utf8).write(to: prevURL)

        let recoveredHandle = try await manager.openActive()
        XCTAssertEqual(recoveredHandle.contentVersion, "1")
    }

    func testCorruptDatabaseAtActivePointerFallsBackToPrevious() async throws {
        let rootURL = try makeTemporaryDirectory(prefix: "CorruptActiveDBFallback")
        let manager = try makeFixtureBundleManager(rootURL: rootURL)
        _ = try await manager.openActive()

        let (v2URL, v2Manifest) = try makeModifiedVersionBundle(contentVersion: 2)
        _ = try await manager.install(fileURL: v2URL, manifest: v2Manifest)

        let activeDB = rootURL.appendingPathComponent("releases/2/content.sqlite")
        try FileManager.default.removeItem(at: activeDB)

        let fallbackHandle = try await manager.openActive()
        XCTAssertEqual(fallbackHandle.contentVersion, "1")
    }
}
