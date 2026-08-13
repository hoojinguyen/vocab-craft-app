import Foundation

/// Production repository implementation connecting SQLite dataset engine and SwiftData user progress actor.
@MainActor
public final class VocabularyRepositoryImpl: VocabularyRepositoryProtocol {
    private let datasetEngine: DatasetDataSourceProtocol?
    private let progressActor: UserProgressModelActor?

    /// Creates a production vocabulary repository with optional dataset engine and progress actor dependencies.
    ///
    /// - Parameters:
    ///   - datasetEngine: The SQLite dataset engine instance or mock implementing DatasetDataSourceProtocol.
    ///   - progressActor: The SwiftData background actor for user progress operations.
    public init(datasetEngine: DatasetDataSourceProtocol? = nil, progressActor: UserProgressModelActor? = nil) {
        self.datasetEngine = datasetEngine
        self.progressActor = progressActor
    }

    /// Fetches vocabulary word records up to the specified limit.
    public func fetchWordRecords(limit: Int) async throws -> [Word] {
        guard let engine = datasetEngine else { return [] }
        let records = engine.fetchWordRecords(limit: limit)
        return records.map { r in
            Word(
                id: r.id,
                lemma: r.lemma,
                pos: r.pos ?? "",
                ipaUs: r.ipaUs ?? "",
                cefrLevel: r.cefrLevel ?? "",
                definitionEn: r.definitionEn ?? "",
                definitionVi: r.definitionVi ?? "",
                example: r.example ?? ""
            )
        }
    }

    /// Fetches a single word by its unique database identifier.
    public func fetchWord(id: Int64) async throws -> Word? {
        guard let engine = datasetEngine, let r = engine.fetchWordById(id: id) else { return nil }
        return Word(
            id: r.id,
            lemma: r.lemma,
            pos: r.pos ?? "",
            ipaUs: r.ipaUs ?? "",
            cefrLevel: r.cefrLevel ?? "",
            definitionEn: r.definitionEn ?? "",
            definitionVi: r.definitionVi ?? "",
            example: r.example ?? ""
        )
    }

    /// Fetches reflex drill prompt records matching the specified CEFR level.
    public func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillRecord] {
        guard let engine = datasetEngine, let record = engine.getRandomReflexDrill(cefrLevel: cefrLevel) else { return [] }
        return [record]
    }

    /// Searches vocabulary words matching the given query string.
    public func searchWords(query: String) async throws -> [Word] {
        guard let engine = datasetEngine else { return [] }
        let records = engine.searchWords(query: query)
        return records.map { r in
            Word(
                id: r.id,
                lemma: r.lemma,
                pos: r.pos ?? "",
                ipaUs: r.ipaUs ?? "",
                cefrLevel: r.cefrLevel ?? "",
                definitionEn: r.definitionEn ?? "",
                definitionVi: r.definitionVi ?? "",
                example: r.example ?? ""
            )
        }
    }

    /// Fetches daily suggested words.
    public func fetchSuggestedWords(limit: Int) async throws -> [SuggestedWord] {
        guard let engine = datasetEngine else { return MockVocabularyDataSource.shared.mockSuggestedWords }
        let records = engine.fetchWordRecords(limit: limit)
        if records.isEmpty {
            return MockVocabularyDataSource.shared.mockSuggestedWords
        }
        return records.map { r in
            SuggestedWord(
                id: String(r.id),
                lemma: r.lemma,
                pos: r.pos ?? "",
                ipaUs: r.ipaUs ?? "",
                cefrLevel: r.cefrLevel ?? "",
                definitionVi: r.definitionVi ?? "",
                definitionEn: r.definitionEn ?? "",
                example: r.example ?? "",
                isBookmarked: false,
                topicTag: "Từ vựng nổi bật"
            )
        }
    }

    /// Fetches available topic decks and their associated subtopic nodes.
    public func fetchTopicDecks() async throws -> [TopicDeck] {
        return MockVocabularyDataSource.shared.mockTopicDecks
    }
}
