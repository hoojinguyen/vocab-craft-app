import Foundation

public protocol SpeakingRepositoryProtocol: Sendable {
    func save(_ session: SpeakingSessionSnapshot) async throws
    func session(id: UUID) async throws -> SpeakingSessionSnapshot?
    func sessions(limit: Int?) async throws -> [SpeakingSessionSnapshot]
    func updateAnalysis(sessionId: UUID, status: SpeakingSessionStatus, analysis: SpeakingAnalysis?) async throws
    func savePhrase(_ phrase: SavedPhrase) async throws -> Bool
    func phrases() async throws -> [SavedPhrase]
    func deletePhrase(id: UUID) async throws
    func detachAudio(keepingLatest count: Int) async throws -> [String]
}
