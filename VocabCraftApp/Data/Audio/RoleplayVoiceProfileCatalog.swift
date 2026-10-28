import Foundation

public enum RoleplayVoiceProfileCatalog: Sendable {
    public static let defaultProfile = RoleplayVoiceProfile(
        id: "systemAuto",
        displayNameKey: "app.settings.voice.auto_persona",
        gender: .neutral,
        locale: "en-US",
        engine: .appleEnhanced,
        qualityDescriptionKey: "app.settings.voice.quality_apple",
        sampleText: "Hello! I am ready to practice English conversation with you."
    )

    public static let allProfiles: [RoleplayVoiceProfile] = [
        defaultProfile,
        RoleplayVoiceProfile(
            id: "apple-ava",
            displayNameKey: "Ava",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hi! I'm Ava. Let's practice English together.",
            appleVoiceIdentifier: "ava"
        ),
        RoleplayVoiceProfile(
            id: "apple-zoe",
            displayNameKey: "Zoe",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hey there! I'm Zoe. Ready when you are!",
            appleVoiceIdentifier: "zoe"
        ),
        RoleplayVoiceProfile(
            id: "apple-samantha",
            displayNameKey: "Samantha",
            gender: .female,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hello! I'm Samantha. How can I help you practice today?",
            appleVoiceIdentifier: "samantha"
        ),
        RoleplayVoiceProfile(
            id: "apple-daniel",
            displayNameKey: "Daniel",
            gender: .male,
            locale: "en-GB",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Good day! I'm Daniel. It's a pleasure to speak with you.",
            appleVoiceIdentifier: "daniel"
        ),
        RoleplayVoiceProfile(
            id: "apple-oliver",
            displayNameKey: "Oliver",
            gender: .male,
            locale: "en-GB",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hello! I'm Oliver. Let's have a great chat.",
            appleVoiceIdentifier: "oliver"
        ),
        RoleplayVoiceProfile(
            id: "apple-nathan",
            displayNameKey: "Nathan",
            gender: .male,
            locale: "en-US",
            engine: .appleEnhanced,
            qualityDescriptionKey: "app.settings.voice.quality_apple",
            sampleText: "Hey, I'm Nathan. Let's get right into our conversation.",
            appleVoiceIdentifier: "nathan"
        ),
        RoleplayVoiceProfile(
            id: "gemini-aoede",
            displayNameKey: "Aoede",
            gender: .female,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "app.settings.voice.quality_gemini",
            sampleText: "Hi! I'm Aoede. Let's have an authentic conversation.",
            geminiPersona: .friendlyFemale
        ),
        RoleplayVoiceProfile(
            id: "gemini-puck",
            displayNameKey: "Puck",
            gender: .male,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "app.settings.voice.quality_gemini",
            sampleText: "Hey there! I'm Puck. Ready to talk about anything.",
            geminiPersona: .friendlyMale
        ),
        RoleplayVoiceProfile(
            id: "gemini-charon",
            displayNameKey: "Charon",
            gender: .male,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "app.settings.voice.quality_gemini",
            sampleText: "Welcome. I'm Charon. I'm here to practice with you.",
            geminiPersona: .authoritativeMale
        ),
        RoleplayVoiceProfile(
            id: "gemini-kore",
            displayNameKey: "Kore",
            gender: .female,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "app.settings.voice.quality_gemini",
            sampleText: "Hello! I'm Kore. Wonderful to speak with you today.",
            geminiPersona: .expressiveFemale
        ),
        RoleplayVoiceProfile(
            id: "kokoro-friendly-female",
            displayNameKey: "Nova",
            gender: .female,
            locale: "en-US",
            engine: .kokoroNeural,
            qualityDescriptionKey: "app.settings.voice.quality_kokoro",
            sampleText: "Hi, I'm Nova. I can't wait to practice English with you today.",
            geminiPersona: .friendlyFemale
        ),
        RoleplayVoiceProfile(
            id: "kokoro-authoritative-male",
            displayNameKey: "Orion",
            gender: .male,
            locale: "en-US",
            engine: .kokoroNeural,
            qualityDescriptionKey: "app.settings.voice.quality_kokoro",
            sampleText: "Hello. I'm Orion. Let's focus and have a great conversation.",
            geminiPersona: .authoritativeMale
        )
    ]

    public static func profile(for id: String) -> RoleplayVoiceProfile? {
        allProfiles.first(where: { $0.id == id }) ?? defaultProfile
    }
}
