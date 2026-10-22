import Foundation

public struct ShadowingProgressRecord: Codable, Sendable, Identifiable, Equatable {
    public var id: String { videoId }
    public let videoId: String
    public var bestScore: Double
    public var lastCompletedAt: Date
    public var timesCompleted: Int
    public var sentenceScores: [String: Double]

    public init(
        videoId: String,
        bestScore: Double,
        lastCompletedAt: Date = Date(),
        timesCompleted: Int = 1,
        sentenceScores: [String: Double] = [:]
    ) {
        self.videoId = videoId
        self.bestScore = bestScore
        self.lastCompletedAt = lastCompletedAt
        self.timesCompleted = timesCompleted
        self.sentenceScores = sentenceScores
    }
}
