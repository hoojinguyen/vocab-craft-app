import Foundation
import SwiftData

public struct SharedAppGroupContainer {
    public static let appGroupID = "group.com.hoojinguyen.vocabcraft"

    public static func createContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            UserWordProgress.self,
            ReflexSessionLog.self,
            WidgetCurrentState.self
        ])

        if inMemory {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [config])
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
        return try ModelContainer(for: schema, configurations: [config])
    }
}
