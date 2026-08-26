import XCTest
import SwiftUI
@testable import CraftUIKit

final class FeedbackComponentTests: XCTestCase {
    func testCraftFeedbackStatusProperties() {
        XCTAssertEqual(CraftFeedbackStatus.success.iconName, "checkmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.error.iconName, "xmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.warning.iconName, "exclamationmark.circle.fill")
        XCTAssertEqual(CraftFeedbackStatus.info.iconName, "info.circle.fill")

        XCTAssertEqual(CraftFeedbackStatus.allCases.count, 4)
    }
}
