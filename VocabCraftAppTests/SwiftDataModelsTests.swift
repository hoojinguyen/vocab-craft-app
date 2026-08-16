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

    func testUserWordProgressCRUD() throws {
        let progress = UserWordProgress(wordId: 303, masteryLevel: 1, easeFactor: 2.4, intervalDays: 2)
        context.insert(progress)
        try context.save()

        let descriptor = FetchDescriptor<UserWordProgress>(predicate: #Predicate { $0.wordId == 303 })
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.masteryLevel, 1)

        // Update
        fetched.first?.masteryLevel = 4
        fetched.first?.totalReviews = 10
        try context.save()

        let updated = try context.fetch(descriptor)
        XCTAssertEqual(updated.first?.masteryLevel, 4)
        XCTAssertEqual(updated.first?.totalReviews, 10)

        // Delete
        if let toDelete = updated.first {
            context.delete(toDelete)
            try context.save()
        }

        let afterDelete = try context.fetch(descriptor)
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
            retrieveTimeMs: 1_100,
            useTimeMs: 2_600,
            retrieveSucceeded: true,
            useSucceeded: true,
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
        XCTAssertEqual(records.first?.retrieveTimeMs, 1_100)
        XCTAssertEqual(records.first?.useTimeMs, 2_600)
        XCTAssertEqual(records.first?.retrieveSucceeded, true)
        XCTAssertEqual(records.first?.useSucceeded, true)
        XCTAssertEqual(records.first?.maxHintLevel, 1)
        XCTAssertEqual(records.first?.inputModeRawValue, "voice")
        XCTAssertEqual(records.first?.retryCount, 1)
        XCTAssertEqual(records.first?.confidenceRawValue, "comfortable")
        XCTAssertEqual(records.first?.timestamp, timestamp)
    }

    func testQuickReflexAttemptRecordCRUD() throws {
        let record = QuickReflexAttemptRecord(
            wordId: 8,
            retrieveTimeMs: 800,
            useTimeMs: 1_200,
            retrieveSucceeded: true,
            useSucceeded: false,
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

        fetched.first?.useSucceeded = true
        fetched.first?.confidenceRawValue = "comfortable"
        try context.save()

        let updated = try context.fetch(descriptor)
        XCTAssertEqual(updated.first?.useSucceeded, true)
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
}
