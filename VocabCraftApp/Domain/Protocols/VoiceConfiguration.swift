import Foundation

public struct VoiceConfiguration: Sendable, Codable, Equatable {
    public let gender: VoiceGender
    public let style: VoiceStyle
    public let locale: String

    public init(gender: VoiceGender, style: VoiceStyle, locale: String = "en-US") {
        self.gender = gender
        self.style = style
        self.locale = locale
    }

    public enum VoiceGender: String, Codable, Sendable {
        case male
        case female
    }

    public enum VoiceStyle: String, Codable, Sendable {
        case friendly
        case authoritative
        case expressive
        case calm
    }
}
