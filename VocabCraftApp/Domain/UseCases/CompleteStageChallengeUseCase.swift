import Foundation

/// Protocol for completing a stage challenge, recording scores, updating weak words, and unlocking progression.
public protocol CompleteStageChallengeUseCaseProtocol: Sendable {
    func execute(stageId: String, deckId: String, results: [WordChallengeResult]) async throws -> StageCompletionSummary
}

/// Evaluates a user's stage challenge results, awards XP, flags weak words, and persists stage progress.
public final class CompleteStageChallengeUseCase: CompleteStageChallengeUseCaseProtocol, Sendable {
    private let stageRepo: StageProgressRepositoryProtocol
    private let progressRepo: (any UserProgressRepositoryProtocol)?

    public init(
        stageRepo: StageProgressRepositoryProtocol,
        progressRepo: (any UserProgressRepositoryProtocol)? = nil
    ) {
        self.stageRepo = stageRepo
        self.progressRepo = progressRepo
    }

    public func execute(stageId: String, deckId: String, results: [WordChallengeResult]) async throws -> StageCompletionSummary {
        let totalQuestions: Int = results.count
        let correctCount: Int = results.reduce(into: 0) { count, res in
            if res.isCorrect { count += 1 }
        }
        let weakWordIds: [Int64] = results.compactMap { res in
            res.isCorrect ? nil : res.wordId
        }
        let xpEarned: Int = correctCount * 10
        let score: Int
        if totalQuestions > 0 {
            let ratio: Double = Double(correctCount) / Double(totalQuestions)
            score = Int(ratio * 100.0)
        } else {
            score = 0
        }

        // Save completed stage progress
        try await stageRepo.saveStageProgress(
            stageId: stageId,
            deckId: deckId,
            isCompleted: true,
            score: score
        )

        // Record individual word challenge outcomes in user progress repository
        if let progressRepo {
            for result in results {
                try await progressRepo.recordChallengeResult(
                    wordId: result.wordId,
                    isCorrect: result.isCorrect,
                    stageId: stageId,
                    deckId: deckId
                )
            }
        }

        return StageCompletionSummary(
            stageId: stageId,
            totalQuestions: totalQuestions,
            correctCount: correctCount,
            xpEarned: xpEarned,
            weakWordIds: weakWordIds
        )
    }
}
