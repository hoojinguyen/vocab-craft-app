import Foundation

/// Selects learned vocabulary that needs the most speaking practice.
struct SpeakingWordPicker: Sendable {
    private let progressRepository: any UserProgressRepositoryProtocol
    private let vocabulary: any VocabularyDataSourceProtocol

    /// Creates a picker backed by the learner's progress and vocabulary sources.
    init(
        progressRepository: any UserProgressRepositoryProtocol,
        vocabulary: any VocabularyDataSourceProtocol
    ) {
        self.progressRepository = progressRepository
        self.vocabulary = vocabulary
    }

    /// Returns up to `limit` resolvable words ranked from weakest to strongest.
    func pick(limit: Int = 3) async throws -> [SpeakingTargetWord] {
        guard limit > 0 else { return [] }

        let rankedProgress = try await progressRepository.fetchAllProgress()
            .filter { $0.totalReviews > 0 || $0.masteryLevel > 0 }
            .sorted(by: isWeaker)
        guard !rankedProgress.isEmpty else { return [] }

        let words = try await vocabulary.fetchWordsByIds(ids: Set(rankedProgress.map(\.wordId)))
        let wordsByID = Dictionary(words.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        return rankedProgress.compactMap { progress in
            guard let word = wordsByID[progress.wordId] else { return nil }
            return SpeakingTargetWord(wordId: word.id, lemma: word.lemma, definitionVi: word.definitionVi)
        }
        .prefix(limit)
        .map { $0 }
    }

    private func isWeaker(_ lhs: UserWordProgressData, _ rhs: UserWordProgressData) -> Bool {
        if lhs.masteryLevel != rhs.masteryLevel {
            return lhs.masteryLevel < rhs.masteryLevel
        }
        if lhs.mistakeCount != rhs.mistakeCount {
            return lhs.mistakeCount > rhs.mistakeCount
        }
        if lhs.lastReviewDate != rhs.lastReviewDate {
            return lhs.lastReviewDate < rhs.lastReviewDate
        }
        return lhs.wordId < rhs.wordId
    }
}
