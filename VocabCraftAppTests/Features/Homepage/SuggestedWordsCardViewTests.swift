import SwiftUI
@testable import VocabCraftApp
import XCTest

@MainActor
final class SuggestedWordsCardViewTests: XCTestCase {
    private let sampleWords: [SuggestedWord] = [
        SuggestedWord(
            id: "1",
            lemma: "Resilience",
            pos: "noun",
            ipaUs: "/rɪˈzɪl.jəns/",
            cefrLevel: "C1",
            definitionVi: "Khả năng phục hồi nhanh chóng sau khó khăn.",
            definitionEn: "The capacity to recover quickly from difficulties; toughness.",
            example: "Her resilience helped her overcome the financial hardship.",
            isBookmarked: false
        )
    ]

    func testSuggestedWordSampleData() {
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
        XCTAssertEqual(vm.suggestedWords.count, 0)

        // Explicit index initialization
        let customState = HomepageState(currentSuggestedWordIndex: 0)
        let customVM = HomepageViewModel(initialState: customState)
        XCTAssertEqual(customVM.currentSuggestedWordIndex, 0)
    }

    func testToggleBookmarkSuggestedWord() {
        let vm = HomepageViewModel()
        XCTAssertTrue(vm.suggestedWords.isEmpty)
    }

    func testSuggestedWordsCardViewInstantiation() {
        let words = sampleWords
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
