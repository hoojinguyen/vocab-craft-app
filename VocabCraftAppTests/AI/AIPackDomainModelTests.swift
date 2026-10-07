import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AI Pack Domain Models Tests")
struct AIPackDomainModelTests {
    @Test("AIPackIdentifier has all required Phase 1 and future cases")
    func testPackIdentifiers() {
        let cases = AIPackIdentifier.allCases
        #expect(cases.contains(.appleDefault))
        #expect(cases.contains(.offlineAI))
        #expect(cases.contains(.geminiCloud))
        #expect(cases.contains(.groqCloud))
        #expect(cases.contains(.openAICloud))
    }

    @Test("AIPackStatus equality and representation")
    func testPackStatus() {
        let ready = AIPackStatus.ready
        let needsKey = AIPackStatus.needsApiKey(providerName: "Gemini")
        let needsDownload = AIPackStatus.needsDownload(sizeDescription: "~500MB")
        let unavailable = AIPackStatus.unavailable(reason: "Requires iOS 26+")

        #expect(ready != needsKey)
        #expect(needsKey == .needsApiKey(providerName: "Gemini"))
        #expect(needsDownload == .needsDownload(sizeDescription: "~500MB"))
        #expect(unavailable == .unavailable(reason: "Requires iOS 26+"))
    }

    @Test("VoiceConfiguration maps gender and style")
    func testVoiceConfiguration() {
        let config = VoiceConfiguration(
            gender: .female,
            style: .friendly,
            locale: "en-US"
        )
        #expect(config.gender == .female)
        #expect(config.style == .friendly)
        #expect(config.locale == "en-US")
    }

    @Test("VoiceCallState contains error case")
    func testVoiceCallStateErrorCase() {
        let errorState = VoiceCallState.error(AIPackError.networkUnavailable)
        if case .error(let err) = errorState {
            #expect(err == .networkUnavailable)
        } else {
            Issue.record("Expected .error case in VoiceCallState")
        }
    }

    @Test("AIPackError localized keys are properly mapped")
    func testAIPackErrorLocalizedKeys() {
        #expect(AIPackError.apiKeyRequired(providerName: "Gemini").localizedKey == "app.ai.error.api_key_required")
        #expect(AIPackError.downloadRequired(packName: "Offline", sizeDescription: "500MB").localizedKey == "app.ai.error.download_required")
        #expect(AIPackError.deviceNotSupported(reason: "No NPU").localizedKey == "app.ai.error.device_not_supported")
        #expect(AIPackError.noPackAvailable.localizedKey == "app.ai.error.no_pack_available")
        #expect(AIPackError.llmFailed(packName: "Gemini", underlyingMessage: "Timeout").localizedKey == "app.ai.error.llm_failed")
        #expect(AIPackError.ttsFailed(packName: "Apple", underlyingMessage: "Audio error").localizedKey == "app.ai.error.tts_failed")
        #expect(AIPackError.sttFailed(packName: "Apple", underlyingMessage: "Permission").localizedKey == "app.ai.error.stt_failed")
        #expect(AIPackError.networkUnavailable.localizedKey == "app.ai.error.network_unavailable")
    }

    @Test("VoiceProfile creation and property mapping")
    func testVoiceProfile() {
        let config = VoiceConfiguration(gender: .male, style: .calm, locale: "en-US")
        let profile = VoiceProfile(
            id: "voice-1",
            displayName: "Calm Male",
            voiceConfig: config,
            sampleText: "Hello world"
        )
        #expect(profile.id == "voice-1")
        #expect(profile.displayName == "Calm Male")
        #expect(profile.voiceConfig == config)
        #expect(profile.sampleText == "Hello world")
    }

    @Test("AIPackProtocol mock implementation satisfies protocol contract")
    func testAIPackProtocolConformance() throws {
        struct MockTTS: TTSEngineProtocol {
            var engineName: String = "MockTTS"
            var isReady: Bool = true
            func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {}
            func stop() {}
        }

        struct MockSTT: STTEngineProtocol {
            var engineName: String = "MockSTT"
            var isReady: Bool = true
            func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
                AsyncThrowingStream { $0.finish() }
            }
            func stopRecognition() {}
        }

        struct MockPack: AIPackProtocol {
            var identifier: AIPackIdentifier = .appleDefault
            var displayName: String = "Apple Default"
            var packDescription: String = "Built-in AI"
            var status: AIPackStatus = .ready
            var supportedVoices: [VoiceProfile] = []
            var defaultVoice: VoiceProfile = VoiceProfile(
                id: "default",
                displayName: "Default",
                voiceConfig: VoiceConfiguration(gender: .female, style: .friendly),
                sampleText: "Hi"
            )

            func makeLLMProvider() throws(AIPackError) -> any LLMProviderProtocol {
                throw AIPackError.noPackAvailable
            }

            func makeTTSEngine() throws(AIPackError) -> any TTSEngineProtocol {
                MockTTS()
            }

            func makeSTTEngine() throws(AIPackError) -> any STTEngineProtocol {
                MockSTT()
            }
        }

        let pack = MockPack()
        #expect(pack.identifier == .appleDefault)
        #expect(pack.status == .ready)
        let tts = try pack.makeTTSEngine()
        #expect(tts.engineName == "MockTTS")
        let stt = try pack.makeSTTEngine()
        #expect(stt.engineName == "MockSTT")
        #expect(throws: AIPackError.self) {
            try pack.makeLLMProvider()
        }
    }
}
