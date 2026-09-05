import Foundation

// MARK: - Content Manifest

public struct ContentManifestCounts: Codable, Sendable, Hashable {
    public let entries: Int
    public let senses: Int
    public let decks: Int
    public let lessons: Int

    public init(entries: Int, senses: Int, decks: Int, lessons: Int) {
        self.entries = entries
        self.senses = senses
        self.decks = decks
        self.lessons = lessons
    }
}

public struct ContentManifest: Codable, Sendable, Hashable {
    public let contentVersion: Int
    public let datasetSchemaVersion: Int
    public let publishedAt: String
    public let contentLanguage: String
    public let explanationLanguage: String
    public let bundleURL: String
    public let sha256: String
    public let byteSize: Int
    public let counts: ContentManifestCounts

    enum CodingKeys: String, CodingKey {
        case contentVersion = "content_version"
        case datasetSchemaVersion = "dataset_schema_version"
        case publishedAt = "published_at"
        case contentLanguage = "content_language"
        case explanationLanguage = "explanation_language"
        case bundleURL = "bundle_url"
        case sha256
        case byteSize = "byte_size"
        case counts
    }

    public init(
        contentVersion: Int,
        datasetSchemaVersion: Int,
        publishedAt: String,
        contentLanguage: String = "en",
        explanationLanguage: String = "vi",
        bundleURL: String,
        sha256: String,
        byteSize: Int,
        counts: ContentManifestCounts
    ) {
        self.contentVersion = contentVersion
        self.datasetSchemaVersion = datasetSchemaVersion
        self.publishedAt = publishedAt
        self.contentLanguage = contentLanguage
        self.explanationLanguage = explanationLanguage
        self.bundleURL = bundleURL
        self.sha256 = sha256
        self.byteSize = byteSize
        self.counts = counts
    }
}

// MARK: - Errors

public enum ContentRepositoryError: Error, LocalizedError, Sendable, Equatable {
    case unsupportedSchema(expected: Int, actual: Int)
    case corruptedDatabase(String)
    case missingDatabase(String)
    case entityNotFound(String)
    case sqliteError(code: Int32, message: String)
    case invalidCursor(String)

    public var errorDescription: String? {
        switch self {
        case .unsupportedSchema(let expected, let actual):
            return "Unsupported schema version. Expected: \(expected), actual: \(actual)"
        case .corruptedDatabase(let details):
            return "Corrupted database: \(details)"
        case .missingDatabase(let path):
            return "Database file missing at path: \(path)"
        case .entityNotFound(let details):
            return "Entity not found: \(details)"
        case .sqliteError(let code, let message):
            return "SQLite error (\(code)): \(message)"
        case .invalidCursor(let message):
            return "Invalid search cursor: \(message)"
        }
    }
}

// MARK: - Search Result

public struct ContentSearchResult: Sendable, Hashable {
    public let senses: [SenseSummary]
    public let nextCursor: String?
    public let hasMore: Bool
    public let contentVersion: Int

    public var items: [SenseSummary] { senses }

    public init(
        senses: [SenseSummary],
        nextCursor: String?,
        hasMore: Bool,
        contentVersion: Int
    ) {
        self.senses = senses
        self.nextCursor = nextCursor
        self.hasMore = hasMore
        self.contentVersion = contentVersion
    }
}

// MARK: - Repository Protocol

public protocol ContentRepository: Sendable {
    func fetchDecks() async throws -> [DeckSummary]
    func fetchLessons(deckID: DeckID) async throws -> [LessonDetail]
    func fetchLessonContent(lessonID: LessonID) async throws -> LessonDetail
    func fetchSense(senseID: SenseID) async throws -> SenseDetail?
    func fetchEntry(entryID: EntryID) async throws -> EntryDetail?
    func fetchSenses(ids: [SenseID]) async throws -> [SenseDetail]
    func search(query: String, limit: Int, cursor: String?) async throws -> ContentSearchResult
}
