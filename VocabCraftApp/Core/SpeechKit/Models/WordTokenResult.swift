import Foundation

public struct WordTokenResult: Identifiable, Sendable, Equatable, Codable {
    public let id: Int
    public let targetWord: String
    public let spokenWord: String?
    public let status: WordMatchStatus
    public let similarityScore: Double

    public init(
        id: Int,
        targetWord: String,
        spokenWord: String? = nil,
        status: WordMatchStatus = .missing,
        similarityScore: Double = 0.0
    ) {
        self.id = id
        self.targetWord = targetWord
        self.spokenWord = spokenWord
        self.status = status
        self.similarityScore = similarityScore
    }
}
