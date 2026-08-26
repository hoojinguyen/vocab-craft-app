import SwiftData
@testable import VocabCraftApp
import XCTest

@MainActor
final class SwiftDataModelsTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try SharedAppGroupContainer.createContainer(inMemory: true)
        context = container.mainContext
    }

    override func tearDownWithError() throws {
        context = nil
        container = nil
        try super.tearDownWithError()
    }

    // MARK: - App Group Container Tests

    func testAppGroupContainerInitializationInMemory() throws {
        let testContainer = try SharedAppGroupContainer.createContainer(inMemory: true)
        XCTAssertNotNil(testContainer)
    }

    func testAppGroupContainerInitializationDisk() throws {
        let testContainer = try SharedAppGroupContainer.createContainer(inMemory: false)
        XCTAssertNotNil(testContainer)
    }

    func testAppGroupIDConstant() {
        XCTAssertEqual(SharedAppGroupContainer.appGroupID, "group.com.hoojinguyen.vocabcraft")
    }

    func testSchemaV1StoreMigratesToV2AndRetainsProgress() throws {
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuickReflexMigration-\(UUID().uuidString).sqlite")
        defer {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-shm"))
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: storeURL.path + "-wal"))
        }

        let expectedReviewDate = Date(timeIntervalSince1970: 1_700_000_000)
        do {
            let schema = Schema(versionedSchema: SchemaV1.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let v1Container = try ModelContainer(for: schema, configurations: [configuration])
            let v1Context = v1Container.mainContext
            v1Context.insert(UserWordProgress(
                wordId: 909,
                masteryLevel: 3,
                easeFactor: 2.7,
                intervalDays: 12,
                nextReviewDate: expectedReviewDate,
                lastReviewDate: expectedReviewDate,
                totalReviews: 8
            ))
            try v1Context.save()
        }

        let v2Schema = Schema(versionedSchema: SchemaV2.self)
        let v2Configuration = ModelConfiguration(schema: v2Schema, url: storeURL)
        let v2Container = try ModelContainer(
            for: v2Schema,
            migrationPlan: AppMigrationPlan.self,
            configurations: [v2Configuration]
        )
        let v2Context = v2Container.mainContext

        let progress = try v2Context.fetch(FetchDescriptor<UserWordProgress>(
            predicate: #Predicate { $0.wordId == 909 }
        ))
        XCTAssertEqual(progress.count, 1)
        XCTAssertEqual(progress.first?.masteryLevel, 3)
        XCTAssertEqual(progress.first?.nextReviewDate, expectedReviewDate)

        let attempt = QuickReflexAttemptRecord(
            wordId: 909,
            retrieveTimeMs: 900,
            useTimeMs: 1_500,
            retrieveSucceeded: true,
            useSucceeded: true,
            maxHintLevel: 0,
            inputModeRawValue: "voice",
            retryCount: 0,
            confidenceRawValue: "comfortable"
        )
        v2Context.insert(attempt)
        try v2Context.save()

        XCTAssertEqual(try v2Context.fetch(FetchDescriptor<QuickReflexAttemptRecord>()).count, 1)
    }

    // MARK: - UserWordProgress Tests

    func testUserWordProgressCreationAndDefaults() {
        let progress = UserWordProgress(wordId: 101)
        XCTAssertEqual(progress.wordId, 101)
        XCTAssertEqual(progress.masteryLevel, 0)
        XCTAssertEqual(progress.easeFactor, 2.5, accuracy: 0.001)
        XCTAssertEqual(progress.intervalDays, 1)
        XCTAssertEqual(progress.totalReviews, 0)
        XCTAssertNotNil(progress.nextReviewDate)
        XCTAssertNotNil(progress.lastReviewDate)
    }

    func testUserWordProgressCustomInitialization() {
        let now = Date()
        let progress = UserWordProgress(
            wordId: 202,
            masteryLevel: 3,
            easeFactor: 2.1,
            intervalDays: 6,
            nextReviewDate: now,
            lastReviewDate: now,
            totalReviews: 5
        )
        XCTAssertEqual(progress.wordId, 202)
        XCTAssertEqual(progress.masteryLevel, 3)
        XCTAssertEqual(progress.easeFactor, 2.1, accuracy: 0.001)
        XCTAssertEqual(progress.intervalDays, 6)
        XCTAssertEqual(progress.nextReviewDate, now)
        XCTAssertEqual(progress.lastReviewDate, now)
        XCTAssertEqual(progress.totalReviews, 5)
    }

    func testUserWordProgressNewFieldsDefaultsAndCustomInitialization() {
        let defaultProgress = UserWordProgress(wordId: 105)
        XCTAssertFalse(defaultProgress.needsReview)
        XCTAssertEqual(defaultProgress.mistakeCount, 0)
        XCTAssertNil(defaultProgress.sourceDeckId)
        XCTAssertNil(defaultProgress.sourceNodeId)

        let customProgress = UserWordProgress(
            wordId: 106,
            needsReview: true,
            mistakeCount: 3,
            sourceDeckId: "deck_daily",
            sourceNodeId: "stage_daily_1"
        )
        XCTAssertTrue(customProgress.needsReview)
        XCTAssertEqual(customProgress.mistakeCount, 3)
        XCTAssertEqual(customProgress.sourceDeckId, "deck_daily")
        XCTAssertEqual(customProgress.sourceNodeId, "stage_daily_1")
    }

    func testUserWordProgressCRUD() throws {
        let progress = UserWordProgress(
            wordId: 303,
            masteryLevel: 1,
            easeFactor: 2.4,
            intervalDays: 2,
            needsReview: true,
            mistakeCount: 2,
            sourceDeckId: "deck_daily",
            sourceNodeId: "stage_daily_1"
        )
        context.insert(progress)
        try context.save()

        let descriptor = FetchDescriptor<UserWordProgress>(predicate: #Predicate { $0.wordId == 303 })
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.masteryLevel, 1)
        XCTAssertEqual(fetched.first?.needsReview, true)
        XCTAssertEqual(fetched.first?.mistakeCount, 2)
        XCTAssertEqual(fetched.first?.sourceDeckId, "deck_daily")
        XCTAssertEqual(fetched.first?.sourceNodeId, "stage_daily_1")

        // Update
        fetched.first?.masteryLevel = 4
        fetched.first?.totalReviews = 10
        fetched.first?.needsReview = false
        fetched.first?.mistakeCount = 0
        try context.save()

        let updated = try context.fetch(descriptor)
        XCTAssertEqual(updated.first?.masteryLevel, 4)
        XCTAssertEqual(updated.first?.totalReviews, 10)
        XCTAssertEqual(updated.first?.needsReview, false)
        XCTAssertEqual(updated.first?.mistakeCount, 0)

        // Delete
        if let toDelete = updated.first {
            context.delete(toDelete)
            try context.save()
        }

        let afterDelete = try context.fetch(descriptor)
        XCTAssertEqual(afterDelete.count, 0)
    }

    // MARK: - UserStageProgress Tests

    func testUserStageProgressCreationAndDefaults() {
        let now = Date()
        let progress = UserStageProgress(stageId: "stage_food_1", deckId: "deck_food")
        XCTAssertEqual(progress.stageId, "stage_food_1")
        XCTAssertEqual(progress.deckId, "deck_food")
        XCTAssertFalse(progress.isCompleted)
        XCTAssertEqual(progress.score, 0)
        XCTAssertEqual(progress.progressFraction, 0.0, accuracy: 0.001)
        XCTAssertLessThanOrEqual(progress.completedAt.timeIntervalSince(now), 1.0)
    }

    func testUserStageProgressCRUD() throws {
        let testSchema = Schema([UserStageProgress.self])
        let testConfig = ModelConfiguration(isStoredInMemoryOnly: true)
        let testContainer = try ModelContainer(for: testSchema, configurations: [testConfig])
        let stageContext = testContainer.mainContext

        let stage = UserStageProgress(
            stageId: "stage_travel_1",
            deckId: "deck_travel",
            isCompleted: true,
            score: 85,
            progressFraction: 1.0
        )
        stageContext.insert(stage)
        try stageContext.save()

        let descriptor = FetchDescriptor<UserStageProgress>(predicate: #Predicate { $0.stageId == "stage_travel_1" })
        let fetched = try stageContext.fetch(descriptor)
        let fetchedRecord = try XCTUnwrap(fetched.first)
        XCTAssertEqual(fetchedRecord.stageId, "stage_travel_1")
        XCTAssertEqual(fetchedRecord.deckId, "deck_travel")
        XCTAssertEqual(fetchedRecord.isCompleted, true)
        XCTAssertEqual(fetchedRecord.score, 85)
        XCTAssertEqual(fetchedRecord.progressFraction, 1.0, accuracy: 0.001)

        // Update
        fetchedRecord.score = 100
        fetchedRecord.progressFraction = 1.0
        try stageContext.save()

        let updated = try stageContext.fetch(descriptor)
        let updatedRecord = try XCTUnwrap(updated.first)
        XCTAssertEqual(updatedRecord.score, 100)
        XCTAssertEqual(updatedRecord.progressFraction, 1.0, accuracy: 0.001)

        // Delete
        if let toDelete = updated.first {
            stageContext.delete(toDelete)
            try stageContext.save()
        }

        let afterDelete = try stageContext.fetch(descriptor)
        XCTAssertEqual(afterDelete.count, 0)
    }

    // MARK: - ReflexSessionLog Tests

    func testReflexSessionLogCreation() {
        let log = ReflexSessionLog(drillId: 501, responseTimeMs: 1200, accuracyScore: 0.95)
        XCTAssertNotNil(log.id)
        XCTAssertEqual(log.drillId, 501)
        XCTAssertEqual(log.responseTimeMs, 1200)
        XCTAssertEqual(log.accuracyScore, 0.95, accuracy: 0.001)
        XCTAssertNotNil(log.timestamp)
    }

    func testReflexSessionLogCRUD() throws {
        let log1 = ReflexSessionLog(drillId: 1001, responseTimeMs: 1800, accuracyScore: 1.0)
        let log2 = ReflexSessionLog(drillId: 1002, responseTimeMs: 2200, accuracyScore: 0.8)

        context.insert(log1)
        context.insert(log2)
        try context.save()

        let descriptor = FetchDescriptor<ReflexSessionLog>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 2)

        // Delete
        context.delete(log1)
        try context.save()

        let afterDelete = try context.fetch(descriptor)
        XCTAssertEqual(afterDelete.count, 1)
        XCTAssertEqual(afterDelete.first?.drillId, 1002)
    }

    // MARK: - Quick Reflex Attempt Tests

    func testQuickReflexAttemptRecordStoresAllLearningSignals() throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let record = QuickReflexAttemptRecord(
            wordId: 7,
            recallWordTimeMs: 1_100,
            collocationTimeMs: 1_500,
            produceSentenceTimeMs: 2_600,
            recallWordSucceeded: true,
            collocationSucceeded: true,
            produceSentenceSucceeded: true,
            shadowPronunciationScore: 92.5,
            maxHintLevel: 1,
            inputModeRawValue: "voice",
            retryCount: 1,
            confidenceRawValue: "comfortable",
            timestamp: timestamp
        )

        context.insert(record)
        try context.save()

        let records = try context.fetch(FetchDescriptor<QuickReflexAttemptRecord>())
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.id, record.id)
        XCTAssertEqual(records.first?.wordId, 7)
        XCTAssertEqual(records.first?.recallWordTimeMs, 1_100)
        XCTAssertEqual(records.first?.collocationTimeMs, 1_500)
        XCTAssertEqual(records.first?.produceSentenceTimeMs, 2_600)
        XCTAssertEqual(records.first?.recallWordSucceeded, true)
        XCTAssertEqual(records.first?.collocationSucceeded, true)
        XCTAssertEqual(records.first?.produceSentenceSucceeded, true)
        XCTAssertEqual(records.first?.shadowPronunciationScore, 92.5)
        XCTAssertEqual(records.first?.maxHintLevel, 1)
        XCTAssertEqual(records.first?.inputModeRawValue, "voice")
        XCTAssertEqual(records.first?.retryCount, 1)
        XCTAssertEqual(records.first?.confidenceRawValue, "comfortable")
        XCTAssertEqual(records.first?.timestamp, timestamp)

        // Backward-compatible properties
        XCTAssertEqual(records.first?.retrieveTimeMs, 1_100)
        XCTAssertEqual(records.first?.useTimeMs, 2_600)
        XCTAssertEqual(records.first?.retrieveSucceeded, true)
        XCTAssertEqual(records.first?.useSucceeded, true)
    }

    func testQuickReflexAttemptRecordCRUD() throws {
        let record = QuickReflexAttemptRecord(
            wordId: 8,
            recallWordTimeMs: 800,
            collocationTimeMs: 950,
            produceSentenceTimeMs: 1_200,
            recallWordSucceeded: true,
            collocationSucceeded: false,
            produceSentenceSucceeded: false,
            shadowPronunciationScore: nil,
            maxHintLevel: 0,
            inputModeRawValue: "typing",
            retryCount: 0,
            confidenceRawValue: "uncertain"
        )
        context.insert(record)
        try context.save()

        let descriptor = FetchDescriptor<QuickReflexAttemptRecord>(
            predicate: #Predicate { $0.wordId == 8 }
        )
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)

        fetched.first?.collocationSucceeded = true
        fetched.first?.produceSentenceSucceeded = true
        fetched.first?.shadowPronunciationScore = 88.0
        fetched.first?.confidenceRawValue = "comfortable"
        try context.save()

        let updated = try context.fetch(descriptor)
        XCTAssertEqual(updated.first?.collocationSucceeded, true)
        XCTAssertEqual(updated.first?.produceSentenceSucceeded, true)
        XCTAssertEqual(updated.first?.shadowPronunciationScore, 88.0)
        XCTAssertEqual(updated.first?.confidenceRawValue, "comfortable")

        if let recordToDelete = updated.first {
            context.delete(recordToDelete)
            try context.save()
        }

        XCTAssertTrue(try context.fetch(descriptor).isEmpty)
    }

    // MARK: - WidgetCurrentState Tests

    func testWidgetCurrentStateDefaults() {
        let state = WidgetCurrentState(
            currentWordId: 404,
            lemma: "resilient",
            ipaUs: "/rɪˈzɪliənt/",
            definitionVi: "kiên cường",
            exampleEn: "She is remarkably resilient."
        )

        XCTAssertEqual(state.id, "default_widget")
        XCTAssertEqual(state.currentWordId, 404)
        XCTAssertEqual(state.lemma, "resilient")
        XCTAssertEqual(state.ipaUs, "/rɪˈzɪliənt/")
        XCTAssertEqual(state.definitionVi, "kiên cường")
        XCTAssertEqual(state.exampleEn, "She is remarkably resilient.")
        XCTAssertNotNil(state.lastUpdated)
    }

    func testWidgetCurrentStateCRUD() throws {
        let state = WidgetCurrentState(
            currentWordId: 505,
            lemma: "tenacious",
            ipaUs: "/təˈneɪ.ʃəs/",
            definitionVi: "ngoan cường",
            exampleEn: "He is tenacious in pursuing his goals."
        )
        context.insert(state)
        try context.save()

        let descriptor = FetchDescriptor<WidgetCurrentState>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.lemma, "tenacious")

        // Update state
        fetched.first?.lemma = "eloquent"
        fetched.first?.currentWordId = 506
        try context.save()

        let updated = try context.fetch(descriptor)
        XCTAssertEqual(updated.first?.lemma, "eloquent")
        XCTAssertEqual(updated.first?.currentWordId, 506)

        // Delete
        if let toDelete = updated.first {
            context.delete(toDelete)
            try context.save()
        }

        let afterDelete = try context.fetch(descriptor)
        XCTAssertEqual(afterDelete.count, 0)
    }

    // MARK: - UserProgressModelActor Batch Query Tests

    func testUserProgressSummaryInitialization() {
        let summary = UserProgressSummary(masteryLevel: 5, isBookmarked: true)
        XCTAssertEqual(summary.masteryLevel, 5)
        XCTAssertTrue(summary.isBookmarked)
    }

    func testUserProgressModelActorFetchAllMasteryLevels() async throws {
        let actor = UserProgressModelActor(modelContainer: container)
        try await actor.saveProgress(wordId: 101, masteryLevel: 3, isBookmarked: false)
        try await actor.saveProgress(wordId: 102, masteryLevel: 5, isBookmarked: true)

        let masteryMap = try await actor.fetchAllMasteryLevels()
        XCTAssertEqual(masteryMap[101], 3)
        XCTAssertEqual(masteryMap[102], 5)
        XCTAssertNil(masteryMap[999])
    }

    func testUserProgressModelActorFetchAllProgressSummaryMap() async throws {
        let actor = UserProgressModelActor(modelContainer: container)
        try await actor.saveProgress(wordId: 201, masteryLevel: 2, isBookmarked: true)
        try await actor.saveProgress(wordId: 202, masteryLevel: 5, isBookmarked: false)

        let summaryMap = try await actor.fetchAllProgressSummaryMap()
        XCTAssertEqual(summaryMap[201]?.masteryLevel, 2)
        XCTAssertEqual(summaryMap[201]?.isBookmarked, true)
        XCTAssertEqual(summaryMap[202]?.masteryLevel, 5)
        XCTAssertEqual(summaryMap[202]?.isBookmarked, false)
        XCTAssertNil(summaryMap[999])
    }
}
