import XCTest
@testable import VocabCraftApp

final class SampleVocabularyDataSourceTests: XCTestCase {
    func test_fetchTopicDecks_returnsFourCuratedDecks() async throws {
        let sut = SampleVocabularyDataSource()
        let decks = try await sut.fetchTopicDecks()
        XCTAssertEqual(decks.count, 4)
        XCTAssertEqual(decks.map(\.id), ["deck_daily", "deck_business", "deck_tech", "deck_academic"])
    }

    func test_fetchWordsAcrossAllStages_returnsFiftyTotalWords() async throws {
        let sut = SampleVocabularyDataSource()
        let decks = try await sut.fetchTopicDecks()
        var totalWordsCount = 0
        for deck in decks {
            let stages = try await sut.fetchSubTopicStages(deckId: deck.id)
            for stage in stages {
                let words = try await sut.fetchWordsForStage(stageId: stage.id)
                totalWordsCount += words.count
            }
        }
        XCTAssertEqual(totalWordsCount, 50)
    }

    func test_searchWords_returnsMatchingEntries() async throws {
        let sut = SampleVocabularyDataSource()
        let results = try await sut.searchWords(query: "Resilience")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.lemma, "Resilience")
    }
}
