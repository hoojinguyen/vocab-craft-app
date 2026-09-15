import Foundation

/// Accesses vocabulary entities, topic decks, and drill dataset records.
public protocol VocabularyRepositoryProtocol: AnyObject, Sendable {
    /// Fetches vocabulary word records up to the specified limit.
    ///
    /// - Parameter limit: The maximum number of words to return. Defaults to 50.
    /// - Returns: An array of ``Word`` entities.
    func fetchWordRecords(limit: Int) async throws -> [Word]

    /// Fetches a single word by its unique database identifier.
    ///
    /// - Parameter id: The unique 64-bit integer identifier of the word.
    /// - Returns: The matching ``Word`` if found, or `nil`.
    func fetchWord(id: Int64) async throws -> Word?

    /// Searches vocabulary words matching the given query string.
    ///
    /// - Parameter query: The search string to match against word lemmas and definitions.
    /// - Returns: An array of matching ``Word`` entities.
    func searchWords(query: String) async throws -> [Word]

    /// Fetches daily suggested words.
    ///
    /// - Parameter limit: The maximum number of suggested words to return.
    /// - Returns: An array of ``SuggestedWord`` entities.
    func fetchSuggestedWords(limit: Int) async throws -> [SuggestedWord]
}

public extension VocabularyRepositoryProtocol {
    /// Fetches vocabulary word records using the default limit of 50.
    func fetchWordRecords() async throws -> [Word] {
        try await fetchWordRecords(limit: 50)
    }

    /// Fetches daily suggested words using the default limit of 10.
    func fetchSuggestedWords() async throws -> [SuggestedWord] {
        try await fetchSuggestedWords(limit: 10)
    }
}
