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
        // Accept consonant doubling for short CVC targets
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "planned", targetLemma: "plan"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "planning", targetLemma: "plan"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "stopped", targetLemma: "stop"))
        // Reject non-inflection extensions on 4-letter targets (e.g. target "past" vs spoken "paste", target "plan" vs spoken "planet")
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "paste", targetLemma: "past"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "planet", targetLemma: "plan"))
    }

    // MARK: - Medium Words (5 - 7 chars): Threshold 0.80

    func testMediumWords_acceptsHighSimilarity() {
        // "vital" (5 chars) vs "vital" (exact) and "vitals" (6 chars, dist 1 / 6 = ratio 0.83)
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "vital", targetLemma: "vital"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "vitals", targetLemma: "vital"))
    }

    func testMediumWords_rejectsDissimilarTokens() {
        // "vital" (5 chars) vs "metal" (5 chars, dist 2 / 5 = ratio 0.60 < 0.80)
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "metal", targetLemma: "vital"))
    }

    // MARK: - Long Words (>= 8 chars): Threshold 0.70

    func testLongWords_acceptsAccentTolerantVariants() {
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "ephemeral", targetLemma: "ephemeral"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "hesitated", targetLemma: "hesitate"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "hesitating", targetLemma: "hesitate"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "hesitation", targetLemma: "hesitate"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "creation", targetLemma: "create"))
        // Reject non-inflection derivations (e.g. "creative" should not match "create")
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "creative", targetLemma: "create"))
        // Reject bare truncated stem when target is a distinct longer word (e.g. "past" vs "paste", "cast" vs "caste")
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "past", targetLemma: "paste"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "cast", targetLemma: "caste"))
    }

    // MARK: - Multi-Word Lemmas

    func testMultiWordLemmas_evaluatesCorrectly() {
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "please give up now", targetLemma: "give up"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "give in now", targetLemma: "give up"))
    }
}
