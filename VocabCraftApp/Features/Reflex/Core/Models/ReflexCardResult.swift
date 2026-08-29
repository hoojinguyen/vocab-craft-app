import Foundation

/// Outcome result for a single Reflex card response.
public struct ReflexCardResult: Equatable, Sendable {
    public let isCorrect: Bool
    public let responseTimeMs: Int
    public let isTimeout: Bool
    public let selectedOption: String?
    public let typedText: String?
    public let recognizedSpoken: String?

    public init(
        isCorrect: Bool,
        responseTimeMs: Int,
        isTimeout: Bool,
        selectedOption: String? = nil,
        typedText: String? = nil,
        recognizedSpoken: String? = nil
    ) {
        self.isCorrect = isCorrect
        self.responseTimeMs = responseTimeMs
        self.isTimeout = isTimeout
        self.selectedOption = selectedOption
        self.typedText = typedText
        self.recognizedSpoken = recognizedSpoken
    }
}
