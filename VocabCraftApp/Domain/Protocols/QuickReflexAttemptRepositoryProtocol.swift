import Foundation

/// Persists and retrieves quick-reflex learning attempts.
public protocol QuickReflexAttemptRepositoryProtocol: AnyObject {
    /// Saves a completed quick-reflex attempt.
    func save(_ attempt: QuickReflexAttempt) async throws

    /// Returns the newest attempt whose retrieval stage succeeded for a word.
    func mostRecentSuccessfulAttempt(for wordId: Int64) async throws -> QuickReflexAttempt?
}
