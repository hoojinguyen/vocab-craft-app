import Foundation

public enum CraftSpeechWordStatus: String, Sendable, Equatable, CaseIterable {
    case pending
    case matched
    case fuzzy
    case mismatched
}

public typealias CraftSpeechStatus = CraftSpeechWordStatus

public struct CraftSpeechWordToken: Identifiable, Sendable, Equatable {
    public let id: String
    public let targetWord: String
    public let status: CraftSpeechWordStatus
    public let spokenWord: String?
    public let confidence: Double?

    public init(
        id: String = UUID().uuidString,
        targetWord: String,
        status: CraftSpeechWordStatus = .pending,
        spokenWord: String? = nil,
        confidence: Double? = nil
    ) {
        self.id = id
        self.targetWord = targetWord
        self.status = status
        self.spokenWord = spokenWord
        self.confidence = confidence
    }
}

public enum CraftSpeechState: Equatable, Sendable {
    case idle
    case preparing
    case listening(audioLevels: [CGFloat] = [])
    case processing
    case evaluated(overallScore: Double)
    case unavailable

    public var isListening: Bool {
        if case .listening = self { return true }
        return false
    }
}

