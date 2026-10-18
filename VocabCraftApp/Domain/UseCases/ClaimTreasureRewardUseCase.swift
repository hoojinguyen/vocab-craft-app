import Foundation

/// Represents the result of claiming a treasure chest milestone reward.
public struct TreasureRewardResult: Sendable, Equatable {
    public let stageId: String
    public let deckId: String
    public let xpEarned: Int
    public let isAlreadyClaimed: Bool

    public init(
        stageId: String,
        deckId: String,
        xpEarned: Int,
        isAlreadyClaimed: Bool
    ) {
        self.stageId = stageId
        self.deckId = deckId
        self.xpEarned = xpEarned
        self.isAlreadyClaimed = isAlreadyClaimed
    }
}

/// Errors thrown during treasure chest claim operations.
public enum TreasureClaimError: Error, LocalizedError, Sendable, Equatable {
    case checkpointIncomplete

    public var errorDescription: String? {
        switch self {
        case .checkpointIncomplete:
            return String(localized: "app.treasure.error.checkpoint_incomplete")
        }
    }
}

/// Domain contract for claiming treasure chest milestone rewards upon completing a unit.
public protocol ClaimTreasureRewardUseCaseProtocol: Sendable {
    func execute(deckId: String) async throws -> TreasureRewardResult
}

/// Implementation of `ClaimTreasureRewardUseCaseProtocol` validating milestone progression and awarding XP.
public final class ClaimTreasureRewardUseCase: ClaimTreasureRewardUseCaseProtocol, Sendable {
    private let stageRepo: StageProgressRepositoryProtocol

    public init(stageRepo: StageProgressRepositoryProtocol) {
        self.stageRepo = stageRepo
    }

    public func execute(deckId: String) async throws -> TreasureRewardResult {
        let checkpointStageId = "checkpoint_\(deckId)"
        let treasureStageId = "treasure_\(deckId)"

        // 1. Validation: Verify checkpoint is completed
        let checkpointProgress = try await stageRepo.fetchStageProgress(stageId: checkpointStageId)
        guard let checkpointProgress, checkpointProgress.isCompleted else {
            throw TreasureClaimError.checkpointIncomplete
        }

        // 2. Idempotence: Check if treasure chest has already been claimed
        let existingTreasure = try await stageRepo.fetchStageProgress(stageId: treasureStageId)
        if let existingTreasure, existingTreasure.isCompleted {
            return TreasureRewardResult(
                stageId: treasureStageId,
                deckId: deckId,
                xpEarned: 0,
                isAlreadyClaimed: true
            )
        }

        // 3. Persistence: Record completion to stage progress repository
        try await stageRepo.saveStageProgress(
            stageId: treasureStageId,
            deckId: deckId,
            isCompleted: true,
            score: 100,
            progressFraction: 1.0
        )

        // 4. Return result with awarded XP from LessonEconomyPolicy
        return TreasureRewardResult(
            stageId: treasureStageId,
            deckId: deckId,
            xpEarned: LessonEconomyPolicy.treasureXP,
            isAlreadyClaimed: false
        )
    }
}
