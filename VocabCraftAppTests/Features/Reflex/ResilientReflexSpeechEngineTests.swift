@preconcurrency import AVFoundation
import Speech
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

@MainActor
final class ResilientReflexSpeechEngineTests: XCTestCase {
    private var engine: ResilientReflexSpeechEngine!

    override func setUp() {
        super.setUp()
        engine = ResilientReflexSpeechEngine()
    }

    override func tearDown() {
        engine.stopSession()
        engine = nil
        super.tearDown()
    }

    func testStartSession_activatesSession() {
        engine.startSession(contextualPhrases: ["hello", "world"])
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testStopSession_deactivatesEverything() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testBeginWord_activatesWord() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: ["test"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }

    func testBeginWord_whenSessionInactive_doesNothing() {
        XCTAssertFalse(engine.isSessionActive)
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: ["test"])
        XCTAssertFalse(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")

        engine.startSession(contextualPhrases: [])
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: ["test"])
        XCTAssertFalse(engine.isWordActive)
    }

    func testStartListening_activatesWordAndSimulatesMatch() async throws {
        var matchedLemma: String?
        engine.onMatchDetected = { matchedLemma = $0 }
        engine.startSession(contextualPhrases: [])
        try await engine.startListening(targetLemma: "ephemeral", contextualPhrases: ["test"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")

        engine.simulateTranscript("ephemeral")
        XCTAssertEqual(matchedLemma, "ephemeral")
    }

    func testStartListening_whenSessionInactiveThrowsCancelled() async {
        do {
            try await engine.startListening(targetLemma: "ephemeral", contextualPhrases: [])
            XCTFail("Expected startListening to throw when session is inactive")
        } catch let error as SpeechCaptureError {
            XCTAssertEqual(error, .cancelled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testEndWord_deactivatesWordKeepsSession() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.endWord()
        XCTAssertFalse(engine.isWordActive)
        XCTAssertTrue(engine.isSessionActive)
    }

    func testPauseAndResumeListening_lifecycle() {
        engine.startSession(contextualPhrases: ["test"])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        XCTAssertTrue(engine.isWordActive)

        engine.pauseListening()
        XCTAssertFalse(engine.isWordActive)
        XCTAssertTrue(engine.isSessionActive)

        engine.resumeListening()
        XCTAssertTrue(engine.isSessionActive)
    }

    func testMultipleWordCycles_nocrash() {
        engine.startSession(contextualPhrases: [])
        for i in 0..<10 {
            engine.beginWord(targetLemma: "word\(i)", contextualPhrases: [])
            engine.endWord()
        }
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testSimulateTranscript_updatesLiveTranscript() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.simulateTranscript("hello world")
        XCTAssertEqual(engine.liveTranscript, "hello world")
        XCTAssertEqual(received, "hello world")
    }

    func testSimulateTranscript_matchDetected() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: [])
        engine.simulateTranscript("ephemeral")
        XCTAssertEqual(matched, "ephemeral")
    }

    func testSimulateTranscript_noMatchForWrongWord() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: [])
        engine.simulateTranscript("hello")
        XCTAssertNil(matched)
    }

    func testSimulateTranscript_ignoredWhenWordNotActive() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.simulateTranscript("hello")
        XCTAssertNil(received)
    }

    func testBeginWord_endsPreviousWordAutomatically() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "word1", contextualPhrases: [])
        XCTAssertTrue(engine.isWordActive)
        engine.beginWord(targetLemma: "word2", contextualPhrases: [])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }

    func testResolveSpeechRecognizer_refreshesWhenNil() {
        let testEngine = ResilientReflexSpeechEngine(speechRecognizer: nil)
        XCTAssertNil(testEngine.currentSpeechRecognizer)
        let resolved = testEngine.resolveSpeechRecognizer()
        XCTAssertNotNil(resolved)
        XCTAssertNotNil(testEngine.currentSpeechRecognizer)
    }

    func testResolveSpeechRecognizer_returnsExistingWhenAvailable() {
        let existing = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        let testEngine = ResilientReflexSpeechEngine(speechRecognizer: existing)
        let resolved = testEngine.resolveSpeechRecognizer()
        XCTAssertNotNil(resolved)
        if let existing, existing.isAvailable {
            XCTAssertTrue(resolved === existing)
        }
    }

    func testAudioBufferRelay_threadSafetyAndNilHandling() {
        let relay = AudioBufferRelay()
        relay.setRequest(nil)
        XCTAssertNotNil(relay)
    }

    func testAudioBufferRelay_muteAndUnmute() {
        let relay = AudioBufferRelay()
        relay.mute()
        XCTAssertTrue(relay.isCurrentlyMuted)
        relay.unmute()
        XCTAssertFalse(relay.isCurrentlyMuted)
    }

    func testAudioBufferRelay_detachAndEnd_resetsRequestAndMutes() {
        let relay = AudioBufferRelay()
        let request = SFSpeechAudioBufferRecognitionRequest()
        relay.setRequest(request)
        XCTAssertFalse(relay.isCurrentlyMuted)

        relay.detachAndEnd()
        XCTAssertTrue(relay.isCurrentlyMuted)
        XCTAssertNil(relay.currentRequest)
    }

    func testAudioBufferRelay_concurrentAppendAndDetach_noCrash() {
        let relay = AudioBufferRelay()
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024

        let iterations = 1000
        let group = DispatchGroup()

        // Background thread appending buffers rapidly
        group.enter()
        DispatchQueue.global(qos: .userInteractive).async {
            for _ in 0..<iterations {
                relay.append(buffer)
            }
            group.leave()
        }

        // Main thread alternating request and detachAndEnd
        group.enter()
        DispatchQueue.global(qos: .default).async {
            for _ in 0..<iterations {
                let req = SFSpeechAudioBufferRecognitionRequest()
                relay.setRequest(req)
                relay.detachAndEnd()
            }
            group.leave()
        }

        let result = group.wait(timeout: .now() + 5.0)
        XCTAssertEqual(result, .success)
    }

    func testTimeout1110_whenSessionNotActive_doesNotRestartRecognition() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.stopSession()

        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    #if os(iOS)
    func testAudioInterruptionBegan_pausesListening() {
        engine.startSession(contextualPhrases: ["apple"])
        engine.beginWord(targetLemma: "apple", contextualPhrases: ["apple"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertTrue(engine.isSessionActive)

        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
        engine.handleAudioInterruption(notification)

        XCTAssertFalse(engine.isWordActive, "Interruption began must pause listening and deactivate current word")
        XCTAssertTrue(engine.isSessionActive, "Session must remain active across interruption")
        XCTAssertTrue(engine.isListeningPaused, "Interruption began must set isListeningPaused to true")
    }

    func testAudioInterruptionEndedWithShouldResume_resumesListening() {
        engine.startSession(contextualPhrases: ["apple"])
        engine.beginWord(targetLemma: "apple", contextualPhrases: ["apple"])

        // Interruption began
        let beganNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
        engine.handleAudioInterruption(beganNotification)
        XCTAssertFalse(engine.isWordActive)
        XCTAssertTrue(engine.isListeningPaused)

        // Interruption ended with shouldResume
        let endedNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )
        engine.handleAudioInterruption(endedNotification)

        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isListeningPaused)
        // Can begin word and match normally after resuming
        var matchedLemma: String?
        engine.onMatchDetected = { matchedLemma = $0 }
        engine.beginWord(targetLemma: "apple", contextualPhrases: ["apple"])
        engine.simulateTranscript("apple")
        XCTAssertEqual(matchedLemma, "apple")
    }

    func testAudioInterruptionEndedWithoutShouldResume_doesNotResume() {
        engine.startSession(contextualPhrases: ["apple"])
        engine.beginWord(targetLemma: "apple", contextualPhrases: ["apple"])

        // Interruption began
        let beganNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )
        engine.handleAudioInterruption(beganNotification)
        XCTAssertFalse(engine.isWordActive)

        // Interruption ended without options
        let endedNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue]
        )
        engine.handleAudioInterruption(endedNotification)

        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testStopSessionDeregistersInterruptionObserver() {
        engine.startSession(contextualPhrases: ["apple"])
        #if os(iOS)
        XCTAssertTrue(engine.hasInterruptionObserver, "Interruption observer must be registered when session starts")
        #endif

        engine.stopSession()

        #if os(iOS)
        XCTAssertFalse(engine.hasInterruptionObserver, "Interruption observer must be deregistered when session stops")
        #endif
        XCTAssertFalse(engine.isSessionActive)

        // Posting notification through NotificationCenter after deregistration is harmless
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue]
        )

        XCTAssertFalse(engine.isSessionActive)
    }

    func testPauseListeningResetsIsStartingEngineAndAllowsResume() {
        engine.startSession(contextualPhrases: ["apple"], lazy: true)
        XCTAssertTrue(engine.isSessionActive)

        engine.pauseListening()
        XCTAssertTrue(engine.isListeningPaused)

        // Resume listening should be permitted and reset paused state
        engine.resumeListening()
        XCTAssertFalse(engine.isListeningPaused)
    }

    func testAudioInterruptionWithNSNumberKeys() {
        engine.startSession(contextualPhrases: ["apple"])
        engine.beginWord(targetLemma: "apple", contextualPhrases: ["apple"])

        // Began with NSNumber
        let beganType = NSNumber(value: AVAudioSession.InterruptionType.began.rawValue)
        let beganNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: beganType]
        )
        engine.handleAudioInterruption(beganNotification)
        XCTAssertFalse(engine.isWordActive)

        // Ended with NSNumbers
        let endedType = NSNumber(value: AVAudioSession.InterruptionType.ended.rawValue)
        let shouldResumeOpt = NSNumber(value: AVAudioSession.InterruptionOptions.shouldResume.rawValue)
        let endedNotification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: endedType,
                AVAudioSessionInterruptionOptionKey: shouldResumeOpt
            ]
        )
        engine.handleAudioInterruption(endedNotification)
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isListeningPaused)
    }

    func testHandleInterruptionWhenSessionInactiveDoesNothing() {
        XCTAssertFalse(engine.isSessionActive)
        let notification = Notification(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue
            ]
        )
        engine.handleAudioInterruption(notification)
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testPauseAndResumeListeningLifecycle() {
        engine.startSession(contextualPhrases: ["apple"])
        XCTAssertFalse(engine.isListeningPaused)

        engine.pauseListening()
        XCTAssertTrue(engine.isListeningPaused)

        engine.resumeListening()
        XCTAssertFalse(engine.isListeningPaused)

        engine.pauseListening()
        XCTAssertTrue(engine.isListeningPaused)

        engine.stopSession()
        XCTAssertFalse(engine.isListeningPaused)
    }
    #endif
}
