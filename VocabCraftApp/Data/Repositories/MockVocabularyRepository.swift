import Foundation

/// Repository implementation serving mock vocabulary data for development and preview modes.
public final class MockVocabularyRepository: VocabularyRepositoryProtocol, Sendable {
    private let dataSource: MockVocabularyDataSource

    /// Creates a mock vocabulary repository using the specified data source.
    ///
    /// - Parameter dataSource: The mock data provider to read from. Defaults to ``MockVocabularyDataSource/shared``.
    public init(dataSource: MockVocabularyDataSource = .shared) {
        self.dataSource = dataSource
    }

    /// Fetches vocabulary word records up to the specified limit.
    ///
    /// - Parameter limit: The maximum number of words to return.
    /// - Returns: An array of ``Word`` entities.
    public func fetchWordRecords(limit: Int) async throws -> [Word] {
        return Array(dataSource.mockWords.prefix(limit))
    }

    /// Fetches a single word by its unique database identifier.
    ///
    /// - Parameter id: The unique 64-bit integer identifier of the word.
    /// - Returns: The matching ``Word`` if found, or `nil`.
    public func fetchWord(id: Int64) async throws -> Word? {
        return dataSource.mockWords.first { $0.id == id }
    }

    /// Fetches reflex drill prompt records matching the specified CEFR level.
    ///
    /// - Parameter cefrLevel: The target CEFR level (e.g., "A1", "B1", "C1").
    /// - Returns: An array of ``ReflexDrillItem`` objects.
    public func fetchReflexDrillRecords(cefrLevel: String) async throws -> [ReflexDrillItem] {
        return dataSource.mockReflexDrills
    }

    /// Searches vocabulary words matching the given query string.
    ///
    /// - Parameter query: The search string to match against word lemmas and definitions.
    /// - Returns: An array of matching ``Word`` entities.
    public func searchWords(query: String) async throws -> [Word] {
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return dataSource.mockWords
        }
        return dataSource.mockWords.filter {
            $0.lemma.localizedCaseInsensitiveContains(query) ||
            ($0.definitionVi?.localizedCaseInsensitiveContains(query) ?? false)
        }

    }

    /// Fetches daily suggested words.
    ///
    /// - Parameter limit: The maximum number of suggested words to return.
    /// - Returns: An array of ``SuggestedWord`` entities.
    public func fetchSuggestedWords(limit: Int) async throws -> [SuggestedWord] {
        return Array(dataSource.mockSuggestedWords.prefix(limit))
    }
}
