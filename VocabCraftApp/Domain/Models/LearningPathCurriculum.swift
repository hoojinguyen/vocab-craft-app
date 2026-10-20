import Foundation

public struct LearningPathCurriculum: Sendable, Equatable {
    public let activePath: LearningPathDTO?
    public let decks: [TopicDeckDTO]
    public let stages: [SubTopicStageDTO]
    public let words: [TopicWordDTO]
    public let progressList: [UserStageProgressData]
    public let weakWords: [UserWordProgressData]

    public init(
        activePath: LearningPathDTO? = nil,
        decks: [TopicDeckDTO],
        stages: [SubTopicStageDTO],
        words: [TopicWordDTO],
        progressList: [UserStageProgressData],
        weakWords: [UserWordProgressData] = []
    ) {
        self.activePath = activePath
        self.decks = decks
        self.stages = stages
        self.words = words
        self.progressList = progressList
        self.weakWords = weakWords
    }
}
