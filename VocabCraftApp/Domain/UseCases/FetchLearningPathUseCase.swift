import Foundation

public protocol FetchLearningPathUseCaseProtocol: Sendable {
    func execute(pathId: String?, forceRefresh: Bool) async throws -> LearningPathCurriculum
    func execute(forceRefresh: Bool) async throws -> LearningPathCurriculum
    func execute() async throws -> LearningPathCurriculum
}

public extension FetchLearningPathUseCaseProtocol {
    func execute() async throws -> LearningPathCurriculum {
        try await execute(pathId: nil, forceRefresh: false)
    }

    func execute(forceRefresh: Bool) async throws -> LearningPathCurriculum {
        try await execute(pathId: nil, forceRefresh: forceRefresh)
    }

    func execute(pathId: String?) async throws -> LearningPathCurriculum {
        try await execute(pathId: pathId, forceRefresh: false)
    }

    func execute(pathId: String?, forceRefresh: Bool) async throws -> LearningPathCurriculum {
        try await execute(forceRefresh: forceRefresh)
    }
}

private struct StaticCurriculumData: Sendable {
    let decks: [TopicDeckDTO]
    let stages: [SubTopicStageDTO]
    let words: [TopicWordDTO]
}

private actor StaticCurriculumCache {
    private var cache: [String: StaticCurriculumData] = [:]

    func get(pathId: String? = nil) -> StaticCurriculumData? {
        let key = pathId ?? "__default__"
        return cache[key]
    }

    func set(_ newData: StaticCurriculumData, pathId: String? = nil) {
        let key = pathId ?? "__default__"
        cache[key] = newData
    }

    func clear() {
        cache.removeAll()
    }
}

public final class FetchLearningPathUseCase: FetchLearningPathUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol
    private let userSettings: (any UserRoadmapSettingsProtocol)?
    private let curriculumCache = StaticCurriculumCache()

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol,
        userSettings: (any UserRoadmapSettingsProtocol)? = nil
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
        self.userSettings = userSettings
    }

    public func execute(pathId: String? = nil, forceRefresh: Bool = false) async throws -> LearningPathCurriculum {
        async let progressTask = stageRepo.fetchAllStageProgress()

        let paths = (try? await dataSource.fetchLearningPaths()) ?? []
        let targetId: String?
        if let pathId {
            targetId = pathId
        } else if let userSettings {
            targetId = await MainActor.run { userSettings.selectedLearningPathId }
        } else {
            targetId = nil
        }
        let activePath = paths.first(where: { $0.id == targetId }) ?? paths.first
        let resolvedPathId = activePath?.id ?? targetId

        let staticData: StaticCurriculumData
        if !forceRefresh, let cached = await curriculumCache.get(pathId: resolvedPathId) {
            staticData = cached
        } else {
            let loaded = try await loadStaticCurriculum(pathId: resolvedPathId)
            await curriculumCache.set(loaded, pathId: resolvedPathId)
            staticData = loaded
        }

        let progressList = try await progressTask
        return LearningPathCurriculum(
            activePath: activePath,
            decks: staticData.decks,
            stages: staticData.stages,
            words: staticData.words,
            progressList: progressList
        )
    }

    private func loadStaticCurriculum(pathId: String?) async throws -> StaticCurriculumData {
        let decks: [TopicDeckDTO]
        if let pathId {
            decks = try await dataSource.fetchTopicDecks(for: pathId)
        } else {
            decks = try await dataSource.fetchTopicDecks()
        }

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
