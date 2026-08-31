import Foundation
#if canImport(Testing)
import Testing
#endif
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("SmartVaultWordSelector Tests")
struct SmartVaultWordSelectorTests {
    @Test("Returns all words when pool is smaller than targetCount")
    func testPoolSmallerThanTarget() {
        let selector = SmartVaultWordSelector()
        let words = [
            VaultWordItem(id: 1, lemma: "apple", pos: "noun", definitionVi: "quả táo"),
            VaultWordItem(id: 2, lemma: "banana", pos: "noun", definitionVi: "quả chuối")
        ]
        let selected = selector.selectWords(from: words, targetCount: 10)
        #expect(selected.count == 2)
    }

    @Test("Returns all words when pool is equal to targetCount")
    func testPoolEqualToTarget() {
        let selector = SmartVaultWordSelector()
        let words = [
            VaultWordItem(id: 1, lemma: "apple", pos: "noun", definitionVi: "quả táo"),
            VaultWordItem(id: 2, lemma: "banana", pos: "noun", definitionVi: "quả chuối")
        ]
        let selected = selector.selectWords(from: words, targetCount: 2)
        #expect(selected.count == 2)
    }

    @Test("Returns empty array when pool is empty or targetCount is zero or negative")
    func testEmptyPoolOrZeroTarget() {
        let selector = SmartVaultWordSelector()
        let words = [
            VaultWordItem(id: 1, lemma: "apple", pos: "noun", definitionVi: "quả táo")
        ]
        #expect(selector.selectWords(from: [], targetCount: 5).isEmpty)
        #expect(selector.selectWords(from: words, targetCount: 0).isEmpty)
        #expect(selector.selectWords(from: words, targetCount: -1).isEmpty)
    }

    @Test("Prioritizes words with lowest mode count and lower streak")
    func testPriorityOrdering() {
        let selector = SmartVaultWordSelector()
        let wordWeak = VaultWordItem(
            id: 1,
            lemma: "weak",
            pos: "adj",
            definitionVi: "yếu",
            correctStreak: 0,
            modeStats: ModeSuccessStats(speaking: 0, typing: 0, multipleChoice: 0, listening: 0)
        )
        let wordMastered = VaultWordItem(
            id: 2,
            lemma: "strong",
            pos: "adj",
            definitionVi: "mạnh",
            correctStreak: 5,
            modeStats: ModeSuccessStats(speaking: 5, typing: 5, multipleChoice: 5, listening: 5)
        )
        let selected = selector.selectWords(from: [wordMastered, wordWeak], targetCount: 1)
        #expect(selected.first?.id == 1)
    }

    @Test("Prioritizes words with older practice dates over recently practiced words")
    func testTimeSinceLastPracticeFactor() {
        let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
        let selector = SmartVaultWordSelector(
            dateProvider: { fixedNow },
            jitterProvider: { 0.0 }
        )

        let tenDaysAgo = fixedNow.addingTimeInterval(-10 * 86400)
        let oneDayAgo = fixedNow.addingTimeInterval(-1 * 86400)

        let wordOld = VaultWordItem(
            id: 1,
            lemma: "old",
            pos: "adj",
            definitionVi: "cũ",
            correctStreak: 2,
            lastPracticedAt: tenDaysAgo,
            modeStats: ModeSuccessStats(speaking: 1, typing: 1, multipleChoice: 1, listening: 0)
        )

        let wordRecent = VaultWordItem(
            id: 2,
            lemma: "recent",
            pos: "adj",
            definitionVi: "gần đây",
            correctStreak: 2,
            lastPracticedAt: oneDayAgo,
            modeStats: ModeSuccessStats(speaking: 1, typing: 1, multipleChoice: 1, listening: 0)
        )

        let selected = selector.selectWords(from: [wordRecent, wordOld], targetCount: 1)
        #expect(selected.first?.id == 1)
    }

    @Test("Unpracticed words with nil lastPracticedAt receive maximum time bonus")
    func testNeverPracticedWordBonus() {
        let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
        let selector = SmartVaultWordSelector(
            dateProvider: { fixedNow },
            jitterProvider: { 0.0 }
        )

        let wordNever = VaultWordItem(
            id: 1,
            lemma: "newbie",
            pos: "n",
            definitionVi: "mới",
            correctStreak: 2,
            lastPracticedAt: nil,
            modeStats: ModeSuccessStats(speaking: 1, typing: 1, multipleChoice: 1, listening: 0)
        )

        let wordToday = VaultWordItem(
            id: 2,
            lemma: "today",
            pos: "n",
            definitionVi: "hôm nay",
            correctStreak: 2,
            lastPracticedAt: fixedNow,
            modeStats: ModeSuccessStats(speaking: 1, typing: 1, multipleChoice: 1, listening: 0)
        )

        let selected = selector.selectWords(from: [wordToday, wordNever], targetCount: 1)
        #expect(selected.first?.id == 1)
    }

    @Test("Exact score calculation with custom date and jitter providers")
    func testExactScoringCalculation() {
        let fixedNow = Date(timeIntervalSince1970: 1_700_000_000)
        let selector = SmartVaultWordSelector(
            dateProvider: { fixedNow },
            jitterProvider: { 0.5 }
        )

        // Word 1: 2 modes completed (4-2)*10 = 20
        // streak 2: (5-2)*3 = 9
        // 3 days ago: 3*2 = 6
        // jitter: 0.5
        // Score = 20 + 9 + 6 + 0.5 = 35.5
        let word1 = VaultWordItem(
            id: 1,
            lemma: "alpha",
            pos: "n",
            definitionVi: "chữ cái đầu",
            correctStreak: 2,
            lastPracticedAt: fixedNow.addingTimeInterval(-3 * 86400),
            modeStats: ModeSuccessStats(speaking: 1, typing: 1, multipleChoice: 0, listening: 0)
        )

        // Word 2: 3 modes completed (4-3)*10 = 10
        // streak 0: (5-0)*3 = 15
        // 1 day ago: 1*2 = 2
        // jitter: 0.5
        // Score = 10 + 15 + 2 + 0.5 = 27.5
        let word2 = VaultWordItem(
            id: 2,
            lemma: "beta",
            pos: "n",
            definitionVi: "chữ cái hai",
            correctStreak: 0,
            lastPracticedAt: fixedNow.addingTimeInterval(-1 * 86400),
            modeStats: ModeSuccessStats(speaking: 1, typing: 1, multipleChoice: 1, listening: 0)
        )

        let selected = selector.selectWords(from: [word2, word1], targetCount: 2)
        #expect(selected.count == 2)
        #expect(selected[0].id == 1)
        #expect(selected[1].id == 2)
    }

    @Test("Limits selection to targetCount top words from larger pool")
    func testTargetCountTruncation() {
        let selector = SmartVaultWordSelector(jitterProvider: { 0.0 })
        let words = (1...15).map { idx in
            VaultWordItem(
                id: Int64(idx),
                lemma: "word\(idx)",
                pos: "n",
                definitionVi: "nghĩa \(idx)",
                correctStreak: idx,
                modeStats: ModeSuccessStats(
                    speaking: idx,
                    typing: idx,
                    multipleChoice: idx,
                    listening: idx
                )
            )
        }
        let selected = selector.selectWords(from: words, targetCount: 5)
        #expect(selected.count == 5)
        // Word 1 has lowest streak and lowest mode counts, so it will have highest priority score
        #expect(selected[0].id == 1)
    }
}
#endif

final class SmartVaultWordSelectorXCTestCase: XCTestCase {
    func testPoolSmallerThanTarget() {
        let selector = SmartVaultWordSelector()
        let words = [
            VaultWordItem(id: 1, lemma: "apple", pos: "noun", definitionVi: "quả táo"),
            VaultWordItem(id: 2, lemma: "banana", pos: "noun", definitionVi: "quả chuối")
        ]
        let selected = selector.selectWords(from: words, targetCount: 10)
        XCTAssertEqual(selected.count, 2)
    }

    func testPriorityOrdering() {
        let selector = SmartVaultWordSelector()
        let wordWeak = VaultWordItem(
            id: 1,
            lemma: "weak",
            pos: "adj",
            definitionVi: "yếu",
            correctStreak: 0,
            modeStats: ModeSuccessStats(speaking: 0, typing: 0, multipleChoice: 0, listening: 0)
        )
        let wordMastered = VaultWordItem(
            id: 2,
            lemma: "strong",
            pos: "adj",
            definitionVi: "mạnh",
            correctStreak: 5,
            modeStats: ModeSuccessStats(speaking: 5, typing: 5, multipleChoice: 5, listening: 5)
        )
        let selected = selector.selectWords(from: [wordMastered, wordWeak], targetCount: 1)
        XCTAssertEqual(selected.first?.id, 1)
    }
}
