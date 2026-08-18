import SwiftUI
import XCTest
@testable import VocabCraftApp

final class ReflexBlitzSummaryViewTests: XCTestCase {
    @MainActor
    func testSummaryViewInstantiation() {
        var didReDrill = false
        var didFinish = false
        var spokenLemma: String?

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
            onSpeakWord: { lemma in spokenLemma = lemma },
            onReDrillWeak: { didReDrill = true },
            onFinish: { didFinish = true }
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(view.summary.speedRating, "⚡️ Reflex Master")
        XCTAssertEqual(view.summary.totalWords, 5)
        XCTAssertEqual(view.summary.correctWords, 4)

        view.onReDrillWeak()
        view.onFinish()
        view.onSpeakWord?("habit")
        XCTAssertTrue(didReDrill)
        XCTAssertTrue(didFinish)
        XCTAssertEqual(spokenLemma, "habit")
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
            onSpeakWord: { _ in },
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
            pos: "adj.",
            ipa: "/ɪˈfem.ər.əl/",
            definitionVi: "Phù du, chóng tàn",
            responseTimeMs: 6000,
            usedHint: false,
            isCorrect: false
        )
        let weakAttempt2 = ReflexBlitzAttempt(
            wordId: 2,
            lemma: "lucid",
            pos: "adj.",
            ipa: "/ˈluː.sɪd/",
            definitionVi: "Rõ ràng, minh bạch",
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
        var spokenWord: String?
        let view = ReflexBlitzSummaryView(
            summary: summary,
            onSpeakWord: { lemma in spokenWord = lemma },
            onReDrillWeak: {},
            onFinish: {}
        )
        XCTAssertNotNil(view.body)
        XCTAssertEqual(view.summary.weakWordAttempts.count, 2)
        XCTAssertEqual(view.summary.weakWordAttempts[0].pos, "adj.")
        XCTAssertEqual(view.summary.weakWordAttempts[0].ipa, "/ɪˈfem.ər.əl/")
        XCTAssertEqual(view.summary.weakWordAttempts[0].definitionVi, "Phù du, chóng tàn")
        
        view.onSpeakWord?("ephemeral")
        XCTAssertEqual(spokenWord, "ephemeral")
    }

    @MainActor
    func testSummaryViewCallbackTriggers() {
        var reDrillCount = 0
        var finishCount = 0
        var speakCount = 0
        var lastSpoken: String?

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
            onSpeakWord: { lemma in
                speakCount += 1
                lastSpoken = lemma
            },
            onReDrillWeak: { reDrillCount += 1 },
            onFinish: { finishCount += 1 }
        )

        view.onReDrillWeak()
        view.onReDrillWeak()
        view.onFinish()
        view.onSpeakWord?("resilient")

        XCTAssertEqual(reDrillCount, 2)
        XCTAssertEqual(finishCount, 1)
        XCTAssertEqual(speakCount, 1)
        XCTAssertEqual(lastSpoken, "resilient")
    }

    @MainActor
    func testSummaryViewDefaultSpeakWordIsNil() {
        let summary = ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: 3,
            correctWords: 3,
            averageResponseTimeMs: 2000,
            maxComboStreak: 3,
            attempts: [],
            weakWordAttempts: [],
            speedRating: "⚡️ Reflex Master"
        )

        let view = ReflexBlitzSummaryView(
            summary: summary,
            onReDrillWeak: {},
            onFinish: {}
        )

        XCTAssertNil(view.onSpeakWord)
    }
}
