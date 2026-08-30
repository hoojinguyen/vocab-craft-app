import Foundation
@testable import SpeechKit
#if canImport(XCTest)
import XCTest
#endif

final class StringNormalizerTests: XCTestCase {
    // MARK: - Basic Normalization Tests

    func testNormalize_lowercaseAndTrimming() {
        let input = "  Hello WORLD  "
        let expected = "hello world"
        XCTAssertEqual(StringNormalizer.normalize(input), expected)
    }

    func testNormalize_multiWhitespaceCollapsing() {
        let input = "The   quick\tbrown\n\nfox   jumps"
        let expected = "the quick brown fox jumps"
        XCTAssertEqual(StringNormalizer.normalize(input), expected)
    }

    func testNormalize_emptyAndWhitespaceOnly() {
        XCTAssertEqual(StringNormalizer.normalize(""), "")
        XCTAssertEqual(StringNormalizer.normalize("   "), "")
        XCTAssertEqual(StringNormalizer.normalize("\t\n\r"), "")
    }

    func testNormalize_punctuationStripping() {
        let input = "Hello, world! How are you doing? (Great: 100% fine...)"
        // Note: digits are also converted, so 100 -> one hundred
        let normalized = StringNormalizer.normalize(input)
        XCTAssertFalse(normalized.contains(","))
        XCTAssertFalse(normalized.contains("!"))
        XCTAssertFalse(normalized.contains("?"))
        XCTAssertFalse(normalized.contains(":"))
        XCTAssertFalse(normalized.contains("("))
        XCTAssertFalse(normalized.contains(")"))
        XCTAssertFalse(normalized.contains("."))
        XCTAssertFalse(normalized.contains("%"))
    }

    // MARK: - Contraction Expansion Tests

    func testNormalize_standardContractions() {
        let cases: [(input: String, expected: String)] = [
            ("I'm happy", "i am happy"),
            ("You're welcome", "you are welcome"),
            ("He's fast", "he is fast"),
            ("She's smart", "she is smart"),
            ("It's okay", "it is okay"),
            ("We're ready", "we are ready"),
            ("They're here", "they are here"),
            ("That's true", "that is true"),
            ("There's time", "there is time"),
            ("What's up", "what is up"),
            ("Who's there", "who is there"),
            ("Where's Waldo", "where is waldo"),
            ("How's it going", "how is it going"),
            ("Let's go", "let us go")
        ]

        for (input, expected) in cases {
            XCTAssertEqual(StringNormalizer.normalize(input), expected, "Failed for: \(input)")
        }
    }

    func testNormalize_negativeContractions() {
        let cases: [(input: String, expected: String)] = [
            ("I can't swim", "i cannot swim"),
            ("I won't give up", "i will not give up"),
            ("Don't panic", "do not panic"),
            ("He doesn't know", "he does not know"),
            ("We didn't see", "we did not see"),
            ("It isn't real", "it is not real"),
            ("They aren't ready", "they are not ready"),
            ("I wasn't sure", "i was not sure"),
            ("We weren't late", "we were not late"),
            ("I haven't eaten", "i have not eaten"),
            ("She hasn't left", "she has not left"),
            ("They hadn't started", "they had not started"),
            ("I wouldn't do that", "i would not do that"),
            ("You shouldn't worry", "you should not worry"),
            ("We couldn't reach", "we could not reach"),
            ("You mustn't touch", "you must not touch")
        ]

        for (input, expected) in cases {
            XCTAssertEqual(StringNormalizer.normalize(input), expected, "Failed for: \(input)")
        }
    }

    func testNormalize_haveWillWouldContractions() {
        let cases: [(input: String, expected: String)] = [
            ("I've seen it", "i have seen it"),
            ("You've got this", "you have got this"),
            ("We've arrived", "we have arrived"),
            ("They've won", "they have won"),
            ("I'll do it", "i will do it"),
            ("You'll see", "you will see"),
            ("He'll come", "he will come"),
            ("She'll win", "she will win"),
            ("It'll work", "it will work"),
            ("We'll meet", "we will meet"),
            ("They'll come", "they will come"),
            ("I'd like that", "i would like that"),
            ("You'd know", "you would know"),
            ("He'd agree", "he would agree"),
            ("She'd stay", "she would stay"),
            ("We'd love to", "we would love to"),
            ("They'd help", "they would help")
        ]

        for (input, expected) in cases {
            XCTAssertEqual(StringNormalizer.normalize(input), expected, "Failed for: \(input)")
        }
    }

    func testNormalize_curlyApostrophes() {
        let cases: [(input: String, expected: String)] = [
            ("I’m ready", "i am ready"),
            ("Don’t stop", "do not stop"),
            ("Can’t wait", "cannot wait"),
            ("It’s great", "it is great"),
            ("You’re right", "you are right"),
            ("They’ve arrived", "they have arrived"),
            ("We’ll see", "we will see")
        ]

        for (input, expected) in cases {
            XCTAssertEqual(StringNormalizer.normalize(input), expected, "Failed for: \(input)")
        }
    }

    // MARK: - Digits to Words Tests

    func testNormalize_digitsZeroToTen() {
        let input = "0 1 2 3 4 5 6 7 8 9 10"
        let expected = "zero one two three four five six seven eight nine ten"
        XCTAssertEqual(StringNormalizer.normalize(input), expected)
    }

    func testNormalize_digitsInSentence() {
        let input = "I have 2 cats and 3 dogs in room 10."
        let expected = "i have two cats and three dogs in room ten"
        XCTAssertEqual(StringNormalizer.normalize(input), expected)
    }

    // MARK: - Complex Sentence Integration Tests

    func testNormalize_complexSentence() {
        let input = "\"Don't worry!\", she said, \"I'm 100% sure we'll win 1st place!\""
        let normalized = StringNormalizer.normalize(input)
        XCTAssertEqual(normalized, "do not worry she said i am one hundred sure we will win first place")
    }

    // MARK: - Tokenization Tests

    func testTokenize_basicSentence() {
        let input = "The quick brown fox"
        let tokens = StringNormalizer.tokenize(input)
        XCTAssertEqual(tokens, ["the", "quick", "brown", "fox"])
    }

    func testTokenize_withContractionsAndPunctuation() {
        let input = "Hello, world! I can't believe it's 3 o'clock."
        let tokens = StringNormalizer.tokenize(input)
        XCTAssertEqual(tokens, ["hello", "world", "i", "cannot", "believe", "it", "is", "three", "oclock"])
    }

    func testTokenize_emptyAndWhitespace() {
        XCTAssertEqual(StringNormalizer.tokenize(""), [String]())
        XCTAssertEqual(StringNormalizer.tokenize("   "), [String]())
        XCTAssertEqual(StringNormalizer.tokenize(" \t\n "), [String]())
    }

    // MARK: - Standalone Helpers Tests

    func testExpandContractions_standalone() {
        XCTAssertEqual(StringNormalizer.expandContractions("I'm"), "i am")
        XCTAssertEqual(StringNormalizer.expandContractions("can't"), "cannot")
        XCTAssertEqual(StringNormalizer.expandContractions("won't"), "will not")
        XCTAssertEqual(StringNormalizer.expandContractions("It’s"), "it is")
    }

    func testConvertDigitsToWords_standalone() {
        XCTAssertEqual(StringNormalizer.convertDigitsToWords("5"), "five")
        XCTAssertEqual(StringNormalizer.convertDigitsToWords("10"), "ten")
        XCTAssertEqual(StringNormalizer.convertDigitsToWords("0"), "zero")
        XCTAssertEqual(StringNormalizer.convertDigitsToWords("1,000"), "one thousand")
        XCTAssertEqual(StringNormalizer.convertDigitsToWords("3.14"), "three point one four")
    }

    func testNormalize_groupedAndDecimalNumbers() {
        let input = "There are 1,000 meters in a kilometer and pi is 3.14."
        let expected = "there are one thousand meters in a kilometer and pi is three point one four"
        XCTAssertEqual(StringNormalizer.normalize(input), expected)
    }

    func testStripPunctuation_standalone() {
        XCTAssertEqual(StringNormalizer.stripPunctuation("hello, world!"), "hello  world ")
        XCTAssertEqual(StringNormalizer.stripPunctuation("\"quote\""), " quote ")
    }
}
