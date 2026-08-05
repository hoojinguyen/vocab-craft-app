import XCTest
import SwiftUI
@testable import VocabCraftApp

final class SubTopicStudySessionViewTests: XCTestCase {
    func testViewInitialization() {
        let node = SubTopicNode(id: "1", title: "Công nghệ", iconName: "cpu", totalWords: 10, learnedWords: 0, state: .active, words: [])
        let view = SubTopicStudySessionView(node: node, onDismiss: {}, onComplete: { _ in })
        XCTAssertNotNil(view)
    }
}
