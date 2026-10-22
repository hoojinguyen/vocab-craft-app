import Foundation

/// Speaker roles participating in a practice dialogue.
public enum PracticeSpeaker: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case learner
    case character
    case coach
}

/// Reliability and verification state of user transcriptions.
public enum PracticeTranscriptStatus: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case notApplicable
    case final
    case edited
    case needsConfirmation
    case uncertain
}

/// Lifecycle status of AI turn generation.
public enum PracticeGenerationStatus: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case notApplicable
    case pending
    case succeeded
    case failed
}

/// Single conversational exchange within a practice session.
public struct PracticeTurn: Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let sequence: Int
    public let speaker: PracticeSpeaker
    public let inputMode: PracticeInputMode
    public let originalText: String
    public let acceptedText: String
    public let transcriptStatus: PracticeTranscriptStatus
    public let generationStatus: PracticeGenerationStatus
    public let requestId: String
    public let sessionRevision: Int
    public let timestamp: Date

    public init(
        id: UUID,
        sessionId: UUID,
        sequence: Int,
        speaker: PracticeSpeaker,
        inputMode: PracticeInputMode,
        originalText: String,
        acceptedText: String,
        transcriptStatus: PracticeTranscriptStatus = .final,
        generationStatus: PracticeGenerationStatus = .succeeded,
        requestId: String,
        sessionRevision: Int = 1,
        timestamp: Date
    ) {
        self.id = id
        self.sessionId = sessionId
        self.sequence = sequence
        self.speaker = speaker
        self.inputMode = inputMode
        self.originalText = originalText
        self.acceptedText = acceptedText
        self.transcriptStatus = transcriptStatus
        self.generationStatus = generationStatus
        self.requestId = requestId
        self.sessionRevision = sessionRevision
        self.timestamp = timestamp
    }
}
