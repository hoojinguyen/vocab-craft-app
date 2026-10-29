import Foundation

public enum SpeakingAnalysisError: Error, Equatable, Sendable {
    case missingKey
    case unauthorized
    case quotaExceeded
    case network
    case invalidResponse
    case audioUnavailable
}

public protocol SpeakingAnalyzing: Sendable {
    func analyze(_ session: SpeakingSessionSnapshot, audioURL: URL) async throws -> SpeakingAnalysis
}

public enum QuoteNormalizer {
    public static func normalize(_ text: String) -> String {
        let normalizedQuotes = text
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "‘", with: "'")
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .precomposedStringWithCanonicalMapping
            .lowercased()

        let filtered = normalizedQuotes.unicodeScalars.filter { scalar in
            !CharacterSet.punctuationCharacters.contains(scalar) || scalar == "'"
        }
        return String(String.UnicodeScalarView(filtered))
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
