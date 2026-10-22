import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Craft Shadowing Teleprompter Tests")
struct CraftShadowingTeleprompterTests {
    @Test("Computes active word index with explicit timestamps and bounds clamping")
    func testActiveWordIndexWithExplicitTimestamps() {
        let words = [
            ShadowingWordTimestamp(word: "Can", start: 1.0, end: 1.3),
            ShadowingWordTimestamp(word: "I", start: 1.3, end: 1.5),
            ShadowingWordTimestamp(word: "get", start: 1.5, end: 1.9)
        ]
        let calculator = TeleprompterPacerCalculator(
            words: words,
            sentenceStartTime: 1.0,
            sentenceEndTime: 1.9
        )

        #expect(calculator.activeWordIndex(at: 1.2) == 0)
        #expect(calculator.activeWordIndex(at: 1.4) == 1)
        #expect(calculator.activeWordIndex(at: 1.7) == 2)
        #expect(calculator.activeWordIndex(at: 0.5) == 0) // clamp start
        #expect(calculator.activeWordIndex(at: 3.0) == 2) // clamp end
    }

    @Test("Proportionally falls back across whitespace-split words when words array is empty")
    func testProportionalFallbackWhenWordsEmpty() {
        let sentenceText = "Can I get this"
        let calculator = TeleprompterPacerCalculator(
            words: [],
            sentenceStartTime: 2.0,
            sentenceEndTime: 6.0,
            sentenceText: sentenceText
        )

        #expect(calculator.words.count == 4)
        #expect(calculator.words.map(\.word) == ["Can", "I", "get", "this"])

        #expect(calculator.activeWordIndex(at: 1.5) == 0) // Before start -> first word
        #expect(calculator.activeWordIndex(at: 2.5) == 0) // Word 0: [2.0, 3.0)
        #expect(calculator.activeWordIndex(at: 3.5) == 1) // Word 1: [3.0, 4.0)
        #expect(calculator.activeWordIndex(at: 4.5) == 2) // Word 2: [4.0, 5.0)
        #expect(calculator.activeWordIndex(at: 5.5) == 3) // Word 3: [5.0, 6.0)
        #expect(calculator.activeWordIndex(at: 7.0) == 3) // After end -> clamped to last word
    }

    @Test("Handles edge case of completely empty words and text gracefully")
    func testEmptyWordsAndTextSafety() {
        let calculator = TeleprompterPacerCalculator(words: [], sentenceStartTime: 0, sentenceEndTime: 0, sentenceText: "")
        #expect(calculator.words.isEmpty)
        #expect(calculator.activeWordIndex(at: 0.0) == 0)
        #expect(calculator.activeWordIndex(at: 10.0) == 0)
    }

    @Test("Calculates correct WordPacerState for past, active, and upcoming words")
    func testWordPacerStateCalculation() {
        #expect(WordPacerState.state(for: 0, activeIndex: 1) == .past)
        #expect(WordPacerState.state(for: 1, activeIndex: 1) == .active)
        #expect(WordPacerState.state(for: 2, activeIndex: 1) == .upcoming)
        #expect(WordPacerState.state(for: 3, activeIndex: 1) == .upcoming)
    }

    @Test("Evaluates dynamic WordPacerState transitions based on currentTime")
    func testDynamicPacerStateTransitions() {
        let words = [
            ShadowingWordTimestamp(word: "Hello", start: 1.0, end: 1.5),
            ShadowingWordTimestamp(word: "world", start: 1.5, end: 2.0)
        ]
        let calculator = TeleprompterPacerCalculator(
            words: words,
            sentenceStartTime: 1.0,
            sentenceEndTime: 2.0
        )

        // At t = 1.2s: word 0 is active, word 1 is upcoming
        #expect(calculator.pacerState(for: 0, at: 1.2) == .active)
        #expect(calculator.pacerState(for: 1, at: 1.2) == .upcoming)

        // At t = 1.7s: word 0 is past, word 1 is active
        #expect(calculator.pacerState(for: 0, at: 1.7) == .past)
        #expect(calculator.pacerState(for: 1, at: 1.7) == .active)

        // At t = 2.5s: word 0 is past, word 1 is active (clamped at end)
        #expect(calculator.pacerState(for: 0, at: 2.5) == .past)
        #expect(calculator.pacerState(for: 1, at: 2.5) == .active)
    }
}
