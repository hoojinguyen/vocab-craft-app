#if canImport(XCTest)
import XCTest
#endif
@testable import CraftUIKit

final class CraftSpeechEngineTests: XCTestCase {
    func testExactMatchProducesAllMatchedTokens() {
        let origin = "It was a good job."
        let actual = "It was a good job"
        let tokens = CraftTextMatchEngine.match(originText: origin, actualText: actual, isFinal: true)
        
        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(tokens.map(\.targetWord), ["It", "was", "a", "good", "job."])
        XCTAssertTrue(tokens.allSatisfy { $0.status == .matched })
    }

    func testPartialStreamingMatchProducesPendingRemainder() {
        let origin = "It was a good job."
        let actual = "It was"
        let tokens = CraftTextMatchEngine.match(originText: origin, actualText: actual, isFinal: false)
        
        XCTAssertEqual(tokens[0].status, .matched)
        XCTAssertEqual(tokens[1].status, .matched)
        XCTAssertEqual(tokens[2].status, .pending)
        XCTAssertEqual(tokens[3].status, .pending)
        XCTAssertEqual(tokens[4].status, .pending)
    }

    func testMismatchedWordDetection() {
        let origin = "It was a good job."
        let actual = "It was a bad job"
        let tokens = CraftTextMatchEngine.match(originText: origin, actualText: actual, isFinal: true)
        
        XCTAssertEqual(tokens[0].status, .matched) // It
        XCTAssertEqual(tokens[1].status, .matched) // was
        XCTAssertEqual(tokens[2].status, .matched) // a
        XCTAssertEqual(tokens[3].status, .mismatched) // good vs bad
        XCTAssertEqual(tokens[4].status, .matched) // job.
    }
}
