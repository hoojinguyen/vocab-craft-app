import CraftUIKit
import Foundation
@testable import VocabCraftApp
import XCTest

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

        let sections = try await sut.execute()

        XCTAssertFalse(sections.isEmpty)
        XCTAssertEqual(sections.count, 4)

        // First section should have active first node for fresh user
        let firstSection = sections[0]
        XCTAssertEqual(firstSection.id, "deck_daily")
        XCTAssertFalse(firstSection.nodes.isEmpty)

        let firstNode = firstSection.nodes[0]
        XCTAssertEqual(firstNode.id, "stage_daily_1")
        XCTAssertEqual(firstNode.state, LessonNodeState.active)

        // Other nodes locked
        XCTAssertEqual(firstSection.nodes[1].state, LessonNodeState.locked)
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

        let sections = try await sut.execute()
        let firstSection = sections[0]

        XCTAssertEqual(firstSection.nodes[0].state, LessonNodeState.completed)
        XCTAssertEqual(firstSection.nodes[0].stars, 3)
        XCTAssertEqual(firstSection.nodes[1].state, LessonNodeState.active)
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
}
