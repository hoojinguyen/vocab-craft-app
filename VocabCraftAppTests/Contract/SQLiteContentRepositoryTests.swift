import Foundation
import SQLite3
@testable import VocabCraftApp
import XCTest

final class SQLiteContentRepositoryTests: XCTestCase {
    // 1. Vietnamese text preservation (exact brief test)
    func testServiceBundlePreservesVietnameseExample() async throws {
        let expected = try ContractFixture.expected()
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let sense = try await repo.fetchSense(senseID: expected.bookVerbID)
        XCTAssertEqual(sense?.examples.first?.textVi, expected.bookVerbExampleVi)
        XCTAssertEqual(sense?.definitionVi, "đặt chỗ, đặt vé trước")
    }

    // 2. Distinct senses for "book" (noun vs verb)
    func testBookSensesDistinctNounVsVerb() async throws {
        let expected = try ContractFixture.expected()
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let bookEntryID = try XCTUnwrap(EntryID(uuidString: "a0000000-0000-4000-8000-000000000001"))
        let entry = try await repo.fetchEntry(entryID: bookEntryID)
        let unwrappedEntry = try XCTUnwrap(entry)
        XCTAssertEqual(unwrappedEntry.headword, "book")
        XCTAssertEqual(unwrappedEntry.senses.count, 2)

        let nounID = try XCTUnwrap(SenseID(uuidString: "b0000000-0000-4000-8000-000000000001"))
        let verbID = expected.bookVerbID

        let nounSense = try await repo.fetchSense(senseID: nounID)
        let verbSense = try await repo.fetchSense(senseID: verbID)

        let unwrappedNoun = try XCTUnwrap(nounSense)
        let unwrappedVerb = try XCTUnwrap(verbSense)

        XCTAssertEqual(unwrappedNoun.partOfSpeech, .noun)
        XCTAssertEqual(unwrappedVerb.partOfSpeech, .verb)
        XCTAssertNotEqual(unwrappedNoun.id, unwrappedVerb.id)
        XCTAssertNotEqual(unwrappedNoun.definitionVI, unwrappedVerb.definitionVI)
        XCTAssertEqual(unwrappedNoun.cefrLevel, .a1)
        XCTAssertEqual(unwrappedVerb.cefrLevel, .a2)
    }

    // 3. Shared membership across lessons without duplicating global sense records
    func testSharedMembershipAcrossLessonsNoDuplicateGlobalRecords() async throws {
        let expected = try ContractFixture.expected()
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )

        let lesson1ID = try XCTUnwrap(LessonID(uuidString: "d1000000-0000-4000-8000-000000000001"))
        let lesson2ID = try XCTUnwrap(LessonID(uuidString: "d1000000-0000-4000-8000-000000000002"))

        let lesson1 = try await repo.fetchLessonContent(lessonID: lesson1ID)
        let lesson2 = try await repo.fetchLessonContent(lessonID: lesson2ID)

        let lesson1SenseIDs = lesson1.senses.map(\.senseID)
        let lesson2SenseIDs = lesson2.senses.map(\.senseID)

        XCTAssertTrue(lesson1SenseIDs.contains(expected.bookVerbID))
        XCTAssertTrue(lesson2SenseIDs.contains(expected.bookVerbID))

        // Both refer to identical SenseDetail in database
        let sense1 = try await repo.fetchSense(senseID: expected.bookVerbID)
        let sense2 = try await repo.fetchSense(senseID: expected.bookVerbID)
        XCTAssertEqual(sense1?.id, sense2?.id)
        XCTAssertEqual(sense1?.definitionVI, sense2?.definitionVI)
    }

    // 4. Fetch decks with derived CEFR levels
    func testFetchDecksAndDerivedCefrLevels() async throws {
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let decks = try await repo.fetchDecks()
        XCTAssertEqual(decks.count, 1)

        let deck = decks[0]
        XCTAssertEqual(deck.titleEN, "Core Vocabulary")
        XCTAssertEqual(deck.titleVI, "Từ vựng cốt lõi")
        XCTAssertEqual(deck.iconKey, "book_open")
        XCTAssertEqual(deck.themeKey, "ocean_blue")
        // CEFR levels derived from senses in deck: A1, A2, B1
        XCTAssertEqual(deck.cefrLevels, [.a1, .a2, .b1])
    }

    // 5. Fetch lessons for deck with sort order and sense counts
    func testFetchLessonsForDeck() async throws {
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let deckID = try XCTUnwrap(DeckID(uuidString: "d0000000-0000-4000-8000-000000000001"))
        let lessons = try await repo.fetchLessons(deckID: deckID)

        XCTAssertEqual(lessons.count, 2)
        XCTAssertEqual(lessons[0].titleEN, "Travel Essentials")
        XCTAssertEqual(lessons[0].sortOrder, 0)
        XCTAssertEqual(lessons[0].senses.count, 2)

        XCTAssertEqual(lessons[1].titleEN, "Daily Actions")
        XCTAssertEqual(lessons[1].sortOrder, 1)
        XCTAssertEqual(lessons[1].senses.count, 3)
    }

    // 6. Fetch batch senses preserving requested order
    func testFetchSensesBatchPreservesOrder() async throws {
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let id1 = try XCTUnwrap(SenseID(uuidString: "b0000000-0000-4000-8000-000000000002"))
        let id2 = try XCTUnwrap(SenseID(uuidString: "b0000000-0000-4000-8000-000000000001"))
        let nonExistentID = try XCTUnwrap(SenseID(uuidString: "b0000000-0000-4000-8000-000000000099"))

        let senses = try await repo.fetchSenses(ids: [id1, nonExistentID, id2])
        XCTAssertEqual(senses.count, 2)
        XCTAssertEqual(senses[0].id, id1)
        XCTAssertEqual(senses[1].id, id2)
    }

    // 7. Non-existent entities return nil or throw entityNotFound
    func testFetchNonExistentEntities() async throws {
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let nonExistentSenseID = try XCTUnwrap(SenseID(uuidString: "b0000000-0000-4000-8000-000000000099"))
        let sense = try await repo.fetchSense(senseID: nonExistentSenseID)
        XCTAssertNil(sense)

        let nonExistentEntryID = try XCTUnwrap(EntryID(uuidString: "a0000000-0000-4000-8000-000000000099"))
        let entry = try await repo.fetchEntry(entryID: nonExistentEntryID)
        XCTAssertNil(entry)

        let nonExistentLessonID = try XCTUnwrap(LessonID(uuidString: "d1000000-0000-4000-8000-000000000099"))
        do {
            _ = try await repo.fetchLessonContent(lessonID: nonExistentLessonID)
            XCTFail("Expected entityNotFound error for missing lesson")
        } catch let ContentRepositoryError.entityNotFound(details) {
            XCTAssertTrue(details.contains(nonExistentLessonID.description))
        }
    }

    // 8. Missing database file throws typed error
    func testMissingDatabaseThrowsTypedError() throws {
        let manifest = try ContractFixture.manifest()
        let missingURL = URL(fileURLWithPath: "/tmp/non_existent_vocab_\(UUID().uuidString).sqlite")
        XCTAssertThrowsError(try SQLiteContentRepository(url: missingURL, manifest: manifest)) { error in
            guard case ContentRepositoryError.missingDatabase = error else {
                XCTFail("Expected missingDatabase error, got \(error)")
                return
            }
        }
    }

    // 9. Corrupted database throws typed error
    func testCorruptedDatabaseThrowsTypedError() throws {
        let manifest = try ContractFixture.manifest()
        let tempDir = FileManager.default.temporaryDirectory
        let corruptURL = tempDir.appendingPathComponent("corrupted_\(UUID().uuidString).sqlite")
        try Data("NOT_A_SQLITE_DATABASE".utf8).write(to: corruptURL)
        defer { try? FileManager.default.removeItem(at: corruptURL) }

        XCTAssertThrowsError(try SQLiteContentRepository(url: corruptURL, manifest: manifest)) { error in
            switch error {
            case ContentRepositoryError.corruptedDatabase, ContentRepositoryError.sqliteError:
                break // Valid typed errors
            default:
                XCTFail("Expected corruptedDatabase or sqliteError, got \(error)")
            }
        }
    }

    // 10. Schema version mismatch throws unsupportedSchema
    func testSchemaVersionMismatchThrowsUnsupportedSchema() throws {
        let originalManifest = try ContractFixture.manifest()
        let mismatchedManifest = ContentManifest(
            contentVersion: originalManifest.contentVersion,
            datasetSchemaVersion: 99,
            publishedAt: originalManifest.publishedAt,
            contentLanguage: originalManifest.contentLanguage,
            explanationLanguage: originalManifest.explanationLanguage,
            bundleURL: originalManifest.bundleURL,
            sha256: originalManifest.sha256,
            byteSize: originalManifest.byteSize,
            counts: originalManifest.counts
        )
        XCTAssertThrowsError(
            try SQLiteContentRepository(url: ContractFixture.bundleURL(), manifest: mismatchedManifest)
        ) { error in
            guard case ContentRepositoryError.unsupportedSchema(let expected, let actual) = error else {
                XCTFail("Expected unsupportedSchema error, got \(error)")
                return
            }
            XCTAssertEqual(expected, 1)
            XCTAssertEqual(actual, 99)
        }
    }

    // 11. Search: escaping special characters and matching EN/VI
    func testSearchEscapingAndLiteralCharacters() async throws {
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )

        // Wildcard characters % and _ should be treated literally
        let wildcardResult = try await repo.search(query: "%", limit: 10, cursor: nil)
        XCTAssertEqual(wildcardResult.senses.count, 0)

        let underscoreResult = try await repo.search(query: "_", limit: 10, cursor: nil)
        XCTAssertEqual(underscoreResult.senses.count, 0)

        // Search by headword
        let bookResult = try await repo.search(query: "book", limit: 10, cursor: nil)
        XCTAssertEqual(bookResult.senses.count, 2)

        // Search by Vietnamese definition
        let bookingResult = try await repo.search(query: "đặt vé", limit: 10, cursor: nil)
        XCTAssertEqual(bookingResult.senses.count, 1)
        XCTAssertEqual(bookingResult.senses[0].partOfSpeech, .verb)

        // Search by English definition
        let reserveResult = try await repo.search(query: "reserve", limit: 10, cursor: nil)
        XCTAssertEqual(reserveResult.senses.count, 1)
        XCTAssertEqual(reserveResult.senses[0].partOfSpeech, .verb)

        // Empty query returns bounded results
        let emptyResult = try await repo.search(query: "", limit: 2, cursor: nil)
        XCTAssertEqual(emptyResult.senses.count, 2)
    }

    // 12. Search: cursor pagination with version tagging
    func testSearchPaginationAndVersionTaggedCursor() async throws {
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )

        // Page 1 with limit 2
        let page1 = try await repo.search(query: "", limit: 2, cursor: nil)
        XCTAssertEqual(page1.senses.count, 2)
        XCTAssertTrue(page1.hasMore)
        let cursor1 = try XCTUnwrap(page1.nextCursor)
        XCTAssertEqual(page1.contentVersion, 1)

        // Page 2 using cursor
        let page2 = try await repo.search(query: "", limit: 2, cursor: cursor1)
        XCTAssertEqual(page2.senses.count, 2)
        XCTAssertFalse(page2.hasMore)

        // Senses across pages should be distinct
        let page1IDs = Set(page1.senses.map(\.senseID))
        let page2IDs = Set(page2.senses.map(\.senseID))
        XCTAssertTrue(page1IDs.isDisjoint(with: page2IDs))

        // Stale cursor from different version resets to beginning
        let staleCursor = Data("{\"v\":999,\"offset\":2}".utf8).base64EncodedString()
        let resetResult = try await repo.search(query: "", limit: 2, cursor: staleCursor)
        XCTAssertEqual(resetResult.senses.map(\.senseID), page1.senses.map(\.senseID))
    }

    // 13. Sense IPA resolution prioritizes sense-specific over entry-level
    func testSenseIPAResolution() async throws {
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )

        let bookNounID = try XCTUnwrap(SenseID(uuidString: "b0000000-0000-4000-8000-000000000001"))
        let bookSense = try await repo.fetchSense(senseID: bookNounID)
        let unwrappedSense = try XCTUnwrap(bookSense)
        // Entry has /bʊk/ for US and UK
        XCTAssertEqual(unwrappedSense.ipa, "/bʊk/")
        XCTAssertFalse(unwrappedSense.pronunciations.isEmpty)
    }

    // 14. Lesson content yields senses with distinct ordered sortOrders matching fixture
    func testLessonContentPreservesDistinctOrderedSortOrders() async throws {
        let repo = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )

        let lesson1ID = try XCTUnwrap(LessonID(uuidString: "d1000000-0000-4000-8000-000000000001"))
        let lesson1 = try await repo.fetchLessonContent(lessonID: lesson1ID)
        XCTAssertEqual(lesson1.senses.map(\.sortOrder), [0, 1])

        let lesson2ID = try XCTUnwrap(LessonID(uuidString: "d1000000-0000-4000-8000-000000000002"))
        let lesson2 = try await repo.fetchLessonContent(lessonID: lesson2ID)
        XCTAssertEqual(lesson2.senses.map(\.sortOrder), [0, 1, 2])
    }

    // 15. Missing required column throws corruptedDatabase instead of empty string
    func testMissingRequiredColumnThrowsCorruptedDatabase() async throws {
        let originalURL = try ContractFixture.bundleURL()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("corrupted_null_\(UUID().uuidString).sqlite")
        try FileManager.default.copyItem(at: originalURL, to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(tempURL.path, &db), SQLITE_OK)
        let dropSQL = """
        CREATE TABLE dummy_entries AS SELECT * FROM entries;
        DROP TABLE entries;
        CREATE TABLE entries (id TEXT PRIMARY KEY, headword TEXT, lookup_key TEXT, entry_kind TEXT, revision INTEGER);
        INSERT INTO entries SELECT id, NULL, lookup_key, entry_kind, revision FROM dummy_entries;
        """
        XCTAssertEqual(sqlite3_exec(db, dropSQL, nil, nil, nil), SQLITE_OK)
        sqlite3_close(db)

        let repo = try SQLiteContentRepository(url: tempURL, manifest: ContractFixture.manifest())
        let bookEntryID = try XCTUnwrap(EntryID(uuidString: "a0000000-0000-4000-8000-000000000001"))
        do {
            _ = try await repo.fetchEntry(entryID: bookEntryID)
            XCTFail("Expected corruptedDatabase error due to NULL headword")
        } catch let ContentRepositoryError.corruptedDatabase(details) {
            XCTAssertTrue(details.contains("headword"))
        }
    }

    // 16. Invalid sense ID string in pronunciation throws corruptedDatabase
    func testInvalidSenseIDInPronunciationThrowsCorruptedDatabase() async throws {
        let originalURL = try ContractFixture.bundleURL()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("corrupted_pron_\(UUID().uuidString).sqlite")
        try FileManager.default.copyItem(at: originalURL, to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open(tempURL.path, &db), SQLITE_OK)
        let updateSQL = "UPDATE pronunciations SET sense_id = 'not-a-valid-uuid' WHERE id = 'c1000000-0000-4000-8000-000000000001';"
        XCTAssertEqual(sqlite3_exec(db, updateSQL, nil, nil, nil), SQLITE_OK)
        sqlite3_close(db)

        let repo = try SQLiteContentRepository(url: tempURL, manifest: ContractFixture.manifest())
        let bookEntryID = try XCTUnwrap(EntryID(uuidString: "a0000000-0000-4000-8000-000000000001"))
        do {
            _ = try await repo.fetchEntry(entryID: bookEntryID)
            XCTFail("Expected corruptedDatabase error due to invalid sense_id in pronunciation")
        } catch let ContentRepositoryError.corruptedDatabase(details) {
            XCTAssertTrue(details.contains("not-a-valid-uuid") || details.contains("pronunciation"))
        }
    }
}
