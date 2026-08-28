import SwiftUI
import Testing
@testable import VocabCraftApp
import XCTest

@Suite("Reflex Blitz Summary Re-drill Tests")
@MainActor
struct ReflexBlitzSummaryReDrillTests {
    @Test("Summary re-drill retains same modality for weak words in speaking mode")
    func testSameModeReDrill() {
        let viewModel = ReflexBlitzViewModel()
        let wordItem1 = ReflexBlitzWordItem(id: 1, lemma: "word1", ipa: "/w1/", definitionVi: "nghĩa 1", clozeSentenceEn: "[word1]", clozeSentenceVi: "câu 1")
        let wordItem2 = ReflexBlitzWordItem(id: 2, lemma: "word2", ipa: "/w2/", definitionVi: "nghĩa 2", clozeSentenceEn: "[word2]", clozeSentenceVi: "câu 2")

        viewModel.startDrillSession(mode: .speaking, words: [wordItem1, wordItem2])
        viewModel.submitSpeakingResult(isCorrect: true, responseTimeMs: 1200)
        viewModel.advanceToNextWord()
        viewModel.submitSpeakingResult(isCorrect: false, responseTimeMs: 6000)
        viewModel.advanceToNextWord()

        #expect(viewModel.phase == .summary)
        #expect(viewModel.sessionSummary?.weakWordAttempts.count == 1)
        #expect(viewModel.sessionSummary?.weakWordAttempts.first?.wordId == 2)

        viewModel.reDrillWeakWords()
        #expect(viewModel.selectedMode == .speaking)
        #expect(viewModel.words.count == 1)
        #expect(viewModel.words.first?.id == 2)
        #expect(viewModel.phase == .countdown)
    }

    @Test("Summary re-drill retains typing modality for weak words")
    func testTypingModeReDrill() {
        let viewModel = ReflexBlitzViewModel()
        let wordItem1 = ReflexBlitzWordItem(id: 10, lemma: "apple", ipa: "/ˈæp.əl/", definitionVi: "quả táo", clozeSentenceEn: "[apple]", clozeSentenceVi: "quả táo")
        let wordItem2 = ReflexBlitzWordItem(id: 20, lemma: "banana", ipa: "/bəˈnɑː.nə/", definitionVi: "quả chuối", clozeSentenceEn: "[banana]", clozeSentenceVi: "quả chuối")

        viewModel.startDrillSession(mode: .typing, words: [wordItem1, wordItem2])
        viewModel.submitTypingAnswer("apple")
        viewModel.advanceToNextWord()
        viewModel.handleTimeout()
        viewModel.advanceToNextWord()

        #expect(viewModel.phase == .summary)
        #expect(viewModel.sessionSummary?.weakWordAttempts.count == 1)
        #expect(viewModel.sessionSummary?.weakWordAttempts.first?.wordId == 20)

        viewModel.reDrillWeakWords()
        #expect(viewModel.selectedMode == .typing)
        #expect(viewModel.words.count == 1)
        #expect(viewModel.words.first?.id == 20)
    }

    @Test("Summary re-drill retains multiple choice modality for weak words")
    func testMultipleChoiceModeReDrill() {
        let viewModel = ReflexBlitzViewModel()
        let wordItem1 = ReflexBlitzWordItem(id: 100, lemma: "cat", ipa: "/kæt/", definitionVi: "con mèo", clozeSentenceEn: "[cat]", clozeSentenceVi: "con mèo")
        let wordItem2 = ReflexBlitzWordItem(id: 200, lemma: "dog", ipa: "/dɒɡ/", definitionVi: "con chó", clozeSentenceEn: "[dog]", clozeSentenceVi: "con chó")

        viewModel.startDrillSession(mode: .multipleChoice, words: [wordItem1, wordItem2])
        if let correct = viewModel.currentOptions.first(where: { $0.isCorrect }) {
            viewModel.selectOption(correct)
        }
        viewModel.advanceToNextWord()
        if let wrong = viewModel.currentOptions.first(where: { !$0.isCorrect }) {
            viewModel.selectOption(wrong)
        }
        viewModel.advanceToNextWord()

        #expect(viewModel.phase == .summary)
        #expect(viewModel.sessionSummary?.weakWordAttempts.count == 1)
        #expect(viewModel.sessionSummary?.weakWordAttempts.first?.wordId == 200)

        viewModel.reDrillWeakWords()
        #expect(viewModel.selectedMode == .multipleChoice)
        #expect(viewModel.words.count == 1)
        #expect(viewModel.words.first?.id == 200)
    }

    @Test("Re-drill with empty weak words does nothing")
    func testReDrillNoWeakWords() {
        let viewModel = ReflexBlitzViewModel()
        let wordItem1 = ReflexBlitzWordItem(id: 1, lemma: "word1", ipa: "/w1/", definitionVi: "nghĩa 1")
        viewModel.startDrillSession(mode: .speaking, words: [wordItem1])
        viewModel.submitSpeakingResult(isCorrect: true, responseTimeMs: 1000)
        viewModel.advanceToNextWord()

        #expect(viewModel.phase == .summary)
        #expect(viewModel.sessionSummary?.weakWordAttempts.isEmpty == true)

        let wordsBefore = viewModel.words
        viewModel.reDrillWeakWords()
        #expect(viewModel.words == wordsBefore)
        #expect(viewModel.phase == .summary)
    }
}

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
        XCTAssertNotNil(view.summaryContent)
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
        XCTAssertNotNil(view.summaryContent)
        XCTAssertEqual(view.summary.weakWordAttempts.count, 2)
        XCTAssertEqual(view.summary.weakWordAttempts[0].pos, "adj.")
        XCTAssertEqual(view.summary.weakWordAttempts[0].ipa, "/ɪˈfem.ər.əl/")
        XCTAssertEqual(view.summary.weakWordAttempts[0].definitionVi, "Phù du, chóng tàn")

        view.onSpeakWord?("ephemeral")
        XCTAssertEqual(spokenWord, "ephemeral")
    }

    @MainActor
    func testSummaryViewWithLongIPAAndComplexPhonetics() {
        let longIPAAttempts = [
            ReflexBlitzAttempt(
                wordId: 101,
                lemma: "serendipity",
                pos: "n.",
                ipa: "/ˌser.ənˈdɪp.ə.ti/",
                definitionVi: "Sự tình cờ may mắn",
                responseTimeMs: 6000,
                usedHint: true,
                isCorrect: false
            ),
            ReflexBlitzAttempt(
                wordId: 102,
                lemma: "meticulous",
                pos: "adj.",
                ipa: "/məˈtɪk.jə.ləs/",
                definitionVi: "Tỉ mỉ, cẩn thận từng li từng tí",
                responseTimeMs: 5200,
                usedHint: false,
                isCorrect: false
            ),
            ReflexBlitzAttempt(
                wordId: 103,
                lemma: "unconditional",
                pos: "adj.",
                ipa: "/ˌʌn.kənˈdɪʃ.ən.əl/",
                definitionVi: "Vô điều kiện, tuyệt đối",
                responseTimeMs: 4800,
                usedHint: true,
                isCorrect: true
            ),
            ReflexBlitzAttempt(
                wordId: 104,
                lemma: "comprehensive",
                pos: "adj.",
                ipa: "/ˌkɒm.prɪˈhen.sɪv/",
                definitionVi: "Toàn diện, bao quát",
                responseTimeMs: 6000,
                usedHint: false,
                isCorrect: false
            )
        ]

        let summary = ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: 4,
            correctWords: 1,
            averageResponseTimeMs: 5500,
            maxComboStreak: 1,
            attempts: longIPAAttempts,
            weakWordAttempts: longIPAAttempts,
            speedRating: "🌱 Steady Learner"
        )

        let view = ReflexBlitzSummaryView(
            summary: summary,
            onSpeakWord: { _ in },
            onReDrillWeak: {},
            onFinish: {}
        )

        XCTAssertNotNil(view.body)
        XCTAssertNotNil(view.summaryContent)
        XCTAssertEqual(view.summary.weakWordAttempts.count, 4)
        XCTAssertEqual(view.summary.weakWordAttempts[0].ipa, "/ˌser.ənˈdɪp.ə.ti/")
        XCTAssertEqual(view.summary.weakWordAttempts[1].ipa, "/məˈtɪk.jə.ləs/")
        XCTAssertEqual(view.summary.weakWordAttempts[2].ipa, "/ˌʌn.kənˈdɪʃ.ən.əl/")
        XCTAssertEqual(view.summary.weakWordAttempts[3].ipa, "/ˌkɒm.prɪˈhen.sɪv/")
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

    @MainActor
    func testSummaryViewWithDifferentSpeedRatings() {
        let ratings = ["⚡️ Reflex Master", "🔥 Swift Reflex", "🌱 Steady Learner"]
        for rating in ratings {
            let summary = ReflexBlitzSessionSummary(
                id: UUID(),
                totalWords: 5,
                correctWords: 4,
                averageResponseTimeMs: 2500,
                maxComboStreak: 3,
                attempts: [],
                weakWordAttempts: [],
                speedRating: rating
            )
            let view = ReflexBlitzSummaryView(
                summary: summary,
                onSpeakWord: { _ in },
                onReDrillWeak: {},
                onFinish: {}
            )
            XCTAssertNotNil(view.body)
            XCTAssertNotNil(view.summaryContent)
            XCTAssertEqual(view.summary.speedRating, rating)
        }
    }
}
