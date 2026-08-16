import SwiftData
@testable import VocabCraftApp
import XCTest

@MainActor
final class QuickReflexAttemptRepositoryTests: XCTestCase {
    private var container: ModelContainer!
    private var repository: QuickReflexAttemptRepositoryImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try SharedAppGroupContainer.createContainer(inMemory: true)
        repository = QuickReflexAttemptRepositoryImpl(modelContext: container.mainContext)
    }

    override func tearDownWithError() throws {
        repository = nil
        container = nil
        try super.tearDownWithError()
    }

    func testSavePersistsEveryLearningSignal() async throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let attempt = makeAttempt(
            wordId: 42,
            retrieveTimeMs: 1_050,
            useTimeMs: 2_100,
            retrieveSucceeded: true,
            useSucceeded: false,
            maxHintLevel: 2,
            inputMode: .typing,
            retryCount: 1,
            confidence: .uncertain,
            timestamp: timestamp
        )

        try await repository.save(attempt)

        let saved = try await repository.mostRecentSuccessfulAttempt(for: 42)
        XCTAssertEqual(saved, attempt)
    }

    func testMostRecentSuccessfulAttemptReturnsNewestSuccessfulRetrieval() async throws {
        let failed = makeAttempt(
            wordId: 42,
            retrieveSucceeded: false,
            useSucceeded: false,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let olderSuccessful = makeAttempt(
            wordId: 42,
            retrieveSucceeded: true,
            useSucceeded: true,
            timestamp: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let newerSuccessful = makeAttempt(
            wordId: 42,
            retrieveSucceeded: true,
            useSucceeded: false,
            inputMode: .typing,
            retryCount: 2,
            confidence: .uncertain,
            timestamp: Date(timeIntervalSince1970: 1_700_000_200)
        )

        try await repository.save(failed)
        try await repository.save(olderSuccessful)
        try await repository.save(newerSuccessful)

        let latest = try await repository.mostRecentSuccessfulAttempt(for: 42)

        XCTAssertEqual(latest, newerSuccessful)
    }

    func testMostRecentSuccessfulAttemptReturnsNilWhenRetrievalNeverSucceeds() async throws {
        try await repository.save(makeAttempt(wordId: 42, retrieveSucceeded: false, useSucceeded: true))

        let latest = try await repository.mostRecentSuccessfulAttempt(for: 42)

        XCTAssertNil(latest)
    }

    private func makeAttempt(
        wordId: Int64,
        retrieveTimeMs: Int = 1_000,
        useTimeMs: Int = 2_000,
        retrieveSucceeded: Bool,
        useSucceeded: Bool,
        maxHintLevel: Int = 0,
        inputMode: QuickReflexInputMode = .voice,
        retryCount: Int = 0,
        confidence: QuickReflexConfidence = .comfortable,
        timestamp: Date = Date()
    ) -> QuickReflexAttempt {
        QuickReflexAttempt(
            wordId: wordId,
            retrieveTimeMs: retrieveTimeMs,
            useTimeMs: useTimeMs,
            retrieveSucceeded: retrieveSucceeded,
            useSucceeded: useSucceeded,
            maxHintLevel: maxHintLevel,
            inputMode: inputMode,
            retryCount: retryCount,
            confidence: confidence,
            timestamp: timestamp
        )
    }
}
