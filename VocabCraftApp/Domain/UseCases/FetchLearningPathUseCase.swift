import CraftUIKit
import Foundation

public protocol FetchLearningPathUseCaseProtocol: Sendable {
    func execute() async throws -> [LessonSection]
}

public final class FetchLearningPathUseCase: FetchLearningPathUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
    }

    public func execute() async throws -> [LessonSection] {
        let decks = try await dataSource.fetchTopicDecks()
        var allStages: [SubTopicStageDTO] = []
        var allWords: [TopicWordDTO] = []

        for deck in decks {
            let stages = try await dataSource.fetchSubTopicStages(deckId: deck.id)
            allStages.append(contentsOf: stages)
            for stage in stages {
                let words = try await dataSource.fetchWordsForStage(stageId: stage.id)
                allWords.append(contentsOf: words)
            }
        }

        let progressList = try await stageRepo.fetchAllStageProgress()
        return LearningPathDataMapper.map(
            decks: decks,
            stages: allStages,
            words: allWords,
            progressList: progressList
        )
    }
}
