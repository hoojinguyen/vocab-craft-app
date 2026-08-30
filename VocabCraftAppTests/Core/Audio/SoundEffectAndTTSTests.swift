import Foundation
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class SoundEffectAndTTSTests: XCTestCase {
    func testAsyncTTSCompletesSuccessfully() async {
        let tts = TextToSpeechService()
        await tts.speakAsync(text: "habit", rate: 0.5, locale: "en-US")
        XCTAssertFalse(tts.isSpeaking)
    }

    func testAsyncTTSDefaultParameters() async {
        let tts = TextToSpeechService()
        await tts.speakAsync(text: "habit")
        XCTAssertFalse(tts.isSpeaking)
    }

    func testAsyncTTSEmptyTextDoesNotHangOrSetSpeaking() async {
        let tts = TextToSpeechService()
        await tts.speakAsync(text: "")
        XCTAssertFalse(tts.isSpeaking)
    }

    func testSoundEffectServicePlaysWithoutCrashing() {
        let soundService: SoundEffectServiceProtocol = SoundEffectService.shared
        soundService.playSuccessChime()
        soundService.playIncorrectChime()
        XCTAssertTrue(true)
    }

    func testSoundEffectServiceInstanceCreation() {
        let instance = SoundEffectService()
        instance.playSuccessChime()
        instance.playIncorrectChime()
        XCTAssertTrue(true)
    }

    func testResolveVoiceReturnsVoiceAndCaches() {
        let voice1 = TextToSpeechService.resolveVoice(for: "en-US")
        let voice2 = TextToSpeechService.resolveVoice(for: "en-US")
        XCTAssertNotNil(voice1)
        XCTAssertEqual(voice1, voice2)
    }

    func testResolveVoiceWithDifferentLocales() {
        let voiceUS = TextToSpeechService.resolveVoice(for: "en-US")
        let voiceGB = TextToSpeechService.resolveVoice(for: "en-GB")
        XCTAssertNotNil(voiceUS)
        XCTAssertNotNil(voiceGB)
    }

    func testResolveVoiceFallbackForUnknownLocale() {
        let fallbackVoice = TextToSpeechService.resolveVoice(for: "unknown-locale-xyz")
        XCTAssertNotNil(fallbackVoice)
    }

    func testSpeakSyncWithCustomRateAndLocale() {
        let tts = TextToSpeechService()
        tts.speak(text: "hello world", rate: 0.8, locale: "en-GB")
        XCTAssertTrue(tts.isSpeaking)
        tts.stop()
        XCTAssertFalse(tts.isSpeaking)
    }

    func testSpeakEmptyTextDoesNothing() {
        let tts = TextToSpeechService()
        tts.speak(text: "   ")
        XCTAssertFalse(tts.isSpeaking)
    }

    func testPrewarmExecutesWithoutCrashing() {
        let tts = TextToSpeechService()
        tts.prewarm()
        XCTAssertFalse(tts.isSpeaking)
    }
}
