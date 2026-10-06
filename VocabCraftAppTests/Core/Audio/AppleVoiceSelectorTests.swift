import AVFoundation
import Testing
@testable import VocabCraftApp

@Suite("Apple Voice Selector Tests")
struct AppleVoiceSelectorTests {
    @Test("Verify blacklisted novelty/distorted voices are rejected")
    func test_blacklistedVoices_rejected() {
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Albert"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "albert"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "ALBERT"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Bad News"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Fred"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Eddy"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Grandpa"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Grandma"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Whisper"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Zarvox"))
        #expect(AppleVoiceSelector.isBlacklisted(voiceName: "Boing"))
        #expect(!AppleVoiceSelector.isBlacklisted(voiceName: "Samantha"))
        #expect(!AppleVoiceSelector.isBlacklisted(voiceName: "Ava"))
        #expect(!AppleVoiceSelector.isBlacklisted(voiceName: "Zoe"))
    }

    @Test("Verify voice resolver prioritizes higher quality and whitelisted voices")
    func test_resolveBestVoice_prioritizesCorrectly() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let resolved = AppleVoiceSelector.resolveBestVoice(for: "en-US", availableVoices: voices)

        #expect(resolved != nil)
        if let resolved {
            #expect(!AppleVoiceSelector.isBlacklisted(voiceName: resolved.name))
        }
    }

    @Test("Verify voice resolver fallback when available voices is empty")
    func test_resolveBestVoice_fallbackWhenAvailableEmpty() {
        let resolved = AppleVoiceSelector.resolveBestVoice(for: "en-US", availableVoices: [])
        #expect(resolved != nil)
        #expect(resolved?.language.hasPrefix("en") == true)
    }

    @Test("Verify caching and cache clearing")
    func test_resolveBestVoice_cachingAndClearCache() {
        AppleVoiceSelector.clearCache()
        let voice1 = AppleVoiceSelector.resolveBestVoice(for: "en-US")
        let voice2 = AppleVoiceSelector.resolveBestVoice(for: "en-US")

        #expect(voice1 != nil)
        #expect(voice1 == voice2)

        AppleVoiceSelector.clearCache()
        let voice3 = AppleVoiceSelector.resolveBestVoice(for: "en-US")
        #expect(voice3 != nil)
        #expect(voice3?.identifier == voice1?.identifier)
    }

    @Test("Verify concurrent resolution safety")
    func test_concurrentAccess() async {
        AppleVoiceSelector.clearCache()
        await withTaskGroup(of: AVSpeechSynthesisVoice?.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    AppleVoiceSelector.resolveBestVoice(for: "en-US")
                }
            }
            for await voice in group {
                #expect(voice != nil)
            }
        }
    }

    @Test("Verify curated whitelist contains expected warm voices")
    func test_curatedWhitelistContainsExpectedWarmVoices() {
        #expect(AppleVoiceSelector.curatedWhitelist.contains("ava"))
        #expect(AppleVoiceSelector.curatedWhitelist.contains("zoe"))
        #expect(AppleVoiceSelector.curatedWhitelist.contains("allison"))
        #expect(AppleVoiceSelector.curatedWhitelist.contains("samantha"))
        #expect(AppleVoiceSelector.curatedWhitelist.contains("nathan"))
        #expect(AppleVoiceSelector.curatedWhitelist.contains("daniel"))
    }

    @Test("Verify en-GB voice is preferred over en-US voice for en-GB locale when both have same quality")
    func test_resolveBestVoice_prefersExactLocaleOverUS() {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let usVoice = voices.first(where: {
            $0.language == "en-US" && !AppleVoiceSelector.isBlacklisted(voiceName: $0.name)
        })
        let gbVoice = voices.first(where: {
            $0.language == "en-GB" && !AppleVoiceSelector.isBlacklisted(voiceName: $0.name)
        })

        guard let usVoice, let gbVoice else {
            return
        }

        let resolved = AppleVoiceSelector.resolveBestVoice(for: "en-GB", availableVoices: [usVoice, gbVoice])
        #expect(resolved?.language == "en-GB")
        #expect(resolved?.identifier == gbVoice.identifier)
    }

    @Test("Verify voice resolver selects appropriate voice based on persona")
    func test_resolveBestVoice_withPersona() {
        AppleVoiceSelector.clearCache()
        let femaleVoice = AppleVoiceSelector.resolveBestVoice(for: "en-US", persona: .friendlyFemale)
        let maleVoice = AppleVoiceSelector.resolveBestVoice(for: "en-US", persona: .friendlyMale)

        #expect(femaleVoice != nil)
        #expect(maleVoice != nil)
    }
}
