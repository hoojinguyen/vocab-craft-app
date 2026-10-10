import Foundation

public struct LearningPathCurriculum: Sendable, Equatable {
    public let activePath: LearningPathDTO?
    public let decks: [TopicDeckDTO]
    public let stages: [SubTopicStageDTO]
    public let words: [TopicWordDTO]
    public let progressList: [UserStageProgressData]

    public init(
        activePath: LearningPathDTO? = nil,
        decks: [TopicDeckDTO],
        stages: [SubTopicStageDTO],
        words: [TopicWordDTO],
        progressList: [UserStageProgressData]
    ) {
        self.activePath = activePath
        self.decks = decks
        self.stages = stages
        self.words = words
        self.progressList = progressList
    }
}
