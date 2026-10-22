import Foundation

/// Repository contract governing persistence and querying of guided practice sessions,
/// turn evaluations, and learner communication progress.
public protocol PracticeRepositoryProtocol: Sendable {
    /// Retrieves all aggregated communication progress records.
    func progress() async throws -> [CommunicationProgress]

    /// Retrieves all historical word use evidence records.
    func evidence() async throws -> [WordUseEvidence]

    /// Fetches the currently active practice session snapshot, if any.
    func activeSession() async throws -> PracticeSessionSnapshot?

    /// Loads a persisted practice session snapshot by its unique identifier.
    func loadSession(id: UUID) async throws -> PracticeSessionSnapshot?
}
