import Foundation

/// Lifecycle phase of an active Reflex card during drilling.
public enum ReflexCardPhase: Equatable, Sendable {
    case activeCountdown
    case reviewed(result: ReflexCardResult)

    public var isReviewed: Bool {
        if case .reviewed = self { return true }
        return false
    }

    public var reviewResult: ReflexCardResult? {
        if case .reviewed(let result) = self { return result }
        return nil
    }
}

