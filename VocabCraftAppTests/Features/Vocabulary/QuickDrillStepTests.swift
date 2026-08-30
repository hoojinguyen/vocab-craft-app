import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class QuickDrillStepTests: XCTestCase {
    func testQuickDrillStepInitialization() {
        let step = QuickDrillStep(
            id: 1,
            type: .pronunciation,
            promptText: "Đọc to câu ví dụ",
            targetText: "Her fame proved to be ephemeral.",
            options: [],
            sentenceWithGap: nil
        )
        XCTAssertEqual(step.id, 1)
        XCTAssertEqual(step.type, .pronunciation)
        XCTAssertEqual(step.targetText, "Her fame proved to be ephemeral.")
    }
}
