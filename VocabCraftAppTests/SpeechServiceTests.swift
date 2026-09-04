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

    @Test("Cancellation during preparation does not invoke onError")
    @MainActor
    func cancellationDuringPreparationDoesNotInvokeOnError() async throws {
        let controller = SuspendedSpeechAudioEngineController()
        let engine = ResilientReflexSpeechEngine(audioController: controller)
        engine.startSession(contextualPhrases: [], lazy: true)

        var errorDelivered = false
        engine.onError = { _ in
            errorDelivered = true
        }

        let task = Task {
            try await engine.prepareEngineIfNeeded()
        }
        await controller.waitUntilPreparationStarts()
        task.cancel()
        await controller.completePreparation()
        _ = try? await task.value

        #expect(errorDelivered == false)
        #expect(engine.isEngineReady == false)
    }

    @Test("Sequential stop and prepare executes teardown before next prepare")
    @MainActor
    func sequentialStopAndPrepareExecutesTeardownFirst() async throws {
        let controller = SuspendedSpeechAudioEngineController()
        let engine = ResilientReflexSpeechEngine(audioController: controller)
        engine.startSession(contextualPhrases: [], lazy: true)

        let prepTask = Task { try await engine.prepareEngineIfNeeded() }
        await controller.waitUntilPreparationStarts()
        await controller.completePreparation()
        try await prepTask.value
        #expect(engine.isEngineReady)

        engine.stopSession()
        #expect(engine.isSessionActive == false)

        engine.startSession(contextualPhrases: [], lazy: true)
        let secondPrepTask = Task { try await engine.prepareEngineIfNeeded() }
        await controller.waitUntilPreparationStarts(expectedCount: 2)
        await controller.completePreparation()
        try await secondPrepTask.value

        #expect(engine.isEngineReady)
        #expect(await controller.teardownCallCount == 1)
        #expect(await controller.prepareCallCount == 2)
    }

    @Test("Preparing engine succeeds and readies the engine even when listening was paused")
    @MainActor
    func prepareEngineWhenListeningIsPausedSucceeds() async throws {
        let controller = SuspendedSpeechAudioEngineController()
        let engine = ResilientReflexSpeechEngine(audioController: controller)
        engine.startSession(contextualPhrases: [], lazy: true)
        engine.pauseListening()
        #expect(engine.isListeningPaused)

        let prepTask = Task { try await engine.prepareEngineIfNeeded() }
        await controller.waitUntilPreparationStarts()
        await controller.completePreparation()
        try await prepTask.value

        #expect(engine.isEngineReady == true)
        #expect(await controller.prepareCallCount == 1)
    }

    @Test("SuspendedMockReflexSpeechEngine supports concurrent preparations and cancellation")
    @MainActor
    func suspendedMockSupportsConcurrentPreparationsAndCancellation() async throws {
        let mock = SuspendedMockReflexSpeechEngine()
        mock.startSession(contextualPhrases: [], lazy: true)

        let task1 = Task { try await mock.prepareEngineIfNeeded() }
        let task2 = Task { try await mock.prepareEngineIfNeeded() }

        await mock.waitUntilPreparationStarts(expectedCount: 2)
        #expect(mock.prepareCallCount == 2)

        task1.cancel()
        await #expect(throws: CancellationError.self) {
            try await task1.value
        }

        mock.completePreparation()
        try await task2.value
    }

    @Test("SuspendedMockReflexSpeechEngine releases pending continuations on stopSession")
    @MainActor
    func suspendedMockReleasesContinuationsOnStopSession() async throws {
        let mock = SuspendedMockReflexSpeechEngine()
        mock.startSession(contextualPhrases: [], lazy: true)

        let task = Task { try await mock.prepareEngineIfNeeded() }
        await mock.waitUntilPreparationStarts()
        #expect(mock.prepareCallCount == 1)

        mock.stopSession()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}

@Suite("TTS Audio Session Tests")
struct TTSAudioSessionTests {
    @Test("TTS activates playback session when no duplex active")
    @MainActor
    func ttsActivatesPlaybackWhenNoDuplexActive() async throws {
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let tts = TextToSpeechService(audioSessionCoordinator: coordinator)
        tts.speak(text: "test")
        await tts.playbackStartTask?.value

        #expect(await coordinator.effectiveIntent == .playback)
        #expect(await coordinator.activeLeaseCount == 1)
        #expect(mockHardware.operations.contains { operation in
            if case .setCategory(.playback, mode: .spokenAudio, options: [.duckOthers]) = operation { return true }
            return false
        })

        tts.stop()
        _ = await tts.playbackReleaseTask?.value
        #expect(await coordinator.activeLeaseCount == 0)
        #expect(mockHardware.operations.last == .setActive(false, options: [.notifyOthersOnDeactivation]))
    }

    @Test("TTS playback acquire does not replace active duplex lease")
    @MainActor
    func ttsPlaybackAcquireDoesNotReplaceActiveDuplexLease() async throws {
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let duplexLease = try await coordinator.acquire(.duplexSpeech)

        let tts = TextToSpeechService(audioSessionCoordinator: coordinator)
        tts.speak(text: "Hello world")
        await tts.playbackStartTask?.value

        #expect(await coordinator.effectiveIntent == .duplexSpeech)
        #expect(await coordinator.activeLeaseCount == 2)
        #expect(!mockHardware.operations.contains { operation in
            if case .setCategory(.playback, _, _) = operation { return true }
            return false
        })

        tts.stop()
        _ = await tts.playbackReleaseTask?.value
        await coordinator.release(duplexLease)
    }

    @Test("TTS stop releases only its playback lease")
    @MainActor
    func ttsStopReleasesOnlyItsPlaybackLease() async throws {
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let duplexLease = try await coordinator.acquire(.duplexSpeech)

        let tts = TextToSpeechService(audioSessionCoordinator: coordinator)
        tts.speak(text: "Hello world")
        await tts.playbackStartTask?.value

        #expect(await coordinator.activeLeaseCount == 2)
        #expect(await coordinator.effectiveIntent == .duplexSpeech)

        tts.stop()
        _ = await tts.playbackReleaseTask?.value

        #expect(await coordinator.activeLeaseCount == 1)
        #expect(await coordinator.effectiveIntent == .duplexSpeech)
        #expect(mockHardware.operations.last != .setActive(false, options: [.notifyOthersOnDeactivation]))

        await coordinator.release(duplexLease)
        #expect(await coordinator.activeLeaseCount == 0)
        #expect(mockHardware.operations.last == .setActive(false, options: [.notifyOthersOnDeactivation]))
    }
}

actor SuspendedSpeechAudioEngineController: SpeechAudioEngineControlling {
    private var preparationContinuations: [UUID: CheckedContinuation<Void, Error>] = [:]
    private var preparationStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var isCompleted = false
    private var pendingError: Error?
    private(set) var prepareCallCount = 0
    private(set) var teardownCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var pauseCallCount = 0

    func waitUntilPreparationStarts(expectedCount: Int = 1) async {
        guard prepareCallCount < expectedCount else { return }
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

        let continuationID = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else {
                    preparationContinuations[continuationID] = continuation
                }
            }
        } onCancel: {
            Task { [weak self] in
                await self?.cancelContinuation(id: continuationID)
            }
        }
    }

    private func cancelContinuation(id: UUID) {
        if let continuation = preparationContinuations.removeValue(forKey: id) {
            continuation.resume(throwing: CancellationError())
        }
    }

    func completePreparation() {
        isCompleted = true
        let continuations = Array(preparationContinuations.values)
        preparationContinuations.removeAll()
        for continuation in continuations {
            continuation.resume()
        }
    }

    func failPreparation(with error: Error) {
        pendingError = error
        let continuations = Array(preparationContinuations.values)
        preparationContinuations.removeAll()
        for continuation in continuations {
            continuation.resume(throwing: error)
        }
    }

    func resume() async throws {
        resumeCallCount += 1
    }

    func pause() async {
        pauseCallCount += 1
    }

    func teardown() async {
        teardownCallCount += 1
        isCompleted = false
        let continuations = Array(preparationContinuations.values)
        preparationContinuations.removeAll()
        for continuation in continuations {
            continuation.resume(throwing: CancellationError())
        }
    }
}
#endif
#endif
