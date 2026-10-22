import Foundation

/// Repository contract governing persistence, transactional mutations, idempotency,
/// and querying of guided practice sessions, turns, exposures, and communication progress.
public protocol PracticeRepositoryProtocol: Sendable {
    /// Creates and persists a new practice session.
    func create(_ session: PracticeSession) async throws

    /// Loads a persisted practice session snapshot by its unique identifier.
    func loadSession(id: UUID) async throws -> PracticeSessionSnapshot?

    /// Fetches the currently active (.inProgress) practice session snapshot, if any.
    func activeSession() async throws -> PracticeSessionSnapshot?

    /// Retrieves all aggregated communication progress records.
    func progress() async throws -> [CommunicationProgress]

    /// Retrieves all historical word use evidence records.
    func evidence() async throws -> [WordUseEvidence]

    /// Saves a pending conversational turn and updates session checkpoint before asynchronous generation/assessment.
    func savePendingTurn(_ turn: PracticeTurn, checkpoint: PracticeCheckpoint, expectedRevision: Int) async throws

    /// Atomically commits turn evaluation results, creates/deduplicates evidence, rebuilds communication progress,
    /// and persists session checkpoint.
    func commit(_ value: PracticeCommit) async throws -> PracticeSessionSnapshot

    /// Durably prepares a presentation intent prior to UI rendering or audio playback.
    func preparePresentation(_ intent: PracticePresentationIntent, expectedRevision: Int) async throws

    /// Confirms that a presentation intent has been successfully rendered/played, creating an immutable support exposure.
    func confirmPresentation(id: UUID, exposure: SupportExposure, expectedRevision: Int) async throws

    /// Advances the session revision and persists checkpoint when input mode or provider changes or operation is cancelled.
    func revise(sessionId: UUID, expectedRevision: Int, checkpoint: PracticeCheckpoint) async throws -> Int

    /// Finalizes a practice session as completed or partial, returning a summary report.
    func finalize(sessionId: UUID, completion: PracticeCompletion, expectedRevision: Int) async throws -> PracticeSummary

    /// Deletes a specific practice session and its associated turns, exposures, presentations, and evidence,
    /// rebuilding communication progress for affected words.
    func deleteSession(id: UUID) async throws

    /// Deletes all practice sessions, turns, exposures, presentations, evidence, and communication progress records.
    func deleteAllPractice() async throws

    /// Resets all user learning progress (SRS, reflex, quick reflex) and all practice records.
    func resetAllLearningProgress() async throws
}
