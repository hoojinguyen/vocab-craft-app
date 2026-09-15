import Foundation

public struct VocabularyCatalogDTO: Codable, Sendable, Equatable {
    public let version: Int
    public let decks: [TopicDeckDTO]

    public init(version: Int = 1, decks: [TopicDeckDTO]) {
        self.version = version
        self.decks = decks
    }
}

public enum VocabularyCatalogError: LocalizedError, Sendable {
    case resourceNotFound(name: String, bundle: String)
    case decodingFailed(description: String)

    public var errorDescription: String? {
        switch self {
        case .resourceNotFound(let name, let bundle):
            return "Vocabulary catalog resource '\(name)' could not be found in bundle '\(bundle)'."
        case .decodingFailed(let description):
            return "Failed to decode vocabulary catalog: \(description)"
        }
    }
}
