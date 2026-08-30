import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class VocabularyHubIntegrationTests: XCTestCase {
    func test_endToEnd_stageCompletion_ingestsWordsIntoPersonalVault() async throws {
        let container = AppContainer(useMockData: true, useSampleData: true)
        let roadmapVM = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await roadmapVM.loadRoadmap()

        guard let stage = roadmapVM.stages.first else {
            XCTFail("Missing stage in topic roadmap")
            return
        }

        let challengeVM = container.makeStageChallengeViewModel(stage: stage)
        XCTAssertFalse(challengeVM.questions.isEmpty)

        // Complete all questions correctly
        while let question = challengeVM.currentQuestion, !challengeVM.isCompleted {
            challengeVM.submitAnswer(question.correctAnswer)
            if !challengeVM.isLastQuestion {
                challengeVM.nextQuestion()
            } else {
                break
            }
        }

        await challengeVM.completeStage()
        XCTAssertTrue(challengeVM.isCompleted)
        XCTAssertEqual(challengeVM.summary?.correctCount, challengeVM.summary?.totalQuestions)
        XCTAssertGreaterThan(challengeVM.summary?.xpEarned ?? 0, 0)

        // Verify words ingested into personal vault
        let vaultVM = container.makePersonalVaultViewModel()
        await vaultVM.loadData()
        XCTAssertGreaterThan(vaultVM.metrics.totalCount, 0)
        XCTAssertEqual(vaultVM.metrics.totalCount, stage.words.count)

        // Verify stage progress is marked completed
        let updatedRoadmapVM = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await updatedRoadmapVM.loadRoadmap()
        let updatedStage1 = updatedRoadmapVM.stages.first(where: { $0.id == stage.id })
        XCTAssertEqual(updatedStage1?.state, .completed)
    }

    func test_endToEnd_topicDecks_progressiveStageUnlocking() async throws {
        let container = AppContainer(useMockData: true, useSampleData: true)
        let roadmapVM = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await roadmapVM.loadRoadmap()

        XCTAssertGreaterThanOrEqual(roadmapVM.stages.count, 2)
        let stage1 = roadmapVM.stages[0]
        let stage2 = roadmapVM.stages[1]

        XCTAssertEqual(stage1.state, .active)
        XCTAssertEqual(stage2.state, .locked)

        // Complete stage 1
        let challengeVM = container.makeStageChallengeViewModel(stage: stage1)
        while let question = challengeVM.currentQuestion, !challengeVM.isCompleted {
            challengeVM.submitAnswer(question.correctAnswer)
            if !challengeVM.isLastQuestion {
                challengeVM.nextQuestion()
            } else {
                break
            }
        }
        await challengeVM.completeStage()

        // Reload roadmap and verify stage 2 unlocked / active
        let reloadedRoadmapVM = container.makeTopicRoadmapViewModel(deckId: "deck_daily")
        await reloadedRoadmapVM.loadRoadmap()

        let reloadedStage1 = reloadedRoadmapVM.stages[0]
        let reloadedStage2 = reloadedRoadmapVM.stages[1]

        XCTAssertEqual(reloadedStage1.state, .completed)
        XCTAssertEqual(reloadedStage2.state, .active)

        // Verify topic decks summary progress
        let topicDecksVM = container.makeTopicDecksViewModel()
        await topicDecksVM.loadDecks()
        let dailyDeck = topicDecksVM.decks.first(where: { $0.id == "deck_daily" })
        XCTAssertNotNil(dailyDeck)
        XCTAssertGreaterThan(dailyDeck?.completionPercentage ?? 0, 0)
    }

    func test_endToEnd_smartReview_reinforcesWeakWordsAndUpdatesMastery() async throws {
        let container = AppContainer(useMockData: true, useSampleData: true)

        // Seed a weak word in progress repository
        try await container.userProgressRepository.saveProgress(
            wordId: 1,
            cefrLevel: "B2",
            masteryLevel: 0,
            isBookmarked: true,
            needsReview: true,
            mistakeCount: 2,
            sourceDeckId: "deck_daily",
            sourceNodeId: "stage_daily_1"
        )

        let vaultVM = container.makePersonalVaultViewModel()
        await vaultVM.loadData()
        XCTAssertEqual(vaultVM.metrics.needsReviewCount, 1)

        let weakWords = vaultVM.words.filter(\.needsReview)
        XCTAssertEqual(weakWords.count, 1)

        // Run smart review session
        let reviewVM = container.makeSmartReviewViewModel(weakWords: weakWords)
        await reviewVM.loadWeakWords()

        reviewVM.revealDefinition()
        XCTAssertTrue(reviewVM.isRevealed)

        // Mark word as remembered
        await reviewVM.markCurrentReviewed(isCorrect: true)
        XCTAssertTrue(reviewVM.isCompleted)

        // Verify updated progress in vault
        let updatedVaultVM = container.makePersonalVaultViewModel()
        await updatedVaultVM.loadData()
        XCTAssertEqual(updatedVaultVM.metrics.needsReviewCount, 0)
        let reviewedWord = updatedVaultVM.words.first(where: { $0.id == 1 })
        XCTAssertEqual(reviewedWord?.needsReview, false)
        XCTAssertEqual(reviewedWord?.masteryLevel, 1)
    }

    func test_endToEnd_personalVault_searchFilterAndBookmarkInteractions() async throws {
        let container = AppContainer(useMockData: true, useSampleData: true)

        // Seed 3 words with varied state
        try await container.userProgressRepository.saveProgress(
            wordId: 1,
            cefrLevel: "B2",
            masteryLevel: 1,
            isBookmarked: false,
            needsReview: true,
            mistakeCount: 1,
            sourceDeckId: "deck_daily",
            sourceNodeId: "stage_daily_1"
        )
        try await container.userProgressRepository.saveProgress(
            wordId: 7,
            cefrLevel: "A2",
            masteryLevel: 5,
            isBookmarked: true,
            needsReview: false,
            mistakeCount: 0,
            sourceDeckId: "deck_daily",
            sourceNodeId: "stage_daily_1"
        )
        try await container.userProgressRepository.saveProgress(
            wordId: 31,
            cefrLevel: "C1",
            masteryLevel: 3,
            isBookmarked: false,
            needsReview: false,
            mistakeCount: 0,
            sourceDeckId: "deck_tech",
            sourceNodeId: "stage_tech_1"
        )

        let vaultVM = container.makePersonalVaultViewModel()
        await vaultVM.loadData()
        XCTAssertEqual(vaultVM.words.count, 3)
        XCTAssertEqual(vaultVM.metrics.totalCount, 3)
        XCTAssertEqual(vaultVM.metrics.needsReviewCount, 1)
        XCTAssertEqual(vaultVM.metrics.masteredCount, 1)
        XCTAssertEqual(vaultVM.metrics.bookmarkedCount, 1)

        // Filter: needs review
        vaultVM.setFilter(.needsReview)
        await vaultVM.loadData()
        XCTAssertEqual(vaultVM.words.count, 1)
        XCTAssertEqual(vaultVM.words.first?.id, 1)

        // Filter: mastered
        vaultVM.setFilter(.mastered)
        await vaultVM.loadData()
        XCTAssertEqual(vaultVM.words.count, 1)
        XCTAssertEqual(vaultVM.words.first?.id, 7)

        // Filter: bookmarked
        vaultVM.setFilter(.bookmarked)
        await vaultVM.loadData()
        XCTAssertEqual(vaultVM.words.count, 1)
        XCTAssertEqual(vaultVM.words.first?.id, 7)

        // Search query
        vaultVM.setFilter(.all)
        vaultVM.setSearchQuery("Resilience")
        await vaultVM.loadData()
        XCTAssertEqual(vaultVM.words.count, 1)
        XCTAssertEqual(vaultVM.words.first?.lemma, "Resilience")

        // Search query Vietnamese definition match
        vaultVM.setSearchQuery("tin cậy")
        await vaultVM.loadData()
        XCTAssertEqual(vaultVM.words.count, 1)
        XCTAssertEqual(vaultVM.words.first?.lemma, "Reliable")

        // Bookmark toggle
        vaultVM.setSearchQuery("")
        await vaultVM.loadData()
        let initialWord = vaultVM.words.first(where: { $0.id == 1 })
        let initialBookmarkState = initialWord?.isBookmarked == true
        await vaultVM.toggleBookmark(wordId: 1)
        let updatedWord = vaultVM.words.first(where: { $0.id == 1 })
        let updatedBookmarkState = updatedWord?.isBookmarked == true
        XCTAssertEqual(updatedBookmarkState, !initialBookmarkState)
    }

    func test_endToEnd_appContainer_factoryResolution() {
        let container = AppContainer(useMockData: true, useSampleData: true)

        let topicDecksVM = container.makeTopicDecksViewModel()
        XCTAssertNotNil(topicDecksVM)

        let roadmapVM = container.makeTopicRoadmapViewModel(deckId: "deck_business")
        XCTAssertNotNil(roadmapVM)

        let stage = SubTopicStage(
            id: "stage_biz_1",
            deckId: "deck_business",
            title: "Test Stage",
            iconName: "star",
            sortOrder: 1,
            state: .active,
            words: []
        )
        let challengeVM = container.makeStageChallengeViewModel(stage: stage)
        XCTAssertNotNil(challengeVM)

        let vaultVM = container.makePersonalVaultViewModel()
        XCTAssertNotNil(vaultVM)

        let smartReviewVM = container.makeSmartReviewViewModel()
        XCTAssertNotNil(smartReviewVM)
    }
}
