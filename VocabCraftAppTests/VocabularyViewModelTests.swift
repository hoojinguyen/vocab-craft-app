import XCTest
@testable import VocabCraftApp

@MainActor
final class VocabularyViewModelTests: XCTestCase {
    
    var sut: VocabularyViewModel!
    
    override func setUp() {
        super.setUp()
        sut = VocabularyViewModel()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func test_filteredWords_emptySearchAndAllFilter_returnsAllWords() {
        sut.searchText = ""
        sut.selectedFilter = "Tất cả"
        
        let result = sut.filteredWords
        
        XCTAssertEqual(result.count, sut.wordItems.count)
    }
    
    func test_filteredWords_withSearchText_returnsMatchingWords() {
        // Find a word from mockData, e.g., "resilience"
        sut.searchText = "resilience"
        sut.selectedFilter = "Tất cả"
        
        let result = sut.filteredWords
        
        XCTAssertTrue(result.count > 0)
        XCTAssertTrue(result.first?.lemma.lowercased() == "resilience" || result.first?.definition.lowercased().contains("resilience") == true)
    }
    
    func test_filteredWords_withFilter_returnsCorrectWords() {
        sut.searchText = ""
        sut.selectedFilter = "Cần ôn ⚡"
        
        let result = sut.filteredWords
        
        let expectedCount = sut.wordItems.filter { $0.masteryLevel < 3 }.count
        XCTAssertEqual(result.count, expectedCount)
    }
    
    func test_filterCount_returnsCorrectCounts() {
        let totalCount = sut.wordItems.count
        let needsReviewCount = sut.wordItems.filter { $0.masteryLevel < 3 }.count
        
        XCTAssertEqual(sut.filterCount(for: "Tất cả"), totalCount)
        XCTAssertEqual(sut.filterCount(for: "Cần ôn ⚡"), needsReviewCount)
    }
}
