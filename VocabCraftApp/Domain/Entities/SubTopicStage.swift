import Foundation

public enum StageState: String, Sendable, Equatable {
    case locked
    case active
    case completed
}

public struct SubTopicStage: Identifiable, Sendable, Equatable {
    public let id: String
    public let deckId: String
    public let title: String
    public let iconName: String
    public let sortOrder: Int
    public let state: StageState
    public let words: [TopicWord]

    public init(
        id: String,
        deckId: String,
        title: String,
        iconName: String,
        sortOrder: Int,
        state: StageState = .locked,
        words: [TopicWord] = []
    ) {
        self.id = id
        self.deckId = deckId
        self.title = title
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.state = state
        self.words = words
    }
}
