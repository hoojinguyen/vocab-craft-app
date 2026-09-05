import CraftUIKit
import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class ContentLearningPathAdapterTests: XCTestCase {
    func testLearningPathUsesServiceContent() async throws {
        let repository = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let journal = try LearningJournal(url: ContractFixture.temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let adapter = ContentLearningPathAdapter(
            repository: repository,
            journal: journal,
            profileID: profile
        )
        let sections = try await adapter.load()
        XCTAssertEqual(sections.count, 1)
        let section = sections[0]
        XCTAssertEqual(section.nodes.count, 2)

        let expected = try ContractFixture.expected()
        XCTAssertEqual(section.nodes[0].id, expected.orderedLessonIDs[0].rawValue.uuidString.lowercased())
        XCTAssertEqual(section.nodes[1].id, expected.orderedLessonIDs[1].rawValue.uuidString.lowercased())
        XCTAssertEqual(section.nodes[0].state, .active)
        XCTAssertEqual(section.nodes[1].state, .upcoming)
    }

    func testAdapterReflectsLessonCompletion() async throws {
        let repository = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let journal = try LearningJournal(url: ContractFixture.temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        let completion = TestCompletion.make(
            originProfileID: profile,
            lessonID: expected.orderedLessonIDs[0],
            lessonRevision: 1
        )
        try await journal.complete(completion, profileID: profile)

        let adapter = ContentLearningPathAdapter(
            repository: repository,
            journal: journal,
            profileID: profile
        )
        let sections = try await adapter.load()
        XCTAssertEqual(sections.count, 1)
        let nodes = sections[0].nodes
        XCTAssertEqual(nodes[0].state, .completed)
        XCTAssertEqual(nodes[0].stars, 3)
        XCTAssertEqual(nodes[1].state, .active)
    }

    func testSharedSenseAcrossLessonsDoesNotDuplicateInGlobalVault() async throws {
        let repository = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let journal = try LearningJournal(url: ContractFixture.temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        // Complete both lessons which share bookVerbID
        for lessonID in expected.orderedLessonIDs {
            let completion = TestCompletion.make(
                originProfileID: profile,
                lessonID: lessonID,
                lessonRevision: 1
            )
            try await journal.complete(completion, profileID: profile)
        }

        let useCase = FetchPersonalVaultUseCase(
            contentRepository: repository,
            journal: journal,
            profileID: profile
        )
        let vaultResult = try await useCase.execute()
        let senseIDs = vaultResult.words.compactMap(\.senseID)
        let uniqueSenseIDs = Set(senseIDs)
        XCTAssertEqual(senseIDs.count, uniqueSenseIDs.count, "Global vault must not contain duplicate senses")
        XCTAssertTrue(uniqueSenseIDs.contains(expected.bookVerbID))
    }

    func testAdapterRequiresMatchingLessonRevisionForCompletion() async throws {
        let repository = try SQLiteContentRepository(
            url: ContractFixture.bundleURL(),
            manifest: ContractFixture.manifest()
        )
        let journal = try LearningJournal(url: ContractFixture.temporaryJournalURL())
        let profile = try await journal.createGuestProfile()
        let expected = try ContractFixture.expected()

        let completion = TestCompletion.make(
            originProfileID: profile,
            lessonID: expected.orderedLessonIDs[0],
            lessonRevision: 99
        )
        try await journal.complete(completion, profileID: profile)

        let adapter = ContentLearningPathAdapter(
            repository: repository,
            journal: journal,
            profileID: profile
        )
        let sections = try await adapter.load()
        XCTAssertEqual(sections.count, 1)
        let nodes = sections[0].nodes
        XCTAssertEqual(nodes[0].state, .active, "Mismatched revision must not mark lesson as completed")
    }
}
