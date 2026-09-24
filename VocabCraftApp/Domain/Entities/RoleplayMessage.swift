import Foundation

public enum RoleplayMessageSender: Codable, Sendable, Equatable {
    case user
    case character(name: String)
}

public struct RoleplayMessage: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let sender: RoleplayMessageSender
    public let text: String
    public let timestamp: Date
    public let refinementSuggestion: String?
    public let pedagogicalNote: String?

    public init(
        id: UUID = UUID(),
        sender: RoleplayMessageSender,
        text: String,
        timestamp: Date = Date(),
        refinementSuggestion: String? = nil,
        pedagogicalNote: String? = nil
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
        self.refinementSuggestion = refinementSuggestion
        self.pedagogicalNote = pedagogicalNote
    }
}
