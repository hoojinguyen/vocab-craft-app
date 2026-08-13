import SwiftUI
@testable import VocabCraftApp
import XCTest

final class HeaderViewTests: XCTestCase {
    func testHeaderViewInstantiation() {
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

    func testHeaderViewCallbacks() {
        var avatarTapped = false
        var notificationTapped = false

        let view = HeaderView(
            userName: "Alex Swift",
            streakDays: 7,
            dailyGoalProgress: 0.50,
            unreadNotifications: false,
            onAvatarTap: { avatarTapped = true },
            onNotificationTap: { notificationTapped = true }
        )

        XCTAssertNotNil(view.onAvatarTap)
        XCTAssertNotNil(view.onNotificationTap)

        view.onAvatarTap?()
        view.onNotificationTap?()

        XCTAssertTrue(avatarTapped)
        XCTAssertTrue(notificationTapped)
    }
}
