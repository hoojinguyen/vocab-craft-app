import Foundation
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

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
