@testable import VocabCraftApp
import XCTest

final class SQLiteContentRepositoryTests: XCTestCase {
    func testInitializationThrowsOnMissingFile() {
        let missingURL = FileManager.default.temporaryDirectory.appendingPathComponent("missing.sqlite")
        XCTAssertThrowsError(try SQLiteContentRepository(url: missingURL))
    }

    func testFetchDecksAndStages() async throws {
        let originalURL = try resolveBundledDatabaseURL()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_vocab_content.sqlite")
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        try FileManager.default.copyItem(at: originalURL, to: tempURL)

        let repo = try SQLiteContentRepository(url: tempURL)
        let decks = try await repo.fetchTopicDecks()
        XCTAssertFalse(decks.isEmpty)
        XCTAssertEqual(decks, decks.sorted(by: { $0.sortOrder < $1.sortOrder }))
        guard let firstDeck = decks.first else { return }
        XCTAssertFalse(firstDeck.title.isEmpty)
        XCTAssertFalse(firstDeck.iconName.isEmpty)

        let stages = try await repo.fetchSubTopicStages(deckId: firstDeck.id)
        XCTAssertFalse(stages.isEmpty)
        XCTAssertEqual(stages, stages.sorted(by: { $0.sortOrder < $1.sortOrder }))
        for stage in stages {
            XCTAssertEqual(stage.deckId, firstDeck.id)
            XCTAssertFalse(stage.title.isEmpty)
        }

        let nonExistentStages = try await repo.fetchSubTopicStages(deckId: "nonexistent-deck-id")
        XCTAssertTrue(nonExistentStages.isEmpty)
    }

    func testFetchWordsAndSearch() async throws {
        let originalURL = try resolveBundledDatabaseURL()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_vocab_content.sqlite")
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        try FileManager.default.copyItem(at: originalURL, to: tempURL)

        let repo = try SQLiteContentRepository(url: tempURL)

        let words = try await repo.searchWords(query: "hello")
        XCTAssertFalse(words.isEmpty)

        if let first = words.first {
            let fetched = try await repo.fetchWordById(id: first.id)
            XCTAssertEqual(first.id, fetched?.id)
            XCTAssertEqual(first.lemma, fetched?.lemma)
            XCTAssertEqual(first.pos, fetched?.pos)
            XCTAssertEqual(first.definitionEn, fetched?.definitionEn)
            XCTAssertEqual(first.definitionVi, fetched?.definitionVi)
        }

        let nonExistent = try await repo.fetchWordById(id: 999_999_999)
        XCTAssertNil(nonExistent)
    }

    func testFetchWordsForStage() async throws {
        let originalURL = try resolveBundledDatabaseURL()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_vocab_content.sqlite")
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try FileManager.default.removeItem(at: tempURL)
        }
        try FileManager.default.copyItem(at: originalURL, to: tempURL)

        let repo = try SQLiteContentRepository(url: tempURL)
        let decks = try await repo.fetchTopicDecks()
        guard let firstDeck = decks.first else {
            XCTFail("Expected at least one deck")
            return
        }
        let stages = try await repo.fetchSubTopicStages(deckId: firstDeck.id)
        guard let firstStage = stages.first else {
            XCTFail("Expected at least one stage")
            return
        }

        let stageWords = try await repo.fetchWordsForStage(stageId: firstStage.id)
        XCTAssertFalse(stageWords.isEmpty)
        for word in stageWords {
            XCTAssertEqual(word.stageId, firstStage.id)
            XCTAssertFalse(word.lemma.isEmpty)
            XCTAssertFalse(word.definitionEn.isEmpty)
        }

        let emptyWords = try await repo.fetchWordsForStage(stageId: "nonexistent-stage")
        XCTAssertTrue(emptyWords.isEmpty)
    }

    private func resolveBundledDatabaseURL() throws -> URL {
        let testBundle = Bundle(for: type(of: self))
        if let url = testBundle.url(forResource: "vocab_content", withExtension: "sqlite") {
            return url
        }
        if let subURL = testBundle.url(
            forResource: "vocab_content",
            withExtension: "sqlite",
            subdirectory: "VocabCraftApp_VocabCraftApp.bundle/Contents/Resources"
        ) {
            return subURL
        }
        if let subURL = testBundle.url(
            forResource: "vocab_content",
            withExtension: "sqlite",
            subdirectory: "VocabCraftApp_VocabCraftApp.bundle"
        ) {
            return subURL
        }
        let currentFilePath = URL(fileURLWithPath: #filePath)
        let sourceURL = currentFilePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("VocabCraftApp/Resources/Content/vocab_content.sqlite")
        if FileManager.default.fileExists(atPath: sourceURL.path) {
            return sourceURL
        }
        struct MissingBundledDatabaseError: Error {}
        throw MissingBundledDatabaseError()
    }
}
