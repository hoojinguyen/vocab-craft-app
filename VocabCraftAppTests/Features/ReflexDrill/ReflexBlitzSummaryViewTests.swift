import SwiftUI
import XCTest
@testable import VocabCraftApp

final class ReflexBlitzSummaryViewTests: XCTestCase {
    @MainActor
    func testSummaryViewInstantiation() {
        var didReDrill = false
        var didFinish = false

        let summary = ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: 5,
            correctWords: 4,
            averageResponseTimeMs: 1900,
            maxComboStreak: 4,
            attempts: [],
            weakWordAttempts: [],
            speedRating: "⚡️ Reflex Master"
        )
        let view = ReflexBlitzSummaryView(
            summary: summary,
            onReDrillWeak: { didReDrill = true },
            onFinish: { didFinish = true }
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(view.summary.speedRating, "⚡️ Reflex Master")
        XCTAssertEqual(view.summary.totalWords, 5)
        XCTAssertEqual(view.summary.correctWords, 4)

        view.onReDrillWeak()
        view.onFinish()
        XCTAssertTrue(didReDrill)
        XCTAssertTrue(didFinish)
    }

    @MainActor
    func testSummaryViewBodyRendersWithoutWeakWords() {
        let summary = ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: 5,
            correctWords: 5,
            averageResponseTimeMs: 1500,
            maxComboStreak: 5,
            attempts: [],
            weakWordAttempts: [],
            speedRating: "⚡️ Reflex Master"
        )
        let view = ReflexBlitzSummaryView(
            summary: summary,
            onReDrillWeak: {},
            onFinish: {}
        )
        XCTAssertNotNil(view.body)
        XCTAssertTrue(view.summary.weakWordAttempts.isEmpty)
    }

    @MainActor
    func testSummaryViewBodyRendersWithWeakWords() {
        let weakAttempt1 = ReflexBlitzAttempt(
            wordId: 1,
            lemma: "ephemeral",
            responseTimeMs: 6000,
            usedHint: false,
            isCorrect: false
        )
        let weakAttempt2 = ReflexBlitzAttempt(
            wordId: 2,
            lemma: "lucid",
            responseTimeMs: 4500,
            usedHint: true,
            isCorrect: true
        )
        let summary = ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: 5,
            correctWords: 3,
            averageResponseTimeMs: 3800,
            maxComboStreak: 2,
            attempts: [weakAttempt1, weakAttempt2],
            weakWordAttempts: [weakAttempt1, weakAttempt2],
            speedRating: "🌱 Steady Learner"
        )
        let view = ReflexBlitzSummaryView(
            summary: summary,
            onReDrillWeak: {},
            onFinish: {}
        )
        XCTAssertNotNil(view.body)
        XCTAssertEqual(view.summary.weakWordAttempts.count, 2)
    }

    @MainActor
    func testSummaryViewCallbackTriggers() {
        var reDrillCount = 0
        var finishCount = 0

        let summary = ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: 3,
            correctWords: 2,
            averageResponseTimeMs: 2200,
            maxComboStreak: 2,
            attempts: [],
            weakWordAttempts: [],
            speedRating: "🔥 Swift Reflex"
        )

        let view = ReflexBlitzSummaryView(
            summary: summary,
            onReDrillWeak: { reDrillCount += 1 },
            onFinish: { finishCount += 1 }
        )

        view.onReDrillWeak()
        view.onReDrillWeak()
        view.onFinish()

        XCTAssertEqual(reDrillCount, 2)
        XCTAssertEqual(finishCount, 1)
    }
}
