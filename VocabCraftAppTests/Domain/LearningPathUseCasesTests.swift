import CraftUIKit
import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class LearningPathUseCasesTests: XCTestCase {
    private var dataSource: SampleVocabularyDataSource!
    private var stageRepo: MockStageProgressRepository!
    private var progressRepo: MockUserProgressRepository!

    override func setUp() {
        super.setUp()
        dataSource = SampleVocabularyDataSource()
        stageRepo = MockStageProgressRepository()
        progressRepo = MockUserProgressRepository()
    }

    // MARK: - FetchLearningPathUseCase Tests

    func test_fetchLearningPathUseCase_fetchesAndMapsAllSections() async throws {
        let sut = FetchLearningPathUseCase(
            dataSource: dataSource,
            stageRepo: stageRepo
        )

        let curriculum = try await sut.execute()

        XCTAssertFalse(curriculum.decks.isEmpty)
        XCTAssertEqual(curriculum.decks.count, 4)
        XCTAssertFalse(curriculum.stages.isEmpty)
        XCTAssertFalse(curriculum.words.isEmpty)
        XCTAssertTrue(curriculum.progressList.isEmpty)

        let sections = LearningPathDataMapper.map(curriculum: curriculum)
        XCTAssertFalse(sections.isEmpty)
        XCTAssertEqual(sections.count, 4)

        // First section should have active first node for fresh user
        let firstSection = sections[0]
        XCTAssertEqual(firstSection.id, "deck_daily")
        XCTAssertFalse(firstSection.nodes.isEmpty)

        let firstNode = firstSection.nodes[0]
        XCTAssertEqual(firstNode.id, "stage_daily_1")
        XCTAssertEqual(firstNode.state, LessonNodeState.active)

        // Next node is upcoming for curiosity preview, remaining nodes locked
        XCTAssertEqual(firstSection.nodes[1].state, LessonNodeState.upcoming)
        XCTAssertEqual(firstSection.nodes[2].state, LessonNodeState.locked)
    }

    func test_fetchLearningPathUseCase_reflectsCompletedProgress() async throws {
        try await stageRepo.saveStageProgress(
            stageId: "stage_daily_1",
            deckId: "deck_daily",
            isCompleted: true,
            score: 3,
            progressFraction: 1.0
        )

        let sut = FetchLearningPathUseCase(
            dataSource: dataSource,
            stageRepo: stageRepo
        )

        let curriculum = try await sut.execute()
        XCTAssertEqual(curriculum.progressList.count, 1)
        XCTAssertEqual(curriculum.progressList.first?.stageId, "stage_daily_1")
        XCTAssertEqual(curriculum.progressList.first?.isCompleted, true)

        let sections = LearningPathDataMapper.map(curriculum: curriculum)
        let firstSection = sections[0]

        XCTAssertEqual(firstSection.nodes[0].state, LessonNodeState.completed)
        XCTAssertEqual(firstSection.nodes[0].stars, 3)
        XCTAssertEqual(firstSection.nodes[1].state, LessonNodeState.active)
    }

    func test_fetchLearningPathUseCase_cachesStaticCurriculumOnSubsequentCalls() async throws {
        let spyDataSource = SpyVocabularyDataSource(base: dataSource)
        let sut = FetchLearningPathUseCase(
            dataSource: spyDataSource,
            stageRepo: stageRepo
        )

        let firstCurriculum = try await sut.execute()
        XCTAssertEqual(spyDataSource.fetchTopicDecksCallCount, 1)
        XCTAssertFalse(firstCurriculum.decks.isEmpty)

        // Second call must reuse cached static curriculum without hitting dataSource
        let secondCurriculum = try await sut.execute()
        XCTAssertEqual(spyDataSource.fetchTopicDecksCallCount, 1)
        XCTAssertEqual(spyDataSource.fetchSubTopicStagesCallCount, 4)
        XCTAssertEqual(firstCurriculum.decks, secondCurriculum.decks)
        XCTAssertEqual(firstCurriculum.stages, secondCurriculum.stages)
        XCTAssertEqual(firstCurriculum.words, secondCurriculum.words)
    }

    func test_fetchLearningPathUseCase_forceRefreshReloadsCurriculumAndUpdatesCache() async throws {
        let spyDataSource = SpyVocabularyDataSource(base: dataSource)
        let sut = FetchLearningPathUseCase(
            dataSource: spyDataSource,
            stageRepo: stageRepo
        )

        _ = try await sut.execute()
        XCTAssertEqual(spyDataSource.fetchTopicDecksCallCount, 1)

        // Force refresh should bypass cache and fetch static data again
        let refreshed = try await sut.execute(forceRefresh: true)
        XCTAssertEqual(spyDataSource.fetchTopicDecksCallCount, 2)
        XCTAssertFalse(refreshed.decks.isEmpty)

        // Subsequent call without force refresh should use the updated cache
        let cachedAfterRefresh = try await sut.execute()
        XCTAssertEqual(spyDataSource.fetchTopicDecksCallCount, 2)
        XCTAssertEqual(refreshed.decks, cachedAfterRefresh.decks)
    }

    func test_fetchLearningPathUseCase_alwaysQueriesUserProgressDynamically() async throws {
        let spyDataSource = SpyVocabularyDataSource(base: dataSource)
        let spyStageRepo = SpyStageProgressRepository(base: stageRepo)
        let sut = FetchLearningPathUseCase(
            dataSource: spyDataSource,
            stageRepo: spyStageRepo
        )

        let initial = try await sut.execute()
        XCTAssertEqual(spyStageRepo.fetchAllStageProgressCallCount, 1)
        XCTAssertEqual(spyDataSource.fetchTopicDecksCallCount, 1)
        XCTAssertTrue(initial.progressList.isEmpty)

        // Mutate progress in stage repository
        try await spyStageRepo.saveStageProgress(
            stageId: "stage_daily_1",
            deckId: "deck_daily",
            isCompleted: true,
            score: 3,
            progressFraction: 1.0
        )

        // Execute again: static data is cached, but progress is queried dynamically
        let updated = try await sut.execute()
        XCTAssertEqual(spyStageRepo.fetchAllStageProgressCallCount, 2)
        XCTAssertEqual(spyDataSource.fetchTopicDecksCallCount, 1)
        XCTAssertEqual(updated.progressList.count, 1)
        XCTAssertEqual(updated.progressList.first?.stageId, "stage_daily_1")
        XCTAssertEqual(updated.progressList.first?.score, 3)
    }

    // MARK: - CompleteLessonUseCase Tests

    func test_completeLessonUseCase_persistsProgressAndReturnsSummary() async throws {
        let sut = CompleteLessonUseCase(
            stageRepo: stageRepo,
            progressRepo: progressRepo
        )

        let result = try await sut.execute(
            stageId: "stage_daily_1",
            deckId: "deck_daily",
            stars: 3,
            weakWordIds: [101],
            progressFraction: 1.0
        )

        XCTAssertEqual(result.stageId, "stage_daily_1")
        XCTAssertEqual(result.deckId, "deck_daily")
        XCTAssertEqual(result.score, 3)
        XCTAssertEqual(result.xpEarned, 25)
        XCTAssertEqual(result.weakWordIds, [101])
        XCTAssertFalse(result.isUnitCheckpoint)

        let savedProgress = try await stageRepo.fetchStageProgress(stageId: "stage_daily_1")
        XCTAssertNotNil(savedProgress)
        XCTAssertEqual(savedProgress?.isCompleted, true)
        XCTAssertEqual(savedProgress?.score, 3)
        XCTAssertEqual(savedProgress?.progressFraction, 1.0)

        let wordProgress = try await progressRepo.getProgress(wordId: 101)
        XCTAssertNotNil(wordProgress)
        XCTAssertEqual(wordProgress?.needsReview, true)
        XCTAssertEqual(wordProgress?.mistakeCount, 1)
    }

    func test_completeLessonUseCase_checkpointExam_awardsExtraXP() async throws {
        let sut = CompleteLessonUseCase(
            stageRepo: stageRepo,
            progressRepo: progressRepo
        )

        let result = try await sut.execute(
            stageId: "checkpoint_deck_daily",
            deckId: "deck_daily",
            stars: 2,
            weakWordIds: [],
            progressFraction: 1.0
        )

        XCTAssertTrue(result.isUnitCheckpoint)
        XCTAssertEqual(result.xpEarned, 80)
        XCTAssertEqual(result.score, 2)
        XCTAssertTrue(result.weakWordIds.isEmpty)

        let savedProgress = try await stageRepo.fetchStageProgress(stageId: "checkpoint_deck_daily")
        XCTAssertNotNil(savedProgress)
        XCTAssertEqual(savedProgress?.isCompleted, true)
        XCTAssertEqual(savedProgress?.score, 2)
    }

    func test_completeLessonUseCase_partialProgress_calculatesCorrectXPAndCompletion() async throws {
        let sut = CompleteLessonUseCase(
            stageRepo: stageRepo,
            progressRepo: progressRepo
        )

        let result = try await sut.execute(
            stageId: "stage_daily_1",
            deckId: "deck_daily",
            stars: 0,
            weakWordIds: [],
            progressFraction: 0.5
        )

        XCTAssertFalse(result.isUnitCheckpoint)
        XCTAssertEqual(result.xpEarned, 25)
        XCTAssertEqual(result.score, 0)

        let savedProgress = try await stageRepo.fetchStageProgress(stageId: "stage_daily_1")
        XCTAssertNotNil(savedProgress)
        XCTAssertEqual(savedProgress?.isCompleted, false)
        XCTAssertEqual(savedProgress?.progressFraction, 0.5)
    }

    func test_completeLessonUseCase_withoutProgressRepo_executesSuccessfully() async throws {
        let sut = CompleteLessonUseCase(
            stageRepo: stageRepo,
            progressRepo: nil as (any UserProgressRepositoryProtocol)?
        )

        let result = try await sut.execute(
            stageId: "stage_daily_1",
            deckId: "deck_daily",
            stars: 3,
            weakWordIds: [102],
            progressFraction: 1.0
        )

        XCTAssertEqual(result.score, 3)
        XCTAssertEqual(result.xpEarned, 25)

        let savedProgress = try await stageRepo.fetchStageProgress(stageId: "stage_daily_1")
        XCTAssertNotNil(savedProgress)
        XCTAssertEqual(savedProgress?.isCompleted, true)
    }

    func test_completeLessonUseCase_concurrentExecution_sharesInFlightTask() async throws {
        stageRepo.delayNanoseconds = 100_000_000
        let sut = CompleteLessonUseCase(
            stageRepo: stageRepo,
            progressRepo: progressRepo
        )

        async let first = sut.execute(
            stageId: "stage_concurrent",
            deckId: "deck_daily",
            stars: 3,
            weakWordIds: [101, 102],
            progressFraction: 1.0
        )
        async let second = sut.execute(
            stageId: "stage_concurrent",
            deckId: "deck_daily",
            stars: 3,
            weakWordIds: [101, 102],
            progressFraction: 1.0
        )

        let (res1, res2) = try await (first, second)
        XCTAssertEqual(res1, res2)
        XCTAssertEqual(res1.score, 3)

        // Verifies dedup: stage progress was saved exactly once, and weak words were recorded once (2 words * 1)
        let saveCount = await stageRepo.saveCallCount
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(progressRepo.recordChallengeCallCount, 2)
    }
}

// MARK: - Test Doubles

private final class SpyVocabularyDataSource: VocabularyDataSourceProtocol, @unchecked Sendable {
    private let base: VocabularyDataSourceProtocol
    private let lock = NSLock()
    private var _fetchTopicDecksCallCount = 0
    private var _fetchSubTopicStagesCallCount = 0
    private var _fetchWordsForStageCallCount = 0

    var fetchTopicDecksCallCount: Int {
        lock.withLock { _fetchTopicDecksCallCount }
    }

    var fetchSubTopicStagesCallCount: Int {
        lock.withLock { _fetchSubTopicStagesCallCount }
    }

    var fetchWordsForStageCallCount: Int {
        lock.withLock { _fetchWordsForStageCallCount }
    }

    init(base: VocabularyDataSourceProtocol) {
        self.base = base
    }

    private func incrementTopicDecks() {
        lock.withLock { _fetchTopicDecksCallCount += 1 }
    }

    private func incrementSubTopicStages() {
        lock.withLock { _fetchSubTopicStagesCallCount += 1 }
    }

    private func incrementWordsForStage() {
        lock.withLock { _fetchWordsForStageCallCount += 1 }
    }

    func fetchTopicDecks() async throws -> [TopicDeckDTO] {
        incrementTopicDecks()
        return try await base.fetchTopicDecks()
    }

    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        incrementSubTopicStages()
        return try await base.fetchSubTopicStages(deckId: deckId)
    }

    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        incrementWordsForStage()
        return try await base.fetchWordsForStage(stageId: stageId)
    }

    func searchWords(query: String) async throws -> [TopicWordDTO] {
        try await base.searchWords(query: query)
    }

    func fetchWordById(id: Int64) async throws -> TopicWordDTO? {
        try await base.fetchWordById(id: id)
    }

    func fetchWordsByIds(ids: Set<Int64>) async throws -> [TopicWordDTO] {
        try await base.fetchWordsByIds(ids: ids)
    }

    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] {
        try await base.fetchAllWordsMap()
    }
}

private final class SpyStageProgressRepository: StageProgressRepositoryProtocol, @unchecked Sendable {
    private let base: StageProgressRepositoryProtocol
    private let lock = NSLock()
    private var _fetchAllStageProgressCallCount = 0

    var fetchAllStageProgressCallCount: Int {
        lock.withLock { _fetchAllStageProgressCallCount }
    }

    init(base: StageProgressRepositoryProtocol) {
        self.base = base
    }

    private func incrementAllStageProgress() {
        lock.withLock { _fetchAllStageProgressCallCount += 1 }
    }

    @MainActor
    func fetchStageProgress(stageId: String) async throws -> UserStageProgressData? {
        try await base.fetchStageProgress(stageId: stageId)
    }

    @MainActor
    func fetchCompletedStageIds(deckId: String) async throws -> Set<String> {
        try await base.fetchCompletedStageIds(deckId: deckId)
    }

    @MainActor
    func fetchAllStageProgress() async throws -> [UserStageProgressData] {
        incrementAllStageProgress()
        return try await base.fetchAllStageProgress()
    }

    @MainActor
    func saveStageProgress(
        stageId: String,
        deckId: String,
        isCompleted: Bool,
        score: Int,
        progressFraction: Double
    ) async throws {
        try await base.saveStageProgress(
            stageId: stageId,
            deckId: deckId,
            isCompleted: isCompleted,
            score: score,
            progressFraction: progressFraction
        )
    }
}
