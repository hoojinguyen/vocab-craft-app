import Foundation

/// Pure policy determining scaffolding transitions, retries, and priming detection.
public struct SupportPolicy: Sendable {
    public init() {}

    /// Computes next progressive support level or jumps directly to full model.
    public func nextLevel(
        current: PracticeSupportLevel,
        requestFullModel: Bool = false
    ) -> PracticeSupportLevel {
        if requestFullModel {
            return .model
        }
        switch current {
        case .none:
            return .intent
        case .intent:
            return .lexical
        case .lexical:
            return .frame
        case .frame, .model:
            return .model
        }
    }

    /// Fades assistance down by exactly one tier following a successful supported attempt.
    public func retryLevel(
        afterSuccessful level: PracticeSupportLevel
    ) -> PracticeSupportLevel {
        switch level {
        case .model:
            return .frame
        case .frame:
            return .lexical
        case .lexical:
            return .intent
        case .intent, .none:
            return .none
        }
    }

    /// Evaluates whether an attempt for `wordId` is primed based on prior exposures and uncertainty.
    ///
    /// - Parameters:
    ///   - wordId: Target vocabulary item ID.
    ///   - exposures: Scaffolding exposures presented during the session.
    ///   - uncertainWordIds: Set of word IDs with uncertain exposure history.
    ///   - before: Timestamp marking the start of the learner's current composition/capture.
    /// - Returns: True if primed by prior lexical, frame, or model exposures, or uncertain status.
    public func isPrimed(
        wordId: Int64,
        exposures: [SupportExposure],
        uncertainWordIds: Set<Int64> = [],
        before: Date
    ) -> Bool {
        if uncertainWordIds.contains(wordId) {
            return true
        }

        for exposure in exposures where exposure.presentedAt < before {
            let appliesToWord = exposure.wordIds.contains(wordId) || exposure.wordIds.isEmpty
            guard appliesToWord else { continue }

            switch exposure.level {
            case .lexical, .frame, .model:
                return true
            case .none, .intent:
                continue
            }
        }

        return false
    }
}
