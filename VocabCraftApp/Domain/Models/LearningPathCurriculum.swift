import Foundation

public struct LearningPathCurriculum: Sendable, Equatable {
    public let decks: [TopicDeckDTO]
    public let stages: [SubTopicStageDTO]
    public let words: [TopicWordDTO]
    public let progressList: [UserStageProgressData]

    public init(
        decks: [TopicDeckDTO],
        stages: [SubTopicStageDTO],
        words: [TopicWordDTO],
        progressList: [UserStageProgressData]
    ) {
        self.decks = decks
        self.stages = stages
        self.words = words
        self.progressList = progressList
    }
}
