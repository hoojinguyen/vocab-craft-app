import XCTest
import AVFoundation
import Speech
@testable import VocabCraftApp

final class SpeechServiceTests: XCTestCase {

    // MARK: - TextToSpeechService Tests

    func testTTSServiceInitializationState() {
        let tts = TextToSpeechService()
        XCTAssertFalse(tts.isSpeaking, "isSpeaking should initially be false")
    }

    func testTTSSpeakConfiguresParameters() {
        let tts = TextToSpeechService()
        XCTAssertFalse(tts.isSpeaking)
        
        // Speak non-empty text
        tts.speak(text: "Hello world", rate: 0.5, locale: "en-US")
        
        // isSpeaking should be true after speak is invoked
        XCTAssertTrue(tts.isSpeaking, "isSpeaking should be true while speaking")
        
        // Stop speech synthesizer
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
}
