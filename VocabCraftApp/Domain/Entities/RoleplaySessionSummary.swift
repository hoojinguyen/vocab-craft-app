import Foundation

public struct SentenceRefinementPair: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let originalUserSentence: String
    public let refinedNativeSentence: String

    public init(id: UUID = UUID(), originalUserSentence: String, refinedNativeSentence: String) {
        self.id = id
        self.originalUserSentence = originalUserSentence
        self.refinedNativeSentence = refinedNativeSentence
    }
}

public struct RoleplaySessionSummary: Identifiable, Codable, Sendable, Equatable {
    public var id: String { scenarioId }
    public let scenarioId: String
    public let totalTurns: Int
    public let targetWordsAttempted: [String]
    public let targetWordsMastered: [String]
    public let fluencyScore: Int
    public let xpEarned: Int
    public let refinements: [SentenceRefinementPair]

    public init(
        scenarioId: String,
        totalTurns: Int,
        targetWordsAttempted: [String],
        targetWordsMastered: [String],
        fluencyScore: Int,
        xpEarned: Int,
        refinements: [SentenceRefinementPair]
    ) {
        self.scenarioId = scenarioId
        self.totalTurns = totalTurns
        self.targetWordsAttempted = targetWordsAttempted
        self.targetWordsMastered = targetWordsMastered
        self.fluencyScore = fluencyScore
        self.xpEarned = xpEarned
        self.refinements = refinements
    }
}
