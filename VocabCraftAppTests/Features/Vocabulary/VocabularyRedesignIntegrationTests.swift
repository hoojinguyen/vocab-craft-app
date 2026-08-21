import Foundation
@testable import VocabCraftApp
import XCTest

@MainActor
final class VocabularyRedesignIntegrationTests: XCTestCase {
    func test_endToEnd_stageCompletion_ingestsWordsIntoPersonalVault() async throws {
        let container = AppContainer.mock
        let roadmapVM = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await roadmapVM.loadRoadmap()

        guard let stage = roadmapVM.stages.first else {
            XCTFail("Missing stage")
            return
        }

        let challengeVM = container.makeStageChallengeViewModel(stage: stage)
        challengeVM.submitAnswer(challengeVM.currentQuestion?.correctAnswer ?? "")
        await challengeVM.completeStage()

        let vaultVM = container.makePersonalVaultViewModel()
        await vaultVM.loadData()
        XCTAssertGreaterThan(vaultVM.metrics.totalCount, 0)
    }
}
