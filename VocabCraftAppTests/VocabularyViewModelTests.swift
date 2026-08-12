@testable import VocabCraftApp
import XCTest

@MainActor
final class VocabularyViewModelTests: XCTestCase {
    var sut: VocabularyViewModel!

    override func setUp() async throws {
        try await super.setUp()
        sut = VocabularyViewModel()
        await sut.loadWords()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_filteredWords_emptySearchAndAllFilter_returnsAllWords() {
        sut.searchText = ""
        sut.selectedFilter = .all

        let result = sut.filteredWords

        XCTAssertEqual(result.count, sut.wordItems.count)
    }

    func test_filteredWords_withSearchText_returnsMatchingWords() {
        sut.searchText = "resilience"
        sut.selectedFilter = .all

        let result = sut.filteredWords

        XCTAssertTrue(!result.isEmpty)
        XCTAssertTrue(result.first?.lemma.lowercased() == "resilience" || result.first?.definition.lowercased().contains("resilience") == true)
    }

    func test_filteredWords_withFilter_returnsCorrectWords() {
        sut.searchText = ""
        sut.selectedFilter = .needsReview

        let result = sut.filteredWords

        let expectedCount = sut.wordItems.filter { $0.masteryLevel < 3 }.count
        XCTAssertEqual(result.count, expectedCount)
    }

    func test_filterCount_returnsCorrectCounts() {
        let totalCount = sut.wordItems.count
        let needsReviewCount = sut.wordItems.filter { $0.masteryLevel < 3 }.count

        XCTAssertEqual(sut.filterCount(for: .all), totalCount)
        XCTAssertEqual(sut.filterCount(for: .needsReview), needsReviewCount)
    }
}
