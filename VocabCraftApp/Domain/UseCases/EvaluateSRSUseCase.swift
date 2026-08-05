import Foundation

/// Business UseCase for computing SRS intervals and updating user mastery.
public protocol EvaluateSRSUseCaseProtocol: Sendable {
    func evaluateResponse(
        currentMastery: Int,
        easeFactor: Double,
        isCorrect: Bool,
        responseTimeMs: Int
    ) -> SRSResult

    func recordReview(
        wordId: Int64,
        isCorrect: Bool,
        responseTimeMs: Int
    ) async throws -> SRSResult
}

public final class EvaluateSRSUseCase: EvaluateSRSUseCaseProtocol {
    private let srsRepository: SRSRepositoryProtocol?

    public init(srsRepository: SRSRepositoryProtocol? = nil) {
        self.srsRepository = srsRepository
    }

    public func evaluateResponse(
        currentMastery: Int,
        easeFactor: Double,
        isCorrect: Bool,
        responseTimeMs: Int
    ) -> SRSResult {
        SRSEngine.calculateNextInterval(
            currentMastery: currentMastery,
            easeFactor: easeFactor,
            isCorrect: isCorrect,
            responseTimeMs: responseTimeMs
        )
    }

    public func recordReview(
        wordId: Int64,
        isCorrect: Bool,
        responseTimeMs: Int
    ) async throws -> SRSResult {
        let currentProgress = try await srsRepository?.getProgress(wordId: wordId)
            ?? SRSProgressItem(wordId: wordId)

        let result = evaluateResponse(
            currentMastery: currentProgress.masteryLevel,
            easeFactor: currentProgress.easeFactor,
            isCorrect: isCorrect,
            responseTimeMs: responseTimeMs
        )

        let now = Date()
        let nextReview = Calendar.current.date(byAdding: .day, value: result.intervalDays, to: now) ?? now

        let updatedProgress = SRSProgressItem(
            wordId: wordId,
            masteryLevel: result.nextMastery,
            easeFactor: result.easeFactor,
            intervalDays: result.intervalDays,
            nextReviewDate: nextReview,
            lastReviewDate: now,
            totalReviews: currentProgress.totalReviews + 1
        )

        try await srsRepository?.saveProgress(updatedProgress)
        return result
    }
}
