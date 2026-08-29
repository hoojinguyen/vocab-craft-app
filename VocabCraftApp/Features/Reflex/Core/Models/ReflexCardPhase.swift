import Foundation

/// Lifecycle phase of an active Reflex card during drilling.
public enum ReflexCardPhase: Equatable, Sendable {
    case activeCountdown
    case reviewed(result: ReflexCardResult)
}
