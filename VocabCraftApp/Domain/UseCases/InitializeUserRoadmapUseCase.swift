import Foundation

public struct RoadmapInitializationResult: Sendable, Equatable {
    public let startingStage: SubTopicStageDTO
    public let starterWords: [TopicWordDTO]

    public init(startingStage: SubTopicStageDTO, starterWords: [TopicWordDTO]) {
        self.startingStage = startingStage
        self.starterWords = starterWords
    }
}

public enum OnboardingDomainError: Error, LocalizedError, Equatable {
    case stageNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .stageNotFound(let deckId):
            return String(
                format: String(
                    localized: "app.onboarding.error.stage_not_found",
                    defaultValue: "No stages found for deck: %@",
                    bundle: .module
                ),
                deckId
            )
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
        // 1. Fetch stages for the target deck
        let stages = try await dataSource.fetchSubTopicStages(deckId: deckId)
        let sortedStages = stages.sorted { $0.sortOrder < $1.sortOrder }

        guard let firstStage = sortedStages.first else {
            throw OnboardingDomainError.stageNotFound(deckId)
        }

        let isAdvancedLevel = (cefrLevel == "B1" || cefrLevel == "B2" || cefrLevel == "C1")
        let startingStage: SubTopicStageDTO

        if isAdvancedLevel && sortedStages.count > 1 {
            startingStage = sortedStages[1]
        } else {
            startingStage = firstStage
        }

        // 2. Fetch starter words with safe fallback before mutating progress
        let fetchedWords: [TopicWordDTO]
        do {
            fetchedWords = try await dataSource.fetchWordsForStage(stageId: startingStage.id)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            fetchedWords = []
        }

        try Task.checkCancellation()

        let starterWords: [TopicWordDTO]
        if fetchedWords.count >= 3 {
            starterWords = Array(fetchedWords.prefix(3))
        } else {
            var combined = fetchedWords
            let fallbacks = VocabularySampleDataset.starterWords(forStageId: startingStage.id)
            for fallback in fallbacks where combined.count < 3 {
                if !combined.contains(where: { $0.lemma.caseInsensitiveCompare(fallback.lemma) == .orderedSame }) {
                    combined.append(fallback)
                }
            }
            starterWords = combined
        }

        // 3. Reconcile foundational stage 1 progress based on assessed level
        try Task.checkCancellation()
        if isAdvancedLevel && sortedStages.count > 1 {
            try await stageRepo.saveStageProgress(
                stageId: firstStage.id,
                deckId: deckId,
                isCompleted: true,
                score: 100,
                progressFraction: 1.0
            )
        } else if !isAdvancedLevel && sortedStages.count > 1 {
            try await stageRepo.saveStageProgress(
                stageId: firstStage.id,
                deckId: deckId,
                isCompleted: false,
                score: 0,
                progressFraction: 0.0
            )
        }

        try Task.checkCancellation()

        // 4. Persist user preferences only after roadmap synthesis succeeds
        userSettings.selectedGoalDeckId = deckId
        userSettings.assessedCefrLevel = cefrLevel
        userSettings.dailyGoalCount = dailyGoalCount
        userSettings.notificationTimeInterval = notificationTimeInterval

        return RoadmapInitializationResult(
            startingStage: startingStage,
            starterWords: starterWords
        )
    }
}
