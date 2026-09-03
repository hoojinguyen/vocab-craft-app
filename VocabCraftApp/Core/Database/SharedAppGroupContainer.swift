import Foundation
#if canImport(SwiftData)
import SwiftData
#endif

#if canImport(SwiftDataMacros)
public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [UserWordProgress.self, ReflexSessionLog.self, WidgetCurrentState.self]
    }
}

public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier = Schema.Version(2, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [
            UserWordProgress.self,
            UserStageProgress.self,
            ReflexSessionLog.self,
            WidgetCurrentState.self,
            QuickReflexAttemptRecord.self
        ]
    }
}

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

    public static func createContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)

        let isTesting = NSClassFromString("XCTestCase") != nil
        if inMemory || isTesting {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
        }

        let storeURL: URL
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            storeURL = groupURL.appendingPathComponent("user_progress.sqlite")
        } else if let baseSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appSupportURL = baseSupportURL.appendingPathComponent("VocabCraft", isDirectory: true)
            storeURL = appSupportURL.appendingPathComponent("user_progress.sqlite")
        } else {
            storeURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("user_progress.sqlite")
        }

        try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
        } catch {
            print("SharedAppGroupContainer: Encountered migration or store loading error (\(error)). Resetting store to recover...")
            let shmURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm")
            let walURL = storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal")
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: shmURL)
            try? FileManager.default.removeItem(at: walURL)
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
        }
    }

    public static func hasPersistedStore(fileManager: FileManager = .default) -> Bool {
        let candidateURLs: [URL?] = [
            fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?.appendingPathComponent("user_progress.sqlite"),
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent("VocabCraft", isDirectory: true).appendingPathComponent("user_progress.sqlite")
        ]
        return candidateURLs.compactMap { $0 }.contains { fileManager.fileExists(atPath: $0.path) }
    }
}
#else
public struct SharedAppGroupContainer {
    public static let appGroupID = "group.com.hoojinguyen.vocabcraft"
    public static func createContainer(inMemory: Bool = false) throws -> Any? {
        nil
    }

    public static func hasPersistedStore(fileManager: FileManager = .default) -> Bool {
        false
    }
}
#endif
