import Foundation

/// Provenance origins for presentation and scaffolding exposures.
public enum SupportOrigin: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case prelessonReview
    case learnerRequested
    case coachSuggested
    case characterSpeech
    case correction
    case transcriptReplay
}

/// Delivery channels for presenting scaffolding to the learner.
public enum PracticePresentationChannel: String, Codable, Sendable, CaseIterable, Equatable, Hashable {
    case visual
    case audio
}

/// Five progressive tiers of communicative assistance.
public enum PracticeSupportLevel: String, Codable, Sendable, CaseIterable, Equatable, Hashable, Comparable {
    case none
    case intent
    case lexical
    case frame
    case model

    private var rank: Int {
        switch self {
        case .none: return 0
        case .intent: return 1
        case .lexical: return 2
        case .frame: return 3
        case .model: return 4
        }
    }

    public static func < (lhs: PracticeSupportLevel, rhs: PracticeSupportLevel) -> Bool {
        lhs.rank < rhs.rank
    }
}

/// Record of an assistance or vocabulary exposure actually rendered or played to the learner.
public struct SupportExposure: Codable, Sendable, Equatable, Hashable {
    public let id: UUID
    public let sessionId: UUID
    public let turnId: UUID?
    public let wordIds: [Int64]
    public let level: PracticeSupportLevel
    public let origin: SupportOrigin
    public let contentSnapshot: String
    public let presentedAt: Date
    public let channel: PracticePresentationChannel

    public init(
        id: UUID,
        sessionId: UUID,
        turnId: UUID? = nil,
        wordIds: [Int64],
        level: PracticeSupportLevel,
        origin: SupportOrigin,
        contentSnapshot: String,
        presentedAt: Date,
        channel: PracticePresentationChannel
    ) {
        self.id = id
        self.sessionId = sessionId
        self.turnId = turnId
        self.wordIds = wordIds
        self.level = level
        self.origin = origin
        self.contentSnapshot = contentSnapshot
        self.presentedAt = presentedAt
        self.channel = channel
    }
}
