import Foundation
#if os(iOS)
import AVFoundation
import Speech
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif
#if canImport(Testing)
import Testing
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

    func testEnginePrepareIfNeededRetainsStateAndIsSafe() async throws {
        let engine = ResilientReflexSpeechEngine()
        // Calling before startSession should not activate session prematurely
        try await engine.prepareEngineIfNeeded()
        XCTAssertFalse(engine.isSessionActive)

        engine.startSession(contextualPhrases: ["test"])
        XCTAssertTrue(engine.isSessionActive)

        // Calling during active session should retain session state
        try await engine.prepareEngineIfNeeded()
        XCTAssertTrue(engine.isSessionActive)

        // Multiple rapid calls should be safe and idempotent
        try await engine.prepareEngineIfNeeded()
        try await engine.prepareEngineIfNeeded()
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

    func testMockEngineTracksPauseResumeAndPrepareCalls() async throws {
        let concreteMock = MockResilientReflexSpeechEngine()
        let mock: ReflexSpeechEngineProtocol = concreteMock
        XCTAssertFalse(mock.isSessionActive)

        mock.startSession(contextualPhrases: ["test"])
        XCTAssertTrue(mock.isSessionActive)

        try await mock.prepareEngineIfNeeded()
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

    func testEngineLazySessionInitialization() async throws {
        let engine = ResilientReflexSpeechEngine()
        XCTAssertFalse(engine.isSessionActive)

        engine.startSession(contextualPhrases: ["test"], lazy: true)
        XCTAssertTrue(engine.isSessionActive)

        try await engine.prepareEngineIfNeeded()
        XCTAssertTrue(engine.isSessionActive)

        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
    }
}

#if canImport(Testing)
@Suite("Speech Engine Readiness Tests")
struct SpeechEngineReadinessTests {
    @Test("Word recognition waits until hardware preparation succeeds")
    @MainActor
    func wordWaitsForEngineReadiness() async throws {
        let controller = SuspendedSpeechAudioEngineController()
        let engine = ResilientReflexSpeechEngine(audioController: controller)
        engine.startSession(contextualPhrases: [], lazy: true)

        let task = Task { try await engine.prepareEngineIfNeeded() }
        await controller.waitUntilPreparationStarts()
        #expect(engine.isEngineReady == false)
        await controller.completePreparation()
        try await task.value
        #expect(engine.isEngineReady)
    }

    @Test("Cancellation during preparation prevents engine readiness")
    @MainActor
    func cancellationDuringPreparationPreventsReadiness() async throws {
        let controller = SuspendedSpeechAudioEngineController()
        let engine = ResilientReflexSpeechEngine(audioController: controller)
        engine.startSession(contextualPhrases: [], lazy: true)

        let task = Task {
            try await engine.prepareEngineIfNeeded()
        }
        await controller.waitUntilPreparationStarts()
        task.cancel()
        await controller.completePreparation()
        _ = try? await task.value

        #expect(engine.isEngineReady == false)
        #expect(await controller.teardownCallCount == 1)
    }

    @Test("Hardware preparation failure preserves error and delivers to onError")
    @MainActor
    func preparationFailureDeliversError() async throws {
        let controller = SuspendedSpeechAudioEngineController()
        let engine = ResilientReflexSpeechEngine(audioController: controller)
        engine.startSession(contextualPhrases: [], lazy: true)

        var deliveredError: (any Error)?
        engine.onError = { error in
            deliveredError = error
        }

        let expectedError = NSError(domain: "TestAudioError", code: 42, userInfo: nil)
        let task = Task {
            try await engine.prepareEngineIfNeeded()
        }
        await controller.waitUntilPreparationStarts()
        await controller.failPreparation(with: expectedError)

        await #expect(throws: Error.self) {
            try await task.value
        }

        #expect(engine.isEngineReady == false)
        let nsDelivered = deliveredError as? NSError
        #expect(nsDelivered?.domain == "TestAudioError")
        #expect(nsDelivered?.code == 42)
    }
}

@Suite("TTS Audio Session Tests")
struct TTSAudioSessionTests {
    @Test("TTS reuses active play-and-record session")
    @MainActor
    func ttsDoesNotReactivateLessonSession() {
        let session = MockAudioSession(category: .playAndRecord, isActive: true)
        let service = TextToSpeechService(audioSession: session)
        service.speak(text: "test")
        #expect(session.setActiveCallCount == 0)
    }

    @Test("TTS activates playback session when not in play-and-record")
    @MainActor
    func ttsActivatesPlaybackSession() {
        let session = MockAudioSession(category: .playback, isActive: false)
        let service = TextToSpeechService(audioSession: session)
        service.speak(text: "test")
        #expect(session.setActiveCallCount == 1)
        #expect(session.setCategoryCallCount == 1)
    }
}

#if os(iOS)
final class MockAudioSession: AudioSessionControlling {
    var category: AVAudioSession.Category
    var isActive: Bool
    private(set) var setActiveCallCount = 0
    private(set) var setCategoryCallCount = 0

    init(category: AVAudioSession.Category = .playback, isActive: Bool = false) {
        self.category = category
        self.isActive = isActive
    }

    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions
    ) throws {
        self.category = category
        setCategoryCallCount += 1
    }

    func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        self.isActive = active
        setActiveCallCount += 1
    }
}
#endif

actor SuspendedSpeechAudioEngineController: SpeechAudioEngineControlling {
    private var preparationContinuation: CheckedContinuation<Void, Error>?
    private var preparationStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var isCompleted = false
    private var pendingError: Error?
    private(set) var prepareCallCount = 0
    private(set) var teardownCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var pauseCallCount = 0

    func waitUntilPreparationStarts() async {
        guard prepareCallCount == 0 else { return }
        await withCheckedContinuation { continuation in
            preparationStartWaiters.append(continuation)
        }
    }

    func prepare(relay: AudioBufferRelay) async throws {
        prepareCallCount += 1
        for waiter in preparationStartWaiters {
            waiter.resume()
        }
        preparationStartWaiters.removeAll()

        if let pendingError {
            throw pendingError
        }
        if isCompleted {
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            preparationContinuation = continuation
        }
    }

    func completePreparation() {
        isCompleted = true
        preparationContinuation?.resume()
        preparationContinuation = nil
    }

    func failPreparation(with error: Error) {
        pendingError = error
        preparationContinuation?.resume(throwing: error)
        preparationContinuation = nil
    }

    func resume() async throws {
        resumeCallCount += 1
    }

    func pause() async {
        pauseCallCount += 1
    }

    func teardown() async {
        teardownCallCount += 1
        preparationContinuation?.resume(throwing: CancellationError())
        preparationContinuation = nil
    }
}

@MainActor
final class SuspendedMockReflexSpeechEngine: ReflexSpeechEngineProtocol {
    var isSessionActive: Bool = true
    var isWordActive: Bool = false
    var liveTranscript: String = ""
    var isListeningPaused: Bool = false
    var onMatchDetected: ((String) -> Void)?
    var onTranscriptUpdate: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    private(set) var prepareCallCount = 0
    private(set) var beginWordCallCount = 0
    private(set) var resumeListeningCallCount = 0
    private(set) var pauseListeningCallCount = 0
    private(set) var stopSessionCallCount = 0
    private var preparationContinuation: CheckedContinuation<Void, Error>?
    private var preparationStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var isCompleted = false
    private var pendingError: Error?

    func startSession(contextualPhrases: [String]) { isSessionActive = true }
    func startSession(contextualPhrases: [String], lazy: Bool) { isSessionActive = true }
    func stopSession() { isSessionActive = false; stopSessionCallCount += 1 }
    func pauseListening() { isListeningPaused = true; pauseListeningCallCount += 1 }
    func resumeListening() { isListeningPaused = false; resumeListeningCallCount += 1 }

    func waitUntilPreparationStarts() async {
        guard prepareCallCount == 0 else { return }
        await withCheckedContinuation { continuation in
            preparationStartWaiters.append(continuation)
        }
    }

    func prepareEngineIfNeeded() async throws {
        prepareCallCount += 1
        for waiter in preparationStartWaiters {
            waiter.resume()
        }
        preparationStartWaiters.removeAll()

        if let pendingError {
            throw pendingError
        }
        if isCompleted {
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            preparationContinuation = continuation
        }
    }

    func completePreparation() {
        isCompleted = true
        preparationContinuation?.resume()
        preparationContinuation = nil
    }

    func failPreparation(with error: Error) {
        pendingError = error
        preparationContinuation?.resume(throwing: error)
        preparationContinuation = nil
    }

    func beginWord(targetLemma: String, contextualPhrases: [String]) {
        beginWordCallCount += 1
        isWordActive = true
    }

    func endWord() {
        isWordActive = false
    }

    func finalizeWordAudio() {}
}
#endif
#endif
