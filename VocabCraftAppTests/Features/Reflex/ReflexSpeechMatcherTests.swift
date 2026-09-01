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

    func testShortWords_acceptsInflectionsAndConsonantDoublingForThreeAndFourChars() {
        // 4-letter regular verbal inflections
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "walked", targetLemma: "walk"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "walking", targetLemma: "walk"))

        // 3-letter regular verbal inflections (-ed, -ing, -s, -es for sibilants)
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "asked", targetLemma: "ask"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "asking", targetLemma: "ask"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "fixed", targetLemma: "fix"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "fixing", targetLemma: "fix"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "boxes", targetLemma: "box"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "buses", targetLemma: "bus"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "ashes", targetLemma: "ash"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "cats", targetLemma: "cat"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "rowing", targetLemma: "row"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "paying", targetLemma: "pay"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "keyed", targetLemma: "key"))

        // 3-letter consonant doubling (CVC)
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "running", targetLemma: "run"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "sitting", targetLemma: "sit"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "fitted", targetLemma: "fit"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "canning", targetLemma: "can"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "pinning", targetLemma: "pin"))

        // 4-letter consonant doubling (CVC)
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "planned", targetLemma: "plan"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "planning", targetLemma: "plan"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "stopped", targetLemma: "stop"))

        // c -> ck spelling transformation
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "panicked", targetLemma: "panic"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "panicking", targetLemma: "panic"))

        // Vowel-drop inflections for 3 and 4 letter silent-e targets
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "making", targetLemma: "make"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "taking", targetLemma: "take"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "loving", targetLemma: "love"))
        XCTAssertTrue(ReflexSpeechMatcher.isReflexMatch(spokenText: "using", targetLemma: "use"))

        // Rejection of non-inflection derivations (e.g. agent nouns, adjectives)
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "rainy", targetLemma: "rain"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "farmer", targetLemma: "farm"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "planner", targetLemma: "plan"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "maker", targetLemma: "make"))

        // Rejection of distinct words slipping through as fake inflections
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "cares", targetLemma: "car"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "canes", targetLemma: "can"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "pines", targetLemma: "pin"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "tones", targetLemma: "ton"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "wines", targetLemma: "win"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "care", targetLemma: "car"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "cared", targetLemma: "car"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "caning", targetLemma: "can"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "pining", targetLemma: "pin"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "catch", targetLemma: "cat"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "paste", targetLemma: "past"))
        XCTAssertFalse(ReflexSpeechMatcher.isReflexMatch(spokenText: "pasted", targetLemma: "past"))
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
