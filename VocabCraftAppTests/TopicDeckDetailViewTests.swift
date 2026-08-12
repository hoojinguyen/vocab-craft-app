import SwiftUI
@testable import VocabCraftApp
import XCTest

final class TopicDeckDetailViewTests: XCTestCase {
    func testDetailViewInitialization() {
        let view = TopicDeckDetailView(deckId: "1", onBack: {})
        XCTAssertNotNil(view)
    }
}
