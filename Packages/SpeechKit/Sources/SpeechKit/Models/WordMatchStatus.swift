import Foundation

public enum WordMatchStatus: String, Sendable, Equatable, Codable {
    case exactMatch
    case fuzzyMatch
    case missing
}
