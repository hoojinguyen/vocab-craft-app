import Foundation
import Testing
@testable import VocabCraftApp

@MainActor
final class MockDatasetDataSource: DatasetDataSourceProtocol {
    var mockRecords: [WordRecord] = [
        WordRecord(id: 1, lemma: "eloquent", pos: "adj", ipaUs: "/ˈel.ə.kwənt/", cefrLevel: "C1", definitionEn: "expressive", definitionVi: "hùng hồn", example: "An eloquent speech"),
        WordRecord(id: 2, lemma: "pragmatic", pos: "adj", ipaUs: "/præɡˈmæt.ɪk/", cefrLevel: "B2", definitionEn: "practical", definitionVi: "thực tế", example: "A pragmatic approach")
    ]

    func getRandomReflexDrill(cefrLevel: String) -> ReflexDrillRecord? {
        ReflexDrillRecord(
            id: 1,
            drillType: "speak",
            promptText: "Một cách tiếp cận thực tế",
            correctAnswer: "A pragmatic approach",
            distractors: [],
            targetTimeMs: 2000,
            sentenceTextEn: "A pragmatic approach"
        )
    }

    func getWordDetails(lemma: String) -> WordRecord? {
        mockRecords.first(where: { $0.lemma == lemma })
    }

    func fetchWordRecords(limit: Int, cefrLevel: String? = nil) -> [WordRecord] {
        Array(mockRecords.prefix(limit))
    }

    func searchWords(query searchQuery: String) -> [WordRecord] {
        mockRecords.filter { $0.lemma.contains(searchQuery) }
    }

    func fetchWordById(id targetId: Int64) -> WordRecord? {
        mockRecords.first(where: { $0.id == targetId })
    }

    func getRandomWordForWidget() -> WordRecord? {
        mockRecords.first
    }

    func fetchTopicDecks() -> [TopicDeckRecord] {
        [
            TopicDeckRecord(id: "deck1", title: "Technology", iconName: "cpu", badgeColorHex: "#00FF00", sortOrder: 1)
        ]
    }

    func fetchTopicDecksSummary() -> [TopicDeckSummaryRecord] {
        [
            TopicDeckSummaryRecord(id: "deck1", title: "Technology", iconName: "cpu", badgeColorHex: "#00FF00", sortOrder: 1, totalWords: 2)
        ]
    }

    func fetchDeckWordIdsMap() -> [String: [Int64]] {
        [
            "deck1": [1, 2]
        ]
    }

    func fetchSubTopicNodes(deckId: String) -> [SubTopicNodeRecord] {
        if deckId == "deck1" {
            return [
                SubTopicNodeRecord(id: "node1", deckId: "deck1", title: "AI Basics", iconName: "brain", sortOrder: 1)
            ]
        }
        return []
    }

    func fetchWordsForNode(nodeId: String) -> [WordRecord] {
        if nodeId == "node1" {
            return mockRecords
        }
        return []
    }
}

@Suite("DatasetDataSource Protocol Tests")
@MainActor
struct DatasetDataSourceTests {
    @Test("Topic decks summary aggregation and deck word ids map")
    func testFetchTopicDecksSummaryAggregation() async throws {
        let mock = MockVocabularyDataSource.shared
        let summaries = mock.fetchTopicDecksSummary()
        #expect(!summaries.isEmpty)
        #expect(summaries[0].totalWords > 0)

        let wordMap = mock.fetchDeckWordIdsMap()
        #expect(!wordMap.isEmpty)
    }

    @Test("VocabularyRepositoryImpl successfully operates via DatasetDataSourceProtocol mock")
    func testRepositoryWithMockDataSource() async throws {
        let mockSource = MockDatasetDataSource()
        let repository = VocabularyRepositoryImpl(datasetEngine: mockSource)

        let words = try await repository.fetchWordRecords(limit: 10)
        #expect(words.count == 2)
        #expect(words.first?.lemma == "eloquent")

        let word = try await repository.fetchWord(id: 2)
        #expect(word?.lemma == "pragmatic")

        let search = try await repository.searchWords(query: "pragmatic")
        #expect(search.count == 1)
    }

    @Test("VocabularyRepositoryImpl fetchTopicDecks and fetchTopicDeckDetails batch progress lookup")
    func testRepositoryTopicDecksWithProgressActor() async throws {
        let container = try SharedAppGroupContainer.createContainer(inMemory: true)
        let actor = UserProgressModelActor(modelContainer: container)
        try await actor.saveProgress(wordId: 1, masteryLevel: 5, isBookmarked: true)
        try await actor.saveProgress(wordId: 2, masteryLevel: 3, isBookmarked: false)

        let mockSource = MockDatasetDataSource()
        let repository = VocabularyRepositoryImpl(datasetEngine: mockSource, progressActor: actor)

        let decks = try await repository.fetchTopicDecks()
        #expect(decks.count == 1)
        #expect(decks.first?.wordCount == 2)
        #expect(decks.first?.completionPercentage == 0.5)

        let nodes = try await repository.fetchTopicDeckDetails(deckId: "deck1")
        #expect(nodes.count == 1)
        #expect(nodes.first?.learnedWords == 1)
        #expect(nodes.first?.totalWords == 2)
        #expect(nodes.first?.state == .active)
        #expect(nodes.first?.words.count == 2)
        #expect(nodes.first?.words[0].isMastered == true)
        #expect(nodes.first?.words[0].isSavedToPersonalVault == true)
        #expect(nodes.first?.words[1].isMastered == false)
        #expect(nodes.first?.words[1].isSavedToPersonalVault == false)
    }
}
