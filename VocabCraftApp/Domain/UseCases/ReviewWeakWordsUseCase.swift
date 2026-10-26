import Foundation

/// Protocol for querying weak words and marking words reviewed in a focused session.
public protocol ReviewWeakWordsUseCaseProtocol: Sendable {
    func fetchWeakWords() async throws -> [PersonalWord]
    /// Words whose `nextReviewDate` has passed (or that are flagged `needsReview`), most overdue first.
    func fetchDueWords(now: Date) async throws -> [PersonalWord]
    func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws
}

public extension ReviewWeakWordsUseCaseProtocol {
    func fetchDueWords(now: Date) async throws -> [PersonalWord] {
        try await fetchWeakWords()
    }

    func markWordReviewed(wordId: Int64) async throws {
        try await markWordReviewed(wordId: wordId, isCorrect: true)
    }
}

/// Scheduling applied when a word is graded in Smart Review.
enum SmartReviewScheduling {
    /// Smart Review has no response timer, so SRS receives a neutral response time.
    static let responseTimeMs = 3000

    struct Schedule {
        let easeFactor: Double
        let intervalDays: Int
        let nextReviewDate: Date
    }

    static func schedule(
        masteryBefore: Int,
        easeFactor: Double,
        isCorrect: Bool,
        now: Date
    ) -> Schedule {
        let result = SRSEngine.calculateNextInterval(
            currentMastery: masteryBefore,
            easeFactor: easeFactor,
            isCorrect: isCorrect,
            responseTimeMs: responseTimeMs
        )
        let nextReviewDate = Calendar.current.date(byAdding: .day, value: result.intervalDays, to: now)
            ?? now.addingTimeInterval(TimeInterval(result.intervalDays) * 86_400)
        return Schedule(easeFactor: result.easeFactor, intervalDays: result.intervalDays, nextReviewDate: nextReviewDate)
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
        return try await resolveWords(for: allProgress.filter(\.needsReview))
    }

    public func fetchDueWords(now: Date) async throws -> [PersonalWord] {
        let allProgress = try await progressRepo.fetchAllProgress()
        let dueProgress = allProgress
            .filter { $0.nextReviewDate <= now || $0.needsReview }
            .sorted { lhs, rhs in
                lhs.nextReviewDate == rhs.nextReviewDate
                    ? lhs.wordId < rhs.wordId
                    : lhs.nextReviewDate < rhs.nextReviewDate
            }
        return try await resolveWords(for: dueProgress)
    }

    private func resolveWords(for weakProgress: [UserWordProgressData]) async throws -> [PersonalWord] {
        guard !weakProgress.isEmpty else { return [] }

        let weakIds = Set(weakProgress.map(\.wordId))
        let wordsList = try await dataSource.fetchWordsByIds(ids: weakIds)
        let wordsMap = Dictionary(wordsList.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
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
