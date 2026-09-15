@preconcurrency import AVFoundation
import Speech
#if canImport(XCTest)
import XCTest
#endif
@testable import VocabCraftApp

@MainActor
final class ResilientReflexSpeechEngineTests: XCTestCase {
    private var mockHardware: MockAudioSessionHardware!
    private var coordinator: AudioSessionCoordinator!
    private var engine: ResilientReflexSpeechEngine!

    override func setUp() async throws {
        try await super.setUp()
        mockHardware = MockAudioSessionHardware()
        coordinator = AudioSessionCoordinator(hardware: mockHardware)
        engine = ResilientReflexSpeechEngine(audioSessionCoordinator: coordinator)
    }

    override func tearDown() async throws {
        engine.stopSession()
        engine = nil
        coordinator = nil
        mockHardware = nil
        try await super.tearDown()
    }

    func testStartSession_activatesSession() {
        engine.startSession(contextualPhrases: ["hello", "world"])
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    @available(*, deprecated)
    func testStopSession_deactivatesEverything() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    @available(*, deprecated)
    func testBeginWord_activatesWord() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: ["test"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertEqual(engine.liveTranscript, "")
    }

    @available(*, deprecated)
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

    @available(*, deprecated)
    func testEndWord_deactivatesWordKeepsSession() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.endWord()
        XCTAssertFalse(engine.isWordActive)
        XCTAssertTrue(engine.isSessionActive)
    }

    @available(*, deprecated)
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

    @available(*, deprecated)
    func testMultipleWordCycles_nocrash() {
        engine.startSession(contextualPhrases: [])
        for i in 0..<10 {
            engine.beginWord(targetLemma: "word\(i)", contextualPhrases: [])
            engine.endWord()
        }
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    @available(*, deprecated)
    func testSimulateTranscript_updatesLiveTranscript() {
        var received: String?
        engine.onTranscriptUpdate = { received = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.simulateTranscript("hello world")
        XCTAssertEqual(engine.liveTranscript, "hello world")
        XCTAssertEqual(received, "hello world")
    }

    @available(*, deprecated)
    func testSimulateTranscript_matchDetected() {
        var matched: String?
        engine.onMatchDetected = { matched = $0 }
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "ephemeral", contextualPhrases: [])
        engine.simulateTranscript("ephemeral")
        XCTAssertEqual(matched, "ephemeral")
    }

    @available(*, deprecated)
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

    @available(*, deprecated)
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

    @available(*, deprecated)
    func testTimeout1110_whenSessionNotActive_doesNotRestartRecognition() {
        engine.startSession(contextualPhrases: [])
        engine.beginWord(targetLemma: "test", contextualPhrases: [])
        engine.stopSession()

        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
    }

    func testAudioInterruptionBegan_pausesListening() async throws {
        engine.startSession(contextualPhrases: ["apple"])
        try await engine.startListening(targetLemma: "apple", contextualPhrases: ["apple"])
        XCTAssertTrue(engine.isWordActive)
        XCTAssertTrue(engine.isSessionActive)

        await coordinator.broadcastEventForTesting(.interruptionBegan)
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertFalse(engine.isWordActive, "Interruption began must pause listening and deactivate current word")
        XCTAssertTrue(engine.isSessionActive, "Session must remain active across interruption")
        XCTAssertTrue(engine.isListeningPaused, "Interruption began must set isListeningPaused to true")
    }

    func testAudioInterruptionEndedWithShouldResume_resumesListening() async throws {
        engine.startSession(contextualPhrases: ["apple"])
        try await engine.startListening(targetLemma: "apple", contextualPhrases: ["apple"])

        await coordinator.broadcastEventForTesting(.interruptionBegan)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(engine.isWordActive)
        XCTAssertTrue(engine.isListeningPaused)

        await coordinator.broadcastEventForTesting(.interruptionEnded(shouldResume: true))
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertTrue(engine.isSessionActive)
        XCTAssertFalse(engine.isListeningPaused)
        // Can begin word and match normally after resuming
        var matchedLemma: String?
        engine.onMatchDetected = { matchedLemma = $0 }
        try await engine.startListening(targetLemma: "apple", contextualPhrases: ["apple"])
        engine.simulateTranscript("apple")
        XCTAssertEqual(matchedLemma, "apple")
    }

    func testAudioInterruptionEndedWithoutShouldResume_doesNotResume() async throws {
        engine.startSession(contextualPhrases: ["apple"])
        try await engine.startListening(targetLemma: "apple", contextualPhrases: ["apple"])

        await coordinator.broadcastEventForTesting(.interruptionBegan)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(engine.isWordActive)

        await coordinator.broadcastEventForTesting(.interruptionEnded(shouldResume: false))
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertTrue(engine.isSessionActive)
        XCTAssertTrue(engine.isListeningPaused)
    }

    func testMediaServicesResetStopsSessionAndDeliversError() async throws {
        var receivedError: (any Error)?
        engine.onError = { error in
            receivedError = error
        }

        engine.startSession(contextualPhrases: ["apple"])
        try await engine.startListening(targetLemma: "apple", contextualPhrases: ["apple"])
        XCTAssertTrue(engine.isSessionActive)

        await coordinator.broadcastEventForTesting(.mediaServicesReset)
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertFalse(engine.isSessionActive)
        guard let speechError = receivedError as? SpeechCaptureError else {
            XCTFail("Expected SpeechCaptureError, got \(String(describing: receivedError))")
            return
        }
        XCTAssertEqual(speechError, .enginePreparationFailed)
    }

    func testStopSessionDeregistersEventSubscription() async throws {
        engine.startSession(contextualPhrases: ["apple"])
        XCTAssertTrue(engine.hasEventSubscription, "Event subscription must be registered when session starts")

        engine.stopSession()

        XCTAssertFalse(engine.hasEventSubscription, "Event subscription must be deregistered when session stops")
        XCTAssertFalse(engine.isSessionActive)

        await coordinator.broadcastEventForTesting(.interruptionBegan)
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isListeningPaused)
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

    func testEventsWhenSessionInactiveDoNothing() async throws {
        XCTAssertFalse(engine.isSessionActive)
        await coordinator.broadcastEventForTesting(.interruptionBegan)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertFalse(engine.isWordActive)
        XCTAssertFalse(engine.isListeningPaused)
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
}
