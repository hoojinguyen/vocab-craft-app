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
            isMastered: evaluation.isMastered
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
            lastPracticedAt: Date()
        )
    }
}
