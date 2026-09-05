import Foundation
@testable import VocabCraftApp
import XCTest

// MARK: - Test Helpers

public enum TestAttempt {
    public static func make(
        senseID: SenseID,
        attemptID: AttemptID? = nil,
        eventSchemaVersion: Int = 1,
        senseRevision: Int = 1,
        contentVersion: Int = 1,
        lessonID: LessonID? = LessonID(uuidString: "d1000000-0000-4000-8000-000000000001"),
        lessonRevision: Int? = 1,
        exerciseKind: ExerciseKind = .recognitionChoice,
        capability: Capability? = .recognition,
        inputModes: [InputMode] = [.text],
        responseMode: ResponseMode = .choice,
        outcome: ExerciseOutcome = .correct,
        scoreMilli: Int? = 1000,
        hintCount: Int = 0,
        retryCount: Int = 0,
        responseTimeMs: Int = 2400,
        occurredAt: String = "2026-09-05T10:15:30.000Z",
        elapsedSincePreviousMs: Int? = nil,
        clientSRSAlgorithmVersion: String = "none",
        evaluatorVersion: String = "exact_match_v1",
        pronunciationScoreMilli: Int? = nil
    ) -> AttemptSubmission {
        let finalAttemptID = attemptID ?? AttemptID(rawValue: UUID())
        let finalCapability = (exerciseKind == .pronunciation) ? nil : capability
        let finalScoreMilli = (outcome == .unscored) ? nil : scoreMilli
        return AttemptSubmission(
            attemptID: finalAttemptID,
            eventSchemaVersion: eventSchemaVersion,
            senseID: senseID,
            senseRevision: senseRevision,
            contentVersion: contentVersion,
            lessonID: lessonID,
            lessonRevision: lessonRevision,
            exerciseKind: exerciseKind,
            capability: finalCapability,
            inputModes: inputModes,
            responseMode: responseMode,
            outcome: outcome,
            scoreMilli: finalScoreMilli,
            hintCount: hintCount,
            retryCount: retryCount,
            responseTimeMs: responseTimeMs,
            occurredAt: occurredAt,
            elapsedSincePreviousMs: elapsedSincePreviousMs,
            clientSRSAlgorithmVersion: clientSRSAlgorithmVersion,
            evaluatorVersion: evaluatorVersion,
            pronunciationScoreMilli: pronunciationScoreMilli
        )
    }
}

public enum TestCompletion {
    public static func make(
        eventID: EventID? = nil,
        originProfileID: ProfileID = ProfileID(rawValue: UUID(uuidString: "f5000000-0000-4000-8000-000000000001") ?? UUID()),
        deviceID: DeviceID = DeviceID(rawValue: UUID(uuidString: "fa000000-0000-4000-8000-000000000001") ?? UUID()),
        deviceSequence: Int = 1,
        eventSchemaVersion: Int = 1,
        lessonID: LessonID = LessonID(uuidString: "d1000000-0000-4000-8000-000000000001") ?? LessonID(rawValue: UUID()),
        lessonRevision: Int = 1,
        contentVersion: Int = 1,
        completedAt: String = "2026-09-05T10:20:00.000Z"
    ) -> LessonCompletion {
        let finalEventID = eventID ?? EventID(rawValue: UUID())
        return LessonCompletion(
            eventID: finalEventID,
            originProfileID: originProfileID,
            deviceID: deviceID,
            deviceSequence: deviceSequence,
            eventSchemaVersion: eventSchemaVersion,
            lessonID: lessonID,
            lessonRevision: lessonRevision,
            contentVersion: contentVersion,
            completedAt: completedAt
        )
    }
}

// MARK: - LearningJournalTests

final class LearningJournalTests: XCTestCase {
    private var tempDirectories: [URL] = []

    override func tearDown() {
        super.tearDown()
        for directory in tempDirectories {
            try? FileManager.default.removeItem(at: directory)
        }
        tempDirectories.removeAll()
    }

    private func temporaryJournalURL() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("LearningJournalTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        tempDirectories.append(dir)
        return dir.appendingPathComponent("learning_journal.sqlite")
    }

    func testRetryDoesNotDuplicatePractice() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()
        let attempt = TestAttempt.make(senseID: expected.bookVerbID)
        let firstResult = try await journal.append(attempt, profileID: profile)
        XCTAssertEqual(firstResult, .inserted)

        let result = try await journal.append(attempt, profileID: profile)
        XCTAssertEqual(result, .duplicate)

        let events = try await journal.attempts(profileID: profile, senseID: expected.bookVerbID)
        XCTAssertEqual(events.count, 1)

        let counter = try await journal.counter(profileID: profile, senseID: expected.bookVerbID, capability: .recognition)
        XCTAssertEqual(counter?.total, 1)
        XCTAssertEqual(counter?.correct, 1)
    }

    func testReopeningJournalPreservesEventsAndProfiles() async throws {
        let fileURL = temporaryJournalURL()
        let expected = try ContractFixture.expected()
        let profileID: ProfileID
        let attemptID = AttemptID(rawValue: UUID())
        let completionID = EventID(rawValue: UUID())

        // First session
        do {
            let journal1 = try LearningJournal(url: fileURL)
            let profile = try await journal1.createGuestProfile()
            profileID = profile

            let attempt = TestAttempt.make(senseID: expected.bookVerbID, attemptID: attemptID)
            let insertResult = try await journal1.append(attempt, profileID: profile)
            XCTAssertEqual(insertResult, .inserted)

            let lessonID = try XCTUnwrap(expected.orderedLessonIDs.first)
            let completion = TestCompletion.make(
                eventID: completionID,
                originProfileID: profile,
                lessonID: lessonID
            )
            try await journal1.complete(completion, profileID: profile)
            await journal1.close()
        }

        // Second session: Reopen
        do {
            let journal2 = try LearningJournal(url: fileURL)
            let activeProfile = try await journal2.activeGuestProfileID()
            XCTAssertEqual(activeProfile, profileID)

            let reopenedProfile = try await journal2.createGuestProfile()
            XCTAssertEqual(reopenedProfile, profileID)

            let storedAttempts = try await journal2.attempts(profileID: profileID, senseID: expected.bookVerbID)
            XCTAssertEqual(storedAttempts.count, 1)
            XCTAssertEqual(storedAttempts.first?.attemptID, attemptID)
            XCTAssertEqual(storedAttempts.first?.deviceSequence, 1)

            let storedCompletions = try await journal2.completedLessons(profileID: profileID)
            XCTAssertEqual(storedCompletions.count, 1)
            XCTAssertEqual(storedCompletions.first?.eventID, completionID)
            await journal2.close()
        }
    }

    func testSameIDWithDifferentPayloadThrowsConflict() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()
        let attemptID = AttemptID(rawValue: UUID())

        let attemptA = TestAttempt.make(
            senseID: expected.bookVerbID,
            attemptID: attemptID,
            outcome: .correct,
            scoreMilli: 1000
        )
        let resultA = try await journal.append(attemptA, profileID: profile)
        XCTAssertEqual(resultA, .inserted)

        let attemptB = TestAttempt.make(
            senseID: expected.bookVerbID,
            attemptID: attemptID,
            outcome: .incorrect,
            scoreMilli: 0
        )

        do {
            _ = try await journal.append(attemptB, profileID: profile)
            XCTFail("Expected conflict error for different payload with same attemptID")
        } catch let error as LearningJournalError {
            switch error {
            case .conflict:
                break
            default:
                XCTFail("Expected .conflict error, got: \(error)")
            }
        } catch {
            XCTFail("Expected LearningJournalError, got: \(error)")
        }

        let events = try await journal.attempts(profileID: profile, senseID: expected.bookVerbID)
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.outcome, .correct)

        let counter = try await journal.counter(profileID: profile, senseID: expected.bookVerbID, capability: .recognition)
        XCTAssertEqual(counter?.total, 1)
        XCTAssertEqual(counter?.correct, 1)
    }

    func testCompletionConflictWithDifferentPayloadThrowsConflict() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let eventID = EventID(rawValue: UUID())
        let lessonA = LessonID(uuidString: "d1000000-0000-4000-8000-000000000001") ?? LessonID(rawValue: UUID())
        let lessonB = LessonID(uuidString: "d1000000-0000-4000-8000-000000000002") ?? LessonID(rawValue: UUID())

        let completionA = TestCompletion.make(eventID: eventID, lessonID: lessonA)
        try await journal.complete(completionA, profileID: profile)

        // Idempotent duplicate: identical completion succeeds without error
        try await journal.complete(completionA, profileID: profile)

        // Conflict: different payload with existing eventID throws .conflict
        let completionB = TestCompletion.make(eventID: eventID, lessonID: lessonB)
        do {
            try await journal.complete(completionB, profileID: profile)
            XCTFail("Expected conflict error for different completion payload with same eventID")
        } catch let error as LearningJournalError {
            switch error {
            case .conflict:
                break
            default:
                XCTFail("Expected .conflict error, got: \(error)")
            }
        } catch {
            XCTFail("Expected LearningJournalError, got: \(error)")
        }

        let completed = try await journal.completedLessons(profileID: profile)
        XCTAssertEqual(completed.count, 1)
        XCTAssertEqual(completed.first?.lessonID, lessonA)
    }

    func testTwoSensesForBookTrackedIndependently() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        let bookNounID = try XCTUnwrap(SenseID(uuidString: "b0000000-0000-4000-8000-000000000001"))
        let bookVerbID = expected.bookVerbID

        let nounAttempt = TestAttempt.make(senseID: bookNounID, outcome: .correct)
        let verbAttempt = TestAttempt.make(senseID: bookVerbID, outcome: .incorrect)

        _ = try await journal.append(nounAttempt, profileID: profile)
        _ = try await journal.append(verbAttempt, profileID: profile)

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

    func testTwoProfilesDoNotLeakEvents() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile1 = try await journal.createGuestProfile()
        let profile2 = try await journal.createGuestProfile(forceNew: true)
        XCTAssertNotEqual(profile1, profile2)

        let expected = try ContractFixture.expected()
        let attempt1 = TestAttempt.make(senseID: expected.bookVerbID, outcome: .correct)
        let attempt2 = TestAttempt.make(senseID: expected.bookVerbID, outcome: .incorrect)

        _ = try await journal.append(attempt1, profileID: profile1)
        _ = try await journal.append(attempt2, profileID: profile2)

        let lessonID = try XCTUnwrap(expected.orderedLessonIDs.first)
        let completion1 = TestCompletion.make(originProfileID: profile1, lessonID: lessonID)
        try await journal.complete(completion1, profileID: profile1)

        let events1 = try await journal.attempts(profileID: profile1, senseID: expected.bookVerbID)
        let events2 = try await journal.attempts(profileID: profile2, senseID: expected.bookVerbID)

        XCTAssertEqual(events1.count, 1)
        XCTAssertEqual(events1.first?.attemptID, attempt1.attemptID)
        XCTAssertEqual(events1.first?.originProfileID, profile1)

        XCTAssertEqual(events2.count, 1)
        XCTAssertEqual(events2.first?.attemptID, attempt2.attemptID)
        XCTAssertEqual(events2.first?.originProfileID, profile2)

        let completions1 = try await journal.completedLessons(profileID: profile1)
        let completions2 = try await journal.completedLessons(profileID: profile2)

        XCTAssertEqual(completions1.count, 1)
        XCTAssertEqual(completions2.count, 0)

        let counter1 = try await journal.counter(profileID: profile1, senseID: expected.bookVerbID, capability: .recognition)
        XCTAssertEqual(counter1?.total, 1)
        XCTAssertEqual(counter1?.correct, 1)

        let counter2 = try await journal.counter(profileID: profile2, senseID: expected.bookVerbID, capability: .recognition)
        XCTAssertEqual(counter2?.total, 1)
        XCTAssertEqual(counter2?.correct, 0)
    }

    func testDiskFailureDoesNotAck() async throws {
        let fileURL = temporaryJournalURL()
        let journal = try LearningJournal(url: fileURL)
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        try await journal.simulateDiskFailure(true)

        let attempt = TestAttempt.make(senseID: expected.bookVerbID)
        var didThrow = false
        do {
            _ = try await journal.append(attempt, profileID: profile)
        } catch {
            didThrow = true
        }
        XCTAssertTrue(didThrow, "append must throw on write failure and NOT acknowledge success")

        try await journal.simulateDiskFailure(false)

        let events = try await journal.attempts(profileID: profile, senseID: expected.bookVerbID)
        XCTAssertEqual(events.count, 0, "Unacknowledged write must not be committed to store")
    }

    func testPronunciationOnlyAndUnscoredDoNotIncreaseCorrectCounters() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        // 1. Pronunciation-only attempt: capability is nil
        let pronAttempt = TestAttempt.make(
            senseID: expected.bookVerbID,
            exerciseKind: .pronunciation,
            capability: nil,
            inputModes: [.audio],
            responseMode: .speech,
            outcome: .correct,
            scoreMilli: 900,
            evaluatorVersion: "speech_v1",
            pronunciationScoreMilli: 900
        )
        let pronResult = try await journal.append(pronAttempt, profileID: profile)
        XCTAssertEqual(pronResult, .inserted)

        let countersAfterPron = try await journal.counters(profileID: profile, senseID: expected.bookVerbID)
        XCTAssertTrue(countersAfterPron.isEmpty)

        // 2. Unscored attempt with capability .application
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
        let unscoredResult = try await journal.append(unscoredAttempt, profileID: profile)
        XCTAssertEqual(unscoredResult, .inserted)

        let appCounter = try await journal.counter(profileID: profile, senseID: expected.bookVerbID, capability: .application)
        let unwrappedAppCounter = try XCTUnwrap(appCounter)
        XCTAssertEqual(unwrappedAppCounter.total, 1)
        XCTAssertEqual(unwrappedAppCounter.correct, 0, "Unscored must NOT increment correct counter")
    }

    func testSequenceNumberIncrementsPerDeviceAndProfile() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        let attempt1 = TestAttempt.make(senseID: expected.bookVerbID)
        let attempt2 = TestAttempt.make(senseID: expected.bookVerbID)

        _ = try await journal.append(attempt1, profileID: profile)
        _ = try await journal.append(attempt2, profileID: profile)

        let events = try await journal.attempts(profileID: profile, senseID: expected.bookVerbID)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].deviceSequence, 1)
        XCTAssertEqual(events[1].deviceSequence, 2)
    }

    func testAppendWithUnknownProfileThrowsProfileNotFound() async throws {
        let journal = try LearningJournal(url: temporaryJournalURL())
        let unknownProfile = ProfileID(rawValue: UUID())
        let expected = try ContractFixture.expected()
        let attempt = TestAttempt.make(senseID: expected.bookVerbID)

        do {
            _ = try await journal.append(attempt, profileID: unknownProfile)
            XCTFail("Expected profileNotFound error")
        } catch let error as LearningJournalError {
            XCTAssertEqual(error, .profileNotFound(unknownProfile))
        } catch {
            XCTFail("Expected LearningJournalError, got: \(error)")
        }
    }
}
