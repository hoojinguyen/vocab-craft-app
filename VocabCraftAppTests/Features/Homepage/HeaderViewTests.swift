import XCTest
import SwiftUI
@testable import VocabCraftApp

final class HeaderViewTests: XCTestCase {
    func testHeaderViewInitialization() {
        let view = HeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyGoalProgress: 0.75,
            unreadNotifications: true
        )
        
        XCTAssertEqual(view.userName, "Hooji N.")
        XCTAssertEqual(view.streakDays, 14)
        XCTAssertEqual(view.dailyGoalProgress, 0.75)
        XCTAssertTrue(view.unreadNotifications)
    }
    
    func testHeaderViewWithoutUnreadNotifications() {
        let view = HeaderView(
            userName: "Alex",
            streakDays: 0,
            dailyGoalProgress: 0.0,
            unreadNotifications: false
        )
        
        XCTAssertEqual(view.userName, "Alex")
        XCTAssertEqual(view.streakDays, 0)
        XCTAssertEqual(view.dailyGoalProgress, 0.0)
        XCTAssertFalse(view.unreadNotifications)
    }
}
