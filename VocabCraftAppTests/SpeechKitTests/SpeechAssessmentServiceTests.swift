@testable import VocabCraftApp
import XCTest

// MARK: - Mock Speech Recognition Engine

final class MockSpeechRecognitionEngine: SpeechRecognitionEngineProtocol, @unchecked Sendable {
    var isRecording: Bool = false
    var requestAuthResult: Bool = true
    var contextualPhrasesPassed: [String] = []

    var onPartialResultHandler: (@Sendable (String) -> Void)?
    var onFinalResultHandler: (@Sendable (String) -> Void)?
    var onErrorHandler: (@Sendable (Error) -> Void)?

    var startCallCount: Int = 0
    var stopCallCount: Int = 0
    var shouldThrowOnStart: Error?

    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        completion(requestAuthResult)
    }

    func start(
        contextualPhrases: [String],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {
        if let error = shouldThrowOnStart {
            throw error
        }
        startCallCount += 1
        isRecording = true
        contextualPhrasesPassed = contextualPhrases
        onPartialResultHandler = onPartialResult
        onFinalResultHandler = onFinalResult
        onErrorHandler = onError
    }

    func stop() {
        stopCallCount += 1
        isRecording = false
    }

    func simulatePartialResult(_ text: String) {
        onPartialResultHandler?(text)
    }

    func simulateFinalResult(_ text: String) {
        onFinalResultHandler?(text)
    }

    func simulateError(_ error: Error) {
        onErrorHandler?(error)
    }
}

// MARK: - Safe Box for Sendable Closures

private final class SafeBoolBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Bool

    init(_ value: Bool = false) {
        self._value = value
    }

    var value: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _value = newValue
        }
    }
}

// MARK: - SpeechAssessmentService Tests

@MainActor
final class SpeechAssessmentServiceTests: XCTestCase {
    var mockEngine: MockSpeechRecognitionEngine!
    var service: SpeechAssessmentService!

    override func setUp() {
        super.setUp()
        mockEngine = MockSpeechRecognitionEngine()
        service = SpeechAssessmentService(
            recognitionEngine: mockEngine,
            initialSilenceDuration: .milliseconds(80),
            silenceDuration: .milliseconds(80)
        )
    }

    override func tearDown() {
        service.stopAssessing()
        mockEngine = nil
        service = nil
        super.tearDown()
    }

    func testStartAssessing_emptyTargetSentence_triggersEmptyTargetSentenceError() async {
        let expectation = expectation(description: "Error received for empty target")
        var receivedError: Error?

        service.startAssessing(
            targetSentence: "   ",
            onError: { error in
                receivedError = error
                expectation.fulfill()
            }
        )

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedError as? SpeechKitError, .emptyTargetSentence)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.startCallCount, 0)
    }

    func testStartAssessing_setsIsListeningAndConfiguresContextualPhrases() {
        let target = "The quick brown fox jumps over the lazy dog"
        let contextual = ["fox", "quick"]

        service.startAssessing(
            targetSentence: target,
            contextualPhrases: contextual
        )

        XCTAssertTrue(service.isListening)
        XCTAssertTrue(mockEngine.isRecording)
        XCTAssertEqual(mockEngine.startCallCount, 1)
        // Verifies contextual phrases include vocabulary and target sentence
        XCTAssertTrue(mockEngine.contextualPhrasesPassed.contains("fox"))
        XCTAssertTrue(mockEngine.contextualPhrasesPassed.contains("quick"))
        XCTAssertTrue(mockEngine.contextualPhrasesPassed.contains(target))
    }

    func testPartialResult_belowThreshold_emitsProgress_doesNotComplete() async {
        let target = "A black dog jumps over the fence."
        let progressExpectation = expectation(description: "Progress callback received")
        var progressResult: SpeechEvaluationResult?
        var didComplete = false

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onProgress: { result in
                progressResult = result
                progressExpectation.fulfill()
            },
            onCompletion: { _ in
                didComplete = true
            }
        )

        // Partial speech with low score (only "a black")
        mockEngine.simulatePartialResult("a black")

        await fulfillment(of: [progressExpectation], timeout: 1.0)

        XCTAssertNotNil(progressResult)
        XCTAssertFalse(progressResult!.isPassed)
        XCTAssertLessThan(progressResult!.overallScore, 75.0)
        XCTAssertFalse(didComplete)
        XCTAssertTrue(service.isListening)
        XCTAssertEqual(service.currentEvaluation?.spokenText, "a black")
    }

    func testPartialResult_reachesThreshold_instantReflexTrigger_completesImmediately() async {
        let target = "A black dog jumps over the fence."
        let completionExpectation = expectation(description: "Instant reflex completion received")
        var completionResult: SpeechEvaluationResult?

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onCompletion: { result in
                completionResult = result
                completionExpectation.fulfill()
            }
        )

        // Spoken text matching exact target -> 100% score >= 75%
        mockEngine.simulatePartialResult("a black dog jumps over the fence")

        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertNotNil(completionResult)
        XCTAssertTrue(completionResult!.isPassed)
        XCTAssertEqual(completionResult!.overallScore, 100.0, accuracy: 1e-6)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.stopCallCount, 1)
    }

    func testAccentTolerance_instantPassWithMinorInflections() async {
        let target = "A black dog jumps over the fence."
        let completionExpectation = expectation(description: "Accent tolerant pass completed")
        var completionResult: SpeechEvaluationResult?

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onCompletion: { result in
                completionResult = result
                completionExpectation.fulfill()
            }
        )

        // Spoken with missing "s" on jumps and missing article "the" (~82.8% score >= 75%)
        mockEngine.simulatePartialResult("a black dog jump over fence")

        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertNotNil(completionResult)
        XCTAssertTrue(completionResult!.isPassed)
        XCTAssertGreaterThanOrEqual(completionResult!.overallScore, 75.0)
        XCTAssertFalse(service.isListening)
    }

    func testInstantReflexTrigger_lowCoverageBelow95_doesNotCompletePrematurely() async {
        let target = "The quick brown fox jumps over the lazy dog in the summer morning"
        var didComplete = false

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.5,
            onCompletion: { _ in
                didComplete = true
            }
        )

        // Partial speech with partial match that is not enough coverage (<85%) and <95% score
        mockEngine.simulatePartialResult("the quick brown fox")

        try? await Task.sleep(for: .milliseconds(30))

        XCTAssertFalse(didComplete, "Should not prematurely trigger instant reflex pass when token coverage is low and score < 95%")
        XCTAssertTrue(service.isListening)
    }

    func testSilenceTimeout_stopsAndEmitsFinalEvaluation() async {
        let target = "I would like a cup of coffee please."
        let completionExpectation = expectation(description: "Silence auto-stop completion")
        var completionResult: SpeechEvaluationResult?

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onCompletion: { result in
                completionResult = result
                completionExpectation.fulfill()
            }
        )

        // Spoken partial text (< 75%)
        mockEngine.simulatePartialResult("i would like a cup")

        // Wait for silence detector (80ms + buffer) to trigger
        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertNotNil(completionResult)
        XCTAssertFalse(completionResult!.isPassed)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.stopCallCount, 1)
        XCTAssertEqual(completionResult?.spokenText, "i would like a cup")
    }

    func testStopAssessing_manuallyStopsListeningAndEngine() {
        service.startAssessing(targetSentence: "Hello world")
        XCTAssertTrue(service.isListening)
        XCTAssertTrue(mockEngine.isRecording)

        service.stopAssessing()

        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.stopCallCount, 1)
    }

    func testEngineError_forwardsToOnErrorAndStopsListening() async {
        let errorExpectation = expectation(description: "Engine error forwarded")
        var receivedError: Error?

        service.startAssessing(
            targetSentence: "Hello world",
            onError: { error in
                receivedError = error
                errorExpectation.fulfill()
            }
        )

        mockEngine.simulateError(SpeechKitError.recognizerUnavailable)

        await fulfillment(of: [errorExpectation], timeout: 1.0)

        XCTAssertEqual(receivedError as? SpeechKitError, .recognizerUnavailable)
        XCTAssertFalse(service.isListening)
        XCTAssertEqual(mockEngine.stopCallCount, 1)
    }

    func testInitialSilenceTimeout_withNoPartialResults_stopsAndEmitsFinalEvaluation() async {
        let target = "Never give up."
        let completionExpectation = expectation(description: "Initial silence auto-stop completion")
        var completionResult: SpeechEvaluationResult?

        service.startAssessing(
            targetSentence: target,
            toleranceThreshold: 0.75,
            onCompletion: { result in
                completionResult = result
                completionExpectation.fulfill()
            }
        )

        // No partial result is simulated; the initial armed timer should fire after 80ms
        await fulfillment(of: [completionExpectation], timeout: 1.0)

        XCTAssertNotNil(completionResult)
        XCTAssertFalse(completionResult!.isPassed)
        XCTAssertEqual(completionResult?.spokenText, "")
        XCTAssertFalse(service.isListening)
    }

    func testAuthorizationDenied_forwardsSpeechRecognitionNotAuthorizedError() async {
        mockEngine.requestAuthResult = false
        let errorExpectation = expectation(description: "Not authorized error received")
        var receivedError: Error?

        service.startAssessing(
            targetSentence: "Hello world",
            onError: { error in
                receivedError = error
                errorExpectation.fulfill()
            }
        )

        await fulfillment(of: [errorExpectation], timeout: 1.0)

        XCTAssertEqual(receivedError as? SpeechKitError, .speechRecognitionNotAuthorized)
        XCTAssertFalse(service.isListening)
    }

    func testSessionTokenIsolation_ignoresStaleCallbacksFromPreviousSession() async {
        let firstTarget = "First sentence"
        let secondTarget = "Second sentence"

        var firstCompletionCalled = false
        var secondCompletionCalled = false
        let secondCompletionExpectation = expectation(description: "Second session completed")

        // Start session 1
        service.startAssessing(
            targetSentence: firstTarget,
            onCompletion: { _ in
                firstCompletionCalled = true
            }
        )
        let firstEngineCallback = mockEngine.onPartialResultHandler

        // Immediately restart with session 2
        service.startAssessing(
            targetSentence: secondTarget,
            onCompletion: { result in
                secondCompletionCalled = true
                XCTAssertEqual(result.targetSentence, secondTarget)
                secondCompletionExpectation.fulfill()
            }
        )

        // Stale callback from session 1 should be ignored
        firstEngineCallback?("first sentence")

        // Valid callback from session 2
        mockEngine.simulatePartialResult("second sentence")

        await fulfillment(of: [secondCompletionExpectation], timeout: 1.0)
        XCTAssertFalse(firstCompletionCalled, "Stale callback from session 1 should not have triggered session 1's completion")
        XCTAssertTrue(secondCompletionCalled)
    }

    // MARK: - Dual-Phase Silence Detector Tests

    func testSilenceDetector_initialSilenceTimeout() async throws {
        let didFireSilence = SafeBoolBox(false)
        let detector = SilenceDetector(
            initialSilenceDuration: .milliseconds(100),
            trailingSilenceDuration: .milliseconds(50)
        ) {
            didFireSilence.value = true
        }
        detector.arm()
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertTrue(didFireSilence.value, "Initial silence timer should fire if no activity registered")
    }

    func testSilenceDetector_activityResetsToTrailingDuration() async throws {
        let didFireSilence = SafeBoolBox(false)
        let detector = SilenceDetector(
            initialSilenceDuration: .milliseconds(200),
            trailingSilenceDuration: .milliseconds(80)
        ) {
            didFireSilence.value = true
        }
        detector.arm()
        try await Task.sleep(for: .milliseconds(50))
        detector.registerActivity()
        XCTAssertFalse(didFireSilence.value)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(didFireSilence.value, "Trailing silence timer should fire after activity registered")
    }
}
