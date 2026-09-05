import Foundation

/// Protocol for querying weak words and marking words reviewed in a focused session.
public protocol ReviewWeakWordsUseCaseProtocol: Sendable {
    func fetchWeakWords() async throws -> [PersonalWord]
    func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws
    func markSenseReviewed(senseID: SenseID, isCorrect: Bool) async throws
}

public extension ReviewWeakWordsUseCaseProtocol {
    func markWordReviewed(wordId: Int64) async throws {
        try await markWordReviewed(wordId: wordId, isCorrect: true)
    }

    func markSenseReviewed(senseID: SenseID, isCorrect: Bool = true) async throws {}
}

/// Retrieves words flagged with `needsReview` and updates their review status and mastery upon practice completion.
public final class ReviewWeakWordsUseCase: ReviewWeakWordsUseCaseProtocol, Sendable {
    private let dataSource: VocabularyDataSourceProtocol?
    private let progressRepo: (any UserProgressRepositoryProtocol)?
    private let contentRepository: (any ContentRepository)?
    private let journal: LearningJournal?
    private let profileID: ProfileID?

    public init(
        dataSource: VocabularyDataSourceProtocol? = nil,
        progressRepo: (any UserProgressRepositoryProtocol)? = nil,
        contentRepository: (any ContentRepository)? = nil,
        journal: LearningJournal? = nil,
        profileID: ProfileID? = nil
    ) {
        self.dataSource = dataSource
        self.progressRepo = progressRepo
        self.contentRepository = contentRepository
        self.journal = journal
        self.profileID = profileID
    }

    public convenience init(
        dataSource: VocabularyDataSourceProtocol,
        progressRepo: any UserProgressRepositoryProtocol
    ) {
        self.init(
            dataSource: dataSource,
            progressRepo: progressRepo,
            contentRepository: nil,
            journal: nil,
            profileID: nil
        )
    }

    public convenience init(
        contentRepository: any ContentRepository,
        journal: LearningJournal,
        profileID: ProfileID? = nil
    ) {
        self.init(
            dataSource: nil,
            progressRepo: nil,
            contentRepository: contentRepository,
            journal: journal,
            profileID: profileID
        )
    }

    public func fetchWeakWords() async throws -> [PersonalWord] {
        if let contentRepository, let journal {
            let profile = try await resolveProfile(journal: journal)
            let weakSenseIDs = try await journal.weakSenseIDs(profileID: profile)
            guard !weakSenseIDs.isEmpty else { return [] }

            let senses = try await contentRepository.fetchSenses(ids: Array(weakSenseIDs))
            let bookmarked = try await journal.bookmarkedSenseIDs(profileID: profile)

            return senses.map { sense in
                PersonalWord(
                    sense: sense,
                    masteryLevel: 1,
                    isBookmarked: bookmarked.contains(sense.id),
                    needsReview: true,
                    mistakeCount: 1
                )
            }
        }

        guard let progressRepo, let dataSource else { return [] }
        let allProgress = try await progressRepo.fetchAllProgress()
        let weakProgress = allProgress.filter(\.needsReview)
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
        try await progressRepo?.markWordReviewed(wordId: wordId, isCorrect: isCorrect)
    }

    public func markSenseReviewed(senseID: SenseID, isCorrect: Bool = true) async throws {
        // If there is journal recording in B5, it will append attempt
    }

    private func resolveProfile(journal: LearningJournal) async throws -> ProfileID {
        if let profileID {
            return try await journal.ensureDefaultGuestProfile(id: profileID)
        }
        return try await journal.createGuestProfile()
    }
}
