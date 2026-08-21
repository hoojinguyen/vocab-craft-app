@testable import VocabCraftApp
import XCTest

final class FuzzySpeechMatcherTests: XCTestCase {
    // MARK: - Levenshtein Distance Tests

    func testLevenshteinDistance_identicalStrings() {
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("hello", "hello"), 0)
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("", ""), 0)
    }

    func testLevenshteinDistance_emptyStrings() {
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("", "swift"), 5)
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("swift", ""), 5)
    }

    func testLevenshteinDistance_singleEdits() {
        // Insertion
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("jump", "jumps"), 1)
        // Deletion
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("jumps", "jump"), 1)
        // Substitution
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("cat", "bat"), 1)
    }

    func testLevenshteinDistance_classicExamples() {
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("kitten", "sitting"), 3)
        XCTAssertEqual(FuzzySpeechMatcher.levenshteinDistance("flaw", "lawn"), 2)
    }

    // MARK: - Similarity Ratio Tests

    func testSimilarityRatio_identical() {
        XCTAssertEqual(FuzzySpeechMatcher.similarityRatio("vocabulary", "vocabulary"), 1.0, accuracy: 1e-6)
        XCTAssertEqual(FuzzySpeechMatcher.similarityRatio("", ""), 1.0, accuracy: 1e-6)
    }

    func testSimilarityRatio_emptyComparison() {
        XCTAssertEqual(FuzzySpeechMatcher.similarityRatio("word", ""), 0.0, accuracy: 1e-6)
        XCTAssertEqual(FuzzySpeechMatcher.similarityRatio("", "word"), 0.0, accuracy: 1e-6)
    }

    func testSimilarityRatio_partialMatches() {
        // "jumps" (len 5) vs "jump" (len 4), dist 1 -> 1.0 - 1/5 = 0.8
        XCTAssertEqual(FuzzySpeechMatcher.similarityRatio("jumps", "jump"), 0.8, accuracy: 1e-6)

        // "books" (len 5) vs "book" (len 4), dist 1 -> 1.0 - 1/5 = 0.8
        XCTAssertEqual(FuzzySpeechMatcher.similarityRatio("books", "book"), 0.8, accuracy: 1e-6)

        // "decided" (len 7) vs "decide" (len 6), dist 1 -> 1.0 - 1/7 = 0.85714...
        XCTAssertEqual(FuzzySpeechMatcher.similarityRatio("decided", "decide"), 6.0 / 7.0, accuracy: 1e-6)
    }

    func testSimilarityRatio_completelyDifferent() {
        XCTAssertEqual(FuzzySpeechMatcher.similarityRatio("abc", "xyz"), 0.0, accuracy: 1e-6)
    }

    // MARK: - SequenceAligner Tests

    func testSequenceAligner_exactMatchSequence() {
        let targets = ["the", "quick", "brown", "fox"]
        let spoken = ["the", "quick", "brown", "fox"]

        let results = SequenceAligner.align(targetTokens: targets, spokenTokens: spoken)

        XCTAssertEqual(results.count, 4)
        for (idx, result) in results.enumerated() {
            XCTAssertEqual(result.id, idx)
            XCTAssertEqual(result.targetWord, targets[idx])
            XCTAssertEqual(result.spokenWord, targets[idx])
            XCTAssertEqual(result.status, .exactMatch)
            XCTAssertEqual(result.similarityScore, 1.0, accuracy: 1e-6)
        }
    }

    func testSequenceAligner_withExtraneousFillerWords() {
        let targets = ["good", "morning"]
        let spoken = ["um", "ah", "good", "like", "morning", "yeah"]

        let results = SequenceAligner.align(targetTokens: targets, spokenTokens: spoken)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].targetWord, "good")
        XCTAssertEqual(results[0].spokenWord, "good")
        XCTAssertEqual(results[0].status, .exactMatch)

        XCTAssertEqual(results[1].targetWord, "morning")
        XCTAssertEqual(results[1].spokenWord, "morning")
        XCTAssertEqual(results[1].status, .exactMatch)
    }

    func testSequenceAligner_missingTokens() {
        let targets = ["the", "quick", "brown", "fox"]
        let spoken = ["the", "fox"]

        let results = SequenceAligner.align(targetTokens: targets, spokenTokens: spoken)

        XCTAssertEqual(results.count, 4)
        XCTAssertEqual(results[0].status, .exactMatch)
        XCTAssertEqual(results[0].spokenWord, "the")

        XCTAssertEqual(results[1].status, .missing)
        XCTAssertNil(results[1].spokenWord)
        XCTAssertEqual(results[1].similarityScore, 0.0)

        XCTAssertEqual(results[2].status, .missing)
        XCTAssertNil(results[2].spokenWord)
        XCTAssertEqual(results[2].similarityScore, 0.0)

        XCTAssertEqual(results[3].status, .exactMatch)
        XCTAssertEqual(results[3].spokenWord, "fox")
    }

    func testSequenceAligner_fuzzyMatches() {
        let targets = ["a", "black", "dog", "jumps"]
        let spoken = ["a", "black", "dog", "jump"]

        let results = SequenceAligner.align(targetTokens: targets, spokenTokens: spoken)

        XCTAssertEqual(results.count, 4)
        XCTAssertEqual(results[0].status, .exactMatch)
        XCTAssertEqual(results[1].status, .exactMatch)
        XCTAssertEqual(results[2].status, .exactMatch)

        XCTAssertEqual(results[3].status, .fuzzyMatch)
        XCTAssertEqual(results[3].targetWord, "jumps")
        XCTAssertEqual(results[3].spokenWord, "jump")
        XCTAssertEqual(results[3].similarityScore, 0.8, accuracy: 1e-6)
    }

    func testSequenceAligner_nearMatch_isFuzzyMatchNotExactMatch() {
        // 100 character token with 1 substitution -> similarity 0.99
        let targetWord = String(repeating: "a", count: 100)
        let spokenWord = String(repeating: "a", count: 99) + "b"

        let results = SequenceAligner.align(targetTokens: [targetWord], spokenTokens: [spokenWord])
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].status, .fuzzyMatch)
        XCTAssertEqual(results[0].similarityScore, 0.99, accuracy: 1e-6)
    }

    func testSequenceAligner_emptyInputs() {
        let emptyTargets = SequenceAligner.align(targetTokens: [], spokenTokens: ["hello"])
        XCTAssertTrue(emptyTargets.isEmpty)

        let emptySpoken = SequenceAligner.align(targetTokens: ["hello", "world"], spokenTokens: [])
        XCTAssertEqual(emptySpoken.count, 2)
        XCTAssertEqual(emptySpoken[0].status, .missing)
        XCTAssertEqual(emptySpoken[1].status, .missing)
    }

    // MARK: - FuzzySpeechMatcher Evaluate Tests

    func testEvaluate_exactMatchSentence() {
        let target = "The quick brown fox jumps over the lazy dog."
        let spoken = "the quick brown fox jumps over the lazy dog"

        let result = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target)

        XCTAssertTrue(result.isPassed)
        XCTAssertEqual(result.overallScore, 100.0, accuracy: 1e-6)
        XCTAssertEqual(result.tokens.count, 9)
        XCTAssertTrue(result.tokens.allSatisfy { $0.status == .exactMatch })
    }

    func testEvaluate_contractionEquivalence_spokenContracted() {
        let target = "I am ready to learn English."
        let spoken = "I'm ready to learn English"

        let result = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target)

        XCTAssertTrue(result.isPassed)
        XCTAssertEqual(result.overallScore, 100.0, accuracy: 1e-6)
    }

    func testEvaluate_contractionEquivalence_targetContracted() {
        let target = "They're going to the library."
        let spoken = "They are going to the library"

        let result = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target)

        XCTAssertTrue(result.isPassed)
        XCTAssertEqual(result.overallScore, 100.0, accuracy: 1e-6)
    }

    func testEvaluate_accentVariations_passesThreshold() {
        // Missing "s" on jumps (0.8 similarity) and missing article "the"
        let target = "A black dog jumps over the fence."
        let spoken = "a black dog jump over fence"

        let result = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target)

        // Target tokens: ["a", "black", "dog", "jumps", "over", "the", "fence"] (7 tokens)
        // Scores: 1.0 + 1.0 + 1.0 + 0.8 + 1.0 + 0.0 + 1.0 = 5.8 / 7.0 = 82.857%
        XCTAssertTrue(result.isPassed)
        XCTAssertGreaterThanOrEqual(result.overallScore, 75.0)
    }

    func testEvaluate_fillerWordsTolerated() {
        let target = "Turn left at the next corner."
        let spoken = "um turn left uh like at the next corner please"

        let result = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target)

        XCTAssertTrue(result.isPassed)
        XCTAssertGreaterThanOrEqual(result.overallScore, 90.0)
    }

    func testEvaluate_incompleteSentence_failsThreshold() {
        let target = "The spectacular performance left the entire audience in complete awe."
        let spoken = "the spectacular performance"

        let result = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target)

        XCTAssertFalse(result.isPassed)
        XCTAssertLessThan(result.overallScore, 75.0)
    }

    func testEvaluate_completelyWrongSentence_failsThreshold() {
        let target = "Welcome to the interactive language learning experience."
        let spoken = "banana apple pineapple strawberry"

        let result = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target)

        XCTAssertFalse(result.isPassed)
        XCTAssertEqual(result.overallScore, 0.0, accuracy: 1e-6)
    }

    func testEvaluate_emptyInputs() {
        let emptySpokenResult = FuzzySpeechMatcher.evaluate(spokenText: "", targetSentence: "Hello world")
        XCTAssertFalse(emptySpokenResult.isPassed)
        XCTAssertEqual(emptySpokenResult.overallScore, 0.0)
        XCTAssertEqual(emptySpokenResult.tokens.count, 2)
        XCTAssertTrue(emptySpokenResult.tokens.allSatisfy { $0.status == .missing })

        let emptyTargetResult = FuzzySpeechMatcher.evaluate(spokenText: "Hello world", targetSentence: "")
        XCTAssertFalse(emptyTargetResult.isPassed)
        XCTAssertEqual(emptyTargetResult.overallScore, 0.0)
        XCTAssertTrue(emptyTargetResult.tokens.isEmpty)
    }

    func testEvaluate_customPassThreshold() {
        let target = "A black dog jumps over the fence."
        let spoken = "a black dog jump over fence" // Score ~82.85%

        // With strict 90% threshold, it should fail
        let strictResult = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target, passThreshold: 0.90)
        XCTAssertFalse(strictResult.isPassed)

        // With lenient 70% threshold, it should pass
        let lenientResult = FuzzySpeechMatcher.evaluate(spokenText: spoken, targetSentence: target, passThreshold: 0.70)
        XCTAssertTrue(lenientResult.isPassed)
    }

    func testEvaluate_durationMsPreserved() {
        let result = FuzzySpeechMatcher.evaluate(
            spokenText: "hello world",
            targetSentence: "hello world",
            durationMs: 1450
        )
        XCTAssertEqual(result.durationMs, 1450)
        XCTAssertTrue(result.isPassed)
    }
}
