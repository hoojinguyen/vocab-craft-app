import Foundation
import os

public struct LessonCompletionResult: Sendable, Equatable {
    public let stageId: String
    public let deckId: String
    public let score: Int
    public let xpEarned: Int
    public let weakWordIds: [Int64]
    public let isUnitCheckpoint: Bool

    public init(
        stageId: String,
        deckId: String,
        score: Int,
        xpEarned: Int,
        weakWordIds: [Int64],
        isUnitCheckpoint: Bool
    ) {
        self.stageId = stageId
        self.deckId = deckId
        self.score = score
        self.xpEarned = xpEarned
        self.weakWordIds = weakWordIds
        self.isUnitCheckpoint = isUnitCheckpoint
    }
}

public protocol CompleteLessonUseCaseProtocol: Sendable {
    func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        weakWordIds: [Int64],
        progressFraction: Double
    ) async throws -> LessonCompletionResult
}

public final class CompleteLessonUseCase: CompleteLessonUseCaseProtocol, Sendable {
    private let stageRepo: StageProgressRepositoryProtocol
    private let progressRepo: (any UserProgressRepositoryProtocol)?
    private let inFlightTasksLock = OSAllocatedUnfairLock(initialState: [String: Task<LessonCompletionResult, any Error>]())

    public init(
        stageRepo: StageProgressRepositoryProtocol,
        progressRepo: (any UserProgressRepositoryProtocol)? = nil
    ) {
        self.stageRepo = stageRepo
        self.progressRepo = progressRepo
    }

    public func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        weakWordIds: [Int64],
        progressFraction: Double
    ) async throws -> LessonCompletionResult {
        let sessionKey = "\(deckId):\(stageId)"

        let sessionTask: Task<LessonCompletionResult, any Error> = inFlightTasksLock.withLock { state in
            if let existing = state[sessionKey] {
                return existing
            }
            let newTask = Task { [self] in
                defer {
                    self.inFlightTasksLock.withLock { state in
                        _ = state.removeValue(forKey: sessionKey)
                    }
                }
                return try await self.performExecution(
                    stageId: stageId,
                    deckId: deckId,
                    stars: stars,
                    weakWordIds: weakWordIds,
                    progressFraction: progressFraction
                )
            }
            state[sessionKey] = newTask
            return newTask
        }

        return try await sessionTask.value
    }

    private func performExecution(
        stageId: String,
        deckId: String,
        stars: Int,
        weakWordIds: [Int64],
        progressFraction: Double
    ) async throws -> LessonCompletionResult {
        let isCheckpoint = stageId.hasPrefix("checkpoint_")
        let isCompleted = progressFraction >= 1.0 || stars > 0
        let xpEarned = isCheckpoint ? 80 : 25

        try await stageRepo.saveStageProgress(
            stageId: stageId,
            deckId: deckId,
            isCompleted: isCompleted,
            score: stars,
            progressFraction: progressFraction
        )

        if let progressRepo, !weakWordIds.isEmpty {
            for wordId in weakWordIds {
                try await progressRepo.recordChallengeResult(
                    wordId: wordId,
                    isCorrect: false,
                    stageId: stageId,
                    deckId: deckId
                )
            }
        }

        return LessonCompletionResult(
            stageId: stageId,
            deckId: deckId,
            score: stars,
            xpEarned: xpEarned,
            weakWordIds: weakWordIds,
            isUnitCheckpoint: isCheckpoint
        )
    }
}
