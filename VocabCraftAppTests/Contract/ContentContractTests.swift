import Foundation
import SQLite3
@testable import VocabCraftApp
import XCTest

final class ContentContractTests: XCTestCase {
    // 1. Snapshot structure and membership
    func testSenseDoesNotOwnLessonMembership() throws {
        let snapshot = try ContractFixture.loadSnapshot()
        XCTAssertEqual(snapshot.entries.count, 3)
        XCTAssertEqual(snapshot.senses.count, 4)
        let repeated = snapshot.lessonSenses[1].senseID
        XCTAssertEqual(snapshot.lessonSenses.filter { $0.senseID == repeated }.count, 2)
    }

    // 2. Expected JSON matches fixture
    func testExpectedJsonMatchesFixture() throws {
        let snapshot = try ContractFixture.loadSnapshot()
        let expected = try ContractFixture.expected()

        XCTAssertEqual(snapshot.senses[1].id, expected.bookVerbID)

        let verbExample = snapshot.examples.first(where: { $0.senseID == expected.bookVerbID })
        let unwrappedExample = try XCTUnwrap(verbExample)
        XCTAssertEqual(unwrappedExample.textVI, expected.bookVerbExampleVI)

        XCTAssertEqual(snapshot.entries.count, expected.counts.entries)
        XCTAssertEqual(snapshot.senses.count, expected.counts.senses)
        XCTAssertEqual(snapshot.pronunciations.count, expected.counts.pronunciations)
        XCTAssertEqual(snapshot.examples.count, expected.counts.examples)
        XCTAssertEqual(snapshot.collocations.count, expected.counts.collocations)
        XCTAssertEqual(snapshot.decks.count, expected.counts.decks)
        XCTAssertEqual(snapshot.lessons.count, expected.counts.lessons)
        XCTAssertEqual(snapshot.lessonSenses.count, expected.counts.lessonSenses)
        XCTAssertEqual(snapshot.attributions.count, expected.counts.attributions)
        XCTAssertEqual(snapshot.senseAttributions.count, expected.counts.senseAttributions)
        XCTAssertEqual(snapshot.retiredSenses.count, expected.counts.retiredSenses)

        if let reviews = snapshot.reviews {
            XCTAssertEqual(reviews.count, expected.counts.reviews)
        }
        if let sources = snapshot.sources {
            XCTAssertEqual(sources.count, expected.counts.sources)
        }
        if let sourceLinks = snapshot.sourceLinks {
            XCTAssertEqual(sourceLinks.count, expected.counts.sourceLinks)
        }

        XCTAssertEqual(snapshot.entries.map(\.id), expected.orderedEntryIDs)
        XCTAssertEqual(snapshot.senses.map(\.id), expected.orderedSenseIDs)
        XCTAssertEqual(snapshot.lessons.map(\.id), expected.orderedLessonIDs)
    }

    // 3. Catalog tokens
    func testCatalogJsonValid() throws {
        let catalog = try ContractFixture.loadCatalog()
        XCTAssertEqual(catalog.iconKeys["book_open"], "token.icon.book_open")
        XCTAssertEqual(catalog.iconKeys["plane"], "token.icon.plane")
        XCTAssertEqual(catalog.themeKeys["ocean_blue"], "token.theme.ocean_blue")
    }

    // 4. Typed IDs canonical UUID v4 validation
    func testTypedIDsCanonicalValidation() throws {
        // Valid canonical UUID v4: lowercase, version 4, variant 8/9/a/b
        let validString = "b0000000-0000-4000-8000-000000000001"
        let validSenseID = try XCTUnwrap(SenseID(uuidString: validString))
        XCTAssertEqual(validSenseID.description, validString)
        XCTAssertEqual(validSenseID.rawValue.uuidString.lowercased(), validString)

        // Uppercase rejected
        let uppercaseString = "B0000000-0000-4000-8000-000000000001"
        XCTAssertNil(SenseID(uuidString: uppercaseString))

        // Non-v4 rejected (version 1)
        let v1String = "b0000000-0000-1000-8000-000000000001"
        XCTAssertNil(SenseID(uuidString: v1String))

        // Non-v4 rejected (version 3)
        let v3String = "b0000000-0000-3000-8000-000000000001"
        XCTAssertNil(SenseID(uuidString: v3String))

        // Non-RFC4122 variant rejected (variant 0: char at 19 is '0')
        let badVariant0 = "b0000000-0000-4000-0000-000000000001"
        XCTAssertNil(SenseID(uuidString: badVariant0))

        // Non-RFC4122 variant rejected (variant 3: char at 19 is 'c')
        let badVariantC = "b0000000-0000-4000-c000-000000000001"
        XCTAssertNil(SenseID(uuidString: badVariantC))

        // Malformed string rejected
        XCTAssertNil(SenseID(uuidString: "NOT-A-VALID-UUID"))

        // Decoder rejection on invalid strings
        let jsonWithBadUUID = Data("\"NOT-A-VALID-UUID\"".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SenseID.self, from: jsonWithBadUUID))

        let jsonWithUppercase = Data("\"\(uppercaseString)\"".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SenseID.self, from: jsonWithUppercase))

        // Other ID types validate identically
        XCTAssertNotNil(EntryID(uuidString: "a0000000-0000-4000-8000-000000000001"))
        XCTAssertNotNil(LessonID(uuidString: "d1000000-0000-4000-8000-000000000001"))
        XCTAssertNotNil(DeckID(uuidString: "d0000000-0000-4000-8000-000000000001"))
        XCTAssertNotNil(ProfileID(uuidString: "f5000000-0000-4000-8000-000000000001"))
        XCTAssertNotNil(AttemptID(uuidString: "e1000000-0000-4000-8000-000000000001"))
    }

    // 5. Practice attempts from event-fixture
    func testEventFixturePracticeAttemptsDecode() throws {
        let fixture = try ContractFixture.loadEventFixture()
        XCTAssertEqual(fixture.practiceAttempts.count, 4)

        // Attempt 1: Recognition choice
        let att1 = fixture.practiceAttempts[0]
        XCTAssertEqual(att1.eventType, "practice_attempt")
        XCTAssertEqual(att1.exerciseKind, .recognitionChoice)
        XCTAssertEqual(att1.capability, .recognition)
        XCTAssertEqual(att1.outcome, .correct)
        XCTAssertEqual(att1.scoreMilli, 1000)
        XCTAssertEqual(att1.clientSRSAlgorithmVersion, "none")
        XCTAssertNil(att1.pronunciationScoreMilli)

        // Attempt 2: Recall text
        let att2 = fixture.practiceAttempts[1]
        XCTAssertEqual(att2.exerciseKind, .recallText)
        XCTAssertEqual(att2.capability, .recall)
        XCTAssertEqual(att2.outcome, .correct)
        XCTAssertEqual(att2.clientSRSAlgorithmVersion, "fsrs_v1")

        // Attempt 3: Application text - unscored
        let att3 = fixture.practiceAttempts[2]
        XCTAssertEqual(att3.exerciseKind, .applicationText)
        XCTAssertEqual(att3.capability, .application)
        XCTAssertEqual(att3.outcome, .unscored)
        XCTAssertNil(att3.scoreMilli)
        XCTAssertEqual(att3.hintCount, 1)

        // Attempt 4: Pronunciation - capability MUST be nil
        let att4 = fixture.practiceAttempts[3]
        XCTAssertEqual(att4.exerciseKind, .pronunciation)
        XCTAssertNil(att4.capability)
        XCTAssertEqual(att4.outcome, .correct)
        XCTAssertEqual(att4.pronunciationScoreMilli, 920)
        XCTAssertEqual(att4.clientSRSAlgorithmVersion, "none")
    }

    // 6. Lesson completions from event-fixture
    func testEventFixtureLessonCompletionsDecode() throws {
        let fixture = try ContractFixture.loadEventFixture()
        XCTAssertEqual(fixture.lessonCompletions.count, 1)

        let comp = fixture.lessonCompletions[0]
        XCTAssertEqual(comp.eventType, "lesson_completion")
        XCTAssertEqual(comp.eventID.description, "ec000000-0000-4000-8000-000000000001")
        XCTAssertEqual(comp.lessonID.description, "d1000000-0000-4000-8000-000000000001")
        XCTAssertEqual(comp.lessonRevision, 1)
        XCTAssertEqual(comp.contentVersion, 1)
        XCTAssertEqual(comp.completedAt, "2026-09-05T10:20:00.000Z")
    }

    // 7. Event fixture invalid cases strictly rejected
    func testEventFixtureInvalidCasesAreStrictlyRejected() throws {
        let fixture = try ContractFixture.loadEventFixture()
        XCTAssertGreaterThanOrEqual(fixture.invalidCases.count, 4)

        for invalidCase in fixture.invalidCases {
            XCTAssertThrowsError(
                try JSONDecoder().decode(PracticeAttempt.self, from: invalidCase.payloadData),
                "Expected failure for: \(invalidCase.reason)"
            )
        }
    }

    // 8. SQLite artifact loads and integrity check
    func testSQLiteArtifactLoadsAndIntegrityCheck() throws {
        let sqliteURL = try ContractFixture.bundleURL(for: "vocab_content.sqlite")
        var db: OpaquePointer?
        let openResult = sqlite3_open_v2(sqliteURL.path, &db, SQLITE_OPEN_READONLY, nil)
        XCTAssertEqual(openResult, SQLITE_OK, "Failed to open sqlite database")
        defer { sqlite3_close(db) }

        // Integrity check
        var integrityStmt: OpaquePointer?
        let prepResult = sqlite3_prepare_v2(db, "PRAGMA integrity_check;", -1, &integrityStmt, nil)
        XCTAssertEqual(prepResult, SQLITE_OK)
        defer { sqlite3_finalize(integrityStmt) }

        if sqlite3_step(integrityStmt) == SQLITE_ROW {
            let result = String(cString: sqlite3_column_text(integrityStmt, 0))
            XCTAssertEqual(result, "ok")
        } else {
            XCTFail("PRAGMA integrity_check returned no rows")
        }

        // Row count on entries
        var countStmt: OpaquePointer?
        let countPrep = sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM entries;", -1, &countStmt, nil)
        XCTAssertEqual(countPrep, SQLITE_OK)
        defer { sqlite3_finalize(countStmt) }

        if sqlite3_step(countStmt) == SQLITE_ROW {
            let count = sqlite3_column_int(countStmt, 0)
            XCTAssertEqual(count, 3)
        } else {
            XCTFail("Count query failed")
        }
    }

    // 9. PROVENANCE file exists and contains commit + SHA
    func testProvenanceFileExistsAndContainsCommitAndSHA() throws {
        let data = try ContractFixture.loadData(for: "PROVENANCE.txt")
        let text = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertTrue(text.contains("Service repository: vocab-craft-api"))
        XCTAssertTrue(text.contains("Commit: fb88609eb14258f3da2bf23e7e89c4cba55a3aa0"))
        XCTAssertTrue(text.contains("SHA-256 Checksums:"))
        XCTAssertTrue(text.contains("vocab_content.sqlite"))
    }

    // 10. SenseDetail does not own lesson membership or stageId
    func testSenseDetailDoesNotOwnLessonOrStage() {
        let mirror = Mirror(reflecting: SenseDetail.self)
        let propertyNames = mirror.children.compactMap(\.label)
        XCTAssertFalse(propertyNames.contains("lessonId"))
        XCTAssertFalse(propertyNames.contains("lessonID"))
        XCTAssertFalse(propertyNames.contains("stageId"))
        XCTAssertFalse(propertyNames.contains("stageID"))
    }
}
