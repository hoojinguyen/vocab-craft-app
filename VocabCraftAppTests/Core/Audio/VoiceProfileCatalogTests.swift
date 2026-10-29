import Testing
@testable import VocabCraftApp

@Suite("Voice profile catalog")
struct VoiceProfileCatalogTests {
    @Test func containsOnlyAppleVoices() {
        #expect(VoiceProfileCatalog.profiles.allSatisfy { $0.engine == .system || $0.engine == .appleEnhanced })
        #expect(VoiceProfileCatalog.profiles.count == 7)
    }

    @Test func namedAppleProfilesRemainSelectable() {
        for id in ["apple-ava", "apple-zoe", "apple-samantha", "apple-daniel", "apple-oliver", "apple-nathan"] {
            let profile = VoiceProfileCatalog.resolve(id: id)
            #expect(profile.id == id)
            #expect(profile.engine == .appleEnhanced)
            #expect(profile.appleVoiceIdentifier != nil)
        }
        #expect(VoiceProfileCatalog.defaultProfile.engine == .system)
    }

    @Test func unknownLegacyIdFallsBackToAuto() {
        #expect(VoiceProfileCatalog.resolve(id: "gemini_kore").id == VoiceProfileCatalog.defaultProfile.id)
        #expect(VoiceProfileCatalog.resolve(id: "kokoro_af_heart").id == "systemAuto")
    }
}
