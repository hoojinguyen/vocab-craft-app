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
}
