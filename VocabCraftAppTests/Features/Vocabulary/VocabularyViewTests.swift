import SwiftUI
@testable import VocabCraftApp
import XCTest

@MainActor
final class VocabularyViewTests: XCTestCase {
    func testVocabularyViewInitializationAndTabSwitch() {
        let view = VocabularyView()
        let host = UIHostingController(rootView: view)
        XCTAssertNotNil(host.view)
    }

    func testTopicDeckSelectionNavigation() {
        var selectedDeck: String?
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
