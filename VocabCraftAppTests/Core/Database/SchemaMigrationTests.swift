#if canImport(SwiftDataMacros) || canImport(SwiftData)
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

    @MainActor
    func test_v1_to_v2_migration_preserves_multiple_word_progress_and_logs() throws {
        // Step 1: Initialize container with SchemaV1 and insert multiple baseline records
        let baseline = try seedSchemaV1Baseline(storeURL: storeURL)

        // Step 2: Open with SchemaV2 using AppMigrationPlan on the exact same store URL
        let v2Schema = Schema(versionedSchema: SchemaV2.self)
        let v2Config = ModelConfiguration(schema: v2Schema, url: storeURL)
        let v2Container = try ModelContainer(for: v2Schema, migrationPlan: AppMigrationPlan.self, configurations: [v2Config])

        // Step 3: Fetch and verify migrated records
        try verifyMigratedWords(
            in: v2Container,
            date1: baseline.date1,
            date2: baseline.date2,
            date3: baseline.date3
        )

        // Step 4: Verify ReflexSessionLog records
        try verifyMigratedSessions(
            in: v2Container,
            session1ID: baseline.session1ID,
            session2ID: baseline.session2ID
        )

        // Step 5: Verify WidgetCurrentState migration preserves all attributes
        try verifyMigratedWidget(
            in: v2Container,
            expectedDate: baseline.widgetDate
        )

        // Step 6: Verify new V2 entity types (UserStageProgress, QuickReflexAttemptRecord)
        try verifyNewV2EntityOperations(in: v2Container)
    }

    @MainActor
    private func seedSchemaV1Baseline(storeURL: URL) throws -> (
        date1: Date,
        date2: Date,
        date3: Date,
        session1ID: UUID,
        session2ID: UUID,
        widgetDate: Date
    ) {
        let v1Schema = Schema(versionedSchema: SchemaV1.self)
        let v1Config = ModelConfiguration(schema: v1Schema, url: storeURL)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Config])

        let date1 = Date(timeIntervalSince1970: 1_700_000_000)
        let date2 = Date(timeIntervalSince1970: 1_705_000_000)
        let date3 = Date(timeIntervalSince1970: 1_690_000_000)

        let word101 = SchemaV1.UserWordProgress(
            wordId: 101,
            repetitionLevel: 1,
            interval: 2.0,
            easeFactor: 2.3,
            nextReviewDate: date1,
            isBookmarked: true,
            isMastered: false,
            correctStreak: 4,
            mistakeCount: 2,
            lastReviewedAt: Date(timeIntervalSince1970: 1_699_900_000),
            modeSuccessCountsRaw: "s:3,t:1"
        )

        let word102 = SchemaV1.UserWordProgress(
            wordId: 102,
            repetitionLevel: 5,
            interval: 21.0,
            easeFactor: 2.8,
            nextReviewDate: date2,
            isBookmarked: false,
            isMastered: true,
            correctStreak: 12,
            mistakeCount: 0,
            lastReviewedAt: Date(timeIntervalSince1970: 1_704_900_000),
            modeSuccessCountsRaw: "s:10,t:8,m:5,l:6"
        )

        let word103 = SchemaV1.UserWordProgress(
            wordId: 103,
            repetitionLevel: 0,
            interval: 0.0,
            easeFactor: 2.1,
            nextReviewDate: date3,
            isBookmarked: true,
            isMastered: false,
            correctStreak: 0,
            mistakeCount: 5,
            lastReviewedAt: nil,
            modeSuccessCountsRaw: "{}"
        )

        v1Container.mainContext.insert(word101)
        v1Container.mainContext.insert(word102)
        v1Container.mainContext.insert(word103)

        let session1ID = UUID()
        let session1 = SchemaV1.ReflexSessionLog(
            id: session1ID,
            drillId: 201,
            responseTimeMs: 620,
            accuracyScore: 1.0,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let session2ID = UUID()
        let session2 = SchemaV1.ReflexSessionLog(
            id: session2ID,
            drillId: 202,
            responseTimeMs: 1100,
            accuracyScore: 0.75,
            timestamp: Date(timeIntervalSince1970: 1_700_050_000)
        )

        let widgetDate = Date(timeIntervalSince1970: 1_705_000_000)
        let widget = SchemaV1.WidgetCurrentState(
            id: "current",
            activeWord: "serendipity",
            phonetic: "/ˌser.ənˈdɪp.ə.ti/",
            meaningVi: "sự tình cờ may mắn",
            exampleSentence: "A fortunate stroke of serendipity.",
            updatedAt: widgetDate
        )

        v1Container.mainContext.insert(session1)
        v1Container.mainContext.insert(session2)
        v1Container.mainContext.insert(widget)

        try v1Container.mainContext.save()

        return (date1, date2, date3, session1ID, session2ID, widgetDate)
    }

    @MainActor
    private func verifyMigratedWidget(
        in v2Container: ModelContainer,
        expectedDate: Date
    ) throws {
        let widgetDesc = FetchDescriptor<WidgetCurrentState>()
        let widgets = try v2Container.mainContext.fetch(widgetDesc)
        XCTAssertEqual(widgets.count, 1)

        let migrated = try XCTUnwrap(widgets.first)
        XCTAssertEqual(migrated.id, "current")
        XCTAssertEqual(migrated.lemma, "serendipity")
        XCTAssertEqual(migrated.ipaUs, "/ˌser.ənˈdɪp.ə.ti/")
        XCTAssertEqual(migrated.definitionVi, "sự tình cờ may mắn")
        XCTAssertEqual(migrated.exampleEn, "A fortunate stroke of serendipity.")
        XCTAssertEqual(migrated.lastUpdated, expectedDate)
    }

    @MainActor
    private func verifyMigratedWords(
        in v2Container: ModelContainer,
        date1: Date,
        date2: Date,
        date3: Date
    ) throws {
        let wordDesc = FetchDescriptor<UserWordProgress>(sortBy: [SortDescriptor(\.wordId, order: .forward)])
        let words = try v2Container.mainContext.fetch(wordDesc)
        XCTAssertEqual(words.count, 3)

        let migrated101 = words.first(where: { $0.wordId == 101 })
        XCTAssertNotNil(migrated101)
        XCTAssertEqual(migrated101?.wordId, 101)
        XCTAssertEqual(migrated101?.correctStreak, 4)
        XCTAssertEqual(migrated101?.consecutiveCorrectStreak, 4)
        XCTAssertEqual(migrated101?.isBookmarked, true)
        XCTAssertEqual(migrated101?.isMastered, false)
        XCTAssertEqual(migrated101?.mistakeCount, 2)
        XCTAssertEqual(migrated101?.easeFactor, 2.3)
        XCTAssertEqual(migrated101?.nextReviewDate, date1)
        XCTAssertEqual(migrated101?.modeSuccessCountsRaw, "s:3,t:1")
        XCTAssertEqual(migrated101?.cefrLevel, "A1")
        XCTAssertEqual(migrated101?.masteryLevel, 0)
        XCTAssertEqual(migrated101?.intervalDays, 1)
        XCTAssertEqual(migrated101?.needsReview, false)
        XCTAssertNil(migrated101?.sourceDeckId)
        XCTAssertNil(migrated101?.sourceNodeId)
        XCTAssertEqual(migrated101?.practicedModesRaw, "")

        let migrated102 = words.first(where: { $0.wordId == 102 })
        XCTAssertNotNil(migrated102)
        XCTAssertEqual(migrated102?.wordId, 102)
        XCTAssertEqual(migrated102?.correctStreak, 12)
        XCTAssertEqual(migrated102?.consecutiveCorrectStreak, 12)
        XCTAssertEqual(migrated102?.isBookmarked, false)
        XCTAssertEqual(migrated102?.isMastered, true)
        XCTAssertEqual(migrated102?.mistakeCount, 0)
        XCTAssertEqual(migrated102?.easeFactor, 2.8)
        XCTAssertEqual(migrated102?.nextReviewDate, date2)
        XCTAssertEqual(migrated102?.modeSuccessCountsRaw, "s:10,t:8,m:5,l:6")

        let migrated103 = words.first(where: { $0.wordId == 103 })
        XCTAssertNotNil(migrated103)
        XCTAssertEqual(migrated103?.wordId, 103)
        XCTAssertEqual(migrated103?.correctStreak, 0)
        XCTAssertEqual(migrated103?.consecutiveCorrectStreak, 0)
        XCTAssertEqual(migrated103?.isBookmarked, true)
        XCTAssertEqual(migrated103?.isMastered, false)
        XCTAssertEqual(migrated103?.mistakeCount, 5)
        XCTAssertEqual(migrated103?.easeFactor, 2.1)
        XCTAssertEqual(migrated103?.nextReviewDate, date3)
        XCTAssertEqual(migrated103?.modeSuccessCountsRaw, "{}")
    }

    @MainActor
    private func verifyMigratedSessions(
        in v2Container: ModelContainer,
        session1ID: UUID,
        session2ID: UUID
    ) throws {
        let sessionDesc = FetchDescriptor<ReflexSessionLog>(sortBy: [SortDescriptor(\.drillId, order: .forward)])
        let sessions = try v2Container.mainContext.fetch(sessionDesc)
        XCTAssertEqual(sessions.count, 2)

        let migratedSession1 = sessions.first(where: { $0.id == session1ID })
        XCTAssertNotNil(migratedSession1)
        XCTAssertEqual(migratedSession1?.drillId, 201)
        XCTAssertEqual(migratedSession1?.responseTimeMs, 620)
        XCTAssertEqual(migratedSession1?.accuracyScore, 1.0)
        XCTAssertEqual(migratedSession1?.timestamp, Date(timeIntervalSince1970: 1_700_000_000))

        let migratedSession2 = sessions.first(where: { $0.id == session2ID })
        XCTAssertNotNil(migratedSession2)
        XCTAssertEqual(migratedSession2?.drillId, 202)
        XCTAssertEqual(migratedSession2?.responseTimeMs, 1100)
        XCTAssertEqual(migratedSession2?.accuracyScore, 0.75)
        XCTAssertEqual(migratedSession2?.timestamp, Date(timeIntervalSince1970: 1_700_050_000))
    }

    @MainActor
    private func verifyNewV2EntityOperations(in v2Container: ModelContainer) throws {
        let stageProgress = UserStageProgress(
            stageId: "stage_test_multi_1",
            deckId: "deck_test_multi",
            isCompleted: true,
            score: 95,
            progressFraction: 1.0,
            completedAt: Date(timeIntervalSince1970: 1_710_000_000)
        )
        v2Container.mainContext.insert(stageProgress)

        let attemptId = UUID()
        let attemptRecord = QuickReflexAttemptRecord(
            id: attemptId,
            wordId: 101,
            recallWordTimeMs: 450,
            collocationTimeMs: 300,
            produceSentenceTimeMs: 700,
            recallWordSucceeded: true,
            collocationSucceeded: true,
            produceSentenceSucceeded: true,
            shadowPronunciationScore: 0.92,
            maxHintLevel: 1,
            inputModeRawValue: "voice",
            retryCount: 0,
            confidenceRawValue: "high",
            timestamp: Date(timeIntervalSince1970: 1_710_001_000)
        )
        v2Container.mainContext.insert(attemptRecord)
        try v2Container.mainContext.save()

        let stageDesc = FetchDescriptor<UserStageProgress>(predicate: #Predicate { $0.stageId == "stage_test_multi_1" })
        let fetchedStages = try v2Container.mainContext.fetch(stageDesc)
        XCTAssertEqual(fetchedStages.count, 1)
        XCTAssertEqual(fetchedStages.first?.stageId, "stage_test_multi_1")
        XCTAssertEqual(fetchedStages.first?.deckId, "deck_test_multi")
        XCTAssertEqual(fetchedStages.first?.isCompleted, true)
        XCTAssertEqual(fetchedStages.first?.score, 95)
        XCTAssertEqual(fetchedStages.first?.progressFraction, 1.0)

        let attemptDesc = FetchDescriptor<QuickReflexAttemptRecord>(predicate: #Predicate { $0.id == attemptId })
        let fetchedAttempts = try v2Container.mainContext.fetch(attemptDesc)
        XCTAssertEqual(fetchedAttempts.count, 1)
        XCTAssertEqual(fetchedAttempts.first?.wordId, 101)
        XCTAssertEqual(fetchedAttempts.first?.recallWordTimeMs, 450)
        XCTAssertEqual(fetchedAttempts.first?.collocationTimeMs, 300)
        XCTAssertEqual(fetchedAttempts.first?.produceSentenceTimeMs, 700)
        XCTAssertEqual(fetchedAttempts.first?.recallWordSucceeded, true)
        XCTAssertEqual(fetchedAttempts.first?.collocationSucceeded, true)
        XCTAssertEqual(fetchedAttempts.first?.produceSentenceSucceeded, true)
        XCTAssertEqual(fetchedAttempts.first?.shadowPronunciationScore, 0.92)
    }

    func test_v2_container_quarantines_corrupt_store_and_throws_store_init_failed() throws {
        let corruptStoreURL = tempDirectory.appendingPathComponent("corrupt_schema_test.sqlite")
        try "CORRUPT_SQLITE_DATA".write(to: corruptStoreURL, atomically: true, encoding: .utf8)

        XCTAssertThrowsError(
            try SharedAppGroupContainer.createContainer(storeURL: corruptStoreURL)
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
                XCTFail("Expected .storeInitializationFailed, got \(dbError)")
            }
        }
    }
}
#endif
