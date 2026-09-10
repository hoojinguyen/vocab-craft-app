import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftDataMacros) || canImport(SwiftData)
public enum AppMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }
    public static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
        ]
    }
}

public struct SharedAppGroupContainer {
    public static let appGroupID = "group.com.hoojinguyen.vocabcraft"

    public static func persistedStoreURL(fileManager: FileManager = .default) -> URL {
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return groupURL.appendingPathComponent("user_progress.sqlite")
        } else if let baseSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appSupportURL = baseSupportURL.appendingPathComponent("VocabCraft", isDirectory: true)
            return appSupportURL.appendingPathComponent("user_progress.sqlite")
        } else {
            return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("user_progress.sqlite")
        }
    }

    @discardableResult
    public static func quarantineCorruptStoreFiles(
        from storeURL: URL,
        fileManager: FileManager = .default
    ) -> URL? {
        guard fileManager.fileExists(atPath: storeURL.path) else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss_SSS"
        let timestamp = formatter.string(from: Date())

        let directory = storeURL.deletingLastPathComponent()
        let baseName = storeURL.deletingPathExtension().lastPathComponent
        let backupFileName = "\(baseName)_backup_\(timestamp).sqlite"
        let backupURL = directory.appendingPathComponent(backupFileName)

        let cleanupFailedBackup: () -> Void = {
            try? fileManager.removeItem(at: backupURL)
            let backupWal = URL(fileURLWithPath: backupURL.path + "-wal")
            try? fileManager.removeItem(at: backupWal)
            let backupShm = URL(fileURLWithPath: backupURL.path + "-shm")
            try? fileManager.removeItem(at: backupShm)
        }

        do {
            if fileManager.fileExists(atPath: backupURL.path) {
                try fileManager.removeItem(at: backupURL)
            }
            try fileManager.copyItem(at: storeURL, to: backupURL)
        } catch {
            return nil
        }

        let walCandidates = [
            URL(fileURLWithPath: storeURL.path + "-wal"),
            storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        ]
        for wal in walCandidates where fileManager.fileExists(atPath: wal.path) {
            let backupWal = URL(fileURLWithPath: backupURL.path + "-wal")
            do {
                if fileManager.fileExists(atPath: backupWal.path) {
                    try fileManager.removeItem(at: backupWal)
                }
                try fileManager.copyItem(at: wal, to: backupWal)
            } catch {
                cleanupFailedBackup()
                return nil
            }
            break
        }

        let shmCandidates = [
            URL(fileURLWithPath: storeURL.path + "-shm"),
            storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
        ]
        for shm in shmCandidates where fileManager.fileExists(atPath: shm.path) {
            let backupShm = URL(fileURLWithPath: backupURL.path + "-shm")
            do {
                if fileManager.fileExists(atPath: backupShm.path) {
                    try fileManager.removeItem(at: backupShm)
                }
                try fileManager.copyItem(at: shm, to: backupShm)
            } catch {
                cleanupFailedBackup()
                return nil
            }
            break
        }

        return backupURL
    }

    public static func createContainer(
        configuration: ModelConfiguration? = nil,
        storeURL: URL? = nil,
        inMemory: Bool = false
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)

        let isTesting = NSClassFromString("XCTestCase") != nil
        if inMemory || (isTesting && configuration == nil && storeURL == nil) {
            let config = configuration ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
        }

        let targetURL = storeURL ?? configuration?.url ?? persistedStoreURL()

        try? FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let targetConfig = configuration ?? ModelConfiguration(schema: schema, url: targetURL)
        do {
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [targetConfig])
        } catch {
            let backupURL = quarantineCorruptStoreFiles(from: targetURL)
            throw DatabaseStoreError.storeInitializationFailed(
                description: error.localizedDescription,
                backupURL: backupURL
            )
        }
    }

    public static func resetStoreWithQuarantine(
        storeURL: URL = persistedStoreURL(),
        configuration: ModelConfiguration? = nil,
        fileManager: FileManager = .default
    ) throws -> ModelContainer {
        if fileManager.fileExists(atPath: storeURL.path) {
            guard quarantineCorruptStoreFiles(from: storeURL, fileManager: fileManager) != nil else {
                throw DatabaseStoreError.quarantineBackupFailed(
                    description: AppLocalized.string("app.database.error.quarantine_before_reset_failed")
                )
            }
        }

        let walCandidates = [
            URL(fileURLWithPath: storeURL.path + "-wal"),
            storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
        ]
        let shmCandidates = [
            URL(fileURLWithPath: storeURL.path + "-shm"),
            storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
        ]

        try? fileManager.removeItem(at: storeURL)
        for wal in walCandidates {
            try? fileManager.removeItem(at: wal)
        }
        for shm in shmCandidates {
            try? fileManager.removeItem(at: shm)
        }

        let schema = Schema(versionedSchema: SchemaV2.self)
        try? fileManager.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let targetConfig = configuration ?? ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [targetConfig])
        } catch {
            throw DatabaseStoreError.manualResetFailed(description: error.localizedDescription)
        }
    }

    public static func hasPersistedStore(fileManager: FileManager = .default) -> Bool {
        let url = persistedStoreURL(fileManager: fileManager)
        return fileManager.fileExists(atPath: url.path)
    }

    @MainActor
    public static func hasPersistedUserRecords(in container: ModelContainer) -> Bool {
        let context = container.mainContext
        var wordDesc = FetchDescriptor<UserWordProgress>()
        wordDesc.fetchLimit = 1
        if (try? context.fetchCount(wordDesc)) ?? 0 > 0 { return true }

        var stageDesc = FetchDescriptor<UserStageProgress>()
        stageDesc.fetchLimit = 1
        if (try? context.fetchCount(stageDesc)) ?? 0 > 0 { return true }

        var sessionDesc = FetchDescriptor<ReflexSessionLog>()
        sessionDesc.fetchLimit = 1
        if (try? context.fetchCount(sessionDesc)) ?? 0 > 0 { return true }

        var attemptDesc = FetchDescriptor<QuickReflexAttemptRecord>()
        attemptDesc.fetchLimit = 1
        if (try? context.fetchCount(attemptDesc)) ?? 0 > 0 { return true }

        return false
    }
}
#else
public struct SharedAppGroupContainer {
    public static let appGroupID = "group.com.hoojinguyen.vocabcraft"
    public static func createContainer(
        configuration: Any? = nil,
        storeURL: URL? = nil,
        inMemory: Bool = false
    ) throws -> Any? {
        nil
    }

    public static func persistedStoreURL(fileManager: FileManager = .default) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("user_progress.sqlite")
    }

    public static func hasPersistedStore(fileManager: FileManager = .default) -> Bool {
        false
    }

    @MainActor
    public static func hasPersistedUserRecords(in container: Any?) -> Bool {
        false
    }

    @discardableResult
    public static func quarantineCorruptStoreFiles(from storeURL: URL, fileManager: FileManager = .default) -> URL? {
        nil
    }

    public static func resetStoreWithQuarantine(
        storeURL: URL = persistedStoreURL(),
        configuration: Any? = nil,
        fileManager: FileManager = .default
    ) throws -> Any? {
        nil
    }
}
#endif
