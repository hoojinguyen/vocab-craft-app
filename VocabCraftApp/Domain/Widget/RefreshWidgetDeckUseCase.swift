import Foundation

public protocol RefreshWidgetDeckUseCaseProtocol: Sendable {
    func execute() async
}

/// Rebuilds the shared widget deck from the learning path and SRS state.
/// Failures are logged and swallowed: nothing is written and no reload is requested.
public final class RefreshWidgetDeckUseCase: RefreshWidgetDeckUseCaseProtocol {
    private let fetchLearningPath: FetchLearningPathUseCaseProtocol
    private let progressRepository: any UserProgressRepositoryProtocol
    private let dataSource: VocabularyDataSourceProtocol
    private let store: WidgetDeckStore
    private let reloader: WidgetReloading
    private let now: @Sendable () -> Date

    public init(
        fetchLearningPath: FetchLearningPathUseCaseProtocol,
        progressRepository: any UserProgressRepositoryProtocol,
        dataSource: VocabularyDataSourceProtocol,
        store: WidgetDeckStore,
        reloader: WidgetReloading,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.fetchLearningPath = fetchLearningPath
        self.progressRepository = progressRepository
        self.dataSource = dataSource
        self.store = store
        self.reloader = reloader
        self.now = now
    }

    public func execute() async {
        do {
            let currentDate = now()
            let curriculum = try await fetchLearningPath.execute()
            let progress = try await progressRepository.fetchAllProgress()

            let due = try await dueWords(from: progress, now: currentDate)
            let wordsByStage = Dictionary(grouping: curriculum.words, by: \.stageId)
            let recent = recentWords(curriculum: curriculum, wordsByStage: wordsByStage)
            let upcoming = upcomingWords(curriculum: curriculum, wordsByStage: wordsByStage)

            let deck = WidgetDeckComposer.compose(
                due: due,
                recent: recent,
                upcoming: upcoming,
                pathId: curriculum.activePath?.id,
                now: currentDate
            )
            try store.saveDeck(deck)
            reloader.reloadTimelines(ofKind: WidgetKind.vocab)
        } catch {
            print("[RefreshWidgetDeck] refresh failed: \(error)")
        }
    }

    private func dueWords(from progress: [UserWordProgressData], now: Date) async throws -> [TopicWordDTO] {
        let dueRows = progress
            .filter { $0.nextReviewDate <= now }
            .sorted {
                $0.nextReviewDate == $1.nextReviewDate
                    ? $0.wordId < $1.wordId
                    : $0.nextReviewDate < $1.nextReviewDate
            }
        guard !dueRows.isEmpty else { return [] }
        let resolved = try await dataSource.fetchWordsByIds(ids: Set(dueRows.map(\.wordId)))
        let byId = Dictionary(resolved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return dueRows.compactMap { byId[$0.wordId] }
    }

    private func recentWords(
        curriculum: LearningPathCurriculum,
        wordsByStage: [String: [TopicWordDTO]]
    ) -> [TopicWordDTO] {
        curriculum.progressList
            .filter(\.isCompleted)
            .sorted {
                $0.completedAt == $1.completedAt
                    ? $0.stageId < $1.stageId
                    : $0.completedAt > $1.completedAt
            }
            .flatMap { wordsByStage[$0.stageId] ?? [] }
    }

    private func upcomingWords(
        curriculum: LearningPathCurriculum,
        wordsByStage: [String: [TopicWordDTO]]
    ) -> [TopicWordDTO] {
        let completed = Set(curriculum.progressList.filter(\.isCompleted).map(\.stageId))
        let deckOrder = Dictionary(
            curriculum.decks.map { ($0.id, $0.sortOrder) },
            uniquingKeysWith: { first, _ in first }
        )
        let orderedStages = curriculum.stages
            .filter { !completed.contains($0.id) }
            .sorted {
                let lhsDeck = deckOrder[$0.deckId] ?? Int.max
                let rhsDeck = deckOrder[$1.deckId] ?? Int.max
                if lhsDeck != rhsDeck { return lhsDeck < rhsDeck }
                return $0.sortOrder < $1.sortOrder
            }

        // Only the next upcoming lesson: the first incomplete stage in path order that has words.
        for stage in orderedStages {
            if let words = wordsByStage[stage.id], !words.isEmpty {
                return Array(words.prefix(WidgetDeckComposer.maxCards))
            }
        }
        return []
    }
}
