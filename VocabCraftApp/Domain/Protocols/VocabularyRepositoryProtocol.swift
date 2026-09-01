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

    /// Fetches reflex drill prompt records matching the specified CEFR level.
    ///
    /// - Parameter cefrLevel: The target CEFR level (e.g., "A1", "B1", "C1").
    /// - Returns: An array of ``ReflexDrillItem`` objects.
    func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillItem]

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
