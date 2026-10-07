import AVFoundation
import Foundation
import Testing
@testable import VocabCraftApp

final class MockKokoroAudioEngine: KokoroAudioSynthesizing, @unchecked Sendable {
    var isSpeaking: Bool = false
    var isReady: Bool = true
    var synthesizeCallCount: Int = 0
    var lastSynthesizedText: String?
    var lastPersona: VoicePersona?

    func synthesizeAndPlay(text: String, persona: VoicePersona) async throws {
        synthesizeCallCount += 1
        lastSynthesizedText = text
        lastPersona = persona
        isSpeaking = true
    }

    func stop() {
        isSpeaking = false
    }
}

@Suite("KokoroTTSEngine Router Tests")
struct KokoroTTSEngineRouterTests {
    @Test("TextToSpeechService routes conversation to Kokoro engine when ready")
    @MainActor
    func testRoutesToKokoroWhenReady() async {
        let mockKokoro = MockKokoroAudioEngine()
        let mockApple = AppleEnhancedTTSEngine()
        let coordinator = AudioSessionCoordinator()
        let tts = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            appleEngine: mockApple,
            kokoroEngine: mockKokoro
        )

        await tts.speakAsync(text: "Hello from Kokoro!", context: .conversation(persona: .friendlyFemale, locale: "en-US"))

        #expect(mockKokoro.synthesizeCallCount == 1)
        #expect(mockKokoro.lastSynthesizedText == "Hello from Kokoro!")
        #expect(mockKokoro.lastPersona == .friendlyFemale)
        #expect(tts.lastActiveEngine == .kokoro)
    }

    @Test("TextToSpeechService falls back to AppleEngine when Kokoro is not ready")
    @MainActor
    func testFallbackToAppleWhenKokoroNotReady() async {
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let mockApple = AppleEnhancedTTSEngine()
        let coordinator = AudioSessionCoordinator()
        let tts = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            appleEngine: mockApple,
            kokoroEngine: mockKokoro
        )

        await tts.speakAsync(text: "Fallback test", context: .conversation(persona: .friendlyFemale, locale: "en-US"))

        #expect(mockKokoro.synthesizeCallCount == 0)
        #expect(tts.lastActiveEngine == .apple)
    }
}

@Suite("KokoroTTSEngine Direct Tests")
struct KokoroTTSEngineDirectTests {
    @Test("KokoroTTSEngine maps persona to voice profile correctly")
    @MainActor
    func testVoiceProfileMapping() {
        let engine = KokoroTTSEngine()
        #expect(engine.voiceProfile(for: .friendlyFemale) == "af_bella")
        #expect(engine.voiceProfile(for: .friendlyMale) == "am_adam")
        #expect(engine.voiceProfile(for: .authoritativeMale) == "am_michael")
        #expect(engine.voiceProfile(for: .expressiveFemale) == "af_sarah")
    }

    @Test("KokoroTTSEngine synthesizeAndPlay throws when model is unavailable")
    @MainActor
    func testSynthesizeAndPlayDelegatesCleanly() async throws {
        let appleEngine = AppleEnhancedTTSEngine()
        let engine = KokoroTTSEngine(appleEngine: appleEngine)
        await #expect(throws: Error.self) {
            try await engine.synthesizeAndPlay(text: "Hello, nice to meet you!", persona: .friendlyMale)
        }
    }
}
