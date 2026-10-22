import Foundation

/// Evaluation of vocabulary usage correctness in the learner's response.
public enum PracticeUsageVerdict: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case appropriate
    case inappropriate
    case notObserved
    case uncertain
}

/// Evaluation of whether the communicative intent was successfully achieved.
public enum PracticeIntentVerdict: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case achieved
    case notYet
    case uncertain
}

/// Verification classification of the transcribed audio.
public enum PracticeTranscriptReliability: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case usable
    case needsConfirmation
    case unavailable
}

/// Validity status of an evidence record within turn revision history.
public enum PracticeEvidenceStatus: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case valid
    case superseded
}

/// Modality utilized by the learner for input.
public enum PracticeInputMode: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case voice
    case typed
    case editedTranscript
}

/// Atomic unit of pedagogical evidence recording lexical use and scaffolding status.
public struct WordUseEvidence: Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let turnId: UUID
    public let wordId: Int64
    public let objectiveId: String
    public let usageVerdict: PracticeUsageVerdict
    public let intentVerdict: PracticeIntentVerdict
    public let transcriptReliability: PracticeTranscriptReliability
    public let supportExposureIds: [UUID]
    public let primed: Bool
    public let contextFamily: PracticeContextFamily
    public let inputMode: PracticeInputMode
    public let quotedSpan: String?
    public let assessmentVersion: Int
    public let providerIdentity: String
    public let status: PracticeEvidenceStatus
    public let timestamp: Date
    public let turnRevision: Int
    public let opportunityId: String?

    public init(
        id: UUID,
        sessionId: UUID,
        turnId: UUID,
        wordId: Int64,
        objectiveId: String,
        usageVerdict: PracticeUsageVerdict,
        intentVerdict: PracticeIntentVerdict,
        transcriptReliability: PracticeTranscriptReliability,
        supportExposureIds: [UUID] = [],
        primed: Bool = false,
        contextFamily: PracticeContextFamily,
        inputMode: PracticeInputMode,
        quotedSpan: String? = nil,
        assessmentVersion: Int = 1,
        providerIdentity: String = "local_rule_evaluator",
        status: PracticeEvidenceStatus = .valid,
        timestamp: Date,
        turnRevision: Int = 1,
        opportunityId: String? = nil
    ) {
        self.id = id
        self.sessionId = sessionId
        self.turnId = turnId
        self.wordId = wordId
        self.objectiveId = objectiveId
        self.usageVerdict = usageVerdict
        self.intentVerdict = intentVerdict
        self.transcriptReliability = transcriptReliability
        self.supportExposureIds = supportExposureIds
        self.primed = primed
        self.contextFamily = contextFamily
        self.inputMode = inputMode
        self.quotedSpan = quotedSpan
        self.assessmentVersion = assessmentVersion
        self.providerIdentity = providerIdentity
        self.status = status
        self.timestamp = timestamp
        self.turnRevision = turnRevision
        self.opportunityId = opportunityId
    }
}
