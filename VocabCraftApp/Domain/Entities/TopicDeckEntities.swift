import Foundation

public enum NodeState: String, Codable, Equatable, Sendable {
    case locked
    case active
    case completed
}

public struct TopicWord: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let english: String
    public let phonetic: String
    public let vietnamese: String
    public let example: String
    public let partOfSpeech: String
    public var isMastered: Bool
    public var isSavedToPersonalVault: Bool

    public init(
        id: String,
        english: String,
        phonetic: String,
        vietnamese: String,
        example: String = "",
        partOfSpeech: String = "noun",
        isMastered: Bool = false,
        isSavedToPersonalVault: Bool = false
    ) {
        self.id = id
        self.english = english
        self.phonetic = phonetic
        self.vietnamese = vietnamese
        self.example = example
        self.partOfSpeech = partOfSpeech
        self.isMastered = isMastered
        self.isSavedToPersonalVault = isSavedToPersonalVault
    }
}

public struct SubTopicNode: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let iconName: String
    public let totalWords: Int
    public let learnedWords: Int
    public let state: NodeState
    public let words: [TopicWord]

    public init(
        id: String,
        title: String,
        iconName: String,
        totalWords: Int,
        learnedWords: Int,
        state: NodeState,
        words: [TopicWord] = []
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.totalWords = totalWords
        self.learnedWords = learnedWords
        self.state = state
        self.words = words
    }
}

public struct TopicDeck: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let wordCount: Int
    public let completionPercentage: Double
    public let badgeColorHex: String
    public let iconName: String

    public var totalWords: Int {
        wordCount
    }

    public init(
        id: String,
        title: String,
        wordCount: Int,
        completionPercentage: Double,
        badgeColorHex: String,
        iconName: String
    ) {
        self.id = id
        self.title = title
        self.wordCount = wordCount
        self.completionPercentage = completionPercentage
        self.badgeColorHex = badgeColorHex
        self.iconName = iconName
    }
}
