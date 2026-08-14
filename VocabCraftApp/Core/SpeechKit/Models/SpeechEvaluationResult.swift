import Foundation

public struct SpeechEvaluationResult: Sendable, Equatable, Codable {
    public let targetSentence: String
    public let spokenText: String
    public let tokens: [WordTokenResult]
    public let overallScore: Double
    public let isPassed: Bool
    public let durationMs: Int

    public init(
        targetSentence: String,
        spokenText: String,
        tokens: [WordTokenResult],
        overallScore: Double,
        isPassed: Bool,
        durationMs: Int
    ) {
        self.targetSentence = targetSentence
        self.spokenText = spokenText
        self.tokens = tokens
        self.overallScore = overallScore
        self.isPassed = isPassed
        self.durationMs = durationMs
    }

    public static func empty(targetSentence: String = "") -> SpeechEvaluationResult {
        SpeechEvaluationResult(
            targetSentence: targetSentence,
            spokenText: "",
            tokens: [],
            overallScore: 0.0,
            isPassed: false,
            durationMs: 0
        )
    }
}
