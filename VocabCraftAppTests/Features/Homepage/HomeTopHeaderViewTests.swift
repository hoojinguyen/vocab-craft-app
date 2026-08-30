import SwiftUI
#if canImport(Testing)
import Testing
#endif
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("HomeTopHeaderView Tests")
struct HomeTopHeaderViewTestingTests {
    @Test("Header view properties initialization")
    @MainActor
    func testHeaderViewInitialization() {
        let view = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10
        )
        #expect(view.userName == "Hooji N.")
        #expect(view.streakDays == 14)
        #expect(view.dailyWordsLearned == 8)
        #expect(view.dailyWordsGoal == 10)
    }

    @Test("Header view callbacks invocation")
    @MainActor
    func testHeaderViewCallbacks() {
        var avatarTapped = false
        var streakTapped = false

        let view = HomeTopHeaderView(
            userName: "Alex S.",
            streakDays: 7,
            dailyWordsLearned: 10,
            dailyWordsGoal: 10,
            onAvatarTap: { avatarTapped = true },
            onStreakTap: { streakTapped = true }
        )

        view.onAvatarTap?()
        view.onStreakTap?()

        #expect(avatarTapped)
        #expect(streakTapped)
    }

    @Test("Header view body rendering with different inputs")
    @MainActor
    func testHeaderViewBodyRendering() {
        let view = HomeTopHeaderView(
            userName: "John Doe",
            streakDays: 0,
            dailyWordsLearned: 0,
            dailyWordsGoal: 0
        )
        _ = view.body
    }
}
#endif

#if canImport(XCTest)
@MainActor
final class HomeTopHeaderViewTests: XCTestCase {
    func testHeaderViewInitialization() {
        let view = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10
        )
        XCTAssertEqual(view.userName, "Hooji N.")
        XCTAssertEqual(view.streakDays, 14)
        XCTAssertEqual(view.dailyWordsLearned, 8)
        XCTAssertEqual(view.dailyWordsGoal, 10)
    }

    func testHeaderViewCallbacks() {
        var avatarTapped = false
        var streakTapped = false

        let view = HomeTopHeaderView(
            userName: "Alex S.",
            streakDays: 7,
            dailyWordsLearned: 10,
            dailyWordsGoal: 10,
            onAvatarTap: { avatarTapped = true },
            onStreakTap: { streakTapped = true }
        )

        view.onAvatarTap?()
        view.onStreakTap?()

        XCTAssertTrue(avatarTapped)
        XCTAssertTrue(streakTapped)
    }

    func testHeaderViewBodyRendering() {
        let view = HomeTopHeaderView(
            userName: "John Doe",
            streakDays: 0,
            dailyWordsLearned: 0,
            dailyWordsGoal: 0
        )
        XCTAssertNotNil(view.body)
    }
}
#endif
