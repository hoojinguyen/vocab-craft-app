import Foundation

public struct RoleplayTurnOutput: Codable, Sendable, Equatable {
    public let characterReply: String
    public let targetWordsUsed: [String]
    public let refinementSuggestion: String?
    public let pedagogicalNote: String?
    public let suggestedResponses: [String]
    public let isConcluded: Bool

    public init(
        characterReply: String,
        targetWordsUsed: [String],
        refinementSuggestion: String? = nil,
        pedagogicalNote: String? = nil,
        suggestedResponses: [String] = [],
        isConcluded: Bool = false
    ) {
        self.characterReply = characterReply
        self.targetWordsUsed = targetWordsUsed
        self.refinementSuggestion = refinementSuggestion
        self.pedagogicalNote = pedagogicalNote
        self.suggestedResponses = suggestedResponses
        self.isConcluded = isConcluded
    }

    enum CodingKeys: String, CodingKey {
        case characterReply
        case targetWordsUsed
        case refinementSuggestion
        case pedagogicalNote
        case suggestedResponses
        case isConcluded
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.characterReply = try container.decode(String.self, forKey: .characterReply)
        self.targetWordsUsed = try container.decodeIfPresent([String].self, forKey: .targetWordsUsed) ?? []
        self.refinementSuggestion = try container.decodeIfPresent(String.self, forKey: .refinementSuggestion)
        self.pedagogicalNote = try container.decodeIfPresent(String.self, forKey: .pedagogicalNote)
        self.suggestedResponses = try container.decodeIfPresent([String].self, forKey: .suggestedResponses) ?? []
        self.isConcluded = try container.decodeIfPresent(Bool.self, forKey: .isConcluded) ?? false
    }
}
