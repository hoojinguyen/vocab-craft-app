// NOTE (Phase 3A / Task 5):
// Lesson attempts are recorded via RecordSenseAttemptUseCase directly into LearningJournal (B3).
// RecordMixedDrillAttemptUseCase currently handles the mixed drill practice flow with
// UserProgressRepository and will be wired into LearningJournal in the subsequent Mixed Reflex Phase.
import Foundation

public protocol RecordMixedDrillAttemptUseCaseProtocol: Sendable {
    func execute(wordId: Int64, mode: ReflexBlitzMode, isCorrect: Bool) async throws -> VaultWordItem?
}

public final class RecordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol, Sendable {
    private let progressRepo: any UserProgressRepositoryProtocol
    private let dataSource: VocabularyDataSourceProtocol

    public init(
        progressRepo: any UserProgressRepositoryProtocol,
        dataSource: VocabularyDataSourceProtocol
    ) {
        self.progressRepo = progressRepo
        self.dataSource = dataSource
    }

    public func execute(wordId: Int64, mode: ReflexBlitzMode, isCorrect: Bool) async throws -> VaultWordItem? {
        let existingProgress = try await progressRepo.fetchProgress(for: wordId)
        let currentStreak = existingProgress?.consecutiveCorrectStreak ?? 0
        let currentModes = existingProgress?.practicedModes ?? []
        var modeStats = existingProgress?.modeStats ?? ModeSuccessStats()
        if isCorrect {
            modeStats.increment(for: mode)
        }

        let evaluation = MasteryEvaluationPolicy.evaluate(
            currentStreak: currentStreak,
            practicedModes: currentModes,
            isCorrect: isCorrect,
            currentMode: mode
        )

        try await progressRepo.recordDrillResult(
            wordId: wordId,
            isCorrect: isCorrect,
            newStreak: evaluation.newStreak,
            newModes: evaluation.newPracticedModes,
            isMastered: evaluation.isMastered,
            modeStats: modeStats
        )

        guard let wordDTO = try await dataSource.fetchWordById(id: wordId) else { return nil }
        let updatedProgress = try await progressRepo.fetchProgress(for: wordId)

        return VaultWordItem(
            id: wordDTO.id,
            lemma: wordDTO.lemma,
            pos: wordDTO.pos,
            phonetic: wordDTO.phonetic,
            definitionVi: wordDTO.definitionVi,
            exampleSentenceEn: wordDTO.exampleEn,
            exampleSentenceVi: wordDTO.exampleVi,
            cefrLevel: wordDTO.cefrLevel,
            isMastered: evaluation.isMastered,
            isBookmarked: updatedProgress?.isBookmarked ?? false,
            correctStreak: evaluation.newStreak,
            practicedModes: evaluation.newPracticedModes,
            lastPracticedAt: Date(),
            modeStats: updatedProgress?.modeStats ?? modeStats
        )
    }
}
