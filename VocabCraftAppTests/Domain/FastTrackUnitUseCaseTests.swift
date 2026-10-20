import Foundation
import Testing
@testable import VocabCraftApp

@MainActor
@Suite("FastTrackUnitUseCase Tests")
struct FastTrackUnitUseCaseTests {
    @Test("Fast-track success (score >= 0.85) marks all unit stages and checkpoint as complete, and ingests all words")
    func testFastTrackSuccessMarksAllStagesAndIngestsWords() async throws {
        let mockDataSource = MockVocabularyDataSource()
        let mockStageRepo = MockStageProgressRepository()
        let mockProgressRepo = MockUserProgressRepository()
        let useCase = FastTrackUnitUseCase(
            dataSource: mockDataSource,
            stageRepo: mockStageRepo,
            progressRepo: mockProgressRepo
        )

        let result = try await useCase.execute(deckId: "deck_daily", scorePercentage: 0.90)

        #expect(result.isSuccess == true)
        #expect(mockStageRepo.savedStages.contains(where: { $0.stageId == "checkpoint_deck_daily" && $0.isCompleted }))
        #expect(mockStageRepo.savedStages.contains(where: { $0.stageId == "spiral_deck_daily" && $0.isCompleted }))
        #expect(result.completedStageIds.contains("spiral_deck_daily"))
        #expect(mockProgressRepo.recordedBatchCalls.count >= 1)
        #expect(mockProgressRepo.recordedBatchCalls.first?.cefrLevel != nil)
    }

    @Test("Fast-track failure (score < 0.85) leaves stages unchanged and records no batch progress")
    func testFastTrackFailureLeavesStagesUnchanged() async throws {
        let mockDataSource = MockVocabularyDataSource()
        let mockStageRepo = MockStageProgressRepository()
        let mockProgressRepo = MockUserProgressRepository()
        let useCase = FastTrackUnitUseCase(
            dataSource: mockDataSource,
            stageRepo: mockStageRepo,
            progressRepo: mockProgressRepo
        )

        let result = try await useCase.execute(deckId: "deck_daily", scorePercentage: 0.70)

        #expect(result.isSuccess == false)
        #expect(mockStageRepo.savedStages.isEmpty)
        #expect(mockProgressRepo.recordedBatchCalls.isEmpty)
    }

    @Test("Fast-track boundary: exact 85% passes")
    func testFastTrackBoundaryExact85PercentPasses() async throws {
        let mockDataSource = MockVocabularyDataSource()
        let mockStageRepo = MockStageProgressRepository()
        let mockProgressRepo = MockUserProgressRepository()
        let useCase = FastTrackUnitUseCase(
            dataSource: mockDataSource,
            stageRepo: mockStageRepo,
            progressRepo: mockProgressRepo
        )

        let result = try await useCase.execute(deckId: "deck_daily", scorePercentage: 0.85)

        #expect(result.isSuccess == true)
        #expect(mockStageRepo.savedStages.contains(where: { $0.stageId == "checkpoint_deck_daily" && $0.isCompleted }))
    }

    @Test("Fast-track boundary: 84.9% fails")
    func testFastTrackBoundaryJustBelow85PercentFails() async throws {
        let mockDataSource = MockVocabularyDataSource()
        let mockStageRepo = MockStageProgressRepository()
        let mockProgressRepo = MockUserProgressRepository()
        let useCase = FastTrackUnitUseCase(
            dataSource: mockDataSource,
            stageRepo: mockStageRepo,
            progressRepo: mockProgressRepo
        )

        let result = try await useCase.execute(deckId: "deck_daily", scorePercentage: 0.849)

        #expect(result.isSuccess == false)
        #expect(mockStageRepo.savedStages.isEmpty)
    }
}
