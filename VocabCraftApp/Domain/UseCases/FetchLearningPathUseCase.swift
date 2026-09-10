import Foundation

public protocol FetchLearningPathUseCaseProtocol: Sendable {
    func execute() async throws -> LearningPathCurriculum
    func execute(forceRefresh: Bool) async throws -> LearningPathCurriculum
}

public extension FetchLearningPathUseCaseProtocol {
    func execute() async throws -> LearningPathCurriculum {
        try await execute(forceRefresh: false)
    }
}

private struct StaticCurriculumData: Sendable {
    let decks: [TopicDeckDTO]
    let stages: [SubTopicStageDTO]
    let words: [TopicWordDTO]
}

private actor StaticCurriculumCache {
    private var data: StaticCurriculumData?

    func get() -> StaticCurriculumData? {
        data
    }

    func set(_ newData: StaticCurriculumData) {
        data = newData
    }

    func clear() {
        data = nil
    }
}

public final class FetchLearningPathUseCase: FetchLearningPathUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol
    private let curriculumCache = StaticCurriculumCache()

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
    }

    public func execute(forceRefresh: Bool = false) async throws -> LearningPathCurriculum {
        async let progressTask = stageRepo.fetchAllStageProgress()

        let staticData: StaticCurriculumData
        if !forceRefresh, let cached = await curriculumCache.get() {
            staticData = cached
        } else {
            let loaded = try await loadStaticCurriculum()
            await curriculumCache.set(loaded)
            staticData = loaded
        }

        let progressList = try await progressTask
        return LearningPathCurriculum(
            decks: staticData.decks,
            stages: staticData.stages,
            words: staticData.words,
            progressList: progressList
        )
    }

    private func loadStaticCurriculum() async throws -> StaticCurriculumData {
        let decks = try await dataSource.fetchTopicDecks()

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

        return StaticCurriculumData(
            decks: decks,
            stages: allStages,
            words: allWords
        )
    }
}
