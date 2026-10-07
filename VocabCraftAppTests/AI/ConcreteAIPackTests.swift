import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Concrete AI Packs Tests")
@MainActor
struct ConcreteAIPackTests {
    @Test("GeminiCloudPack reports needsApiKey when key is missing")
    func testGeminiPackNeedsApiKey() {
        let suiteName = "test_gemini_pack_\(UUID().uuidString)"
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: suiteName)!)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)
        #expect(pack.status == .needsApiKey(providerName: "Google Gemini"))
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("GeminiCloudPack reports ready when key is present")
    func testGeminiPackReady() {
        let suiteName = "test_gemini_pack_ready_\(UUID().uuidString)"
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: suiteName)!)
        store.geminiApiKey = "test-api-key-123"
        let pack = GeminiCloudPack(settingsStore: store)
        #expect(pack.status == .ready)
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("GeminiCloudPack resolves providers correctly when configured")
    func testGeminiPackResolvesProviders() throws {
        let suiteName = "test_gemini_pack_resolve_\(UUID().uuidString)"
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: suiteName)!)
        store.geminiApiKey = "test-api-key-123"
        let pack = GeminiCloudPack(settingsStore: store)
        #expect(pack.identifier == .geminiCloud)
        #expect(pack.supportedVoices.count >= 2)
        #expect(pack.defaultVoice.id == "gemini-aoede")

        let llm = try pack.makeLLMProvider()
        #expect(llm.providerIdentifier == "gemini-flash")

        let tts = try pack.makeTTSEngine()
        #expect(tts.engineName == "Gemini Studio TTS")

        let stt = try pack.makeSTTEngine()
        #expect(stt.engineName == "Apple Speech Recognition")
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("GeminiCloudPack fails fast when resolving without API key")
    func testGeminiPackResolvingWithoutKeyThrows() {
        let suiteName = "test_gemini_pack_nokey_\(UUID().uuidString)"
        let store = UserSettingsStore(userDefaults: UserDefaults(suiteName: suiteName)!)
        store.geminiApiKey = ""
        let pack = GeminiCloudPack(settingsStore: store)

        #expect(throws: AIPackError.apiKeyRequired(providerName: "Google Gemini")) {
            try pack.makeLLMProvider()
        }
        #expect(throws: AIPackError.apiKeyRequired(providerName: "Google Gemini")) {
            try pack.makeTTSEngine()
        }
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
    }

    @Test("OfflineAIPack reports needsDownload when models are not downloaded")
    func testOfflinePackNeedsDownload() {
        let pack = OfflineAIPack(
            isKokoroReady: { false },
            isWhisperReady: { false }
        )
        if case .needsDownload = pack.status {
            // Success
        } else {
            Issue.record("Expected .needsDownload status for OfflineAIPack")
        }
    }

    @Test("OfflineAIPack reports ready when both models are ready")
    func testOfflinePackReady() {
        let pack = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { true }
        )
        #expect(pack.status == .ready)
        #expect(pack.identifier == .offlineAI)
        #expect(pack.defaultVoice.id == "kokoro-heart")
    }

    @Test("OfflineAIPack fails fast when creating engines without downloaded models")
    func testOfflinePackThrowsWhenEnginesNotDownloaded() {
        let pack = OfflineAIPack(
            isKokoroReady: { false },
            isWhisperReady: { false }
        )
        #expect(throws: AIPackError.downloadRequired(packName: "Kokoro TTS", sizeDescription: "~350MB")) {
            try pack.makeTTSEngine()
        }
        #expect(throws: AIPackError.downloadRequired(packName: "WhisperKit", sizeDescription: "~150MB")) {
            try pack.makeSTTEngine()
        }
    }

    @Test("OfflineAIPack provides working engines when models are downloaded")
    func testOfflinePackProvidesEnginesWhenReady() throws {
        let pack = OfflineAIPack(
            isKokoroReady: { true },
            isWhisperReady: { true }
        )
        let tts = try pack.makeTTSEngine()
        #expect(tts.engineName == "Kokoro Neural TTS")
        let stt = try pack.makeSTTEngine()
        #expect(stt.engineName == "WhisperKit On-Device STT")
    }

    @Test("AppleDefaultPack provides default configuration and system engines")
    func testAppleDefaultPackConfiguration() throws {
        let pack = AppleDefaultPack()
        #expect(pack.identifier == .appleDefault)
        #expect(pack.defaultVoice.id == "apple-default-female")

        let tts = try pack.makeTTSEngine()
        #expect(tts.engineName == "Apple Enhanced TTS")
        let stt = try pack.makeSTTEngine()
        #expect(stt.engineName == "Apple Speech Recognition")
    }

    @Test("AppleFoundationModelLLMProvider identifies correctly and handles unsupported OS")
    func testAppleFoundationModelProvider() async {
        let provider = AppleFoundationModelLLMProvider()
        #expect(provider.providerIdentifier == "apple-foundation-models")
        do {
            let _: String = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "hi")],
                systemPrompt: "sys",
                responseSchema: String.self
            )
            Issue.record("Expected sendStructuredMessage to throw")
        } catch let error as AIPackError {
            if case .deviceNotSupported = error {
                // Success
            } else {
                Issue.record("Expected .deviceNotSupported, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
