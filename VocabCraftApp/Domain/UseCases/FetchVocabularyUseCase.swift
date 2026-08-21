import Foundation

public protocol FetchVocabularyUseCaseProtocol: AnyObject {
    func executeFetchWords(limit: Int) async throws -> [Word]
    func executeSearch(query: String) async throws -> [Word]
    func executeFetchDrills(cefrLevel: String) async throws -> [ReflexDrillItem]
}

public final class FetchVocabularyUseCase: FetchVocabularyUseCaseProtocol {
    private let repository: VocabularyRepositoryProtocol

    public init(repository: VocabularyRepositoryProtocol) {
        self.repository = repository
    }

    public func executeFetchWords(limit: Int = 50) async throws -> [Word] {
        try await repository.fetchWordRecords(limit: limit)
    }

    public func executeSearch(query: String) async throws -> [Word] {
        try await repository.searchWords(query: query)
    }

    public func executeFetchDrills(cefrLevel: String) async throws -> [ReflexDrillItem] {
        try await repository.fetchReflexDrillRecords(cefrLevel: cefrLevel)
    }
}
