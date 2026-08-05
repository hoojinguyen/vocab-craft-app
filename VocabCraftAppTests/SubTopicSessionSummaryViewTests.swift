import XCTest
import SwiftUI
@testable import VocabCraftApp

final class SubTopicSessionSummaryViewTests: XCTestCase {
    func testSummaryViewInitialization() {
        let view = SubTopicSessionSummaryView(
            xpEarned: 85,
            totalQuestions: 10,
            correctCount: 9,
            onRestart: {},
            onFinish: {}
        )
        XCTAssertNotNil(view)
    }
}
