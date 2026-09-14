import Foundation
import SpeechKit

public enum ConversationEvaluationFailure: Equatable, Sendable {
    case silence
    case missingBoundary
    case missingRequiredTerm
    case negationMismatch
    case insufficientCoverage
}

public struct ConversationTurnEvaluation: Equatable, Sendable {
    public let isPassed: Bool
    public let score: Double
    public let failure: ConversationEvaluationFailure?
}

public struct ConversationTurnEvaluator: Sendable {
    private let fuzzyThreshold: Double
    private let minimumCoverage: Double

    public init(fuzzyThreshold: Double = 0.78, minimumCoverage: Double = 0.82) {
        self.fuzzyThreshold = fuzzyThreshold
        self.minimumCoverage = minimumCoverage
    }

    public func evaluate(
        transcript: String,
        target: String,
        requiredTerms: [String]
    ) -> ConversationTurnEvaluation {
        let spokenTokens = StringNormalizer.tokenize(transcript)
        let targetTokens = StringNormalizer.tokenize(target)
        guard !spokenTokens.isEmpty, !targetTokens.isEmpty else {
            return .init(isPassed: false, score: 0, failure: .silence)
        }

        let aligned = SequenceAligner.align(
            targetTokens: targetTokens,
            spokenTokens: spokenTokens,
            fuzzyThreshold: fuzzyThreshold
        )
        let matched = aligned.filter { $0.status != .missing }
        let score = aligned.reduce(0) { $0 + $1.similarityScore } / Double(targetTokens.count)

        guard aligned.first?.status != .missing, aligned.last?.status != .missing else {
            return .init(isPassed: false, score: score, failure: .missingBoundary)
        }

        let requiredTokens = Set(requiredTerms.flatMap(StringNormalizer.tokenize))
        let missingRequiredTerm = aligned.contains {
            requiredTokens.contains($0.targetWord) && $0.status == .missing
        }
        guard !missingRequiredTerm else {
            return .init(isPassed: false, score: score, failure: .missingRequiredTerm)
        }

        let negativeWords: Set<String> = ["cannot", "not", "never", "no"]
        let targetNegation = Set(targetTokens.filter(negativeWords.contains))
        let spokenNegation = Set(spokenTokens.filter(negativeWords.contains))
        guard targetNegation == spokenNegation else {
            return .init(isPassed: false, score: score, failure: .negationMismatch)
        }

        let coverage = Double(matched.count) / Double(targetTokens.count)
        guard coverage >= minimumCoverage, score >= minimumCoverage else {
            return .init(isPassed: false, score: score, failure: .insufficientCoverage)
        }

        return .init(isPassed: true, score: score, failure: nil)
    }
}
