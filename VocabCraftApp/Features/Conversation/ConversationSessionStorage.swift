import Foundation

public struct ConversationSessionSnapshot: Codable, Equatable, Sendable {
    public let conversationID: String
    public let role: ConversationRole
    public let currentTurnIndex: Int
    public let passedTurnIDs: Set<String>
    public let hasCompletedAchievement: Bool
}

@MainActor
public protocol ConversationSessionStorage: AnyObject {
    func load() -> ConversationSessionSnapshot?
    func save(_ snapshot: ConversationSessionSnapshot)
}

@MainActor
public final class InMemoryConversationSessionStorage: ConversationSessionStorage {
    private var snapshot: ConversationSessionSnapshot?

    public init(snapshot: ConversationSessionSnapshot? = nil) {
        self.snapshot = snapshot
    }

    public func load() -> ConversationSessionSnapshot? { snapshot }
    public func save(_ snapshot: ConversationSessionSnapshot) { self.snapshot = snapshot }
}

@MainActor
public final class ConversationUserDefaultsStorage: ConversationSessionStorage {
    private let defaults: UserDefaults
    private let key: String

    public init(defaults: UserDefaults = .standard, key: String = "debug.conversation.mock.session") {
        self.defaults = defaults
        self.key = key
    }

    public func load() -> ConversationSessionSnapshot? {
        defaults.data(forKey: key).flatMap { try? JSONDecoder().decode(ConversationSessionSnapshot.self, from: $0) }
    }

    public func save(_ snapshot: ConversationSessionSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }
}
