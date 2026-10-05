import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speech Context & Voice Persona Domain Tests")
struct SpeechContextTests {
    @Test("Verify VoicePersona identifiers match expected Gemini voices")
    func test_voicePersona_identifiers() {
        #expect(VoicePersona.friendlyFemale.rawValue == "Aoede")
        #expect(VoicePersona.friendlyMale.rawValue == "Puck")
        #expect(VoicePersona.authoritativeMale.rawValue == "Charon")
        #expect(VoicePersona.expressiveFemale.rawValue == "Kore")
        #expect(VoicePersona.allCases.count == 4)
    }

    @Test("Verify VoicePersona Codable roundtrip")
    func test_voicePersona_codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for persona in VoicePersona.allCases {
            let data = try encoder.encode(persona)
            let decoded = try decoder.decode(VoicePersona.self, from: data)
            #expect(decoded == persona)
        }
    }

    @Test("Verify SpeechContext default values and equality")
    func test_speechContext_defaults() {
        let pronunciation = SpeechContext.pronunciation()
        let conversation = SpeechContext.conversation(persona: .friendlyFemale)
        let conversationDefault = SpeechContext.conversation()

        #expect(pronunciation == .pronunciation(locale: "en-US"))
        #expect(conversationDefault == .conversation(persona: .friendlyFemale, locale: "en-US"))
        #expect(conversation == conversationDefault)
        #expect(conversation != pronunciation)
    }

    @MainActor
    private final class MockLegacyTTS: TextToSpeechProtocol {
        var isSpeaking: Bool = false
        var lastSpokenText: String?
        var lastSpokenRate: Float?
        var lastSpokenLocale: String?

        var lastAsyncSpokenText: String?
        var lastAsyncSpokenRate: Float?
        var lastAsyncSpokenLocale: String?

        func speak(text: String, rate: Float, locale: String) {
            lastSpokenText = text
            lastSpokenRate = rate
            lastSpokenLocale = locale
        }

        func speakAsync(text: String, rate: Float, locale: String) async {
            lastAsyncSpokenText = text
            lastAsyncSpokenRate = rate
            lastAsyncSpokenLocale = locale
        }

        func stop() {
            isSpeaking = false
        }
    }

    @Test("Verify TextToSpeechProtocol context default forwarding")
    @MainActor
    func test_ttsProtocol_contextForwarding() async {
        let mock = MockLegacyTTS()

        mock.speak(text: "apple", context: .pronunciation(locale: "en-US"))
        #expect(mock.lastSpokenText == "apple")
        #expect(mock.lastSpokenRate == 1.0)
        #expect(mock.lastSpokenLocale == "en-US")

        mock.speak(text: "Good morning", context: .conversation(persona: .friendlyMale, locale: "en-GB"), rate: 0.8)
        #expect(mock.lastSpokenText == "Good morning")
        #expect(mock.lastSpokenRate == 0.8)
        #expect(mock.lastSpokenLocale == "en-GB")

        await mock.speakAsync(text: "banana", context: .pronunciation(locale: "en-AU"))
        #expect(mock.lastAsyncSpokenText == "banana")
        #expect(mock.lastAsyncSpokenRate == 1.0)
        #expect(mock.lastAsyncSpokenLocale == "en-AU")

        await mock.speakAsync(text: "How are you?", context: .conversation(persona: .authoritativeMale, locale: "en-US"), rate: 1.2)
        #expect(mock.lastAsyncSpokenText == "How are you?")
        #expect(mock.lastAsyncSpokenRate == 1.2)
        #expect(mock.lastAsyncSpokenLocale == "en-US")
    }
}
