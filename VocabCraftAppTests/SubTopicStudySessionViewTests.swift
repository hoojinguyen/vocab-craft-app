import SwiftUI
@testable import VocabCraftApp
import XCTest

final class SubTopicStudySessionViewTests: XCTestCase {
    func testViewInitialization() {
        let node = SubTopicNode(id: "1", title: "Công nghệ", iconName: "cpu", totalWords: 10, learnedWords: 0, state: .active, words: [])
        let view = SubTopicStudySessionView(node: node, onDismiss: {}, onComplete: { _ in })
        XCTAssertNotNil(view)
    }

    func testViewInitializationWithTenWordDataset() {
        let words = (1...10).map { idx in
            TopicWord(id: "w\(idx)", english: "Word \(idx)", phonetic: "/w\(idx)/", vietnamese: "Từ \(idx)")
        }
        let node = SubTopicNode(id: "1", title: "Công nghệ", iconName: "cpu", totalWords: 10, learnedWords: 0, state: .active, words: words)
        let view = SubTopicStudySessionView(node: node, onDismiss: {}, onComplete: { _ in })
        XCTAssertNotNil(view)
    }

    func testProgressBarSegmentStyling() {
        let node = SubTopicNode(id: "1", title: "Công nghệ", iconName: "cpu", totalWords: 10, learnedWords: 0, state: .active, words: SubTopicStudySessionView.sampleWords)
        let view = SubTopicStudySessionView(node: node, onDismiss: {}, onComplete: { _ in })

        // Current index (0) should have peach border and 1.5pt width
        XCTAssertEqual(view.segmentLineWidth(for: 0), 1.5)
        XCTAssertEqual(view.segmentBorderColor(for: 0), Color.vocabPeach)

        // Upcoming index (1...9) should have solid dark grey border in light mode and 1.0pt width
        XCTAssertEqual(view.segmentLineWidth(for: 1), 1.0)
        XCTAssertNotNil(view.segmentBorderColor(for: 1))
        XCTAssertNotNil(view.segmentColor(for: 1))
    }
}
