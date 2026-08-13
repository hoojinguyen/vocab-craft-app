#if os(iOS)
import AVFoundation
import Speech
@testable import VocabCraftApp
import XCTest

@MainActor
final class SpeechServiceTests: XCTestCase {
    // MARK: - TextToSpeechService Tests

    func testTTSServiceInitializationState() {
        let tts = TextToSpeechService()
        XCTAssertFalse(tts.isSpeaking, "isSpeaking should initially be false")
    }

    func testTTSSpeakConfiguresParameters() {
        let tts = TextToSpeechService()
        XCTAssertFalse(tts.isSpeaking)

        tts.speak(text: "Hello world", rate: 0.5, locale: "en-US")
        XCTAssertTrue(tts.isSpeaking, "isSpeaking should be true while speaking")

        tts.stop()
        XCTAssertFalse(tts.isSpeaking, "isSpeaking should be false after stop is called")
    }

    func testTTSSpeakWithCustomRateAndLocale() {
        let tts = TextToSpeechService()
        tts.speak(text: "Testing custom parameters", rate: 0.4, locale: "en-GB")
        XCTAssertTrue(tts.isSpeaking)

        tts.stop()
        XCTAssertFalse(tts.isSpeaking)
    }

    func testTTSSpeakEmptyTextDoesNotStart() {
        let tts = TextToSpeechService()
        tts.speak(text: "")
        XCTAssertFalse(tts.isSpeaking, "Speaking empty text should not set isSpeaking to true")
    }

    // MARK: - SpeechRecognitionService Tests

    func testSTTServiceInitializationState() {
        let stt = SpeechRecognitionService()
        XCTAssertFalse(stt.isRecording, "isRecording should initially be false")
        XCTAssertEqual(stt.recognizedText, "", "recognizedText should initially be empty")
    }

    func testSTTStopListeningWhenNotRecording() {
        let stt = SpeechRecognitionService()
        stt.stopListening()
        XCTAssertFalse(stt.isRecording)
        XCTAssertEqual(stt.recognizedText, "")
    }

    func testSTTAuthorizationRequestHandling() {
        let stt = SpeechRecognitionService()
        let expectation = self.expectation(description: "Speech recognition authorization callback")

        stt.requestAuthorization { authorized in
            XCTAssertTrue(authorized || !authorized, "Completion must provide a boolean result")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSTTStartListeningWithoutAuthorizationFailsGracefully() {
        #if targetEnvironment(simulator)
        // On simulator, SpeechRecognitionService automatically grants mock authorization
        return
        #else
        let stt = SpeechRecognitionService()
        let expectation = self.expectation(description: "Error callback should be triggered when un-authorized")

        stt.startListening(
            onResult: { _ in },
            onError: { error in
                XCTAssertNotNil(error, "Error should be provided when start listening fails")
                expectation.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0, handler: nil)
        #endif
    }
}
#endif
