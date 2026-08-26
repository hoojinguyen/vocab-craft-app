import Foundation
import SpeechKit

public enum TargetExpressionMatcher {
    /// Matches only the target expression after case and punctuation normalization.
    public static func matchesExactly(response: String, expression: String) -> Bool {
        let responseTokens = StringNormalizer.tokenize(response)
        let expressionTokens = StringNormalizer.tokenize(expression)
        return !expressionTokens.isEmpty && responseTokens == expressionTokens
    }

    public static func contains(response: String, expression: String) -> Bool {
        let responseTokens = StringNormalizer.tokenize(response)
        let expressionTokens = StringNormalizer.tokenize(expression)
        guard !expressionTokens.isEmpty, responseTokens.count >= expressionTokens.count else {
            return false
        }

        let windowSize = expressionTokens.count
        return responseTokens.indices.contains { index in
            guard index + windowSize <= responseTokens.count else { return false }
            return Array(responseTokens[index..<(index + windowSize)]) == expressionTokens
        }
    }
}
