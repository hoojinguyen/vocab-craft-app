import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

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

    func test_fetchWordsByIds_returnsMatchingWords() async throws {
        let sut = SampleVocabularyDataSource()
        let words = try await sut.fetchWordsByIds(ids: [1, 2, 3])
        XCTAssertEqual(words.count, 3)
        let ids = Set(words.map(\.id))
        XCTAssertEqual(ids, [1, 2, 3])

        let emptyResult = try await sut.fetchWordsByIds(ids: [])
        XCTAssertTrue(emptyResult.isEmpty)

        let nonexistentResult = try await sut.fetchWordsByIds(ids: [999999])
        XCTAssertTrue(nonexistentResult.isEmpty)

        let mixedResult = try await sut.fetchWordsByIds(ids: [1, 999999])
        XCTAssertEqual(mixedResult.count, 1)
        XCTAssertEqual(mixedResult.first?.id, 1)
    }

    func test_fetchAllWordsMap_returnsFiftyWordsIndexedById() async throws {
        let sut = SampleVocabularyDataSource()
        let wordsMap = try await sut.fetchAllWordsMap()
        XCTAssertEqual(wordsMap.count, 50)
        for (id, word) in wordsMap {
            XCTAssertEqual(word.id, id)
        }
        XCTAssertNotNil(wordsMap[1])
        XCTAssertEqual(wordsMap[1]?.id, 1)
    }
}
