import Foundation
@testable import VocabCraftApp

final class MockCompleteLessonUseCase: CompleteLessonUseCaseProtocol, @unchecked Sendable {
    var executedStageId: String?
    var executedDeckId: String?
    var executedStars: Int?
    var executedPracticedWordIds: [Int64]?
    var executedWeakWordIds: [Int64]?
    var executedProgressFraction: Double?
    var executedCefrLevel: String?
    var shouldFail: Bool = false
    var executeCallCount: Int = 0

    // swiftlint:disable:next function_parameter_count
    func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        practicedWordIds: [Int64],
        weakWordIds: [Int64],
        progressFraction: Double,
        cefrLevel: String?
    ) async throws -> LessonCompletionResult {
        executeCallCount += 1
        if shouldFail {
            throw URLError(.timedOut)
        }
        self.executedStageId = stageId
        self.executedDeckId = deckId
        self.executedStars = stars
        self.executedPracticedWordIds = practicedWordIds
        self.executedWeakWordIds = weakWordIds
        self.executedProgressFraction = progressFraction
        self.executedCefrLevel = cefrLevel
        return LessonCompletionResult(
            stageId: stageId,
            deckId: deckId,
            score: stars,
            xpEarned: 25,
            weakWordIds: weakWordIds,
            isUnitCheckpoint: false
        )
    }

    // swiftlint:disable:next function_parameter_count
    func execute(
        stageId: String,
        deckId: String,
        stars: Int,
        practicedWordIds: [Int64],
        weakWordIds: [Int64],
        progressFraction: Double
    ) async throws -> LessonCompletionResult {
        try await execute(
            stageId: stageId,
            deckId: deckId,
            stars: stars,
            practicedWordIds: practicedWordIds,
            weakWordIds: weakWordIds,
            progressFraction: progressFraction,
            cefrLevel: nil
        )
    }
}
