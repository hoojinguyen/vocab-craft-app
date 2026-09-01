import Foundation

/// Protocol for querying weak words and marking words reviewed in a focused session.
public protocol ReviewWeakWordsUseCaseProtocol: Sendable {
    func fetchWeakWords() async throws -> [PersonalWord]
    func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws
}

public extension ReviewWeakWordsUseCaseProtocol {
    func markWordReviewed(wordId: Int64) async throws {
        try await markWordReviewed(wordId: wordId, isCorrect: true)
    }
}

/// Retrieves words flagged with `needsReview` and updates their review status and mastery upon practice completion.
public final class ReviewWeakWordsUseCase: ReviewWeakWordsUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol
    private let progressRepo: any UserProgressRepositoryProtocol

    public init(
        dataSource: VocabularyDataSourceProtocol,
        progressRepo: any UserProgressRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.progressRepo = progressRepo
    }

    public func fetchWeakWords() async throws -> [PersonalWord] {
        let allProgress = try await progressRepo.fetchAllProgress()
        let weakProgress = allProgress.filter(\.needsReview)
        let wordsMap = try await dataSource.fetchAllWordsMap()
        var weakWords: [PersonalWord] = []
        weakWords.reserveCapacity(weakProgress.count)

        for progress in weakProgress {
            if let wordDTO = wordsMap[progress.wordId] {
                let word = PersonalWord(
                    id: wordDTO.id,
                    lemma: wordDTO.lemma,
                    phonetic: wordDTO.phonetic,
                    pos: wordDTO.pos,
                    cefrLevel: wordDTO.cefrLevel,
                    definitionVi: wordDTO.definitionVi,
                    definitionEn: wordDTO.definitionEn,
                    exampleEn: wordDTO.exampleEn,
                    exampleVi: wordDTO.exampleVi,
                    masteryLevel: progress.masteryLevel,
                    isBookmarked: progress.isBookmarked,
                    needsReview: progress.needsReview,
                    mistakeCount: progress.mistakeCount,
                    sourceDeckTitle: nil,
                    sourceStageTitle: nil
                )
                weakWords.append(word)
            }
        }

        return weakWords
    }

    public func markWordReviewed(wordId: Int64, isCorrect: Bool = true) async throws {
        try await progressRepo.markWordReviewed(wordId: wordId, isCorrect: isCorrect)
    }
}
