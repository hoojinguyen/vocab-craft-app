#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
@testable import VocabCraftApp
import XCTest

final class SchemaMigrationTests: XCTestCase {
    private var tempDirectory: URL!
    private var storeURL: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        storeURL = tempDirectory.appendingPathComponent("test_migration.sqlite")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    @MainActor
    func test_v1_to_v2_lightweight_migration_preserves_records() throws {
        // Step 1: Initialize container with SchemaV1 and insert baseline data
        let v1Schema = Schema(versionedSchema: SchemaV1.self)
        let v1Config = ModelConfiguration(schema: v1Schema, url: storeURL)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Config])

        let v1Word = SchemaV1.UserWordProgress(
            wordId: 101,
            repetitionLevel: 2,
            interval: 6.0,
            easeFactor: 2.6,
            nextReviewDate: Date(),
            isBookmarked: true,
            isMastered: false,
            correctStreak: 3,
            mistakeCount: 1
        )
        v1Container.mainContext.insert(v1Word)

        let sessionID = UUID()
        let v1Session = SchemaV1.ReflexSessionLog(
            id: sessionID,
            drillId: 202,
            responseTimeMs: 850,
            accuracyScore: 0.95,
            timestamp: Date()
        )
        v1Container.mainContext.insert(v1Session)
        try v1Container.mainContext.save()

        // Step 2: Open with SchemaV2 using AppMigrationPlan
        let v2Schema = Schema(versionedSchema: SchemaV2.self)
        let v2Config = ModelConfiguration(schema: v2Schema, url: storeURL)
        let v2Container = try ModelContainer(for: v2Schema, migrationPlan: AppMigrationPlan.self, configurations: [v2Config])

        // Step 3: Verify migrated records exist and match
        let wordDesc = FetchDescriptor<UserWordProgress>(predicate: #Predicate { $0.wordId == 101 })
        let words = try v2Container.mainContext.fetch(wordDesc)
        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(words.first?.wordId, 101)
        XCTAssertEqual(words.first?.correctStreak, 3)
        XCTAssertTrue(words.first?.isBookmarked ?? false)

        let sessionDesc = FetchDescriptor<ReflexSessionLog>(predicate: #Predicate { $0.id == sessionID })
        let sessions = try v2Container.mainContext.fetch(sessionDesc)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions.first?.drillId, 202)

        // Step 4: Verify new V2 model can be saved
        let stageProgress = UserStageProgress(stageId: "stage_test_1", deckId: "deck_test", isCompleted: true, score: 100)
        v2Container.mainContext.insert(stageProgress)
        try v2Container.mainContext.save()

        let stageDesc = FetchDescriptor<UserStageProgress>(predicate: #Predicate { $0.stageId == "stage_test_1" })
        let stages = try v2Container.mainContext.fetch(stageDesc)
        XCTAssertEqual(stages.count, 1)
    }
}
#endif
