import Foundation
import SwiftUI

/// Filter categories for the Personal Vault.
public enum PersonalVaultFilter: String, CaseIterable, Sendable, Equatable {
    case all
    case needsReview
    case mastered
    case bookmarked

    public var titleKey: LocalizedStringKey {
        switch self {
        case .all: return AppStrings.Vocabulary.filterAll
        case .needsReview: return AppStrings.Vocabulary.filterReviewNeeded
        case .mastered: return AppStrings.Vocabulary.filterMastered
        case .bookmarked: return AppStrings.Vocabulary.filterSaved
        }
    }

    public var title: String {
        switch self {
        case .all: return String(localized: "vocabulary.filterAll", defaultValue: "All", bundle: .module)
        case .needsReview: return String(localized: "vocabulary.filterReviewNeeded", defaultValue: "Needs Review", bundle: .module)
        case .mastered: return String(localized: "vocabulary.filterMastered", defaultValue: "Mastered", bundle: .module)
        case .bookmarked: return String(localized: "vocabulary.filterSaved", defaultValue: "Saved", bundle: .module)
        }
    }
}

/// 3-tab filter for the redesigned Vocabulary Vault.
public enum VaultTabFilter: String, CaseIterable, Sendable, Equatable {
    case notMastered
    case mastered
    case bookmarked

    public var titleKey: LocalizedStringKey {
        switch self {
        case .notMastered: return AppStrings.Vault.filterNotMasteredTitleKey
        case .mastered: return AppStrings.Vault.filterMasteredTitleKey
        case .bookmarked: return AppStrings.Vault.filterBookmarkedTitleKey
        }
    }

    public var title: String {
        switch self {
        case .notMastered: return AppStrings.Vault.filterNotMasteredTitle
        case .mastered: return AppStrings.Vault.filterMasteredTitle
        case .bookmarked: return AppStrings.Vault.filterBookmarkedTitle
        }
    }
}

/// Aggregated metrics and word count statistics for the Personal Vault.
public struct PersonalVaultMetrics: Sendable, Equatable {
    public let totalWords: Int
    public let needsReviewCount: Int
    public let masteredCount: Int
    public let bookmarkedCount: Int
    public let unmasteredCount: Int

    public var totalCount: Int { totalWords }
    public var totalLearnedWords: Int { totalWords }

    public init(
        totalWords: Int = 0,
        needsReviewCount: Int = 0,
        masteredCount: Int = 0,
        bookmarkedCount: Int = 0,
        unmasteredCount: Int? = nil,
        totalLearnedWords: Int? = nil
    ) {
        let total = totalLearnedWords ?? totalWords
        self.totalWords = total
        self.needsReviewCount = needsReviewCount
        self.masteredCount = masteredCount
        self.bookmarkedCount = bookmarkedCount
        self.unmasteredCount = unmasteredCount ?? max(0, total - masteredCount)
    }
}

/// The result returned by `FetchPersonalVaultUseCase`, containing the filtered words and the overall metrics.
public struct PersonalVaultResult: Sendable, Equatable {
    public let words: [PersonalWord]
    public let metrics: PersonalVaultMetrics

    public init(words: [PersonalWord], metrics: PersonalVaultMetrics) {
        self.words = words
        self.metrics = metrics
    }
}

/// Protocol for fetching and filtering Personal Vault words and calculating statistics.
public protocol FetchPersonalVaultUseCaseProtocol: Sendable {
    func execute(filter: PersonalVaultFilter, searchQuery: String?) async throws -> PersonalVaultResult
    func fetchVaultWords(filter: VaultTabFilter, searchQuery: String?) async throws -> [VaultWordItem]
}

public extension FetchPersonalVaultUseCaseProtocol {
    func execute(filter: PersonalVaultFilter = .all, searchQuery: String? = nil) async throws -> PersonalVaultResult {
        try await execute(filter: filter, searchQuery: searchQuery)
    }

    func fetchVaultWords(filter: VaultTabFilter = .notMastered, searchQuery: String? = nil) async throws -> [VaultWordItem] {
        try await fetchVaultWords(filter: filter, searchQuery: searchQuery)
    }
}

/// Retrieves the user's personal vault items, overlays live mastery and flags, and computes filter counts.
public final class FetchPersonalVaultUseCase: FetchPersonalVaultUseCaseProtocol, Sendable {
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

    public func execute(filter: PersonalVaultFilter = .all, searchQuery: String? = nil) async throws -> PersonalVaultResult {
        if let contentRepository, let journal {
            return try await executeWithContentRepository(
                contentRepository: contentRepository,
                journal: journal,
                filter: filter,
                searchQuery: searchQuery
            )
        }

        guard let dataSource, let progressRepo else {
            return PersonalVaultResult(words: [], metrics: PersonalVaultMetrics())
        }

        return try await executeWithLegacyDataSource(
            dataSource: dataSource,
            progressRepo: progressRepo,
            filter: filter,
            searchQuery: searchQuery
        )
    }

    private func executeWithContentRepository(
        contentRepository: any ContentRepository,
        journal: LearningJournal,
        filter: PersonalVaultFilter,
        searchQuery: String?
    ) async throws -> PersonalVaultResult {
        let profile = try await resolveProfile(journal: journal)
        let payload = try await fetchSenseEntities(
            contentRepository: contentRepository,
            journal: journal,
            profile: profile
        )
        let senses = payload.senses
        let bookmarked = payload.bookmarked
        let counterMap = payload.counters

        var allPersonalWords: [PersonalWord] = []
        allPersonalWords.reserveCapacity(senses.count)

        for sense in senses {
            let (total, correct) = counterMap[sense.id] ?? (0, 0)
            let mastery = total == 0 ? 0 : min(5, Int((Double(correct) / Double(total)) * 5.0))
            let isMastered = (total >= 4 && Double(correct) / Double(total) >= 0.8)
            let needsReview = (total > 0 && Double(correct) / Double(total) < 0.7)
            let isBookmarked = bookmarked.contains(sense.id)
            let mistakeCount = max(0, total - correct)

            let word = PersonalWord(
                sense: sense,
                masteryLevel: isMastered ? 4 : mastery,
                isBookmarked: isBookmarked,
                needsReview: needsReview,
                mistakeCount: mistakeCount
            )
            allPersonalWords.append(word)
        }

        let metrics = computeMetrics(from: allPersonalWords)
        var filteredWords = filterPersonalWords(allPersonalWords, by: filter)

        if let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let lowerQuery = query.lowercased()
            filteredWords = filteredWords.filter { word in
                word.lemma.lowercased().contains(lowerQuery) ||
                word.definitionVi.lowercased().contains(lowerQuery) ||
                word.definitionEn.lowercased().contains(lowerQuery) ||
                word.phonetic.lowercased().contains(lowerQuery)
            }
        }

        return PersonalVaultResult(words: filteredWords, metrics: metrics)
    }

    private func executeWithLegacyDataSource(
        dataSource: VocabularyDataSourceProtocol,
        progressRepo: any UserProgressRepositoryProtocol,
        filter: PersonalVaultFilter,
        searchQuery: String?
    ) async throws -> PersonalVaultResult {
        let allProgress = try await progressRepo.fetchAllProgress()
        let wordIds = Set(allProgress.map(\.wordId))
        let wordsList = try await dataSource.fetchWordsByIds(ids: wordIds)
        let wordsMap = Dictionary(wordsList.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var allPersonalWords: [PersonalWord] = []
        allPersonalWords.reserveCapacity(allProgress.count)

        for progress in allProgress {
            if let wordDTO = wordsMap[progress.wordId] {
                let personalWord = PersonalWord(
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
                allPersonalWords.append(personalWord)
            }
        }

        let metrics = computeMetrics(from: allPersonalWords)
        var filteredWords = filterPersonalWords(allPersonalWords, by: filter)

        if let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let lowerQuery = query.lowercased()
            filteredWords = filteredWords.filter { word in
                word.lemma.lowercased().contains(lowerQuery) ||
                word.definitionVi.lowercased().contains(lowerQuery) ||
                word.definitionEn.lowercased().contains(lowerQuery) ||
                word.phonetic.lowercased().contains(lowerQuery)
            }
        }

        return PersonalVaultResult(words: filteredWords, metrics: metrics)
    }

    public func fetchVaultWords(filter: VaultTabFilter = .notMastered, searchQuery: String? = nil) async throws -> [VaultWordItem] {
        if let contentRepository, let journal {
            let profile = try await resolveProfile(journal: journal)
            let payload = try await fetchSenseEntities(
                contentRepository: contentRepository,
                journal: journal,
                profile: profile
            )
            let senses = payload.senses
            let bookmarked = payload.bookmarked
            let counterMap = payload.counters

            var allVaultWords: [VaultWordItem] = []
            allVaultWords.reserveCapacity(senses.count)

            for sense in senses {
                let (total, correct) = counterMap[sense.id] ?? (0, 0)
                let isMastered = (total >= 4 && Double(correct) / Double(total) >= 0.8)
                let isBookmarked = bookmarked.contains(sense.id)
                let vaultWord = VaultWordItem(
                    sense: sense,
                    isMastered: isMastered,
                    isBookmarked: isBookmarked,
                    correctStreak: correct
                )
                allVaultWords.append(vaultWord)
            }

            return filterVaultWordItems(allVaultWords, by: filter, searchQuery: searchQuery)
        }

        guard let dataSource, let progressRepo else { return [] }
        let allProgress = try await progressRepo.fetchAllProgress()
        let wordIds = Set(allProgress.map(\.wordId))
        let wordsList = try await dataSource.fetchWordsByIds(ids: wordIds)
        let wordsMap = Dictionary(wordsList.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var allVaultWords: [VaultWordItem] = []
        allVaultWords.reserveCapacity(allProgress.count)

        for progress in allProgress {
            if let wordDTO = wordsMap[progress.wordId] {
                let isMastered = progress.isMastered || progress.masteryLevel >= 4
                let vaultWord = VaultWordItem(
                    id: wordDTO.id,
                    lemma: wordDTO.lemma,
                    pos: wordDTO.pos,
                    phonetic: wordDTO.phonetic,
                    definitionVi: wordDTO.definitionVi,
                    exampleSentenceEn: wordDTO.exampleEn,
                    exampleSentenceVi: wordDTO.exampleVi,
                    cefrLevel: wordDTO.cefrLevel,
                    isMastered: isMastered,
                    isBookmarked: progress.isBookmarked,
                    correctStreak: progress.consecutiveCorrectStreak,
                    practicedModes: progress.practicedModes,
                    lastPracticedAt: progress.lastReviewDate,
                    modeStats: progress.modeStats
                )
                allVaultWords.append(vaultWord)
            }
        }

        return filterVaultWordItems(allVaultWords, by: filter, searchQuery: searchQuery)
    }

    private func resolveProfile(journal: LearningJournal) async throws -> ProfileID {
        if let profileID {
            return try await journal.ensureDefaultGuestProfile(id: profileID)
        }
        return try await journal.createGuestProfile()
    }

    private struct SenseEntitiesPayload {
        let senses: [SenseDetail]
        let bookmarked: Set<SenseID>
        let counters: [SenseID: (total: Int, correct: Int)]
    }

    private func fetchSenseEntities(
        contentRepository: any ContentRepository,
        journal: LearningJournal,
        profile: ProfileID
    ) async throws -> SenseEntitiesPayload {
        let completed = try await journal.completedLessons(profileID: profile)
        var lessonSenseIDs: [SenseID] = []
        for completion in completed {
            let lessonDetail = try await contentRepository.fetchLessonContent(lessonID: completion.lessonID)
            lessonSenseIDs.append(contentsOf: lessonDetail.senses.map(\.senseID))
        }

        let practiced = try await journal.practicedSenseIDs(profileID: profile)
        let bookmarked = try await journal.bookmarkedSenseIDs(profileID: profile)

        var uniqueSenseIDs: [SenseID] = []
        var seen = Set<SenseID>()
        for id in (lessonSenseIDs + Array(practiced) + Array(bookmarked)) where seen.insert(id).inserted {
            uniqueSenseIDs.append(id)
        }

        let senses = try await contentRepository.fetchSenses(ids: uniqueSenseIDs)
        var counterMap: [SenseID: (total: Int, correct: Int)] = [:]
        for sense in senses {
            let counterList = try await journal.counters(profileID: profile, senseID: sense.id)
            let total = counterList.reduce(0) { $0 + $1.totalCount }
            let correct = counterList.reduce(0) { $0 + $1.correctCount }
            counterMap[sense.id] = (total, correct)
        }

        return SenseEntitiesPayload(senses: senses, bookmarked: bookmarked, counters: counterMap)
    }

    private func computeMetrics(from words: [PersonalWord]) -> PersonalVaultMetrics {
        let total = words.count
        let mastered = words.filter { $0.masteryLevel >= 4 }.count
        let bookmarked = words.filter(\.isBookmarked).count
        let needsReview = words.filter(\.needsReview).count
        let unmastered = max(0, total - mastered)

        return PersonalVaultMetrics(
            totalWords: total,
            needsReviewCount: needsReview,
            masteredCount: mastered,
            bookmarkedCount: bookmarked,
            unmasteredCount: unmastered
        )
    }

    private func filterPersonalWords(_ words: [PersonalWord], by filter: PersonalVaultFilter) -> [PersonalWord] {
        switch filter {
        case .all: return words
        case .needsReview: return words.filter(\.needsReview)
        case .mastered: return words.filter { $0.masteryLevel >= 4 }
        case .bookmarked: return words.filter(\.isBookmarked)
        }
    }

    private func filterVaultWordItems(_ words: [VaultWordItem], by filter: VaultTabFilter, searchQuery: String?) -> [VaultWordItem] {
        var filtered: [VaultWordItem]
        switch filter {
        case .notMastered: filtered = words.filter { !$0.isMastered }
        case .mastered: filtered = words.filter(\.isMastered)
        case .bookmarked: filtered = words.filter(\.isBookmarked)
        }

        if let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let lowerQuery = query.lowercased()
            filtered = filtered.filter { word in
                word.lemma.lowercased().contains(lowerQuery) ||
                word.definitionVi.lowercased().contains(lowerQuery) ||
                word.phonetic.lowercased().contains(lowerQuery)
            }
        }

        return filtered
    }
}
