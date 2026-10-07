import Foundation
import Testing
@testable import VocabCraftApp

@Suite("TTS & STT Engine Adapter Tests")
struct TTSEngineAdapterTests {
    @Test("AppleTTSEngineAdapter is always ready and identifies correctly")
    func testAppleTTSEngine() {
        let engine = AppleTTSEngineAdapter()
        #expect(engine.engineName == "Apple Enhanced TTS")
        #expect(engine.isReady == true)
    }

    @Test("KokoroTTSEngineAdapter exposes readiness based on underlying model manager")
    func testKokoroTTSEngine() {
        let engine = KokoroTTSEngineAdapter(isReadyProvider: { false })
        #expect(engine.engineName == "Kokoro Neural TTS")
        #expect(engine.isReady == false)
    }

    @Test("KokoroTTSEngineAdapter fails fast when model is not ready")
    func testKokoroTTSEngineNotReadyThrows() async {
        let engine = KokoroTTSEngineAdapter(isReadyProvider: { false })
        let voice = VoiceConfiguration(gender: .male, style: .friendly)
        do {
            try await engine.synthesizeAndPlay(text: "Hello", voice: voice)
            Issue.record("Expected synthesizeAndPlay to throw when not ready")
        } catch let error as AIPackError {
            #expect(error == .ttsFailed(packName: "Kokoro", underlyingMessage: "Model is not loaded"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("GeminiTTSEngineAdapter checks apiKey presence")
    func testGeminiTTSEngine() {
        let engine = GeminiTTSEngineAdapter(apiKey: "valid-key")
        #expect(engine.engineName == "Gemini Studio TTS")
        #expect(engine.isReady == true)

        let emptyEngine = GeminiTTSEngineAdapter(apiKey: "")
        #expect(emptyEngine.isReady == false)
    }

    @Test("GeminiTTSEngineAdapter throws apiKeyRequired when apiKey is empty")
    func testGeminiTTSEngineRequiresAPIKey() async {
        let engine = GeminiTTSEngineAdapter(apiKey: "")
        let voice = VoiceConfiguration(gender: .female, style: .friendly)
        do {
            try await engine.synthesizeAndPlay(text: "Hello", voice: voice)
            Issue.record("Expected synthesizeAndPlay to throw when apiKey is missing")
        } catch let error as AIPackError {
            #expect(error == .apiKeyRequired(providerName: "Gemini"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("AppleSTTEngineAdapter is always ready and identifies correctly")
    func testAppleSTTEngine() {
        let engine = AppleSTTEngineAdapter()
        #expect(engine.engineName == "Apple Speech Recognition")
        #expect(engine.isReady == true)
    }

    @Test("WhisperKitSTTEngineAdapter exposes readiness based on model manager")
    func testWhisperKitSTTEngine() {
        let engine = WhisperKitSTTEngineAdapter(isReadyProvider: { false })
        #expect(engine.engineName == "WhisperKit On-Device STT")
        #expect(engine.isReady == false)

        let readyEngine = WhisperKitSTTEngineAdapter(isReadyProvider: { true })
        #expect(readyEngine.isReady == true)
    }

    @Test("WhisperKitSTTEngineAdapter fails fast when not ready")
    func testWhisperKitSTTEngineNotReadyThrows() async {
        let engine = WhisperKitSTTEngineAdapter(isReadyProvider: { false })
        let stream = engine.startRecognition(locale: "en-US")
        do {
            for try await _ in stream {
                Issue.record("Stream should not yield when not ready")
            }
            Issue.record("Expected stream to throw when not ready")
        } catch let error as AIPackError {
            #expect(error == .sttFailed(packName: "WhisperKit", underlyingMessage: "Model not downloaded"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
