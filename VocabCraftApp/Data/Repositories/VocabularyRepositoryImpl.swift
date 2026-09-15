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
