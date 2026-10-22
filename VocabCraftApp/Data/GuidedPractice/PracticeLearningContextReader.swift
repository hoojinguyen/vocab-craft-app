import Foundation

/// Assembles learner progress, communicative evidence, and vocabulary snapshots
/// from persistence layers to provide the input context for guided practice mission selection.
public struct PracticeLearningContextReader: Sendable {
    private let vocabularyDataSource: any VocabularyDataSourceProtocol
    private let progressRepository: any UserProgressRepositoryProtocol
    private let practiceRepository: any PracticeRepositoryProtocol
    private let quickReflexWordIdsProvider: (@Sendable () async throws -> Set<Int64>)?

    public init(
        vocabularyDataSource: any VocabularyDataSourceProtocol,
        progressRepository: any UserProgressRepositoryProtocol,
        practiceRepository: any PracticeRepositoryProtocol,
        quickReflexWordIdsProvider: (@Sendable () async throws -> Set<Int64>)? = nil
    ) {
        self.vocabularyDataSource = vocabularyDataSource
        self.progressRepository = progressRepository
        self.practiceRepository = practiceRepository
        self.quickReflexWordIdsProvider = quickReflexWordIdsProvider
    }

    /// Loads and returns the aggregated pedagogical context.
    ///
    /// - Throws: Any underlying repository or data source errors without substituting fake or demo data.
    public func load() async throws -> PracticeLearningContext {
        // 1. Fetch all user vocabulary progress records
        let allProgress = try await progressRepository.fetchAllProgress()

        // 2. Filter learned words: must have recorded reviews or non-zero mastery level.
        // Pure bookmarks (totalReviews == 0 && masteryLevel == 0) are disqualified.
        let learnedProgress = allProgress.filter { $0.totalReviews > 0 || $0.masteryLevel > 0 }

        // 3. Load communication progress and historical evidence from practice repository
        let communicationProgress = try await practiceRepository.progress()
        let evidence = try await practiceRepository.evidence()
        let reflexWordIds = try await quickReflexWordIdsProvider?() ?? []

        guard !learnedProgress.isEmpty else {
            return PracticeLearningContext(
                words: [],
                progress: [],
                communication: communicationProgress,
                evidence: evidence,
                recentReflexWordIds: reflexWordIds
            )
        }

        // 4. Resolve official vocabulary snapshots for eligible words
        let learnedWordIds = Set(learnedProgress.map(\.wordId))
        let dtos = try await vocabularyDataSource.fetchWordsByIds(ids: learnedWordIds)

        var progressByWordId: [Int64: UserWordProgressData] = [:]
        for record in learnedProgress {
            progressByWordId[record.wordId] = record
        }

        var snapshots: [PracticeWordSnapshot] = []
        snapshots.reserveCapacity(dtos.count)
        var resolvedWordIds = Set<Int64>()
        resolvedWordIds.reserveCapacity(dtos.count)

        for dto in dtos {
            resolvedWordIds.insert(dto.id)
            let progressRecord = progressByWordId[dto.id]
            let snapshot = PracticeWordSnapshot(
                wordId: dto.id,
                lemma: dto.lemma,
                definitionEn: dto.definitionEn,
                definitionVi: dto.definitionVi,
                sourceDeckId: progressRecord?.sourceDeckId,
                sourceNodeId: progressRecord?.sourceNodeId ?? dto.stageId
            )
            snapshots.append(snapshot)
        }

        // Only retain progress records whose vocabulary successfully resolved
        let verifiedProgress = learnedProgress.filter { resolvedWordIds.contains($0.wordId) }

        return PracticeLearningContext(
            words: snapshots,
            progress: verifiedProgress,
            communication: communicationProgress,
            evidence: evidence,
            recentReflexWordIds: reflexWordIds
        )
    }
}
