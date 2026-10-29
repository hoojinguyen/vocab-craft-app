import Foundation

public enum VoiceProfileCatalog: Sendable {
    public static let defaultProfile = VoiceProfile(
        id: "systemAuto",
        displayNameKey: "app.settings.voice.auto_persona",
        gender: .neutral,
        locale: "en-US",
        engine: .system,
        qualityDescriptionKey: "app.settings.voice.quality_apple",
        sampleText: String(localized: "app.settings.voice.sample.systemAuto", bundle: .module)
    )

    public static let profiles: [VoiceProfile] = [
        defaultProfile,
        VoiceProfile(
            id: "apple-ava",
            displayNameKey: "app.settings.voice.name.apple_ava",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: String(localized: "app.settings.voice.sample.apple_ava", bundle: .module),
            appleVoiceIdentifier: "ava"
        ),
        VoiceProfile(
            id: "apple-zoe",
            displayNameKey: "app.settings.voice.name.apple_zoe",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: String(localized: "app.settings.voice.sample.apple_zoe", bundle: .module),
            appleVoiceIdentifier: "zoe"
        ),
        VoiceProfile(
            id: "apple-samantha",
            displayNameKey: "app.settings.voice.name.apple_samantha",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: String(localized: "app.settings.voice.sample.apple_samantha", bundle: .module),
            appleVoiceIdentifier: "samantha"
        ),
        VoiceProfile(
            id: "apple-daniel",
            displayNameKey: "app.settings.voice.name.apple_daniel",
            gender: .male,
            locale: "en-GB",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: String(localized: "app.settings.voice.sample.apple_daniel", bundle: .module),
            appleVoiceIdentifier: "daniel"
        ),
        VoiceProfile(
            id: "apple-oliver",
            displayNameKey: "app.settings.voice.name.apple_oliver",
            gender: .male,
            locale: "en-GB",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: String(localized: "app.settings.voice.sample.apple_oliver", bundle: .module),
            appleVoiceIdentifier: "oliver"
        ),
        VoiceProfile(
            id: "apple-nathan",
            displayNameKey: "app.settings.voice.name.apple_nathan",
            gender: .male,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: String(localized: "app.settings.voice.sample.apple_nathan", bundle: .module),
            appleVoiceIdentifier: "nathan"
        )
    ]

    public static func resolve(id: String) -> VoiceProfile {
        profiles.first(where: { $0.id == id }) ?? defaultProfile
    }
}
