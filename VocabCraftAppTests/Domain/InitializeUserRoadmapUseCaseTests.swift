import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class InitializeUserRoadmapUseCaseTests: XCTestCase {
    private var testSuiteName: String!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testSuiteName = "test_roadmap_\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)!
    }

    override func tearDown() {
        super.tearDown()
        testDefaults.removePersistentDomain(forName: testSuiteName)
        testDefaults = nil
        testSuiteName = nil
    }

    @MainActor
    func testInitializeRoadmapForBeginnerA1() async throws {
        let dataSource = SampleVocabularyDataSource()
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore(defaults: testDefaults)

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: dataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        let result = try await useCase.execute(
            deckId: "deck_daily",
            cefrLevel: "A1",
            dailyGoalCount: 10,
            notificationTimeInterval: 72000
        )

        XCTAssertEqual(settings.selectedGoalDeckId, "deck_daily")
        XCTAssertEqual(settings.assessedCefrLevel, "A1")
        XCTAssertEqual(settings.dailyGoalCount, 10)
        XCTAssertEqual(settings.notificationTimeInterval, 72000)

        // Stage 1 of deck_daily should be the starting stage
        XCTAssertEqual(result.startingStage.id, "stage_daily_1")
        XCTAssertEqual(result.starterWords.count, 3)

        // No stages should be marked completed for A1
        let allProgress = try await stageRepo.fetchAllStageProgress()
        XCTAssertTrue(allProgress.isEmpty || allProgress.allSatisfy { !$0.isCompleted })
    }

    @MainActor
    func testInitializeRoadmapForIntermediateB1AutoUnlocksFoundationalStage() async throws {
        let dataSource = SampleVocabularyDataSource()
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore(defaults: testDefaults)

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: dataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        let result = try await useCase.execute(
            deckId: "deck_daily",
            cefrLevel: "B1",
            dailyGoalCount: 15,
            notificationTimeInterval: 28800
        )

        // Preceding stage (stage_daily_1) should be marked completed
        let progressList = try await stageRepo.fetchAllStageProgress()
        let completedStage = progressList.first { $0.stageId == "stage_daily_1" }
        XCTAssertNotNil(completedStage)
        XCTAssertTrue(completedStage?.isCompleted == true)
        XCTAssertEqual(completedStage?.progressFraction, 1.0)

        // Starting stage is stage_daily_2
        XCTAssertEqual(result.startingStage.id, "stage_daily_2")
        XCTAssertEqual(result.starterWords.count, 3)
    }

    @MainActor
    func testInitializeRoadmapFallbackWhenDataSourceFails() async throws {
        let failingDataSource = TestFailingVocabularyDataSource(shouldCancel: false)
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore(defaults: testDefaults)

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: failingDataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        let result = try await useCase.execute(
            deckId: "deck_test",
            cefrLevel: "A1",
            dailyGoalCount: 10,
            notificationTimeInterval: 72000
        )

        XCTAssertEqual(result.starterWords.count, 3)
        XCTAssertEqual(result.starterWords.first?.lemma, "Resilience")
        XCTAssertEqual(result.starterWords.first?.stageId, "stage_daily_1")
    }

    @MainActor
    func testInitializeRoadmapCancellationDoesNotMutateProgress() async throws {
        let cancellingDataSource = TestFailingVocabularyDataSource(shouldCancel: true)
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore(defaults: testDefaults)

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: cancellingDataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        do {
            _ = try await useCase.execute(
                deckId: "deck_test",
                cefrLevel: "B1",
                dailyGoalCount: 15,
                notificationTimeInterval: 28800
            )
            XCTFail("Expected CancellationError to be thrown")
        } catch is CancellationError {
            // Expected
        }

        let progressList = try await stageRepo.fetchAllStageProgress()
        XCTAssertTrue(progressList.isEmpty, "Progress should not be saved if synthesis was cancelled")
        XCTAssertNotEqual(settings.selectedGoalDeckId, "deck_test", "Settings should not be written if cancelled")
    }

    @MainActor
    func testInitializeRoadmapShortStagePadsToThreeWords() async throws {
        let oneWordDataSource = TestOneWordVocabularyDataSource()
        let stageRepo = MockStageProgressRepository()
        let settings = UserSettingsStore(defaults: testDefaults)

        let useCase = InitializeUserRoadmapUseCase(
            dataSource: oneWordDataSource,
            stageRepo: stageRepo,
            userSettings: settings
        )

        let result = try await useCase.execute(
            deckId: "deck_test",
            cefrLevel: "A1",
            dailyGoalCount: 10,
            notificationTimeInterval: 72000
        )

        XCTAssertEqual(result.starterWords.count, 3)
        XCTAssertEqual(result.starterWords[0].lemma, "UniqueSingleWord")
    }
}

private final class TestOneWordVocabularyDataSource: VocabularyDataSourceProtocol, @unchecked Sendable {
    func fetchTopicDecks() async throws -> [TopicDeckDTO] { [] }
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        [SubTopicStageDTO(id: "stage_one_1", deckId: deckId, title: "Stage 1", iconName: "star", sortOrder: 1)]
    }
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        [
            TopicWordDTO(
                id: 99,
                stageId: stageId,
                lemma: "UniqueSingleWord",
                phonetic: "/juːˈniːk/",
                pos: "noun",
                cefrLevel: "A1",
                definitionVi: "Từ đơn",
                definitionEn: "Single word",
                exampleEn: "A single word.",
                exampleVi: "Một từ duy nhất."
            )
        ]
    }
    func searchWords(query: String) async throws -> [TopicWordDTO] { [] }
    func fetchWordById(id: Int64) async throws -> TopicWordDTO? { nil }
    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] { [:] }
}

private final class TestFailingVocabularyDataSource: VocabularyDataSourceProtocol, @unchecked Sendable {
    let shouldCancel: Bool

    init(shouldCancel: Bool) {
        self.shouldCancel = shouldCancel
    }

    func fetchTopicDecks() async throws -> [TopicDeckDTO] { [] }
    func fetchSubTopicStages(deckId: String) async throws -> [SubTopicStageDTO] {
        [
            SubTopicStageDTO(id: "stage_fallback_1", deckId: deckId, title: "Stage 1", iconName: "star", sortOrder: 1),
            SubTopicStageDTO(id: "stage_fallback_2", deckId: deckId, title: "Stage 2", iconName: "star", sortOrder: 2)
        ]
    }
    func fetchWordsForStage(stageId: String) async throws -> [TopicWordDTO] {
        if shouldCancel {
            throw CancellationError()
        }
        throw NSError(domain: "TestError", code: 500)
    }
    func searchWords(query: String) async throws -> [TopicWordDTO] { [] }
    func fetchWordById(id: Int64) async throws -> TopicWordDTO? { nil }
    func fetchAllWordsMap() async throws -> [Int64: TopicWordDTO] { [:] }
}
