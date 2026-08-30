import Foundation
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class TopicDeckDetailViewTests: XCTestCase {
    func testDetailViewInitialization() {
        let view = TopicDeckDetailView(deckId: "1", repository: MockVocabularyRepository(), onBack: {})
        XCTAssertNotNil(view)
    }
}
