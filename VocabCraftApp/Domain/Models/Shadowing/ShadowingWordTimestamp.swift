import Foundation

public struct ShadowingWordTimestamp: Sendable, Codable, Equatable {
    public let word: String
    public let start: Double
    public let end: Double

    public init(word: String, start: Double, end: Double) {
        self.word = word
        self.start = start
        self.end = end
    }
}
