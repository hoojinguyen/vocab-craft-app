import Foundation

public protocol ShadowingProgressRepositoryProtocol: Sendable {
    func getProgress(videoId: String) async -> ShadowingProgressRecord?
    func recordCompletion(videoId: String, score: Double, sentenceScores: [String: Double]) async throws
    func getAllProgress() async -> [String: ShadowingProgressRecord]
}
