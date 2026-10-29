public struct SpeakingAnalysis: Codable, Equatable, Sendable {
    public struct LearnerLine: Codable, Equatable, Sendable {
        public let turnIndex: Int
        public let text: String
    }
    public struct Score: Codable, Equatable, Sendable {
        public let value: Int
        public let reason: String
    }
    public struct Scores: Codable, Equatable, Sendable {
        public let fluency: Score
        public let grammar: Score
        public let vocabulary: Score
        public let pronunciation: Score
    }
    public enum CorrectionCategory: String, Codable, Equatable, Sendable {
        case grammar, wordChoice, other
    }
    public struct Correction: Codable, Equatable, Sendable {
        public let turnIndex: Int
        public let original: String
        public let corrected: String
        public let category: CorrectionCategory
        public let explanation: String
    }
    public struct NaturalPhrasing: Codable, Equatable, Sendable {
        public let original: String
        public let natural: String
        public let note: String
    }
    public struct PronunciationNote: Codable, Equatable, Sendable {
        public let word: String
        public let issue: String
        public let tip: String
    }
    public struct TargetWordUse: Codable, Equatable, Sendable {
        public let lemma: String
        public let used: Bool
        public let usedCorrectly: Bool
        public let quote: String?
    }
    public struct Objective: Codable, Equatable, Sendable {
        public let met: Bool
        public let note: String
    }
    public struct Summary: Codable, Equatable, Sendable {
        public let strengths: [String]
        public let focusNext: [String]
    }
    public let learnerTranscript: [LearnerLine]
    public let scores: Scores
    public let corrections: [Correction]
    public let naturalPhrasings: [NaturalPhrasing]
    public let pronunciation: [PronunciationNote]
    public let targetWords: [TargetWordUse]
    public let objective: Objective?
    public let summary: Summary

    private enum CodingKeys: String, CodingKey {
        case learnerTranscript, scores, corrections, naturalPhrasings, pronunciation, targetWords, objective, summary
    }

}

extension SpeakingAnalysis {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        learnerTranscript = try container.decode([LearnerLine].self, forKey: .learnerTranscript)
        scores = try container.decode(Scores.self, forKey: .scores)
        corrections = try container.decode([Correction].self, forKey: .corrections)
        naturalPhrasings = try container.decode([NaturalPhrasing].self, forKey: .naturalPhrasings)
        pronunciation = try container.decode([PronunciationNote].self, forKey: .pronunciation)
        targetWords = try container.contains(.targetWords) ? container.decode([TargetWordUse].self, forKey: .targetWords) : []
        objective = try container.decodeIfPresent(Objective.self, forKey: .objective)
        summary = try container.decode(Summary.self, forKey: .summary)
    }
}
