import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

final class TargetExpressionMatcherTests: XCTestCase {
    func testContainsAcceptsCaseAndPunctuationVariations() {
        XCTAssertTrue(TargetExpressionMatcher.contains(response: "I showed RESILIENCE!", expression: "resilience"))
    }

    func testContainsRejectsSubstringMatches() {
        XCTAssertFalse(TargetExpressionMatcher.contains(response: "Her resilience is strong.", expression: "silience"))
        XCTAssertFalse(TargetExpressionMatcher.contains(response: "I reconsidered it.", expression: "consider"))
    }

    func testContainsMatchesMultiwordExpressionInTokenWindow() {
        XCTAssertTrue(TargetExpressionMatcher.contains(response: "We should break, the ice before dinner.", expression: "break the ice"))
        XCTAssertFalse(TargetExpressionMatcher.contains(response: "We should break ice before dinner.", expression: "break the ice"))
    }

    func testContainsReturnsFalseForEmptyExpression() {
        XCTAssertFalse(TargetExpressionMatcher.contains(response: "Anything", expression: ""))
    }
}
