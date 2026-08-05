import XCTest
import SwiftUI
@testable import VocabCraftApp

final class VocabularyViewsTests: XCTestCase {
    func testVocabularySummaryCardInstantiation() {
        let view = VocabularySummaryCard(
            totalWords: 1420,
            srsRetentionPercentage: 0.85,
            dueCount: 24
        )
        XCTAssertNotNil(view.body)
        XCTAssertEqual(view.totalWords, 1420)
        XCTAssertEqual(view.srsRetentionPercentage, 0.85)
        XCTAssertEqual(view.dueCount, 24)
    }
}
