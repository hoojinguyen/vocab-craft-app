import Foundation

public enum VoiceEngineType: String, Sendable, Codable, CaseIterable {
    case appleEnhanced
    case geminiNeural
    case kokoroNeural
}

public enum VoiceGender: String, Sendable, Codable, CaseIterable {
    case female
    case male
    case neutral
}

public struct RoleplayVoiceProfile: Identifiable, Sendable, Equatable, Hashable, Codable {
    public let id: String
    public let displayNameKey: String
    public let gender: VoiceGender
    public let locale: String
    public let engine: VoiceEngineType
    public let qualityDescriptionKey: String
    public let sampleText: String
    public let appleVoiceIdentifier: String?
    public let geminiPersona: VoicePersona?

    public init(
        id: String,
        displayNameKey: String,
        gender: VoiceGender,
        locale: String,
        engine: VoiceEngineType,
        qualityDescriptionKey: String,
        sampleText: String = "Hi! I'm excited to practice English conversation with you.",
        appleVoiceIdentifier: String? = nil,
        geminiPersona: VoicePersona? = nil
    ) {
        self.id = id
        self.displayNameKey = displayNameKey
        self.gender = gender
        self.locale = locale
        self.engine = engine
        self.qualityDescriptionKey = qualityDescriptionKey
        self.sampleText = sampleText
        self.appleVoiceIdentifier = appleVoiceIdentifier
        self.geminiPersona = geminiPersona
    }
}
