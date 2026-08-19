@testable import VocabCraftApp
import XCTest

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
        XCTAssertTrue(true)
    }

    func testSoundEffectServiceInstanceCreation() {
        let instance = SoundEffectService()
        instance.playSuccessChime()
        XCTAssertTrue(true)
    }
}
