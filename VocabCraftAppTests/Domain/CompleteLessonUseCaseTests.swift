import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("CompleteLessonUseCase Tests")
@MainActor
struct CompleteLessonUseCaseTests {
    @Test func testCompleteLessonPersistsBothCorrectAndWeakWords() async throws {
        let mockStageRepo = MockStageProgressRepository()
        let mockProgressRepo = MockUserProgressRepository()
        let useCase = CompleteLessonUseCase(stageRepo: mockStageRepo, progressRepo: mockProgressRepo)

        let practicedIds: [Int64] = [101, 102, 103]
        let weakIds: [Int64] = [102]

        let result = try await useCase.execute(
            stageId: "stage_test_1",
            deckId: "deck_test_1",
            stars: 2,
            practicedWordIds: practicedIds,
            weakWordIds: weakIds,
            progressFraction: 1.0
        )

        #expect(result.score == 2)
        #expect(mockProgressRepo.recordedBatchCalls.count == 1)
        let call = try #require(mockProgressRepo.recordedBatchCalls.first)
        #expect(call.practicedWordIds == practicedIds)
        #expect(call.weakWordIds == Set(weakIds))

        // Verify correct word 101 state in repository
        let word101 = try await mockProgressRepo.getProgress(wordId: 101)
        let unwrapped101 = try #require(word101)
        #expect(unwrapped101.masteryLevel >= 1)
        #expect(unwrapped101.needsReview == false)
        #expect(unwrapped101.mistakeCount == 0)

        // Verify weak word 102 state in repository
        let word102 = try await mockProgressRepo.getProgress(wordId: 102)
        let unwrapped102 = try #require(word102)
        #expect(unwrapped102.needsReview == true)
        #expect(unwrapped102.mistakeCount == 1)
        #expect(unwrapped102.consecutiveCorrectStreak == 0)
        #expect(unwrapped102.intervalDays == 1)
    }

    @Test func testCompleteLessonWithoutPracticedWordIds_legacyCompatibility() async throws {
        let mockStageRepo = MockStageProgressRepository()
        let mockProgressRepo = MockUserProgressRepository()
        let useCase = CompleteLessonUseCase(stageRepo: mockStageRepo, progressRepo: mockProgressRepo)

        let weakIds: [Int64] = [105]

        let result = try await useCase.execute(
            stageId: "stage_legacy_1",
            deckId: "deck_legacy_1",
            stars: 3,
            weakWordIds: weakIds,
            progressFraction: 1.0
        )

        #expect(result.score == 3)
        #expect(mockProgressRepo.recordedBatchCalls.count == 1)
        let call = try #require(mockProgressRepo.recordedBatchCalls.first)
        #expect(call.practicedWordIds == [105])
        #expect(call.weakWordIds == Set([105]))
    }

    @Test func testCompleteLessonWithoutProgressRepo_succeeds() async throws {
        let mockStageRepo = MockStageProgressRepository()
        let useCase = CompleteLessonUseCase(stageRepo: mockStageRepo, progressRepo: nil)

        let result = try await useCase.execute(
            stageId: "stage_no_repo",
            deckId: "deck_no_repo",
            stars: 3,
            practicedWordIds: [201, 202],
            weakWordIds: [],
            progressFraction: 1.0
        )

        #expect(result.score == 3)
        let stageProgress = try await mockStageRepo.fetchStageProgress(stageId: "stage_no_repo")
        let unwrappedStage = try #require(stageProgress)
        #expect(unwrappedStage.isCompleted == true)
    }
}
#endif
