import Foundation

/// Repository protocol abstracting user vocabulary progress operations across actor boundaries.
public protocol UserProgressRepositoryProtocol: Sendable {
    /// Records the result of a challenge question for a word.
    func recordChallengeResult(wordId: Int64, isCorrect: Bool, stageId: String?, deckId: String?) async throws
    
    /// Toggles the bookmark status for the given word ID, returning the new bookmark state.
    @discardableResult
    func toggleBookmark(wordId: Int64) async throws -> Bool
    
    /// Marks a word as reviewed during a focused review session.
    func markWordReviewed(wordId: Int64, isCorrect: Bool) async throws
    
    /// Clears the `needsReview` flag for a given word ID.
    func clearNeedsReview(wordId: Int64) async throws
    
    /// Fetches all user word progress data snapshots.
    func fetchAllProgress() async throws -> [UserWordProgressData]
    
    /// Fetches the user word progress data for a single word ID.
    func getProgress(wordId: Int64) async throws -> UserWordProgressData?
    
    /// Saves or updates a word progress snapshot.
    func saveProgress(
        wordId: Int64,
        cefrLevel: String,
        masteryLevel: Int,
        isBookmarked: Bool,
        needsReview: Bool,
        mistakeCount: Int,
        sourceDeckId: String?,
        sourceNodeId: String?
    ) async throws
}
