import Foundation
import Testing
@testable import VocabCraftApp

@Suite("RoleplayVoiceProfileCatalog Tests")
struct RoleplayVoiceProfileCatalogTests {
    @Test("Catalog provides default auto profile and curated Apple and Gemini profiles")
    func testCatalogProfiles() {
        let profiles = RoleplayVoiceProfileCatalog.allProfiles
        #expect(!profiles.isEmpty)
        #expect(profiles.contains(where: { $0.id == "systemAuto" }))
        #expect(profiles.contains(where: { $0.id == "apple-ava" }))
        #expect(profiles.contains(where: { $0.id == "apple-daniel" }))
        #expect(profiles.contains(where: { $0.id == "gemini-aoede" }))

        let defaultProfile = RoleplayVoiceProfileCatalog.defaultProfile
        #expect(defaultProfile.id == "systemAuto")

        let daniel = RoleplayVoiceProfileCatalog.profile(for: "apple-daniel")
        #expect(daniel?.gender == .male)
        #expect(daniel?.engine == .appleEnhanced)

        let unknown = RoleplayVoiceProfileCatalog.profile(for: "unknown-id")
        #expect(unknown?.id == "systemAuto")
    }

    @Test("RoleplayVoiceProfile entity equality, hashable, and properties")
    func testRoleplayVoiceProfileProperties() {
        let profile1 = RoleplayVoiceProfile(
            id: "test-id",
            displayNameKey: "Test",
            gender: .female,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "Quality",
            sampleText: "Sample",
            appleVoiceIdentifier: nil,
            geminiPersona: .friendlyFemale
        )
        let profile2 = RoleplayVoiceProfile(
            id: "test-id",
            displayNameKey: "Test",
            gender: .female,
            locale: "en-US",
            engine: .geminiNeural,
            qualityDescriptionKey: "Quality",
            sampleText: "Sample",
            appleVoiceIdentifier: nil,
            geminiPersona: .friendlyFemale
        )

        #expect(profile1 == profile2)
        #expect(profile1.hashValue == profile2.hashValue)
        #expect(profile1.gender == .female)
        #expect(profile1.engine == .geminiNeural)
        #expect(profile1.geminiPersona == .friendlyFemale)
    }
}
