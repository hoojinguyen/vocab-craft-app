import Foundation

/// Production repository implementation connecting vocabulary data source and SwiftData user progress actor.
@MainActor
public final class VocabularyRepositoryImpl: VocabularyRepositoryProtocol {
    private let dataSource: VocabularyDataSourceProtocol
    private let progressActor: UserProgressModelActor?

    /// Creates a production vocabulary repository with data source and optional progress actor dependencies.
    ///
    /// - Parameters:
    ///   - dataSource: The vocabulary data source conforming to VocabularyDataSourceProtocol.
    ///   - progressActor: The SwiftData background actor for user progress operations.
    public init(dataSource: VocabularyDataSourceProtocol, progressActor: UserProgressModelActor? = nil) {
        self.dataSource = dataSource
        self.progressActor = progressActor
    }

    /// Legacy convenience initializer for backwards compatibility during migration.
    public convenience init(datasetEngine: DatasetDataSourceProtocol?, progressActor: UserProgressModelActor? = nil) {
        self.init(dataSource: DatasetDataSourceAdapter(datasetEngine: datasetEngine), progressActor: progressActor)
    }

    /// Fetches vocabulary word records up to the specified limit.
    public func fetchWordRecords(limit: Int) async throws -> [Word] {
        let records = try await dataSource.searchWords(query: "")
        let limited = Array(records.prefix(max(0, limit)))
        return limited.map { r in
            Word(
                id: r.id,
                lemma: r.lemma,
                pos: r.pos,
                ipaUs: r.phonetic,
                cefrLevel: r.cefrLevel,
                definitionEn: r.definitionEn,
                definitionVi: r.definitionVi,
                example: r.exampleEn
            )
        }
    }

    /// Fetches a single word by its unique database identifier.
    public func fetchWord(id: Int64) async throws -> Word? {
        guard let r = try await dataSource.fetchWordById(id: id) else { return nil }
        return Word(
            id: r.id,
            lemma: r.lemma,
            pos: r.pos,
            ipaUs: r.phonetic,
            cefrLevel: r.cefrLevel,
            definitionEn: r.definitionEn,
            definitionVi: r.definitionVi,
            example: r.exampleEn
        )
    }

    /// Searches vocabulary words matching the given query string.
    public func searchWords(query: String) async throws -> [Word] {
        let records = try await dataSource.searchWords(query: query)
        return records.map { r in
            Word(
                id: r.id,
                lemma: r.lemma,
                pos: r.pos,
                ipaUs: r.phonetic,
                cefrLevel: r.cefrLevel,
                definitionEn: r.definitionEn,
                definitionVi: r.definitionVi,
                example: r.exampleEn
            )
        }
    }

    /// Fetches daily suggested words.
    public func fetchSuggestedWords(limit: Int) async throws -> [SuggestedWord] {
        let records = try await dataSource.searchWords(query: "")
        let limited = Array(records.prefix(max(0, limit)))
        if limited.isEmpty {
            return MockVocabularyDataSource.shared.mockSuggestedWords
        }
        return limited.map { r in
            SuggestedWord(
                id: String(r.id),
                lemma: r.lemma,
                pos: r.pos,
                ipaUs: r.phonetic,
                cefrLevel: r.cefrLevel,
                definitionVi: r.definitionVi,
                definitionEn: r.definitionEn,
                example: r.exampleEn,
                isBookmarked: false,
                topicTag: "Featured Vocabulary"
            )
        }
    }
}

// MARK: - Legacy Dataset Engine Adapter

@MainActor
private final class DatasetDataSourceAdapter: VocabularyDataSourceProtocol, @unchecked Sendable {
    private let datasetEngine: DatasetDataSourceProtocol?

    init(datasetEngine: DatasetDataSourceProtocol?) {
        self.datasetEngine = datasetEngine
    }

    func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        guard let engine = datasetEngine else { return [] }
        return engine.fetchTopicDecks().map {
            TopicDeckDTO(id: $0.id, title: $0.title, iconName: $0.iconName, badgeColorHex: $0.badgeColorHex, cefrLevel: "A1", sortOrder: $0.sortOrder)
        }
    }

    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        guard let engine = datasetEngine else { return [] }
        return engine.fetchSubTopicNodes(deckId: deckId).map {
            SubTopicStageDTO(id: $0.id, deckId: $0.deckId, title: $0.title, iconName: $0.iconName, sortOrder: $0.sortOrder)
        }
    }

    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        guard let engine = datasetEngine else { return [] }
        return engine.fetchWordsForNode(nodeId: stageId).map { r in
            TopicWordDTO(
                id: r.id,
                stageId: stageId,
                lemma: r.lemma,
                phonetic: r.ipaUs ?? "",
                pos: r.pos ?? "",
                cefrLevel: r.cefrLevel ?? "",
                definitionVi: r.definitionVi ?? "",
                definitionEn: r.definitionEn ?? "",
                exampleEn: r.example ?? "",
                exampleVi: ""
            )
        }
    }

    func searchWords(query: String) async throws -> [TopicWordDTO] {
        guard let engine = datasetEngine else { return [] }
        let records = query.isEmpty ? engine.fetchWordRecords(limit: 1000, cefrLevel: nil) : engine.searchWords(query: query)
        return records.map { r in
            TopicWordDTO(
                id: r.id,
                stageId: "",
                lemma: r.lemma,
                phonetic: r.ipaUs ?? "",
                pos: r.pos ?? "",
                cefrLevel: r.cefrLevel ?? "",
                definitionVi: r.definitionVi ?? "",
                definitionEn: r.definitionEn ?? "",
                exampleEn: r.example ?? "",
                exampleVi: ""
            )
        }
    }

    func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        guard let engine = datasetEngine, let r = engine.fetchWordById(id: id) else { return nil }
        return TopicWordDTO(
            id: r.id,
            stageId: "",
            lemma: r.lemma,
            phonetic: r.ipaUs ?? "",
            pos: r.pos ?? "",
            cefrLevel: r.cefrLevel ?? "",
            definitionVi: r.definitionVi ?? "",
            definitionEn: r.definitionEn ?? "",
            exampleEn: r.example ?? "",
            exampleVi: ""
        )
    }
}
