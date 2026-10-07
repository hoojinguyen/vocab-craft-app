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
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
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
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
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
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
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

    @Test("Verify conversation context does not fall back to Apple engine when Gemini throws error")
    @MainActor
    func test_conversationRouting_fallsBackToAppleWhenGeminiFails() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        mockGemini.shouldThrowError = true
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false

        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
            apiKeyProvider: { "valid-api-key" }
        )

        await service.speakAsync(text: "This request will fail in Gemini", context: .conversation(persona: .authoritativeMale), rate: 1.0)
        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .gemini)
        #expect(mockGemini.synthesizeCallCount == 1)
    }

    @Test("Verify stop cancels both engines and resets speaking state")
    @MainActor
    func test_stop_cancelsBothEngines() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let mockKokoro = MockKokoroAudioEngine()
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro
        )

        service.speak(text: "Hello there", context: .conversation(persona: .expressiveFemale))
        service.stop()

        #expect(!service.isSpeaking)
        #expect(mockGemini.stopCallCount >= 1)
        #expect(mockKokoro.isSpeaking == false)
    }

    @Test("Verify backward compatibility of speak and speakAsync without context parameter")
    @MainActor
    func test_backwardCompatibility_pronunciationDefault() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
            apiKeyProvider: { "valid-api-key" }
        )

        await service.speakAsync(text: "Legacy call", rate: 0.5, locale: "en-US")
        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .apple)
        #expect(mockGemini.synthesizeCallCount == 0)
    }

    @Test("Verify synchronous speak with conversation context routes to Gemini without self-cancellation")
    @MainActor
    func test_synchronousSpeak_conversation_executesWithoutSelfCancellation() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
            apiKeyProvider: { "valid-api-key" }
        )

        service.speak(text: "Hello from sync speak!", context: .conversation(persona: .friendlyFemale))
        #expect(service.isSpeaking)

        // Wait for spawned playbackStartTask to complete
        await service.playbackStartTask?.value

        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .gemini)
        #expect(mockGemini.synthesizeCallCount == 1)
        #expect(mockGemini.lastSynthesizedText == "Hello from sync speak!")
        #expect(mockGemini.lastPersona == .friendlyFemale)
        #expect(mockGemini.lastApiKey == "valid-api-key")
    }

    @Test("Verify synchronous speak with pronunciation context cleans up state in test environment")
    @MainActor
    func test_synchronousSpeak_pronunciation_cleansUpInTestEnvironment() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let service = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
            apiKeyProvider: { "valid-api-key" }
        )

        service.speak(text: "Pronounce word", context: .pronunciation(locale: "en-US"))
        #expect(service.isSpeaking)

        await service.playbackStartTask?.value

        #expect(!service.isSpeaking)
        #expect(service.lastActiveEngine == .apple)
        #expect(mockGemini.synthesizeCallCount == 0)
    }

    @Test("TextToSpeechService routes conversation to selected Apple Enhanced profile voice")
    @MainActor
    func testRoutingWithSelectedAppleProfile() async {
        let defaults = UserDefaults(suiteName: "test_tts_profile_\(UUID().uuidString)")!
        let store = UserSettingsStore(defaults: defaults)
        store.roleplayVoiceId = "apple-daniel"
        store.roleplaySpeechRate = 1.10
        store.roleplaySpeechPitch = 0.90

        let coordinator = AudioSessionCoordinator()
        let appleEngine = AppleEnhancedTTSEngine()
        let tts = TextToSpeechService(
            settingsStore: store,
            audioSessionCoordinator: coordinator,
            appleEngine: appleEngine
        )

        await tts.speakAsync(text: "Good day, let's practice.", context: .conversation(persona: .friendlyMale, locale: "en-GB"))
        #expect(tts.lastActiveEngine == .apple)
    }

    @Test("TextToSpeechService previewVoice executes cleanly for Apple Enhanced profile")
    @MainActor
    func testPreviewVoiceAppleProfile() async {
        let coordinator = AudioSessionCoordinator()
        let appleEngine = AppleEnhancedTTSEngine()
        let tts = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            appleEngine: appleEngine
        )

        let profile = RoleplayVoiceProfileCatalog.profile(for: "apple-ava")!
        await tts.previewVoice(profile: profile, rate: 1.0, pitch: 1.0)
        #expect(tts.lastActiveEngine == .apple)
    }

    @Test("TextToSpeechService routes conversation to selected Gemini Neural profile when API key present")
    @MainActor
    func testRoutingWithSelectedGeminiProfile() async {
        let defaults = UserDefaults(suiteName: "test_tts_profile_gemini_\(UUID().uuidString)")!
        let store = UserSettingsStore(defaults: defaults)
        store.roleplayVoiceId = "gemini-aoede"

        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let tts = TextToSpeechService(
            settingsStore: store,
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
            apiKeyProvider: { "valid-key" }
        )

        await tts.speakAsync(text: "Hello from Aoede", context: .conversation(persona: .friendlyMale))
        #expect(tts.lastActiveEngine == .gemini)
        #expect(mockGemini.synthesizeCallCount == 1)
        #expect(mockGemini.lastPersona == .friendlyFemale)
    }

    @Test("TextToSpeechService previewVoice routes to Gemini Neural when API key present")
    @MainActor
    func testPreviewVoiceGeminiProfile() async {
        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let tts = TextToSpeechService(
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            apiKeyProvider: { "valid-key" }
        )

        let profile = RoleplayVoiceProfileCatalog.profile(for: "gemini-puck")!
        await tts.previewVoice(profile: profile, rate: 1.0, pitch: 1.0)
        #expect(tts.lastActiveEngine == .gemini)
        #expect(mockGemini.synthesizeCallCount == 1)
        #expect(mockGemini.lastPersona == .friendlyMale)
    }

    @Test("TextToSpeechService conversation routing with systemAuto uses default behavior")
    @MainActor
    func testRoutingWithSystemAutoProfile() async {
        let defaults = UserDefaults(suiteName: "test_tts_profile_auto_\(UUID().uuidString)")!
        let store = UserSettingsStore(defaults: defaults)
        store.roleplayVoiceId = "systemAuto"

        let coordinator = AudioSessionCoordinator()
        let mockGemini = MockGeminiAudioEngine()
        let mockKokoro = MockKokoroAudioEngine()
        mockKokoro.isReady = false
        let tts = TextToSpeechService(
            settingsStore: store,
            audioSessionCoordinator: coordinator,
            geminiEngine: mockGemini,
            kokoroEngine: mockKokoro,
            apiKeyProvider: { "valid-key" }
        )

        await tts.speakAsync(text: "Hello Auto", context: .conversation(persona: .friendlyMale))
        #expect(tts.lastActiveEngine == .gemini)
        #expect(mockGemini.lastPersona == .friendlyMale)
    }
}
