import CraftUIKit
import Foundation

public protocol FetchLearningPathUseCaseProtocol: Sendable {
    func execute() async throws -> [LessonSection]
}

public final class FetchLearningPathUseCase: FetchLearningPathUseCaseProtocol, Sendable {
    private let adapter: ContentLearningPathAdapter?
    private let legacyDataSource: VocabularyDataSourceProtocol?
    private let legacyStageRepo: StageProgressRepositoryProtocol?

    public init(adapter: ContentLearningPathAdapter) {
        self.adapter = adapter
        self.legacyDataSource = nil
        self.legacyStageRepo = nil
    }

    public init(
        repository: any ContentRepository,
        journal: LearningJournal,
        profileID: ProfileID
    ) {
        self.adapter = ContentLearningPathAdapter(repository: repository, journal: journal, profileID: profileID)
        self.legacyDataSource = nil
        self.legacyStageRepo = nil
    }

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol
    ) {
        self.adapter = nil
        self.legacyDataSource = dataSource
        self.legacyStageRepo = stageRepo
    }

    public func execute() async throws -> [LessonSection] {
        if let adapter {
            return try await adapter.load()
        }

        guard let dataSource = legacyDataSource, let stageRepo = legacyStageRepo else {
            return []
        }

        // Parallelize deck + progress fetch. Then fetch stages and words concurrently via TaskGroup
        async let decksTask = dataSource.fetchTopicDecks()
        async let progressTask = stageRepo.fetchAllStageProgress()

        let decks = try await decksTask

        // Fetch all stages in parallel across decks
        let allStages: [SubTopicStageDTO] = try await withThrowingTaskGroup(of: [SubTopicStageDTO].self) { group in
            for deck in decks {
                group.addTask { [dataSource] in
                    try await dataSource.fetchSubTopicStages(deckId: deck.id)
                }
            }
            var combined: [SubTopicStageDTO] = []
            combined.reserveCapacity(decks.count * 4)
            for try await stages in group {
                combined.append(contentsOf: stages)
            }
            return combined
        }

        // Fetch all words in parallel across stages
        let allWords: [TopicWordDTO] = try await withThrowingTaskGroup(of: [TopicWordDTO].self) { group in
            for stage in allStages {
                group.addTask { [dataSource] in
                    try await dataSource.fetchWordsForStage(stageId: stage.id)
                }
            }
            var combined: [TopicWordDTO] = []
            combined.reserveCapacity(allStages.count * 8)
            for try await words in group {
                combined.append(contentsOf: words)
            }
            return combined
        }

        let progressList = try await progressTask
        return LearningPathDataMapper.map(
            decks: decks,
            stages: allStages,
            words: allWords,
            progressList: progressList
        )
    }
}
