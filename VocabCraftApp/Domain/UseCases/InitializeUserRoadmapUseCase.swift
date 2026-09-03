import Foundation

public struct RoadmapInitializationResult: Sendable, Equatable {
    public let startingStage: SubTopicStageDTO
    public let starterWords: [TopicWordDTO]

    public init(startingStage: SubTopicStageDTO, starterWords: [TopicWordDTO]) {
        self.startingStage = startingStage
        self.starterWords = starterWords
    }
}

public enum OnboardingDomainError: Error, LocalizedError {
    case stageNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .stageNotFound(let deckId):
            return "No stages found for deck: \(deckId)"
        }
    }
}

public protocol InitializeUserRoadmapUseCaseProtocol: Sendable {
    @MainActor
    func execute(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    ) async throws -> RoadmapInitializationResult
}

public final class InitializeUserRoadmapUseCase: InitializeUserRoadmapUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol
    private let userSettings: UserSettingsStore

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol,
        userSettings: UserSettingsStore
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
        self.userSettings = userSettings
    }

    @MainActor
    public func execute(
        deckId: String,
        cefrLevel: String,
        dailyGoalCount: Int,
        notificationTimeInterval: Double
    ) async throws -> RoadmapInitializationResult {
        // 1. Persist user preferences
        userSettings.selectedGoalDeckId = deckId
        userSettings.assessedCefrLevel = cefrLevel
        userSettings.dailyGoalCount = dailyGoalCount
        userSettings.notificationTimeInterval = notificationTimeInterval

        // 2. Fetch stages for the target deck
        let stages = try await dataSource.fetchSubTopicStages(deckId: deckId)
        let sortedStages = stages.sorted { $0.sortOrder < $1.sortOrder }

        guard let firstStage = sortedStages.first else {
            throw OnboardingDomainError.stageNotFound(deckId)
        }

        let isAdvancedLevel = (cefrLevel == "B1" || cefrLevel == "B2" || cefrLevel == "C1")
        let startingStage: SubTopicStageDTO

        if isAdvancedLevel && sortedStages.count > 1 {
            // Auto-unlock foundational stage 1
            try await stageRepo.saveStageProgress(
                stageId: firstStage.id,
                deckId: deckId,
                isCompleted: true,
                score: 100,
                progressFraction: 1.0
            )
            startingStage = sortedStages[1]
        } else {
            startingStage = firstStage
        }

        // 3. Fetch starter words
        let words = try await dataSource.fetchWordsForStage(stageId: startingStage.id)
        let starterWords = Array(words.prefix(3))

        return RoadmapInitializationResult(
            startingStage: startingStage,
            starterWords: starterWords
        )
    }
}
