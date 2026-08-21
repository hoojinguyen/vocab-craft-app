import Foundation

public final class SampleVocabularyDataSource: VocabularyDataSourceProtocol, Sendable {
    public init() {}

    public func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        VocabularySampleDataset.decks.sorted { $0.sortOrder < $1.sortOrder }
    }

    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        VocabularySampleDataset.stages
            .filter { $0.deckId == deckId }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        VocabularySampleDataset.words.filter { $0.stageId == stageId }
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
        VocabularySampleDataset.words.first { $0.id == id }
    }
}
