import XCTest
import SwiftUI
@testable import VocabCraftApp

final class HeaderViewTests: XCTestCase {
    func testHeaderViewInstantiation() {
        let view = HeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyGoalProgress: 0.75,
            unreadNotifications: true
        )
        XCTAssertNotNil(view.body)
        XCTAssertEqual(view.userName, "Hooji N.")
        XCTAssertEqual(view.streakDays, 14)
        XCTAssertEqual(view.dailyGoalProgress, 0.75)
        XCTAssertTrue(view.unreadNotifications)
    }
}


