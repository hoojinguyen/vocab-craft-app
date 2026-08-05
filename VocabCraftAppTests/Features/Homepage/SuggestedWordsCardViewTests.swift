import XCTest
import SwiftUI
@testable import VocabCraftApp

@MainActor
final class SuggestedWordsCardViewTests: XCTestCase {

    func testSuggestedWordSampleData() {
        let sampleWords = SuggestedWord.sampleWords
        XCTAssertGreaterThan(sampleWords.count, 0)
        let first = sampleWords.first!
        XCTAssertEqual(first.lemma, "Resilience")
        XCTAssertEqual(first.cefrLevel, "C1")
        XCTAssertFalse(first.definitionVi.isEmpty)
        XCTAssertFalse(first.definitionEn.isEmpty)
        XCTAssertFalse(first.example.isEmpty)
    }

    func testHomepageViewModelSuggestedWordsRandomization() {
        let vm = HomepageViewModel()
        XCTAssertGreaterThan(vm.suggestedWords.count, 0)
        XCTAssertTrue(vm.suggestedWords.indices.contains(vm.currentSuggestedWordIndex))

        // Explicit index initialization
        let customState = HomepageState(currentSuggestedWordIndex: 2)
        let customVM = HomepageViewModel(initialState: customState)
        XCTAssertEqual(customVM.currentSuggestedWordIndex, 2)
    }

    func testToggleBookmarkSuggestedWord() {
        let vm = HomepageViewModel()
        let targetId = vm.suggestedWords[0].id
        let initialBookmarkState = vm.suggestedWords[0].isBookmarked

        vm.toggleBookmarkSuggestedWord(id: targetId)
        XCTAssertEqual(vm.suggestedWords[0].isBookmarked, !initialBookmarkState)

        vm.toggleBookmarkSuggestedWord(id: targetId)
        XCTAssertEqual(vm.suggestedWords[0].isBookmarked, initialBookmarkState)
    }

    func testSuggestedWordsCardViewInstantiation() {
        let words = SuggestedWord.sampleWords
        var selectedIndex = 0
        let binding = Binding(get: { selectedIndex }, set: { selectedIndex = $0 })

        let view = SuggestedWordsCardView(
            words: words,
            selectedIndex: binding,
            onBookmarkToggle: { _ in }
        )
        XCTAssertNotNil(view)
    }
}
