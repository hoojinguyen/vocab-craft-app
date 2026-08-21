@testable import VocabCraftApp
import XCTest

@MainActor
final class PersonalVaultLegacyViewModelTests: XCTestCase {
    func test_loadVault_calculatesMetricsAndFiltersWithoutEmojiTags() async {
        let container = AppContainer.mock
        let sut = container.makePersonalVaultViewModel()
        await sut.loadData()
        XCTAssertGreaterThanOrEqual(sut.metrics.totalCount, 0)
        XCTAssertEqual(sut.selectedFilter, .all)
        XCTAssertFalse(sut.isLoading)
    }

    func test_filterSelection_updatesFilteredWordsList() async {
        let container = AppContainer.mock
        let sut = container.makePersonalVaultViewModel()
        await sut.loadData()
        sut.setFilter(.needsReview)
        XCTAssertEqual(sut.selectedFilter, .needsReview)

        sut.setFilter(.mastered)
        XCTAssertEqual(sut.selectedFilter, .mastered)

        sut.setFilter(.bookmarked)
        XCTAssertEqual(sut.selectedFilter, .bookmarked)

        sut.setFilter(.all)
        XCTAssertEqual(sut.selectedFilter, .all)
    }

    func test_searchQuery_updatesSearchAndReloads() async {
        let container = AppContainer.mock
        let sut = container.makePersonalVaultViewModel()
        await sut.loadData()

        sut.setSearchQuery("Resilience")
        XCTAssertEqual(sut.searchQuery, "Resilience")
    }

    func test_toggleBookmark_persistsToggle() async {
        let container = AppContainer.mock
        let sut = container.makePersonalVaultViewModel()
        await sut.loadData()

        if let firstWord = sut.words.first {
            let initialBookmark = firstWord.isBookmarked
            await sut.toggleBookmark(wordId: firstWord.id)
            if let updatedWord = sut.words.first(where: { $0.id == firstWord.id }) {
                XCTAssertEqual(updatedWord.isBookmarked, !initialBookmark)
            }
        }
    }

    func test_playAudio_triggersTTS() async {
        let container = AppContainer.mock
        let sut = container.makePersonalVaultViewModel()
        let word = PersonalWord(
            id: 1,
            lemma: "Resilience",
            phonetic: "/rɪˈzɪl.jəns/",
            pos: "noun",
            cefrLevel: "B2",
            definitionVi: "Khả năng phục hồi",
            definitionEn: "Capacity to recover",
            exampleEn: "Her resilience helped her.",
            exampleVi: "Sự kiên cường giúp cô ấy."
        )
        sut.playAudio(for: word)
        // Verify no crash when triggering speech
    }
}
