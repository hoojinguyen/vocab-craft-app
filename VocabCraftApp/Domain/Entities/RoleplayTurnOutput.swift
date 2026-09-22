import Foundation

public struct RoleplayTurnOutput: Codable, Sendable, Equatable {
    public let characterReply: String
    public let targetWordsUsed: [String]
    public let refinementSuggestion: String?
    public let pedagogicalNote: String?

    public init(
        characterReply: String,
        targetWordsUsed: [String],
        refinementSuggestion: String? = nil,
        pedagogicalNote: String? = nil
    ) {
        self.characterReply = characterReply
        self.targetWordsUsed = targetWordsUsed
        self.refinementSuggestion = refinementSuggestion
        self.pedagogicalNote = pedagogicalNote
    }
}
