import Foundation

/// Repository abstraction for vocabulary data access.
public protocol VocabularyRepositoryProtocol: Sendable {
    func fetchWordRecords(limit: Int) async throws -> [Word]
    func fetchWord(id: Int64) async throws -> Word?
    func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillRecord]
    func searchWords(query: String) async throws -> [Word]
}
