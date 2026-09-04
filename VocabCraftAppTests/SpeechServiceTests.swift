import Foundation
#if os(iOS)
import AVFoundation
import Speech
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

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

    func testSTTCancelBeforeAuthorizationCannotStartCapture() async throws {
        #if targetEnvironment(simulator)
        let stt = SpeechRecognitionService()
        stt.startListening(onResult: { _ in }, onError: { _ in })
        stt.stopListening()

        try await Task.sleep(for: .milliseconds(100))

        XCTAssertFalse(stt.isRecording)
        #endif
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

    // MARK: - ResilientReflexSpeechEngine Tests

    func testEnginePauseAndResumeRetainsSession() {
        let engine = ResilientReflexSpeechEngine()
        engine.startSession(contextualPhrases: ["test"])
        XCTAssertEqual(engine.isSessionActive, true)
        engine.pauseListening()
        XCTAssertEqual(engine.isSessionActive, true)
        engine.resumeListening()
        XCTAssertEqual(engine.isSessionActive, true)
        engine.stopSession()
        XCTAssertEqual(engine.isSessionActive, false)
    }

    func testEnginePauseListeningEndsActiveWord() {
        let engine = ResilientReflexSpeechEngine()
        engine.startSession(contextualPhrases: ["test"])
        engine.beginWord(targetLemma: "apple", contextualPhrases: ["apple"])
        XCTAssertTrue(engine.isWordActive)

        engine.pauseListening()
        XCTAssertFalse(engine.isWordActive, "pauseListening must end the active word")
        XCTAssertTrue(engine.isSessionActive, "pauseListening must retain the active session")

        engine.resumeListening()
        XCTAssertTrue(engine.isSessionActive, "resumeListening must retain the active session")
        XCTAssertFalse(engine.isWordActive, "resumeListening must not automatically reactivate word before beginWord")

        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
    }

    func testEnginePauseListeningPreventsSimulatedMatchingUntilResumed() {
        let engine = ResilientReflexSpeechEngine()
        engine.startSession(contextualPhrases: ["apple", "banana"])
        engine.beginWord(targetLemma: "apple", contextualPhrases: ["apple"])

        var matchedLemma: String?
        engine.onMatchDetected = { lemma in
            matchedLemma = lemma
        }

        engine.simulateTranscript("apple")
        XCTAssertEqual(matchedLemma, "apple")

        // Pause listening: simulated transcript should no longer match
        matchedLemma = nil
        engine.pauseListening()
        engine.simulateTranscript("apple")
        XCTAssertNil(matchedLemma, "No matches should be emitted while engine is paused")

        // Resume listening and begin new word
        engine.resumeListening()
        engine.beginWord(targetLemma: "banana", contextualPhrases: ["banana"])
        engine.simulateTranscript("banana")
        XCTAssertEqual(matchedLemma, "banana")

        engine.stopSession()
    }

    func testEnginePrepareIfNeededRetainsStateAndIsSafe() {
        let engine = ResilientReflexSpeechEngine()
        // Calling before startSession should not activate session prematurely
        engine.prepareEngineIfNeeded()
        XCTAssertFalse(engine.isSessionActive)

        engine.startSession(contextualPhrases: ["test"])
        XCTAssertTrue(engine.isSessionActive)

        // Calling during active session should retain session state
        engine.prepareEngineIfNeeded()
        XCTAssertTrue(engine.isSessionActive)

        // Multiple rapid calls should be safe and idempotent
        engine.prepareEngineIfNeeded()
        engine.prepareEngineIfNeeded()
        XCTAssertTrue(engine.isSessionActive)

        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
    }

    func testEngineMultiplePauseResumeCallsAreIdempotent() {
        let engine = ResilientReflexSpeechEngine()
        engine.startSession(contextualPhrases: ["test"])

        // Multiple pauses
        engine.pauseListening()
        engine.pauseListening()
        XCTAssertTrue(engine.isSessionActive)

        // Multiple resumes
        engine.resumeListening()
        engine.resumeListening()
        XCTAssertTrue(engine.isSessionActive)

        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)

        // Stop session when already stopped
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
    }

    func testMockEngineTracksPauseResumeAndPrepareCalls() {
        let concreteMock = MockResilientReflexSpeechEngine()
        let mock: ReflexSpeechEngineProtocol = concreteMock
        XCTAssertFalse(mock.isSessionActive)

        mock.startSession(contextualPhrases: ["test"])
        XCTAssertTrue(mock.isSessionActive)

        mock.prepareEngineIfNeeded()
        mock.pauseListening()
        mock.resumeListening()
        mock.stopSession()
        XCTAssertFalse(mock.isSessionActive)

        XCTAssertEqual(concreteMock.startSessionCallCount, 1)
        XCTAssertEqual(concreteMock.prepareEngineIfNeededCallCount, 1)
        XCTAssertEqual(concreteMock.pauseListeningCallCount, 1)
        XCTAssertEqual(concreteMock.resumeListeningCallCount, 1)
        XCTAssertEqual(concreteMock.stopSessionCallCount, 1)
    }

    func testEngineLazySessionInitialization() {
        let engine = ResilientReflexSpeechEngine()
        XCTAssertFalse(engine.isSessionActive)

        engine.startSession(contextualPhrases: ["test"], lazy: true)
        XCTAssertTrue(engine.isSessionActive)

        engine.prepareEngineIfNeeded()
        XCTAssertTrue(engine.isSessionActive)

        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
    }
}
#endif
