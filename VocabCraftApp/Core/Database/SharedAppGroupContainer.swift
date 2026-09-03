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

    public static func createContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV2.self)

        let isTesting = NSClassFromString("XCTestCase") != nil
        if inMemory || isTesting {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
        }

        let storeURL = persistedStoreURL()

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
        let url = persistedStoreURL(fileManager: fileManager)
        return fileManager.fileExists(atPath: url.path)
    }

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
    public static func createContainer(inMemory: Bool = false) throws -> Any? {
        nil
    }

    public static func persistedStoreURL(fileManager: FileManager = .default) -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("user_progress.sqlite")
    }

    public static func hasPersistedStore(fileManager: FileManager = .default) -> Bool {
        false
    }

    public static func hasPersistedUserRecords(in container: Any?) -> Bool {
        false
    }
}
#endif
