import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class VocabularyHubIntegrationTests: XCTestCase {
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

        let vaultVM = container.makePersonalVaultViewModel()
        XCTAssertNotNil(vaultVM)

        let smartReviewVM = container.makeSmartReviewViewModel()
        XCTAssertNotNil(smartReviewVM)

        let homeVM = container.makeHomepageViewModel()
        XCTAssertNotNil(homeVM)

        let blitzVM = container.makeReflexBlitzViewModel()
        XCTAssertNotNil(blitzVM)
    }
}
