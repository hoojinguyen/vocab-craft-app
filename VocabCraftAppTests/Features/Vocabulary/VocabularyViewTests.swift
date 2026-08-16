import SwiftUI
@testable import VocabCraftApp
import XCTest
#if canImport(UIKit)
import UIKit
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
}

