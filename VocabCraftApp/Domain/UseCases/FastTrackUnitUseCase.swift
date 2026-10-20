import Foundation

/// Result of evaluating a fast-track unit jump-ahead test.
public struct FastTrackResult: Sendable, Equatable {
    public let deckId: String
    public let isSuccess: Bool
    public let scorePercentage: Double
    public let completedStageIds: [String]
    public let ingestedWordCount: Int

    public init(
        deckId: String,
        isSuccess: Bool,
        scorePercentage: Double,
        completedStageIds: [String] = [],
        ingestedWordCount: Int = 0
    ) {
        self.deckId = deckId
        self.isSuccess = isSuccess
        self.scorePercentage = scorePercentage
        self.completedStageIds = completedStageIds
        self.ingestedWordCount = ingestedWordCount
    }
}

/// Protocol defining unit fast-track jump-ahead capability.
public protocol FastTrackUnitUseCaseProtocol: Sendable {
    func execute(deckId: String, scorePercentage: Double) async throws -> FastTrackResult
}

/// Use case evaluating fast-track unit checkpoint tests.
///
/// When the learner achieves a score >= 85%, all subtopic stages in the deck and
/// the unit checkpoint are batch-marked as completed, and all vocabulary in the unit
/// is ingested into UserWordProgress via `recordBatchLessonResults`.
public final class FastTrackUnitUseCase: FastTrackUnitUseCaseProtocol, Sendable {
    public static let passingThreshold: Double = 0.85

    private let dataSource: VocabularyDataSourceProtocol
    private let stageRepo: StageProgressRepositoryProtocol
    private let progressRepo: (any UserProgressRepositoryProtocol)?

    public init(
        dataSource: VocabularyDataSourceProtocol,
        stageRepo: StageProgressRepositoryProtocol,
        progressRepo: (any UserProgressRepositoryProtocol)? = nil
    ) {
        self.dataSource = dataSource
        self.stageRepo = stageRepo
        self.progressRepo = progressRepo
    }

    public func execute(deckId: String, scorePercentage: Double) async throws -> FastTrackResult {
        guard scorePercentage >= Self.passingThreshold else {
            return FastTrackResult(
                deckId: deckId,
                isSuccess: false,
                scorePercentage: scorePercentage,
                completedStageIds: [],
                ingestedWordCount: 0
            )
        }

        // 1. Fetch all stages belonging to this deck
        let stages = try await dataSource.fetchSubTopicStages(deckId: deckId)

        // 2. Mark each stage as completed with full score
        for stage in stages {
            try await stageRepo.saveStageProgress(
                stageId: stage.id,
                deckId: deckId,
                isCompleted: true,
                score: 3,
                progressFraction: 1.0
            )
        }

        // 3. Mark the unit checkpoint as completed
        let checkpointStageId = "checkpoint_\(deckId)"
        try await stageRepo.saveStageProgress(
            stageId: checkpointStageId,
            deckId: deckId,
            isCompleted: true,
            score: 3,
            progressFraction: 1.0
        )

        // 4. Collect all vocabulary words across the unit's stages
        var allWordIds: [Int64] = []
        for stage in stages {
            let stageWords = try await dataSource.fetchWordsForStage(stageId: stage.id)
            allWordIds.append(contentsOf: stageWords.map(\.id))
        }

        // Preserve unique word IDs
        var uniqueWordIds: [Int64] = []
        var seenIds = Set<Int64>()
        for id in allWordIds where !seenIds.contains(id) {
            seenIds.insert(id)
            uniqueWordIds.append(id)
        }

        // 5. Ingest words into user progress via single batch operation
        if let progressRepo, !uniqueWordIds.isEmpty {
            try await progressRepo.recordBatchLessonResults(
                practicedWordIds: uniqueWordIds,
                weakWordIds: [],
                stageId: checkpointStageId,
                deckId: deckId
            )
        }

        let completedStageIds = stages.map(\.id) + [checkpointStageId]
        return FastTrackResult(
            deckId: deckId,
            isSuccess: true,
            scorePercentage: scorePercentage,
            completedStageIds: completedStageIds,
            ingestedWordCount: uniqueWordIds.count
        )
    }
}
