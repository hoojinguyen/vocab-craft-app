import Foundation
import Testing
@testable import VocabCraftApp

@MainActor
@Suite("ClaimTreasureRewardUseCase Tests")
struct ClaimTreasureRewardUseCaseTests {
    @Test("Claim treasure fails if checkpoint has not been recorded")
    func testClaimTreasureFailsIfCheckpointNotCompleted() async throws {
        let stageRepo = MockStageProgressRepository()
        let useCase = ClaimTreasureRewardUseCase(stageRepo: stageRepo)

        await #expect(throws: TreasureClaimError.checkpointIncomplete) {
            try await useCase.execute(deckId: "deck_test")
        }
    }

    @Test("Claim treasure fails if checkpoint progress exists but isCompleted is false")
    func testClaimTreasureFailsIfCheckpointIncomplete() async throws {
        let stageRepo = MockStageProgressRepository()
        try await stageRepo.saveStageProgress(
            stageId: "checkpoint_deck_test",
            deckId: "deck_test",
            isCompleted: false,
            score: 40,
            progressFraction: 0.4
        )
        let useCase = ClaimTreasureRewardUseCase(stageRepo: stageRepo)

        await #expect(throws: TreasureClaimError.checkpointIncomplete) {
            try await useCase.execute(deckId: "deck_test")
        }
    }

    @Test("Claim treasure succeeds and awards 150 XP when checkpoint completed")
    func testClaimTreasureSucceedsWhenCheckpointCompleted() async throws {
        let stageRepo = MockStageProgressRepository()
        try await stageRepo.saveStageProgress(
            stageId: "checkpoint_deck_test",
            deckId: "deck_test",
            isCompleted: true,
            score: 100,
            progressFraction: 1.0
        )
        let useCase = ClaimTreasureRewardUseCase(stageRepo: stageRepo)

        let result = try await useCase.execute(deckId: "deck_test")

        #expect(result.stageId == "treasure_deck_test")
        #expect(result.deckId == "deck_test")
        #expect(result.xpEarned == 150)
        #expect(!result.isAlreadyClaimed)

        // Verify stage progress was persisted to repository
        let savedProgress = try await stageRepo.fetchStageProgress(stageId: "treasure_deck_test")
        #expect(savedProgress != nil)
        #expect(savedProgress?.isCompleted == true)
        #expect(savedProgress?.score == 100)
        #expect(savedProgress?.progressFraction == 1.0)
        #expect(savedProgress?.deckId == "deck_test")
    }

    @Test("Claim treasure returns zero XP and isAlreadyClaimed true when claimed second time")
    func testClaimTreasureAlreadyClaimedReturnsZeroXP() async throws {
        let stageRepo = MockStageProgressRepository()
        try await stageRepo.saveStageProgress(
            stageId: "checkpoint_deck_test",
            deckId: "deck_test",
            isCompleted: true,
            score: 100,
            progressFraction: 1.0
        )
        let useCase = ClaimTreasureRewardUseCase(stageRepo: stageRepo)

        // First claim
        let firstResult = try await useCase.execute(deckId: "deck_test")
        #expect(firstResult.xpEarned == 150)
        #expect(!firstResult.isAlreadyClaimed)
        let initialCallCount = stageRepo.saveCallCount

        // Second claim
        let secondResult = try await useCase.execute(deckId: "deck_test")
        #expect(secondResult.stageId == "treasure_deck_test")
        #expect(secondResult.deckId == "deck_test")
        #expect(secondResult.xpEarned == 0)
        #expect(secondResult.isAlreadyClaimed)
        // Verify no redundant write occurred
        #expect(stageRepo.saveCallCount == initialCallCount)
    }

    @Test("AppContainer wires ClaimTreasureRewardUseCase successfully")
    func testAppContainerWiresClaimTreasureRewardUseCase() {
        let container = AppContainer.mock
        let useCase = container.makeClaimTreasureRewardUseCase()
        #expect(useCase is ClaimTreasureRewardUseCase)
        #expect(container.claimTreasureRewardUseCase is ClaimTreasureRewardUseCase)
    }
}
