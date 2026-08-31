import Foundation
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

final class ReflexSpeechMatcherTests: XCTestCase {
    // MARK: - Short Words (<= 4 chars): Reject noise, allow exact and clear prefix

    func testShortWords_rejectsAmbientNoiseTokens() {
        // "cat" (3 chars) vs "at" (ratio 0.67) or "bat" (ratio 0.67)
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "at", targetLemma: "cat"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "bat", targetLemma: "cat"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "car", targetLemma: "cat"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "un", targetLemma: "run"))
        // 4 chars words: ratio 0.75 would match under old 0.70 threshold without tiered matching
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "cars", targetLemma: "care"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "rest", targetLemma: "test"))
    }

    func testShortWords_acceptsExactMatch() {
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "cat", targetLemma: "cat"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "run", targetLemma: "run"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "i see a cat here", targetLemma: "cat"))
    }

    func testShortWords_acceptsStemOrPrefixWhenTargetFourChars() {
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "walked", targetLemma: "walk"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "walking", targetLemma: "walk"))
    }

    // MARK: - Medium Words (5 - 7 chars): Threshold 0.80

    func testMediumWords_acceptsHighSimilarity() {
        // "vital" (5 chars) vs "vitall" (ratio 0.83)
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "vital", targetLemma: "vital"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "vitals", targetLemma: "vital"))
    }

    func testMediumWords_rejectsDissimilarTokens() {
        // "vital" vs "viral" (dist 1 / 5 = 0.8, but "viral" vs "vital" -> 0.8 is right on edge, test 0.6)
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "metal", targetLemma: "vital"))
    }

    // MARK: - Long Words (>= 8 chars): Threshold 0.72

    func testLongWords_acceptsAccentTolerantVariants() {
        // "ephemeral" (9 chars)
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "ephemeral", targetLemma: "ephemeral"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "hesitated", targetLemma: "hesitate"))
    }

    // MARK: - Multi-Word Lemmas

    func testMultiWordLemmas_evaluatesCorrectly() {
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "please give up now", targetLemma: "give up"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "give in now", targetLemma: "give up"))
    }
}
