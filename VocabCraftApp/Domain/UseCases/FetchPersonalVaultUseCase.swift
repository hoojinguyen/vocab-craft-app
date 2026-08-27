import Foundation

/// Filter categories for the Personal Vault.
public enum PersonalVaultFilter: String, CaseIterable, Sendable, Equatable {
    case all
    case needsReview
    case mastered
    case bookmarked

    public var title: String {
        switch self {
        case .all: return "Tất cả"
        case .needsReview: return "Cần ôn"
        case .mastered: return "Đã thuộc"
        case .bookmarked: return "Đã lưu"
        }
    }
}

/// 3-tab filter for the redesigned Vocabulary Vault.
public enum VaultTabFilter: String, CaseIterable, Sendable, Equatable {
    case notMastered
    case mastered
    case bookmarked

    public var title: String {
        switch self {
        case .notMastered: return "Chưa thuộc"
        case .mastered: return "Đã thuộc"
        case .bookmarked: return "Đã lưu"
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
    private let dataSource: VocabularyDataSourceProtocol
    private let progressRepo: any UserProgressRepositoryProtocol

    public init(
        dataSource: VocabularyDataSourceProtocol,
        progressRepo: any UserProgressRepositoryProtocol
    ) {
        self.dataSource = dataSource
        self.progressRepo = progressRepo
    }

    public func execute(filter: PersonalVaultFilter = .all, searchQuery: String? = nil) async throws -> PersonalVaultResult {
        let allProgress = try await progressRepo.fetchAllProgress()
        var allPersonalWords: [PersonalWord] = []
        allPersonalWords.reserveCapacity(allProgress.count)

        for progress in allProgress {
            if let wordDTO = try await dataSource.fetchWordById(id: progress.wordId) {
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

        let total = allPersonalWords.count
        let mastered = allPersonalWords.filter { $0.masteryLevel >= 4 }.count
        let bookmarked = allPersonalWords.filter(\.isBookmarked).count
        let needsReview = allPersonalWords.filter(\.needsReview).count
        let unmastered = max(0, total - mastered)

        let metrics = PersonalVaultMetrics(
            totalWords: total,
            needsReviewCount: needsReview,
            masteredCount: mastered,
            bookmarkedCount: bookmarked,
            unmasteredCount: unmastered
        )

        var filteredWords: [PersonalWord]
        switch filter {
        case .all:
            filteredWords = allPersonalWords
        case .needsReview:
            filteredWords = allPersonalWords.filter(\.needsReview)
        case .mastered:
            filteredWords = allPersonalWords.filter { $0.masteryLevel >= 4 }
        case .bookmarked:
            filteredWords = allPersonalWords.filter(\.isBookmarked)
        }

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
        let allProgress = try await progressRepo.fetchAllProgress()
        var allVaultWords: [VaultWordItem] = []
        allVaultWords.reserveCapacity(allProgress.count)

        for progress in allProgress {
            if let wordDTO = try await dataSource.fetchWordById(id: progress.wordId) {
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
                    lastPracticedAt: progress.lastReviewDate
                )
                allVaultWords.append(vaultWord)
            }
        }

        var filteredWords: [VaultWordItem]
        switch filter {
        case .notMastered:
            filteredWords = allVaultWords.filter { !$0.isMastered }
        case .mastered:
            filteredWords = allVaultWords.filter(\.isMastered)
        case .bookmarked:
            filteredWords = allVaultWords.filter(\.isBookmarked)
        }

        if let query = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty {
            let lowerQuery = query.lowercased()
            filteredWords = filteredWords.filter { word in
                word.lemma.lowercased().contains(lowerQuery) ||
                word.definitionVi.lowercased().contains(lowerQuery) ||
                word.phonetic.lowercased().contains(lowerQuery)
            }
        }

        return filteredWords
    }
}
