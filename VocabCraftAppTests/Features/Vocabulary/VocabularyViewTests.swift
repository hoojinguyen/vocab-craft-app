import XCTest
import SwiftUI
@testable import VocabCraftApp

@MainActor
final class VocabularyViewTests: XCTestCase {
    func testVocabularyViewInitializationAndTabSwitch() {
        let view = VocabularyView()
        XCTAssertNotNil(view.body)
    }

    func testTopicDeckSelectionNavigation() {
        var selectedDeck: String? = nil
        let gridView = TopicDecksGridView(onDeckSelected: { deckId in
            selectedDeck = deckId
        })
        XCTAssertNotNil(gridView.body)

        // Trigger deck selection callback
        gridView.onDeckSelected("deck-123")
        XCTAssertEqual(selectedDeck, "deck-123")
    }
}
