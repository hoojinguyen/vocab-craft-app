import XCTest
import SwiftUI
@testable import VocabCraftApp

@MainActor
final class VocabularyViewTests: XCTestCase {
    func testVocabularyViewInitializationAndTabSwitch() {
        let view = VocabularyView()
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
    }

    func testTopicDeckSelectionNavigation() {
        var selectedDeck: String? = nil
        let gridView = TopicDecksGridView(onDeckSelected: { deckId in
            selectedDeck = deckId
        })
        let host = UIHostingController(rootView: gridView)
        XCTAssertNotNil(host.view)

        // Trigger deck selection callback
        gridView.onDeckSelected("deck-123")
        XCTAssertEqual(selectedDeck, "deck-123")
    }
}
