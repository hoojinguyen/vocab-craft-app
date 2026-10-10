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
        _ = view.body

        let singleNameView = HomeTopHeaderView(
            userName: "Alex",
            streakDays: 30,
            dailyWordsLearned: 15,
            dailyWordsGoal: 10
        )
        _ = singleNameView.body

        let emptyNameView = HomeTopHeaderView(
            userName: "   ",
            streakDays: 5,
            dailyWordsLearned: 5,
            dailyWordsGoal: 10
        )
        _ = emptyNameView.body
    }

    @Test("Header view with active learning path rendering")
    @MainActor
    func testHeaderViewWithActiveLearningPath() {
        let path = LearningPathDTO(
            id: "path_essential",
            code: "essential-english-mastery",
            titleEn: "Essential English Mastery",
            titleVi: "Chinh Phục Tiếng Anh Toàn Diện",
            descriptionEn: "From Zero to Hero",
            descriptionVi: "Từ số 0 đến tự tin giao tiếp",
            goalCategory: "general_communication",
            targetLevelMin: "A1",
            targetLevelMax: "B2",
            iconKey: "sparkles",
            themeKey: "emerald",
            sortOrder: 1
        )
        let view = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10,
            activeLearningPath: path
        )
        #expect(view.activeLearningPath?.id == "path_essential")
        _ = view.body

        let singleLevelPath = LearningPathDTO(
            id: "path_ielts",
            code: "ielts-core",
            titleEn: "IELTS Core",
            titleVi: "IELTS Cốt Lõi",
            descriptionEn: nil,
            descriptionVi: nil,
            goalCategory: "exam_prep",
            targetLevelMin: "B2",
            targetLevelMax: "B2",
            iconKey: "sparkles",
            themeKey: "emerald",
            sortOrder: 2
        )
        let singleLevelView = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10,
            activeLearningPath: singleLevelPath
        )
        #expect(singleLevelView.activeLearningPath?.id == "path_ielts")
        _ = singleLevelView.body
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

        let singleNameView = HomeTopHeaderView(
            userName: "Alex",
            streakDays: 30,
            dailyWordsLearned: 15,
            dailyWordsGoal: 10
        )
        XCTAssertNotNil(singleNameView.body)

        let emptyNameView = HomeTopHeaderView(
            userName: "   ",
            streakDays: 5,
            dailyWordsLearned: 5,
            dailyWordsGoal: 10
        )
        XCTAssertNotNil(emptyNameView.body)
    }

    func testHeaderViewWithActiveLearningPath() {
        let path = LearningPathDTO(
            id: "path_essential",
            code: "essential-english-mastery",
            titleEn: "Essential English Mastery",
            titleVi: "Chinh Phục Tiếng Anh Toàn Diện",
            descriptionEn: "From Zero to Hero",
            descriptionVi: "Từ số 0 đến tự tin giao tiếp",
            goalCategory: "general_communication",
            targetLevelMin: "A1",
            targetLevelMax: "B2",
            iconKey: "sparkles",
            themeKey: "emerald",
            sortOrder: 1
        )
        let view = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10,
            activeLearningPath: path
        )
        XCTAssertEqual(view.activeLearningPath?.id, "path_essential")
        XCTAssertNotNil(view.body)

        let singleLevelPath = LearningPathDTO(
            id: "path_ielts",
            code: "ielts-core",
            titleEn: "IELTS Core",
            titleVi: "IELTS Cốt Lõi",
            descriptionEn: nil,
            descriptionVi: nil,
            goalCategory: "exam_prep",
            targetLevelMin: "B2",
            targetLevelMax: "B2",
            iconKey: "sparkles",
            themeKey: "emerald",
            sortOrder: 2
        )
        let singleLevelView = HomeTopHeaderView(
            userName: "Hooji N.",
            streakDays: 14,
            dailyWordsLearned: 8,
            dailyWordsGoal: 10,
            activeLearningPath: singleLevelPath
        )
        XCTAssertEqual(singleLevelView.activeLearningPath?.id, "path_ielts")
        XCTAssertNotNil(singleLevelView.body)
    }
}
#endif
