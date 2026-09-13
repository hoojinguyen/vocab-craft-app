import Foundation

public enum ConversationRole: String, Codable, CaseIterable, Sendable {
    case speakerA
    case speakerB
}

public struct ConversationTurn: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let speaker: ConversationRole
    public let english: String
    public let vietnamese: String

    public init(id: String, speaker: ConversationRole, english: String, vietnamese: String) {
        self.id = id
        self.speaker = speaker
        self.english = english
        self.vietnamese = vietnamese
    }
}

public struct ConversationScript: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let situation: String
    public let situationVi: String
    public let vocabularyReferences: [String]
    public let turns: [ConversationTurn]

    public init(
        id: String,
        situation: String,
        situationVi: String,
        vocabularyReferences: [String],
        turns: [ConversationTurn]
    ) {
        self.id = id
        self.situation = situation
        self.situationVi = situationVi
        self.vocabularyReferences = vocabularyReferences
        self.turns = turns
    }
}

public enum ConversationMockOutcome: String, Codable, CaseIterable, Sendable {
    case pass
    case retry
    case noSpeech
}

public enum ConversationSessionPhase: Codable, Equatable, Sendable {
    case preview
    case partnerPlayback(turnID: String)
    case listening(turnID: String)
    case waitingToRetry(turnID: String, outcome: ConversationMockOutcome)
    case paused
    case awaitingContinue
    case completed
}

public enum ConversationRegenerationStatus: Equatable, Sendable {
    case idle
    case loading
    case failed
}

public protocol ConversationRepository: Sendable {
    func nextConversation(after currentID: String) async throws -> ConversationScript
}

public enum ConversationRepositoryError: Error, Sendable {
    case simulatedFailure
    case missingFixture
}
