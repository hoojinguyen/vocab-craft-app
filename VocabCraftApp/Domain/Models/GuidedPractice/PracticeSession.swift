import Foundation

/// High-level lifecycle status of a practice session.
public enum PracticeSessionStatus: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case inProgress
    case completed
    case partial
    case abandoned
}

/// Detailed runtime state machine status of a practice session.
public enum PracticeSessionState: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case preparing
    case awaitingLearner
    case capturing
    case processing
    case playingCharacter
    case coaching
    case paused
    case recoverableError
    case saving
    case completed
    case partial
}

/// Core domain record representing an active or completed practice session.
public struct PracticeSession: Codable, Sendable, Equatable {
    public let id: UUID
    public let missionSnapshot: PracticeMission
    public let status: PracticeSessionStatus
    public let startedAt: Date
    public let completedAt: Date?
    public let checkpoint: PracticeCheckpoint
    public let revision: Int
    public let initialInputMode: PracticeInputMode
    public let policyVersion: Int

    public init(
        id: UUID,
        missionSnapshot: PracticeMission,
        status: PracticeSessionStatus,
        startedAt: Date,
        completedAt: Date? = nil,
        checkpoint: PracticeCheckpoint,
        revision: Int = 1,
        initialInputMode: PracticeInputMode = .voice,
        policyVersion: Int = 1
    ) {
        self.id = id
        self.missionSnapshot = missionSnapshot
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.checkpoint = checkpoint
        self.revision = revision
        self.initialInputMode = initialInputMode
        self.policyVersion = policyVersion
    }
}
