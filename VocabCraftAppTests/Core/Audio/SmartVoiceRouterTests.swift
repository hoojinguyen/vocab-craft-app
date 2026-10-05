import Foundation
import Testing
@testable import VocabCraftApp

@MainActor
private final class MockGeminiAudioEngine: GeminiAudioSynthesizing, @unchecked Sendable {
    var synthesizeCallCount = 0
    var lastSynthesizedText: String?
    var lastPersona: VoicePersona?
    var lastApiKey: String?
    var shouldThrowError = false
    var isSpeaking = false
    var stopCallCount = 0

    func synthesizeAndPlay(text: String, persona: VoicePersona, apiKey: String) async throws {
        synthesizeCallCount += 1
        lastSynthesizedText = text
        lastPersona = persona
        lastApiKey = apiKey
        if shouldThrowError {
            throw URLError(.badServerResponse)
        }
    }

    func stop() {
        stopCallCount += 1
        isSpeaking = false
    }
}

@Suite("Smart Voice Router & Fallback Tests")
struct SmartVoiceRouterTests {
    @Test("Verify pronunciation context always routes to Apple enhanced engine")
    @MainActor
    func test_pronunciationRouting_usesAppleEngine() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            apiKeyProvider: { "valid-gemini-key" }
        )

        await service.speakAsync(text: "Ambition", context: .pronunciation(locale: "en-US"), rate: 1.0)
        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .apple)
        #expect(mockGemini.synthesizeCallCount == 0)
    }

    @Test("Verify conversation context without API key falls back immediately to Apple engine")
    @MainActor
    func test_conversationRouting_fallbackToApple() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            apiKeyProvider: { nil }
        )

        await service.speakAsync(text: "Hello! How can I help you today?", context: .conversation(persona: .friendlyFemale), rate: 1.0)
        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .apple)
        #expect(mockGemini.synthesizeCallCount == 0)
    }

    @Test("Verify conversation context with API key routes to Gemini engine")
    @MainActor
    func test_conversationRouting_usesGeminiEngineWhenKeyPresent() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            apiKeyProvider: { "valid-api-key" }
        )

        await service.speakAsync(text: "Good morning! Ready to practice?", context: .conversation(persona: .friendlyMale), rate: 1.0)
        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .gemini)
        #expect(mockGemini.synthesizeCallCount == 1)
        #expect(mockGemini.lastSynthesizedText == "Good morning! Ready to practice?")
        #expect(mockGemini.lastPersona == .friendlyMale)
        #expect(mockGemini.lastApiKey == "valid-api-key")
    }

    @Test("Verify conversation context falls back to Apple engine when Gemini throws error")
    @MainActor
    func test_conversationRouting_fallsBackToAppleWhenGeminiFails() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        mockGemini.shouldThrowError = true

        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            apiKeyProvider: { "valid-api-key" }
        )

        await service.speakAsync(text: "This request will fail in Gemini", context: .conversation(persona: .authoritativeMale), rate: 1.0)
        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .apple)
        #expect(mockGemini.synthesizeCallCount == 1)
    }

    @Test("Verify stop cancels both engines and resets speaking state")
    @MainActor
    func test_stop_cancelsBothEngines() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini
        )

        service.speak(text: "Hello there", context: .conversation(persona: .expressiveFemale))
        service.stop()

        #expect(!service.isSpeaking)
        #expect(mockGemini.stopCallCount >= 1)
    }

    @Test("Verify backward compatibility of speak and speakAsync without context parameter")
    @MainActor
    func test_backwardCompatibility_pronunciationDefault() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            apiKeyProvider: { "valid-api-key" }
        )

        await service.speakAsync(text: "Legacy call", rate: 0.5, locale: "en-US")
        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .apple)
        #expect(mockGemini.synthesizeCallCount == 0)
    }
}
