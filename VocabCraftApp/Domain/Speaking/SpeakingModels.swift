import Foundation

public enum SpeakingSessionKind: String, Codable, Sendable { case scenario, topic }

public enum SpeakingLevel: String, Codable, Sendable, CaseIterable { case a2, b1 }

public struct SpeakingBlueprint: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let kind: SpeakingSessionKind
    public let titleKey: String
    public let briefKey: String
    public let aiRole: String
    public let setting: String
    public let objective: String?
    public let durationSeconds: Int

    init(
        id: String, kind: SpeakingSessionKind, titleKey: String, briefKey: String,
        aiRole: String, setting: String, objective: String?, durationSeconds: Int = 360
    ) {
        self.id = id
        self.kind = kind
        self.titleKey = titleKey
        self.briefKey = briefKey
        self.aiRole = aiRole
        self.setting = setting
        self.objective = objective
        self.durationSeconds = durationSeconds
    }
}

public struct SpeakingTargetWord: Codable, Sendable, Hashable {
    public let wordId: Int64
    public let lemma: String
    public let definitionVi: String
}

public struct SpeakingSessionPlan: Codable, Sendable, Hashable {
    public let blueprint: SpeakingBlueprint
    public let level: SpeakingLevel
    public let targetWords: [SpeakingTargetWord]
}

public enum SpeakingSpeaker: String, Codable, Sendable { case ai, learner }

public struct SpeakingTurn: Codable, Sendable, Equatable {
    public var index: Int
    public var speaker: SpeakingSpeaker
    public var text: String
    public var startOffset: TimeInterval
    public var endOffset: TimeInterval?
}

public enum SpeakingSessionStatus: String, Codable, Sendable { case pendingAnalysis, analyzed, analysisFailed, tooShort }

public enum SpeakingEndReason: String, Codable, Sendable { case learnerEnded, aiEnded, timeLimit, interrupted, connectionLost }

public struct SpeakingSessionSnapshot: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let plan: SpeakingSessionPlan
    public let startedAt: Date
    public let duration: TimeInterval
    public var status: SpeakingSessionStatus
    public let endReason: SpeakingEndReason
    public let hintCount: Int
    public var audioFileName: String?
    public let turns: [SpeakingTurn]
    public var analysis: SpeakingAnalysis?
    public var learnerTurnCount: Int { turns.filter { $0.speaker == .learner }.count }
}

public enum SavedPhraseSource: String, Codable, Sendable { case correction, naturalPhrasing }

public struct SavedPhrase: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let original: String
    public let suggestion: String
    public let note: String
    public let sessionId: UUID
    public let source: SavedPhraseSource
    public let createdAt: Date
}
