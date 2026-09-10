import Foundation

public struct UserStageProgressData: Sendable, Equatable, Hashable, Identifiable {
    public var id: String { stageId }
    public let stageId: String
    public let deckId: String
    public let isCompleted: Bool
    public let score: Int
    public let progressFraction: Double
    public let completedAt: Date

    public init(
        stageId: String,
        deckId: String,
        isCompleted: Bool = false,
        score: Int = 0,
        progressFraction: Double = 0.0,
        completedAt: Date = Date()
    ) {
        self.stageId = stageId
        self.deckId = deckId
        self.isCompleted = isCompleted
        self.score = score
        self.progressFraction = progressFraction
        self.completedAt = completedAt
    }
}
