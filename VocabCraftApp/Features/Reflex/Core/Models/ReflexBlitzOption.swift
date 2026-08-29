import Foundation

/// An option candidate displayed in Multiple Choice or Listening Reflex drills.
public struct ReflexBlitzOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String
    public let isCorrect: Bool

    public init(id: String = UUID().uuidString, text: String, isCorrect: Bool) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
    }
}
