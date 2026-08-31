import Foundation

public final class SampleVocabularyDataSource: VocabularyDataSourceProtocol, Sendable {
    // Precomputed indexes for O(1) lookups — avoids O(N*M) scans for 3000+ words.
    private static let wordsByStage: [String: [TopicWordDTO]] = Dictionary(grouping: VocabularySampleDataset.words, by: \.stageId)
    private static let stagesByDeck: [String: [SubTopicStageDTO]] = Dictionary(grouping: VocabularySampleDataset.stages, by: \.deckId)
    private static let wordById: [Int64: TopicWordDTO] = Dictionary(VocabularySampleDataset.words.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    public init() {}

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        VocabularySampleDataset.decks.sorted { $0.sortOrder < $1.sortOrder }
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        (Self.stagesByDeck[deckId] ?? []).sorted { $0.sortOrder < $1.sortOrder }
    }

    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        Self.wordsByStage[stageId] ?? []
    }

    public func searchWords(query: String) async throws -> [TopicWordDTO] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return VocabularySampleDataset.words }
        return VocabularySampleDataset.words.filter {
            $0.lemma.lowercased().contains(trimmed) ||
            $0.definitionVi.lowercased().contains(trimmed) ||
            $0.definitionEn.lowercased().contains(trimmed)
        }
    }

    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        Self.wordById[id]
    }
}
