import Foundation
import Testing
@testable import VocabCraftApp

@Suite("RefreshWidgetDeckUseCase")
struct RefreshWidgetDeckUseCaseTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 86_400

    private func word(_ id: Int64, stage: String) -> TopicWordDTO {
        TopicWordDTO(
            id: id, stageId: stage, lemma: "word\(id)", phonetic: "/w\(id)/", pos: "noun",
            cefrLevel: "A1", definitionVi: "nghia \(id)", definitionEn: "meaning \(id)",
            exampleEn: "Example \(id).", exampleVi: "Vi du \(id)."
        )
    }

    private func deck(_ id: String, order: Int) -> TopicDeckDTO {
        TopicDeckDTO(id: id, titleEn: id, iconName: "book", cefrLevel: "A1", sortOrder: order)
    }

    private func stage(_ id: String, deck: String, order: Int) -> SubTopicStageDTO {
        SubTopicStageDTO(id: id, deckId: deck, titleEn: id, iconName: "book", sortOrder: order)
    }

    private func done(_ stage: String, deck: String, at date: Date) -> UserStageProgressData {
        UserStageProgressData(stageId: stage, deckId: deck, isCompleted: true, completedAt: date)
    }

    private func makeStore() -> WidgetDeckStore {
        WidgetDeckStore(
            directoryURL: FileManager.default.temporaryDirectory
                .appendingPathComponent("RefreshWidgetDeckTests-\(UUID().uuidString)", isDirectory: true)
        )
    }

    private struct Harness {
        let useCase: RefreshWidgetDeckUseCase
        let store: WidgetDeckStore
        let reloader: MockReloader
    }

    private func makeHarness(
        curriculum: LearningPathCurriculum?,
        progress: [UserWordProgressData] = []
    ) -> Harness {
        let store = makeStore()
        let reloader = MockReloader()
        let now = self.now
        let useCase = RefreshWidgetDeckUseCase(
            fetchLearningPath: MockFetchLearningPath(curriculum: curriculum),
            progressRepository: MockProgressRepo(progress: progress),
            dataSource: MockDataSource(words: curriculum?.words ?? []),
            store: store,
            reloader: reloader,
            now: { now }
        )
        return Harness(useCase: useCase, store: store, reloader: reloader)
    }

    @Test func writesDeckAndReloads() async {
        let words = [
            word(1, stage: "A"), word(2, stage: "A"), word(3, stage: "B"), word(4, stage: "B")
        ]
        let curriculum = LearningPathCurriculum(
            decks: [deck("d1", order: 1)],
            stages: [stage("A", deck: "d1", order: 1), stage("B", deck: "d1", order: 2)],
            words: words,
            progressList: [done("A", deck: "d1", at: now.addingTimeInterval(-day))]
        )
        let harness = makeHarness(
            curriculum: curriculum,
            progress: [UserWordProgressData(wordId: 1, nextReviewDate: now.addingTimeInterval(-60))]
        )

        await harness.useCase.execute()

        let saved = harness.store.loadDeck()
        #expect(saved?.cards.map(\.wordId) == [1, 2, 3, 4])
        #expect(saved?.cards.first?.source == .due)
        #expect(saved?.cards[1].source == .recent)
        #expect(harness.reloader.kinds == ["VocabWidget"])
    }

    @Test func futureReviewDateIsNotDue() async {
        let curriculum = LearningPathCurriculum(
            decks: [deck("d1", order: 1)],
            stages: [stage("A", deck: "d1", order: 1)],
            words: [word(1, stage: "A")],
            progressList: []
        )
        let harness = makeHarness(
            curriculum: curriculum,
            progress: [UserWordProgressData(wordId: 1, nextReviewDate: now.addingTimeInterval(60), needsReview: true)]
        )

        await harness.useCase.execute()

        #expect(harness.store.loadDeck()?.cards.first?.source == .upcoming)
    }

    @Test func recentOrderedByCompletionDate() async {
        let words = [word(1, stage: "A"), word(2, stage: "C")]
        let curriculum = LearningPathCurriculum(
            decks: [deck("d1", order: 1)],
            stages: [stage("A", deck: "d1", order: 1), stage("C", deck: "d1", order: 2)],
            words: words,
            progressList: [
                done("A", deck: "d1", at: now.addingTimeInterval(-day)),
                done("C", deck: "d1", at: now)
            ]
        )
        let harness = makeHarness(curriculum: curriculum)

        await harness.useCase.execute()

        #expect(harness.store.loadDeck()?.cards.map(\.wordId) == [2, 1])
    }

    @Test func upcomingFollowsPathOrder() async {
        // Stages/decks are listed out of path order on purpose.
        let words = [word(1, stage: "S2"), word(2, stage: "S1")]
        let curriculum = LearningPathCurriculum(
            decks: [deck("d2", order: 2), deck("d1", order: 1)],
            stages: [stage("S2", deck: "d2", order: 1), stage("S1", deck: "d1", order: 1)],
            words: words,
            progressList: []
        )
        let harness = makeHarness(curriculum: curriculum)

        await harness.useCase.execute()

        // Only the first incomplete stage in path order (d1/S1) is used; d2/S2 comes later.
        let ids = harness.store.loadDeck()?.cards.map(\.wordId)
        #expect(ids == [2])
        #expect(ids?.contains(1) == false)
    }

    @Test func upcomingIsOnlyTheNextLesson() async {
        let words = [word(1, stage: "S1"), word(2, stage: "S1"), word(3, stage: "S2"), word(4, stage: "S2")]
        let curriculum = LearningPathCurriculum(
            decks: [deck("d1", order: 1)],
            stages: [stage("S1", deck: "d1", order: 1), stage("S2", deck: "d1", order: 2)],
            words: words,
            progressList: []
        )
        let harness = makeHarness(curriculum: curriculum)

        await harness.useCase.execute()

        let cards = harness.store.loadDeck()?.cards
        #expect(cards?.map(\.wordId) == [1, 2])
        #expect(cards?.allSatisfy { $0.source == .upcoming } == true)
    }

    @Test func recentTiesBreakByStageId() async {
        let words = [word(1, stage: "B"), word(2, stage: "A")]
        let curriculum = LearningPathCurriculum(
            decks: [deck("d1", order: 1)],
            stages: [stage("B", deck: "d1", order: 1), stage("A", deck: "d1", order: 2)],
            words: words,
            progressList: [done("B", deck: "d1", at: now), done("A", deck: "d1", at: now)]
        )
        let harness = makeHarness(curriculum: curriculum)

        await harness.useCase.execute()

        #expect(harness.store.loadDeck()?.cards.map(\.wordId) == [2, 1])
    }

    @Test func failureDoesNotThrowOrWrite() async {
        let harness = makeHarness(curriculum: nil)

        await harness.useCase.execute()

        #expect(harness.store.loadDeck() == nil)
        #expect(harness.reloader.kinds.isEmpty)
    }
}

// MARK: - Test doubles

private struct TestError: Error {}

private struct MockFetchLearningPath: FetchLearningPathUseCaseProtocol {
    let curriculum: LearningPathCurriculum?

    func execute(pathId: String?, forceRefresh: Bool) async throws -> LearningPathCurriculum {
        guard let curriculum else { throw TestError() }
        return curriculum
    }
}

private struct MockProgressRepo: UserProgressRepositoryProtocol {
    let progress: [UserWordProgressData]

    func fetchAllProgress() async throws -> [UserWordProgressData] { progress }

    func recordChallengeResult(wordId: Int64, isCorrect: Bool, stageId: String?, deckId: String?) async throws {}
    func toggleBookmark(wordId: Int64) async throws -> Bool { false }
    func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws {}
    func clearNeedsReview(wordId: Int64) async throws {}
    func getProgress(wordId: Int64) async throws -> UserWordProgressData? { nil }
    func recordBatchLessonResults(
        practicedWordIds: [Int64], weakWordIds: Set<Int64>, stageId: String?, deckId: String?, cefrLevel: String?
    ) async throws {}
    // swiftlint:disable:next function_parameter_count
    func recordDrillResult(
        wordId: Int64, isCorrect: Bool, newStreak: Int, newModes: Set<ReflexBlitzMode>,
        isMastered: Bool, modeStats: ModeSuccessStats?
    ) async throws {}
    // swiftlint:disable:next function_parameter_count
    func saveProgress(
        wordId: Int64, cefrLevel: String, masteryLevel: Int, isBookmarked: Bool, needsReview: Bool,
        mistakeCount: Int, sourceDeckId: String?, sourceNodeId: String?
    ) async throws {}
}

private struct MockDataSource: VocabularyDataSourceProtocol {
    let words: [TopicWordDTO]

    func fetchTopicDecks() async throws -> [TopicDeckDTO] { [] }
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] { [] }
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] { words.filter { $0.stageId == stageId } }
    func searchWords(query: String) async throws -> [TopicWordDTO] { [] }
    func fetchWordById(id: Int64) async throws -> TopicWordDTO? { words.first { $0.id == id } }
}

private final class MockReloader: WidgetReloading, @unchecked Sendable {
    private let lock = NSLock()
    private var recorded: [String] = []

    var kinds: [String] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func reloadTimelines(ofKind kind: String) {
        lock.lock()
        defer { lock.unlock() }
        recorded.append(kind)
    }
}
