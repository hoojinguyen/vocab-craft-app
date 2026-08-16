import Foundation
import SwiftData

public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [UserWordProgress.self, ReflexSessionLog.self, WidgetCurrentState.self]
    }
}

public enum SchemaV2: VersionedSchema {
    public static var versionIdentifier = Schema.Version(2, 0, 0)
    public static var models: [any PersistentModel.Type] {
        [UserWordProgress.self, ReflexSessionLog.self, WidgetCurrentState.self, QuickReflexAttemptRecord.self]
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
        return try ModelContainer(for: schema, migrationPlan: AppMigrationPlan.self, configurations: [config])
    }
}
