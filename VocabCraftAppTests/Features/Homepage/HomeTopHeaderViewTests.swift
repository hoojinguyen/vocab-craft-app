import Foundation
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
        assertHosted(view)

        let singleNameView = HomeTopHeaderView(
            userName: "Alex",
            streakDays: 30,
            dailyWordsLearned: 15,
            dailyWordsGoal: 10
        )
        assertHosted(singleNameView)

        let emptyNameView = HomeTopHeaderView(
            userName: "   ",
            streakDays: 5,
            dailyWordsLearned: 5,
            dailyWordsGoal: 10
        )
        assertHosted(emptyNameView)
    }

    @Test("Lexical pill displays formatted word count and CEFR level correctly")
    @MainActor
    func testLexicalPillFormatting() {
        let view = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10,
            totalWordsAcquired: 450,
            currentCEFRLevel: "B1",
            onLexicalPillTap: {}
        )
        #expect(view.totalWordsAcquired == 450)
        #expect(view.currentCEFRLevel == "B1")
        #expect(view.lexicalPillText.contains("450"))
        #expect(view.lexicalPillText.contains("B1"))
    }

    @Test("Lexical pill callback fires on invocation")
    @MainActor
    func testLexicalPillCallback() {
        var pillTapped = false
        let view = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10,
            totalWordsAcquired: 450,
            currentCEFRLevel: "B1",
            onLexicalPillTap: { pillTapped = true }
        )
        view.onLexicalPillTap?()
        #expect(pillTapped)
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

    func testLexicalPillFormattingAndTap() {
        var pillTapped = false
        let view = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10,
            totalWordsAcquired: 450,
            currentCEFRLevel: "B1",
            onLexicalPillTap: { pillTapped = true }
        )
        XCTAssertEqual(view.totalWordsAcquired, 450)
        XCTAssertEqual(view.currentCEFRLevel, "B1")
        XCTAssertTrue(view.lexicalPillText.contains("450"))
        XCTAssertTrue(view.lexicalPillText.contains("B1"))
        view.onLexicalPillTap?()
        XCTAssertTrue(pillTapped)
    }

    func testHeaderViewBodyRendering() {
        let view = HomeTopHeaderView(
            userName: "John Doe",
            streakDays: 0,
            dailyWordsLearned: 0,
            dailyWordsGoal: 0
        )
        assertHosted(view)

        let singleNameView = HomeTopHeaderView(
            userName: "Alex",
            streakDays: 30,
            dailyWordsLearned: 15,
            dailyWordsGoal: 10
        )
        assertHosted(singleNameView)

        let emptyNameView = HomeTopHeaderView(
            userName: "   ",
            streakDays: 5,
            dailyWordsLearned: 5,
            dailyWordsGoal: 10
        )
        assertHosted(emptyNameView)
    }
}
#endif
