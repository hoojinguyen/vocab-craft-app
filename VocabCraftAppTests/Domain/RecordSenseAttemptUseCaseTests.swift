import Foundation
@testable import VocabCraftApp
import XCTest

final class RecordSenseAttemptUseCaseTests: XCTestCase {
    private func temporaryJournalURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("record_sense_tests_\(UUID().uuidString).sqlite")
    }

    func testSubmissionKeepsTheAttemptIDWhenPersistenceRetries() async throws {
        let attemptID = AttemptID(rawValue: UUID())
        let expected = try ContractFixture.expected()
        let attempt = TestAttempt.make(
            senseID: expected.bookVerbID,
            attemptID: attemptID
        )
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let recorder = RecordSenseAttemptUseCase(journal: journal, profileID: profile)
        let firstResult = try await recorder.execute(attempt: attempt)
        XCTAssertEqual(firstResult, .inserted)
        let retryResult = try await recorder.execute(attempt: attempt)
        XCTAssertEqual(retryResult, .duplicate)
    }

    func testStorageFailureAllowsRetryWithSameAttempt() async throws {
        let attemptID = AttemptID(rawValue: UUID())
        let expected = try ContractFixture.expected()
        let attempt = TestAttempt.make(
            senseID: expected.bookVerbID,
            attemptID: attemptID
        )
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let recorder = RecordSenseAttemptUseCase(journal: journal, profileID: profile)

        try await journal.simulateDiskFailure(true)

        var didThrow = false
        do {
            _ = try await recorder.execute(attempt: attempt)
        } catch {
            didThrow = true
        }
        XCTAssertTrue(didThrow, "Execution must fail when disk failure is simulated")

        try await journal.simulateDiskFailure(false)

        let retryResult = try await recorder.execute(attempt: attempt)
        XCTAssertEqual(retryResult, .inserted, "Retry must succeed with the same attempt")

        let events = try await journal.attempts(profileID: profile, senseID: expected.bookVerbID)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.attemptID, attemptID)
    }

    func testTwoDifferentSensesTrackIndependently() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        let bookNounID = try XCTUnwrap(SenseID(uuidString: "b0000000-0000-4000-8000-000000000001"))
        let bookVerbID = expected.bookVerbID

        let recorder = RecordSenseAttemptUseCase(journal: journal, profileID: profile)

        let nounAttempt = TestAttempt.make(senseID: bookNounID, outcome: .correct)
        let verbAttempt = TestAttempt.make(senseID: bookVerbID, outcome: .incorrect)

        let nounResult = try await recorder.execute(attempt: nounAttempt)
        let verbResult = try await recorder.execute(attempt: verbAttempt)

        XCTAssertEqual(nounResult, .inserted)
        XCTAssertEqual(verbResult, .inserted)

        let nounEvents = try await journal.attempts(profileID: profile, senseID: bookNounID)
        let verbEvents = try await journal.attempts(profileID: profile, senseID: bookVerbID)

        XCTAssertEqual(nounEvents.count, 1)
        XCTAssertEqual(nounEvents.first?.senseID, bookNounID)
        XCTAssertEqual(nounEvents.first?.outcome, .correct)

        XCTAssertEqual(verbEvents.count, 1)
        XCTAssertEqual(verbEvents.first?.senseID, bookVerbID)
        XCTAssertEqual(verbEvents.first?.outcome, .incorrect)

        let nounCounter = try await journal.counter(profileID: profile, senseID: bookNounID, capability: .recognition)
        XCTAssertEqual(nounCounter?.total, 1)
        XCTAssertEqual(nounCounter?.correct, 1)

        let verbCounter = try await journal.counter(profileID: profile, senseID: bookVerbID, capability: .recognition)
        XCTAssertEqual(verbCounter?.total, 1)
        XCTAssertEqual(verbCounter?.correct, 0)
    }

    func testUnscoredApplicationDoesNotIncrementCorrectCounter() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        let recorder = RecordSenseAttemptUseCase(journal: journal, profileID: profile)

        let unscoredAttempt = TestAttempt.make(
            senseID: expected.bookVerbID,
            exerciseKind: .applicationText,
            capability: .application,
            inputModes: [.text],
            responseMode: .text,
            outcome: .unscored,
            scoreMilli: nil,
            evaluatorVersion: "unscored"
        )

        let result = try await recorder.execute(attempt: unscoredAttempt)
        XCTAssertEqual(result, .inserted)

        let appCounter = try await journal.counter(profileID: profile, senseID: expected.bookVerbID, capability: .application)
        let unwrappedCounter = try XCTUnwrap(appCounter)
        XCTAssertEqual(unwrappedCounter.total, 1)
        XCTAssertEqual(unwrappedCounter.correct, 0, "Unscored application must not increment correct counter")
    }
}
