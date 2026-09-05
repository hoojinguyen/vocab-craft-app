import CryptoKit
import Foundation
import SQLite3

// MARK: - Content Handle

public struct ContentHandle: Sendable {
    public let reader: any ContentRepository
    public let contentVersion: String
    public let manifest: PublishedManifest
    public let databaseURL: URL

    public init(
        reader: any ContentRepository,
        contentVersion: String,
        manifest: PublishedManifest,
        databaseURL: URL
    ) {
        self.reader = reader
        self.contentVersion = contentVersion
        self.manifest = manifest
        self.databaseURL = databaseURL
    }
}

// MARK: - Install Result

public enum InstallResult: Equatable, Sendable {
    case installed(version: String)
    case alreadyActive(version: String)
    case ignoredOlderVersion(activeVersion: String, candidateVersion: String)
}

// MARK: - Content Bundle Error

public enum ContentBundleError: Error, LocalizedError, Equatable {
    case missingBaseline
    case checksumMismatch(expected: String, actual: String)
    case fileLengthMismatch(expected: Int64, actual: Int64)
    case invalidDatabase(reason: String)
    case unsupportedSchemaVersion(Int)
    case activationFailed(reason: String)
    case releaseDirectoryCreationFailed(reason: String)

    public var errorDescription: String? {
        switch self {
        case .missingBaseline:
            return "No active content bundle pointer and no valid baseline bundle found."
        case .checksumMismatch(let expected, let actual):
            return "Bundle SHA-256 checksum mismatch. Expected \(expected), got \(actual)."
        case .fileLengthMismatch(let expected, let actual):
            return "Bundle file size mismatch. Expected \(expected) bytes, got \(actual) bytes."
        case .invalidDatabase(let reason):
            return "SQLite database validation failed: \(reason)"
        case .unsupportedSchemaVersion(let version):
            return "Unsupported dataset schema version: \(version). Expected version 1."
        case .activationFailed(let reason):
            return "Activation pointer swap failed: \(reason)"
        case .releaseDirectoryCreationFailed(let reason):
            return "Failed to create release directory: \(reason)"
        }
    }
}

// MARK: - Published Manifest Models

public struct PublishedBundleInfo: Codable, Sendable, Equatable {
    public let sha256: String
    public let bytesLength: Int64
    public let url: String?

    enum CodingKeys: String, CodingKey {
        case sha256
        case bytesLength = "bytes_length"
        case byteSize = "byte_size"
        case url
        case bundleUrl = "bundle_url"
    }

    public init(sha256: String, bytesLength: Int64, url: String? = nil) {
        self.sha256 = sha256
        self.bytesLength = bytesLength
        self.url = url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sha256 = try container.decode(String.self, forKey: .sha256)
        if let length = try? container.decode(Int64.self, forKey: .bytesLength) {
            bytesLength = length
        } else if let length = try? container.decode(Int64.self, forKey: .byteSize) {
            bytesLength = length
        } else {
            bytesLength = try container.decode(Int64.self, forKey: .bytesLength)
        }
        url = (try? container.decodeIfPresent(String.self, forKey: .url))
            ?? (try? container.decodeIfPresent(String.self, forKey: .bundleUrl))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sha256, forKey: .sha256)
        try container.encode(bytesLength, forKey: .bytesLength)
        try container.encodeIfPresent(url, forKey: .url)
    }
}

public struct PublishedManifest: Codable, Sendable, Equatable {
    public let contentVersion: String
    public let datasetSchemaVersion: Int
    public let publishedAt: String?
    public let contentLanguage: String?
    public let explanationLanguage: String?
    public let bundle: PublishedBundleInfo
    public let counts: ContentManifestCounts?

    enum CodingKeys: String, CodingKey {
        case contentVersion = "content_version"
        case datasetSchemaVersion = "dataset_schema_version"
        case publishedAt = "published_at"
        case contentLanguage = "content_language"
        case explanationLanguage = "explanation_language"
        case bundle, counts, sha256
        case byteSize = "byte_size"
        case bytesLength = "bytes_length"
        case bundleURL = "bundle_url"
    }

    public init(
        contentVersion: String,
        datasetSchemaVersion: Int = 1,
        publishedAt: String? = nil,
        contentLanguage: String? = "en",
        explanationLanguage: String? = "vi",
        bundle: PublishedBundleInfo,
        counts: ContentManifestCounts? = nil
    ) {
        self.contentVersion = contentVersion
        self.datasetSchemaVersion = datasetSchemaVersion
        self.publishedAt = publishedAt
        self.contentLanguage = contentLanguage
        self.explanationLanguage = explanationLanguage
        self.bundle = bundle
        self.counts = counts
    }

    public init(contentManifest: ContentManifest) {
        self.contentVersion = String(contentManifest.contentVersion)
        self.datasetSchemaVersion = contentManifest.datasetSchemaVersion
        self.publishedAt = contentManifest.publishedAt
        self.contentLanguage = contentManifest.contentLanguage
        self.explanationLanguage = contentManifest.explanationLanguage
        self.bundle = PublishedBundleInfo(
            sha256: contentManifest.sha256,
            bytesLength: Int64(contentManifest.byteSize),
            url: contentManifest.bundleURL
        )
        self.counts = contentManifest.counts
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let str = try? container.decode(String.self, forKey: .contentVersion) {
            contentVersion = str
        } else if let intVal = try? container.decode(Int.self, forKey: .contentVersion) {
            contentVersion = String(intVal)
        } else {
            contentVersion = try container.decode(String.self, forKey: .contentVersion)
        }
        datasetSchemaVersion = (try? container.decodeIfPresent(Int.self, forKey: .datasetSchemaVersion)) ?? 1
        publishedAt = try? container.decodeIfPresent(String.self, forKey: .publishedAt)
        contentLanguage = try? container.decodeIfPresent(String.self, forKey: .contentLanguage)
        explanationLanguage = try? container.decodeIfPresent(String.self, forKey: .explanationLanguage)
        counts = try? container.decodeIfPresent(ContentManifestCounts.self, forKey: .counts)

        if container.contains(.bundle) {
            bundle = try container.decode(PublishedBundleInfo.self, forKey: .bundle)
        } else {
            let sha = try container.decode(String.self, forKey: .sha256)
            let length: Int64 = (try? container.decode(Int64.self, forKey: .byteSize))
                ?? (try? container.decode(Int64.self, forKey: .bytesLength)) ?? 0
            let url = try? container.decodeIfPresent(String.self, forKey: .bundleURL)
            bundle = PublishedBundleInfo(sha256: sha, bytesLength: length, url: url)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(contentVersion, forKey: .contentVersion)
        try container.encode(datasetSchemaVersion, forKey: .datasetSchemaVersion)
        try container.encodeIfPresent(publishedAt, forKey: .publishedAt)
        try container.encodeIfPresent(contentLanguage, forKey: .contentLanguage)
        try container.encodeIfPresent(explanationLanguage, forKey: .explanationLanguage)
        try container.encode(bundle, forKey: .bundle)
        try container.encodeIfPresent(counts, forKey: .counts)
    }

    public func toContentManifest() -> ContentManifest? {
        guard let ver = Int(contentVersion) else { return nil }
        return ContentManifest(
            contentVersion: ver,
            datasetSchemaVersion: datasetSchemaVersion,
            publishedAt: publishedAt ?? "",
            contentLanguage: contentLanguage ?? "en",
            explanationLanguage: explanationLanguage ?? "vi",
            bundleURL: bundle.url ?? "",
            sha256: bundle.sha256,
            byteSize: Int(bundle.bytesLength),
            counts: counts ?? ContentManifestCounts(entries: 0, senses: 0, decks: 0, lessons: 0)
        )
    }
}

// MARK: - Active Content Pointer

public struct ActiveContentPointer: Codable, Sendable, Equatable {
    public let version: String
    public let databaseRelativePath: String
    public let manifestRelativePath: String
    public let activatedAt: Date

    enum CodingKeys: String, CodingKey {
        case version
        case databaseRelativePath = "database_relative_path"
        case manifestRelativePath = "manifest_relative_path"
        case activatedAt = "activated_at"
    }

    public init(
        version: String,
        databaseRelativePath: String,
        manifestRelativePath: String,
        activatedAt: Date = Date()
    ) {
        self.version = version
        self.databaseRelativePath = databaseRelativePath
        self.manifestRelativePath = manifestRelativePath
        self.activatedAt = activatedAt
    }
}

// MARK: - Content Bundle Manager Protocol

public protocol ContentBundleManagerProtocol: Sendable {
    func openActive() async throws -> ContentHandle
    func install(fileURL: URL, manifest: PublishedManifest) async throws -> InstallResult
}

extension ContentBundleManagerProtocol {
    public func install(fileURL: URL, manifest: ContentManifest) async throws -> InstallResult {
        try await install(fileURL: fileURL, manifest: PublishedManifest(contentManifest: manifest))
    }
}

// MARK: - SQLite Validation Extension

extension SQLiteContentRepository {
    public static func validateDatabase(at url: URL, expectedVersion: String? = nil) throws -> (schemaVersion: Int, contentVersion: Int) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ContentBundleError.invalidDatabase(reason: "File not found at \(url.path)")
        }

        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        let openResult = sqlite3_open_v2(url.path, &dbPointer, flags, nil)
        guard openResult == SQLITE_OK, let dbPointer else {
            let message = dbPointer != nil ? String(cString: sqlite3_errmsg(dbPointer)) : "Unknown open error"
            if let dbPointer { sqlite3_close(dbPointer) }
            throw ContentBundleError.invalidDatabase(reason: "Cannot open SQLite database: \(message)")
        }
        defer { sqlite3_close(dbPointer) }

        // 1. PRAGMA integrity_check
        var integrityStmt: OpaquePointer?
        let integrityResult = sqlite3_prepare_v2(dbPointer, "PRAGMA integrity_check;", -1, &integrityStmt, nil)
        guard integrityResult == SQLITE_OK, let integrityStmt else {
            throw ContentBundleError.invalidDatabase(reason: "Integrity check failed to prepare")
        }
        defer { sqlite3_finalize(integrityStmt) }

        if sqlite3_step(integrityStmt) == SQLITE_ROW {
            guard let ptr = sqlite3_column_text(integrityStmt, 0) else {
                throw ContentBundleError.invalidDatabase(reason: "Integrity check returned null")
            }
            let res = String(cString: ptr)
            if res != "ok" {
                throw ContentBundleError.invalidDatabase(reason: "Integrity check failed: \(res)")
            }
        } else {
            throw ContentBundleError.invalidDatabase(reason: "Integrity check returned no rows")
        }

        // 2. Required tables check
        let requiredTables: Set<String> = [
            "dataset_metadata", "entries", "senses", "pronunciations",
            "examples", "collocations", "decks", "lessons",
            "lesson_senses", "attributions", "sense_attributions", "retired_senses"
        ]

        var tablesStmt: OpaquePointer?
        let tablesResult = sqlite3_prepare_v2(dbPointer, "SELECT name FROM sqlite_master WHERE type='table';", -1, &tablesStmt, nil)
        guard tablesResult == SQLITE_OK, let tablesStmt else {
            throw ContentBundleError.invalidDatabase(reason: "Failed to query tables from database")
        }
        defer { sqlite3_finalize(tablesStmt) }

        var existingTables: Set<String> = []
        while sqlite3_step(tablesStmt) == SQLITE_ROW {
            if let ptr = sqlite3_column_text(tablesStmt, 0) {
                existingTables.insert(String(cString: ptr))
            }
        }

        let missingTables = requiredTables.subtracting(existingTables)
        if !missingTables.isEmpty {
            throw ContentBundleError.invalidDatabase(
                reason: "Missing required tables: \(missingTables.sorted().joined(separator: ", "))"
            )
        }

        // 3. PRAGMA foreign_key_check
        var fkStmt: OpaquePointer?
        let fkResult = sqlite3_prepare_v2(dbPointer, "PRAGMA foreign_key_check;", -1, &fkStmt, nil)
        guard fkResult == SQLITE_OK, let fkStmt else {
            throw ContentBundleError.invalidDatabase(reason: "Foreign key check failed to prepare")
        }
        defer { sqlite3_finalize(fkStmt) }

        if sqlite3_step(fkStmt) == SQLITE_ROW {
            throw ContentBundleError.invalidDatabase(reason: "Foreign key constraint violation detected")
        }

        // 4. Schema version & content version check
        var metaStmt: OpaquePointer?
        let metaSql = "SELECT dataset_schema_version, content_version FROM dataset_metadata LIMIT 1;"
        let metaResult = sqlite3_prepare_v2(dbPointer, metaSql, -1, &metaStmt, nil)
        guard metaResult == SQLITE_OK, let metaStmt else {
            throw ContentBundleError.invalidDatabase(reason: "Failed to read dataset_metadata")
        }
        defer { sqlite3_finalize(metaStmt) }

        guard sqlite3_step(metaStmt) == SQLITE_ROW else {
            throw ContentBundleError.invalidDatabase(reason: "dataset_metadata table is empty")
        }

        let schemaVersion = Int(sqlite3_column_int64(metaStmt, 0))
        let contentVersion = Int(sqlite3_column_int64(metaStmt, 1))

        if schemaVersion != 1 {
            throw ContentBundleError.unsupportedSchemaVersion(schemaVersion)
        }

        if let expectedVersion, let expectedInt = Int(expectedVersion), contentVersion != expectedInt {
            throw ContentBundleError.invalidDatabase(
                reason: "Content version mismatch: database has \(contentVersion), expected \(expectedVersion)"
            )
        }

        return (schemaVersion, contentVersion)
    }
}

// MARK: - Content Bundle Manager Implementation

public actor ContentBundleManager: ContentBundleManagerProtocol {
    public let rootURL: URL
    public let baselineURL: URL?
    public let baselineManifest: PublishedManifest?
    private let fileManager: FileManager

    public init(
        rootURL: URL,
        baselineURL: URL?,
        baselineManifest: PublishedManifest? = nil,
        fileManager: FileManager = .default
    ) {
        self.rootURL = rootURL
        self.baselineURL = baselineURL
        self.baselineManifest = baselineManifest
        self.fileManager = fileManager
    }

    private var releasesDirectoryURL: URL { rootURL.appendingPathComponent("releases", isDirectory: true) }
    private var activePointerURL: URL { rootURL.appendingPathComponent("active.json") }
    private var previousPointerURL: URL { rootURL.appendingPathComponent("previous.json") }

    // MARK: - Recovery State Machine
    // 1. active.json valid & verified -> load handle
    // 2. active.json invalid/missing -> try previous.json -> restore active.json & load handle
    // 3. both missing/invalid -> provision baseline -> write active.json -> load handle
    // 4. all fail -> throw ContentBundleError.missingBaseline

    public func openActive() async throws -> ContentHandle {
        // Step 1: Active pointer check
        if let activePointer = readPointer(from: activePointerURL),
           let handle = tryLoadHandle(for: activePointer) {
            return handle
        }

        // Step 2: Fallback pointer check
        if let previousPointer = readPointer(from: previousPointerURL),
           let handle = tryLoadHandle(for: previousPointer) {
            try? fileManager.removeItem(at: activePointerURL)
            try? fileManager.copyItem(at: previousPointerURL, to: activePointerURL)
            return handle
        }

        // Step 3: Baseline bundle provisioning
        if let baselineURL, fileManager.fileExists(atPath: baselineURL.path) {
            do {
                let manifest = try resolveBaselineManifest(for: baselineURL)
                _ = try SQLiteContentRepository.validateDatabase(at: baselineURL, expectedVersion: manifest.contentVersion)
                try stageAndActivate(fileURL: baselineURL, manifest: manifest)
                if let newPointer = readPointer(from: activePointerURL),
                   let handle = tryLoadHandle(for: newPointer) {
                    return handle
                }
            } catch {
                // Fall through to throw missingBaseline
            }
        }

        // Step 4: Missing baseline
        throw ContentBundleError.missingBaseline
    }

    public func install(fileURL: URL, manifest: PublishedManifest) async throws -> InstallResult {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw ContentBundleError.invalidDatabase(reason: "Bundle file not found at \(fileURL.path)")
        }

        let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
        let actualSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        guard actualSize == manifest.bundle.bytesLength else {
            throw ContentBundleError.fileLengthMismatch(
                expected: manifest.bundle.bytesLength,
                actual: actualSize
            )
        }

        let actualSHA256 = try computeSHA256(for: fileURL)
        guard actualSHA256.lowercased() == manifest.bundle.sha256.lowercased() else {
            throw ContentBundleError.checksumMismatch(
                expected: manifest.bundle.sha256.lowercased(),
                actual: actualSHA256.lowercased()
            )
        }

        guard manifest.datasetSchemaVersion == 1 else {
            throw ContentBundleError.unsupportedSchemaVersion(manifest.datasetSchemaVersion)
        }

        _ = try SQLiteContentRepository.validateDatabase(at: fileURL, expectedVersion: manifest.contentVersion)

        if let activePointer = readPointer(from: activePointerURL) {
            let comparison = Self.compareVersions(manifest.contentVersion, activePointer.version)
            if comparison == .orderedSame {
                return .alreadyActive(version: activePointer.version)
            } else if comparison == .orderedAscending {
                return .ignoredOlderVersion(
                    activeVersion: activePointer.version,
                    candidateVersion: manifest.contentVersion
                )
            }
        }

        try stageAndActivate(fileURL: fileURL, manifest: manifest)
        return .installed(version: manifest.contentVersion)
    }

    // MARK: - Private Helpers

    private func tryLoadHandle(for pointer: ActiveContentPointer) -> ContentHandle? {
        let dbURL = resolveURL(for: pointer.databaseRelativePath)
        let manifestURL = resolveURL(for: pointer.manifestRelativePath)

        guard fileManager.fileExists(atPath: dbURL.path), fileManager.fileExists(atPath: manifestURL.path) else {
            return nil
        }

        do {
            let manifestData = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(PublishedManifest.self, from: manifestData)
            _ = try SQLiteContentRepository.validateDatabase(at: dbURL, expectedVersion: manifest.contentVersion)
            let repo = try SQLiteContentRepository(url: dbURL)
            return ContentHandle(
                reader: repo,
                contentVersion: pointer.version,
                manifest: manifest,
                databaseURL: dbURL
            )
        } catch {
            return nil
        }
    }

    private func readPointer(from url: URL) -> ActiveContentPointer? {
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let pointer = try? JSONDecoder().decode(ActiveContentPointer.self, from: data) else {
            return nil
        }
        return pointer
    }

    private func stageAndActivate(fileURL: URL, manifest: PublishedManifest) throws {
        if !fileManager.fileExists(atPath: rootURL.path) {
            do {
                try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
            } catch {
                throw ContentBundleError.releaseDirectoryCreationFailed(reason: error.localizedDescription)
            }
        }

        let releaseDir = releasesDirectoryURL.appendingPathComponent(manifest.contentVersion, isDirectory: true)
        if !fileManager.fileExists(atPath: releaseDir.path) {
            do {
                try fileManager.createDirectory(at: releaseDir, withIntermediateDirectories: true)
            } catch {
                throw ContentBundleError.releaseDirectoryCreationFailed(reason: error.localizedDescription)
            }
        }

        let destDB = releaseDir.appendingPathComponent("content.sqlite")
        if fileManager.fileExists(atPath: destDB.path) {
            try? fileManager.removeItem(at: destDB)
        }
        do {
            try fileManager.copyItem(at: fileURL, to: destDB)
        } catch {
            throw ContentBundleError.activationFailed(reason: "Failed to copy database: \(error.localizedDescription)")
        }

        let destManifest = releaseDir.appendingPathComponent("manifest.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let manifestData = try encoder.encode(manifest)
            try manifestData.write(to: destManifest, options: .atomic)
        } catch {
            throw ContentBundleError.activationFailed(reason: "Failed to write manifest: \(error.localizedDescription)")
        }

        try fsyncFile(at: destDB)

        let tmpPointerURL = rootURL.appendingPathComponent("active.json.tmp.\(UUID().uuidString)")
        let newPointer = ActiveContentPointer(
            version: manifest.contentVersion,
            databaseRelativePath: "releases/\(manifest.contentVersion)/content.sqlite",
            manifestRelativePath: "releases/\(manifest.contentVersion)/manifest.json",
            activatedAt: Date()
        )

        do {
            let pointerData = try encoder.encode(newPointer)
            try pointerData.write(to: tmpPointerURL, options: .atomic)
            try fsyncFile(at: tmpPointerURL)
        } catch {
            throw ContentBundleError.activationFailed(reason: "Failed to write temporary pointer: \(error.localizedDescription)")
        }

        if fileManager.fileExists(atPath: activePointerURL.path) {
            if fileManager.fileExists(atPath: previousPointerURL.path) {
                try? fileManager.removeItem(at: previousPointerURL)
            }
            try? fileManager.copyItem(at: activePointerURL, to: previousPointerURL)
        }

        if rename(tmpPointerURL.path, activePointerURL.path) != 0 {
            do {
                _ = try fileManager.replaceItemAt(activePointerURL, withItemAt: tmpPointerURL)
            } catch {
                throw ContentBundleError.activationFailed(reason: "Atomic rename failed: \(error.localizedDescription)")
            }
        }
    }

    private func resolveURL(for pathString: String) -> URL {
        if pathString.hasPrefix("/") && fileManager.fileExists(atPath: pathString) {
            return URL(fileURLWithPath: pathString)
        }
        return rootURL.appendingPathComponent(pathString)
    }

    private func fsyncFile(at url: URL) throws {
        let descriptor = open(url.path, O_RDONLY)
        guard descriptor >= 0 else { return }
        defer { close(descriptor) }
        #if os(macOS) || os(iOS)
        _ = fcntl(descriptor, F_FULLFSYNC)
        #else
        _ = fsync(descriptor)
        #endif
    }

    private func computeSHA256(for fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        var hasher = SHA256()
        let bufferSize = 64 * 1024
        while autoreleasepool(invoking: {
            if let chunk = try? handle.read(upToCount: bufferSize), !chunk.isEmpty {
                hasher.update(data: chunk)
                return true
            }
            return false
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func resolveBaselineManifest(for url: URL) throws -> PublishedManifest {
        if let baselineManifest { return baselineManifest }
        let siblingManifest = url.deletingLastPathComponent().appendingPathComponent("manifest.json")
        if fileManager.fileExists(atPath: siblingManifest.path),
           let data = try? Data(contentsOf: siblingManifest),
           let decoded = try? JSONDecoder().decode(PublishedManifest.self, from: data) {
            return decoded
        }
        let siblingFixture = url.deletingLastPathComponent().appendingPathComponent("fixture-manifest.json")
        if fileManager.fileExists(atPath: siblingFixture.path),
           let data = try? Data(contentsOf: siblingFixture),
           let decoded = try? JSONDecoder().decode(PublishedManifest.self, from: data) {
            return decoded
        }
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        let actualSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        let actualSHA256 = try computeSHA256(for: url)
        let (schemaVersion, contentVersion) = try SQLiteContentRepository.validateDatabase(at: url)
        return PublishedManifest(
            contentVersion: String(contentVersion),
            datasetSchemaVersion: schemaVersion,
            bundle: PublishedBundleInfo(sha256: actualSHA256, bytesLength: actualSize, url: nil)
        )
    }

    public static func compareVersions(_ firstVersion: String, _ secondVersion: String) -> ComparisonResult {
        let parts1 = firstVersion.split(whereSeparator: { $0 == "." || $0 == "-" }).map(String.init)
        let parts2 = secondVersion.split(whereSeparator: { $0 == "." || $0 == "-" }).map(String.init)

        let maxCount = max(parts1.count, parts2.count)
        for index in 0..<maxCount {
            let part1 = index < parts1.count ? parts1[index] : ""
            let part2 = index < parts2.count ? parts2[index] : ""

            if let num1 = Int(part1), let num2 = Int(part2) {
                if num1 < num2 { return .orderedAscending }
                if num1 > num2 { return .orderedDescending }
            } else if let num1 = Int(part1) {
                if part2.isEmpty {
                    return num1 > 0 ? .orderedDescending : .orderedSame
                }
                return part1.compare(part2, options: .numeric)
            } else if let num2 = Int(part2) {
                if part1.isEmpty {
                    return num2 > 0 ? .orderedAscending : .orderedSame
                }
                return part1.compare(part2, options: .numeric)
            } else {
                let comp = part1.compare(part2, options: .numeric)
                if comp != .orderedSame {
                    return comp
                }
            }
        }
        return .orderedSame
    }
}
