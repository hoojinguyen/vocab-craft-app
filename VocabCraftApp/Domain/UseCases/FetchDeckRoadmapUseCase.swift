import Foundation

/// Protocol for fetching a deck's roadmap stages with calculated completion and unlock states.
public protocol FetchDeckRoadmapUseCaseProtocol: Sendable {
    func execute(deckId: String) async throws -> [SubTopicStage]
}

/// Fetches the subtopic stages of a topic deck, mapping words and resolving the state (.completed, .active, .locked).
public final class FetchDeckRoadmapUseCase: FetchDeckRoadmapUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
    }

    public func execute(deckId: String) async throws -> [SubTopicStage] {
        let stageDTOs = try await dataSource.fetchSubTopicStages(deckId: deckId)
        let completedStageIds = try await stageRepo.fetchCompletedStageIds(deckId: deckId)

        var roadmapStages: [SubTopicStage] = []
        var hasFoundActive = false

        for stageDTO in stageDTOs {
            let wordDTOs = try await dataSource.fetchWordsForStage(stageId: stageDTO.id)
            let words: [TopicWord] = wordDTOs.map { dto in
                TopicWord(
                    id: String(dto.id),
                    english: dto.lemma,
                    phonetic: dto.phonetic,
                    vietnamese: dto.definitionVi,
                    example: dto.exampleEn,
                    partOfSpeech: dto.pos,
                    isMastered: false,
                    isSavedToPersonalVault: false
                )
            }

            let state: StageState
            if completedStageIds.contains(stageDTO.id) {
                state = .completed
            } else if !hasFoundActive {
                state = .active
                hasFoundActive = true
            } else {
                state = .locked
            }

            let stage = SubTopicStage(
                id: stageDTO.id,
                deckId: stageDTO.deckId,
                title: stageDTO.title,
                iconName: stageDTO.iconName,
                sortOrder: stageDTO.sortOrder,
                state: state,
                words: words
            )
            roadmapStages.append(stage)
        }

        return roadmapStages
    }
}
