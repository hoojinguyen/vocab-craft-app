import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Bundled Vocabulary Data Source Tests")
struct BundledVocabularyDataSourceTests {
    @Test("Loads and decodes valid vocabulary catalog correctly")
    func loadsCatalogSuccessfully() async throws {
        let dataSource = BundledVocabularyDataSource()
        let decks = try await dataSource.fetchAllDecks()
        #expect(!decks.isEmpty)
        #expect(decks.count == 4)
        #expect(decks.contains { $0.id == "deck_daily" })

        let stages = try await dataSource.fetchStages(for: "deck_daily")
        #expect(!stages.isEmpty)
        #expect(stages.count == 2)

        let words = try await dataSource.fetchWords(for: stages[0].id)
        #expect(!words.isEmpty)

        let word = try await dataSource.fetchWord(id: words[0].id)
        #expect(word?.id == words[0].id)

        // Verify total inventory invariants
        let allWordsMap = try await dataSource.fetchAllWordsMap()
        #expect(allWordsMap.count == 50)
    }

    @Test("Searches words across catalog by lemma and definition")
    func searchesWordsSuccessfully() async throws {
        let dataSource = BundledVocabularyDataSource()

        let results = try await dataSource.searchWords(query: "Resilience")
        #expect(!results.isEmpty)
        #expect(results.first?.lemma.localizedCaseInsensitiveContains("resilience") == true)

        let viResults = try await dataSource.searchWords(query: "kiên cường")
        #expect(!viResults.isEmpty)
        #expect(viResults.contains { $0.lemma == "Resilience" })

        let emptyResults = try await dataSource.searchWords(query: "")
        #expect(emptyResults.count == 50)

        let notFoundResults = try await dataSource.searchWords(query: "xyznonexistentword")
        #expect(notFoundResults.isEmpty)
    }

    @Test("Fetches decks and stages through VocabularyDataSourceProtocol")
    func protocolMethodsOperateCorrectly() async throws {
        let dataSource: any VocabularyDataSourceProtocol = BundledVocabularyDataSource()

        let decks = try await dataSource.fetchTopicDecks()
        #expect(decks.count == 4)

        let stages = try await dataSource.fetchSubTopicStages(deckId: "deck_tech")
        #expect(stages.count == 2)

        let words = try await dataSource.fetchWordsForStage(stageId: "stage_tech_1")
        #expect(words.count == 6)

        let singleWord = try await dataSource.fetchWordById(id: 26)
        #expect(singleWord?.lemma == "Algorithm")

        let batchWords = try await dataSource.fetchWordsByIds(ids: Set([28, 26, 27]))
        #expect(batchWords.count == 3)
        #expect(batchWords.map(\.id) == [26, 27, 28])
    }

    @Test("Fetches individual deck by ID")
    func fetchDeckById() async throws {
        let dataSource = BundledVocabularyDataSource()

        let deck = try await dataSource.fetchDeck(id: "deck_academic")
        #expect(deck != nil)
        #expect(deck?.title == "Học Thuật & IELTS")

        let missing = try await dataSource.fetchDeck(id: "deck_unknown")
        #expect(missing == nil)
    }

    @Test("Throws resourceNotFound error for invalid resource name")
    func throwsWhenResourceNotFound() async {
        let dataSource = BundledVocabularyDataSource(resourceName: "non_existent_resource_xyz")
        await #expect(throws: VocabularyCatalogError.self) {
            _ = try await dataSource.fetchAllDecks()
        }
    }
}
