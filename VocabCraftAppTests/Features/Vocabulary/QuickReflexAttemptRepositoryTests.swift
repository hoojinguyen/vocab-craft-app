#if canImport(SwiftDataMacros)
import Foundation
import SwiftData
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

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

    func testSavePersistsEvery3TierLearningSignal() async throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let attempt = makeAttempt(
            wordId: 42,
            recallWordTimeMs: 1_050,
            collocationTimeMs: 1_200,
            produceSentenceTimeMs: 2_100,
            recallWordSucceeded: true,
            collocationSucceeded: true,
            produceSentenceSucceeded: false,
            shadowPronunciationScore: 85.5,
            maxHintLevel: 2,
            inputMode: .typing,
            retryCount: 1,
            confidence: .uncertain,
            timestamp: timestamp
        )

        try await repository.save(attempt)

        let saved = try await repository.mostRecentSuccessfulAttempt(for: 42)
        XCTAssertEqual(saved, attempt)
        XCTAssertEqual(saved?.recallWordTimeMs, 1_050)
        XCTAssertEqual(saved?.collocationTimeMs, 1_200)
        XCTAssertEqual(saved?.produceSentenceTimeMs, 2_100)
        XCTAssertEqual(saved?.recallWordSucceeded, true)
        XCTAssertEqual(saved?.collocationSucceeded, true)
        XCTAssertEqual(saved?.produceSentenceSucceeded, false)
        XCTAssertEqual(saved?.shadowPronunciationScore, 85.5)
        XCTAssertEqual(saved?.retrieveTimeMs, 1_050)
        XCTAssertEqual(saved?.useTimeMs, 2_100)
        XCTAssertEqual(saved?.retrieveSucceeded, true)
        XCTAssertEqual(saved?.useSucceeded, false)
    }

    func testMostRecentSuccessfulAttemptReturnsNewestSuccessfulRecallWord() async throws {
        let failed = makeAttempt(
            wordId: 42,
            recallWordSucceeded: false,
            collocationSucceeded: false,
            produceSentenceSucceeded: false,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let olderSuccessful = makeAttempt(
            wordId: 42,
            recallWordSucceeded: true,
            collocationSucceeded: true,
            produceSentenceSucceeded: true,
            timestamp: Date(timeIntervalSince1970: 1_700_000_100)
        )
        let newerSuccessful = makeAttempt(
            wordId: 42,
            recallWordSucceeded: true,
            collocationSucceeded: false,
            produceSentenceSucceeded: false,
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

    func testMostRecentSuccessfulAttemptReturnsNilWhenRecallWordNeverSucceeds() async throws {
        try await repository.save(makeAttempt(
            wordId: 42,
            recallWordSucceeded: false,
            collocationSucceeded: true,
            produceSentenceSucceeded: true
        ))

        let latest = try await repository.mostRecentSuccessfulAttempt(for: 42)

        XCTAssertNil(latest)
    }

    func testLegacyInitializerMaintainsBackwardCompatibility() {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let legacyAttempt = QuickReflexAttempt(
            wordId: 99,
            retrieveTimeMs: 800,
            useTimeMs: 1_600,
            retrieveSucceeded: true,
            useSucceeded: true,
            maxHintLevel: 1,
            inputMode: .voice,
            retryCount: 0,
            confidence: .comfortable,
            timestamp: timestamp
        )

        XCTAssertEqual(legacyAttempt.recallWordTimeMs, 800)
        XCTAssertEqual(legacyAttempt.collocationTimeMs, 0)
        XCTAssertEqual(legacyAttempt.produceSentenceTimeMs, 1_600)
        XCTAssertEqual(legacyAttempt.recallWordSucceeded, true)
        XCTAssertEqual(legacyAttempt.produceSentenceSucceeded, true)
        XCTAssertNil(legacyAttempt.shadowPronunciationScore)
        XCTAssertEqual(legacyAttempt.retrieveTimeMs, 800)
        XCTAssertEqual(legacyAttempt.useTimeMs, 1_600)
        XCTAssertEqual(legacyAttempt.retrieveSucceeded, true)
        XCTAssertEqual(legacyAttempt.useSucceeded, true)
    }

    private func makeAttempt(
        id: UUID = UUID(),
        wordId: Int64,
        recallWordTimeMs: Int = 1_000,
        collocationTimeMs: Int = 1_500,
        produceSentenceTimeMs: Int = 2_000,
        recallWordSucceeded: Bool,
        collocationSucceeded: Bool = true,
        produceSentenceSucceeded: Bool = true,
        shadowPronunciationScore: Double? = nil,
        maxHintLevel: Int = 0,
        inputMode: QuickReflexInputMode = .voice,
        retryCount: Int = 0,
        confidence: QuickReflexConfidence = .comfortable,
        timestamp: Date = Date()
    ) -> QuickReflexAttempt {
        QuickReflexAttempt(
            id: id,
            wordId: wordId,
            recallWordTimeMs: recallWordTimeMs,
            collocationTimeMs: collocationTimeMs,
            produceSentenceTimeMs: produceSentenceTimeMs,
            recallWordSucceeded: recallWordSucceeded,
            collocationSucceeded: collocationSucceeded,
            produceSentenceSucceeded: produceSentenceSucceeded,
            shadowPronunciationScore: shadowPronunciationScore,
            maxHintLevel: maxHintLevel,
            inputMode: inputMode,
            retryCount: retryCount,
            confidence: confidence,
            timestamp: timestamp
        )
    }
}

#endif
