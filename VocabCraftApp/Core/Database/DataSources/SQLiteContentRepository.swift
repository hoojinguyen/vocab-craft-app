import Foundation
import SQLite3

public enum SQLiteContentError: Error, Equatable, Sendable {
    case missingDatabase(String)
    case sqliteError(String)
}

public final class SQLiteContentRepository: VocabularyDataSourceProtocol, Sendable {
    private let url: URL

    public init(url: URL) throws {
        self.url = url
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SQLiteContentError.missingDatabase(url.path)
        }
    }

    // Stub methods to satisfy protocol
    public func fetchTopicDecks() async throws -> [TopicDeckDTO] { [] }
    public func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] { [] }
    public func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] { [] }
    public func searchWords(query: String) async throws -> [TopicWordDTO] { [] }
    public func fetchWordById(id: Int64) async throws -> TopicWordDTO? { nil }
}
