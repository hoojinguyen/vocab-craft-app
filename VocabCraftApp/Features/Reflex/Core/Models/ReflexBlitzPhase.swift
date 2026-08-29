import Foundation

public enum ReflexBlitzPhase: Equatable, Sendable {
    case modeSelection
    case countdown
    case drilling
    case timeoutRevealing
    case summary
}

public enum ReflexBlitzTimerStage: Equatable, Sendable {
    case steady
    case warning
    case urgent
}

public struct ReflexBlitzDeepLinkConfig: Equatable, Sendable {
    public let mode: ReflexBlitzMode
    public let phase: ReflexBlitzPhase
    public let state: String?
    public let showHint: Bool
    public let combo: Int

    public init(
        mode: ReflexBlitzMode = .speaking,
        phase: ReflexBlitzPhase = .drilling,
        state: String? = nil,
        showHint: Bool = false,
        combo: Int = 0
    ) {
        self.mode = mode
        self.phase = phase
        self.state = state
        self.showHint = showHint
        self.combo = combo
    }
}
