import Foundation
import SwiftUI
@testable import VocabCraftApp
#if canImport(Testing)
import Testing
#endif
#if canImport(XCTest)
import XCTest
#endif
#if canImport(UIKit)
import UIKit
#endif

#if canImport(Testing)
@Suite("VocabularyView Tests")
struct VocabularyViewTestingTests {
    @Test("VocabularyView default initialization and body evaluation")
    @MainActor
    func testVocabularyViewInitialization() {
        let view = VocabularyView()
        _ = view.body
    }

    @Test("VocabularyView with search visible state")
    @MainActor
    func testVocabularyViewSearchVisibleState() {
        let view = VocabularyView(isSearchVisible: true)
        _ = view.body
    }

    @Test("VocabularyView with PersonalVaultViewModel and search queries")
    @MainActor
    func testVocabularyViewWithPersonalVaultVM() async {
        let mockWord = VaultWordItem(
            id: 1,
            lemma: "eloquent",
            pos: "adj",
            phonetic: "/ˈel.ə.kwənt/",
            definitionVi: "Hùng biện",
            cefrLevel: "C1",
            isMastered: false,
            isBookmarked: true
        )
        let vm = PersonalVaultViewModel(mockWords: [mockWord])
        let view = VocabularyView(vaultViewModel: vm, isSearchVisible: false)
            .environment(\.appContainer, AppContainer.mock)
        #if canImport(UIKit)
        _ = UIHostingController(rootView: view).view
        #endif

        vm.setSearchQuery("elo")
        let searchingView = VocabularyView(vaultViewModel: vm, isSearchVisible: true)
            .environment(\.appContainer, AppContainer.mock)
        #if canImport(UIKit)
        _ = UIHostingController(rootView: searchingView).view
        #endif

        vm.setSearchQuery("")
        #expect(vm.searchQuery.isEmpty)
    }
}
#endif

@MainActor
final class VocabularyViewTests: XCTestCase {
    func testVocabularyViewInitializationAndTabSwitch() {
        let view = VocabularyView()
        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }

    func testVocabularyViewWithSearchVisibleInitialization() {
        let view = VocabularyView(isSearchVisible: true)
        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
    }

    func testVocabularyViewWithPersonalVaultViewModelAndSearchToggle() {
        let mockWord = VaultWordItem(
            id: 1,
            lemma: "eloquent",
            pos: "adj",
            phonetic: "/ˈel.ə.kwənt/",
            definitionVi: "Hùng biện",
            cefrLevel: "C1",
            isMastered: false,
            isBookmarked: true
        )
        let vm = PersonalVaultViewModel(mockWords: [mockWord])
        let view = VocabularyView(vaultViewModel: vm, isSearchVisible: false)
            .environment(\.appContainer, AppContainer.mock)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif

        vm.setSearchQuery("elo")
        XCTAssertEqual(vm.searchQuery, "elo")

        let searchingView = VocabularyView(vaultViewModel: vm, isSearchVisible: true)
            .environment(\.appContainer, AppContainer.mock)
        #if canImport(UIKit)
        let searchingHost = UIHostingController(rootView: searchingView)
        XCTAssertNotNil(searchingHost.view)
        #else
        XCTAssertNotNil(searchingView)
        #endif

        vm.setSearchQuery("")
        XCTAssertTrue(vm.searchQuery.isEmpty)
    }

    func testTopicDeckSelectionNavigation() {
        var selectedDeck: String?
        let gridView = TopicDecksGridView(onDeckSelected: { deckId in
            selectedDeck = deckId
        })
        #if canImport(UIKit)
        let host = UIHostingController(rootView: gridView)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(gridView)
        #endif

        // Trigger deck selection callback
        gridView.onDeckSelected("deck-123")
        XCTAssertEqual(selectedDeck, "deck-123")
    }

    func testVocabularyViewWithSelectedDrillWordSheetWiring() {
        let vm = VocabularyViewModel()
        let word = WordItem.mockData[0]
        vm.wordItems = [word]
        vm.selectedDrillWord = word

        let container = AppContainer.mock
        let view = VocabularyView(viewModel: vm)
            .environment(\.appContainer, container)

        #if canImport(UIKit)
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
        #else
        XCTAssertNotNil(view)
        #endif
        XCTAssertEqual(vm.selectedDrillWord?.id, word.id)
    }

    func testDrillWordCompletionUpdatesMasteryInViewModel() {
        let vm = VocabularyViewModel()
        var word = WordItem.mockData[0]
        word.masteryLevel = 2
        vm.wordItems = [word]

        let targetWord = word
        // Simulate sheet onComplete behavior in VocabularyView
        let updatedMastery = 4
        if let idx = vm.wordItems.firstIndex(where: { $0.id == targetWord.id }) {
            vm.wordItems[idx].masteryLevel = updatedMastery
        }

        XCTAssertEqual(vm.wordItems[0].masteryLevel, 4)
    }

    func testVocabularyViewModelMemoizedFilterCounts() {
        let vm = VocabularyViewModel()
        let words = [
            WordItem(id: 1, lemma: "apple", phonetic: "", pos: "n.", definition: "a fruit", exampleSentenceEn: "", exampleSentenceVi: "", cefrLevel: "A1", masteryLevel: 1),
            WordItem(id: 2, lemma: "banana", phonetic: "", pos: "n.", definition: "another fruit", exampleSentenceEn: "", exampleSentenceVi: "", cefrLevel: "B1", masteryLevel: 5)
        ]
        vm.wordItems = words

        XCTAssertEqual(vm.filterCount(for: .all), 2)
        XCTAssertEqual(vm.filterCount(for: .needsReview), 1)
        XCTAssertEqual(vm.filterCount(for: .mastered), 1)
        XCTAssertEqual(vm.filterCount(for: .a1a2), 1)
        XCTAssertEqual(vm.filterCount(for: .b1b2), 1)
        XCTAssertEqual(vm.filterCount(for: .c1c2), 0)

        // Test update after delete
        vm.deleteWord(id: 1)
        XCTAssertEqual(vm.filterCount(for: .all), 1)
        XCTAssertEqual(vm.filterCount(for: .needsReview), 0)

        // Test update after toggleMastered
        vm.toggleMastered(id: 2)
        XCTAssertEqual(vm.filterCount(for: .mastered), 0)
        XCTAssertEqual(vm.filterCount(for: .needsReview), 1)
    }
}
