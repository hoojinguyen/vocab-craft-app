import Foundation
@testable import VocabCraftApp
import XCTest

final class OfflineLearningAcceptanceTests: XCTestCase {
    private var tempDir: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OfflineAcceptance_\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        try super.tearDownWithError()
    }

    @MainActor
    func testProductionBundleLoadsOfflineWithoutNetwork() async throws {
        // Given: Production container operating strictly from embedded bundle
        let container = AppContainer(useSampleData: false)
        XCTAssertEqual(container.contentAvailability, .ready)

        let repo = try XCTUnwrap(container.contentRepository)

        // When: Fetching topic decks offline
        let decks = try await repo.fetchDecks()

        // Then: Golden first-release deck is returned
        XCTAssertEqual(decks.count, 1)
        let deck = try XCTUnwrap(decks.first)
        XCTAssertEqual(deck.titleEn, "Everyday Travel & Service")
        XCTAssertEqual(deck.titleVi, "Giao tiếp hàng ngày & Dịch vụ")

        // When: Fetching lessons offline
        let lessons = try await repo.fetchLessons(deckID: deck.id)
        XCTAssertEqual(lessons.count, 5, "First release must contain exactly 5 lessons")

        // Then: Each lesson contains 10-15 senses with complete bilingual content
        for lesson in lessons {
            let fullLesson = try await repo.fetchLessonContent(lessonID: lesson.id)
            XCTAssertGreaterThanOrEqual(fullLesson.senses.count, 10)
            XCTAssertLessThanOrEqual(fullLesson.senses.count, 15)

            for sense in fullLesson.senses {
                XCTAssertFalse(sense.headword.isEmpty)
                XCTAssertFalse(sense.definitionEn.isEmpty)
                XCTAssertFalse(sense.definitionVi.isEmpty)

                let detail = try await repo.fetchSense(senseID: sense.id)
                XCTAssertNotNil(detail)
                XCTAssertFalse(detail?.examples.isEmpty ?? true, "Sense \(sense.headword) must have examples")
                let example = detail?.examples.first
                XCTAssertFalse(example?.textEn.isEmpty ?? true)
                XCTAssertFalse(example?.textVi.isEmpty ?? true)
            }
        }
    }

    @MainActor
    func testOfflineSenseProgressionAndJournalPersistenceAcrossRelaunch() async throws {
        // Given: An isolated offline journal file simulating device local storage
        let journalURL = tempDir.appendingPathComponent("learning_journal.sqlite")
        let initialJournal = try LearningJournal(url: journalURL)
        let guestProfileID = try await initialJournal.createGuestProfile()

        let container1 = AppContainer(
            useSampleData: false,
            learningJournal: initialJournal
        )
        let repo = try XCTUnwrap(container1.contentRepository)
        let decks = try await repo.fetchDecks()
        let deck = try XCTUnwrap(decks.first)
        let lessons = try await repo.fetchLessons(deckID: deck.id)
        XCTAssertGreaterThanOrEqual(lessons.count, 2)

        let lesson1 = lessons[0]
        let lesson2 = lessons[1]

        // When: Completing lesson 1 in offline mode
        let completion = TestCompletion.make(
            originProfileID: guestProfileID,
            lessonID: lesson1.id,
            lessonRevision: lesson1.revision
        )
        try await initialJournal.complete(completion, profileID: guestProfileID)

        // Verify adapter reflects progression immediately
        let adapter1 = ContentLearningPathAdapter(
            repository: repo,
            journal: initialJournal,
            profileID: guestProfileID
        )
        let sections1 = try await adapter1.load()
        XCTAssertEqual(sections1.count, 1)
        let nodes1 = sections1[0].nodes
        XCTAssertEqual(nodes1[0].state, .completed)
        XCTAssertEqual(nodes1[0].stars, 3)
        XCTAssertEqual(nodes1[1].state, .active)

        // Then: Simulate App Relaunch (create new container and journal instance pointing to same file)
        let relaunchedJournal = try LearningJournal(url: journalURL)
        let container2 = AppContainer(
            useSampleData: false,
            learningJournal: relaunchedJournal
        )
        let relaunchedRepo = try XCTUnwrap(container2.contentRepository)
        let adapter2 = ContentLearningPathAdapter(
            repository: relaunchedRepo,
            journal: relaunchedJournal,
            profileID: guestProfileID
        )
        let sections2 = try await adapter2.load()
        XCTAssertEqual(sections2.count, 1)
        let nodes2 = sections2[0].nodes

        // Verified: Progression is 100% preserved across app relaunch without network!
        XCTAssertEqual(nodes2[0].state, .completed)
        XCTAssertEqual(nodes2[0].stars, 3)
        XCTAssertEqual(nodes2[1].state, .active)
    }
}
