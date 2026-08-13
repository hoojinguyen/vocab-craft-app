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
}

@Suite("DatasetDataSource Protocol Tests")
@MainActor
struct DatasetDataSourceTests {
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
}
