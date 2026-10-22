import Foundation

/// Four-tier communication achievement stages for active vocabulary use.
public enum CommunicationStage: String, Codable, Sendable, CaseIterable, Equatable, Hashable, Comparable {
    case noEvidence
    case practicing
    case independentFamiliar
    case transferred

    private var rank: Int {
        switch self {
        case .noEvidence: return 0
        case .practicing: return 1
        case .independentFamiliar: return 2
        case .transferred: return 3
        }
    }

    public static func < (lhs: CommunicationStage, rhs: CommunicationStage) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// Aggregated, rebuildable cache of communicative competence per word and input modality.
public struct CommunicationProgress: Codable, Sendable, Equatable, Hashable {
    public let wordId: Int64
    public let inputMode: PracticeInputMode
    public let stage: CommunicationStage
    public let independentEvidenceIds: [UUID]
    public let lastIndependentUseAt: Date?
    public let nextPracticeAt: Date?
    public let recentOutcome: PracticeOpportunityOutcome?
    public let policyVersion: Int

    public init(
        wordId: Int64,
        inputMode: PracticeInputMode,
        stage: CommunicationStage,
        independentEvidenceIds: [UUID] = [],
        lastIndependentUseAt: Date? = nil,
        nextPracticeAt: Date? = nil,
        recentOutcome: PracticeOpportunityOutcome? = nil,
        policyVersion: Int = 1
    ) {
        self.wordId = wordId
        self.inputMode = inputMode
        self.stage = stage
        self.independentEvidenceIds = independentEvidenceIds
        self.lastIndependentUseAt = lastIndependentUseAt
        self.nextPracticeAt = nextPracticeAt
        self.recentOutcome = recentOutcome
        self.policyVersion = policyVersion
    }
}
