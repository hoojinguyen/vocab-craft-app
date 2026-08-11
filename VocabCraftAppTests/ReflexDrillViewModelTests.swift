import XCTest
@testable import VocabCraftApp

// MARK: - Mocks for Deterministic Unit Testing

final class MockSpeechRecognitionService: SpeechRecognitionProtocol {
    var isListening: Bool = false
    var recognizedText: String = ""
    var onResultCallback: ((String) -> Void)?
    var onErrorCallback: ((Error) -> Void)?

    func startListening(onResult: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.isListening = true
        self.onResultCallback = onResult
        self.onErrorCallback = onError
    }

    func stopListening() {
        self.isListening = false
    }

    func simulateResult(_ text: String) {
        self.recognizedText = text
        onResultCallback?(text)
    }

    func simulateError(_ error: Error) {
        onErrorCallback?(error)
    }
}

final class MockTextToSpeechService: TextToSpeechProtocol {
    var isSpeaking: Bool = false
    var lastSpokenText: String?

    func speak(text: String, rate: Float, locale: String) {
        isSpeaking = true
        lastSpokenText = text
    }

    func stop() {
        isSpeaking = false
    }
}

// MARK: - ViewModel Unit Tests

@MainActor
final class ReflexDrillViewModelTests: XCTestCase {
    private var mockSTT: MockSpeechRecognitionService!
    private var mockTTS: MockTextToSpeechService!
    private var viewModel: ReflexDrillViewModel!

    override func setUp() {
        super.setUp()
        mockSTT = MockSpeechRecognitionService()
        mockTTS = MockTextToSpeechService()
        viewModel = ReflexDrillViewModel(
            ttsService: mockTTS,
            sttService: mockSTT,
            cefrLevel: "B1"
        )
    }

    override func tearDown() {
        viewModel = nil
        mockSTT = nil
        mockTTS = nil
        super.tearDown()
    }

    func testReflexDrillViewModelInitializationAndSampleDrill() {
        viewModel.setupSampleDrill()
        
        XCTAssertNotNil(viewModel.state.drill)
        XCTAssertEqual(viewModel.state.drill?.promptText, "Một chú chó đen nhảy qua rào")
    }

    func testEvaluateAnswerCorrectIncreasesMastery() {
        viewModel.setupSampleDrill()
        viewModel.startDrillTimer()
        
        viewModel.evaluateAnswer("A black dog jumps over the fence")
        
        XCTAssertTrue(viewModel.state.isEvaluated)
        XCTAssertTrue(viewModel.state.isCorrect)
        XCTAssertEqual(viewModel.state.currentMastery, 1)
        XCTAssertTrue(viewModel.state.triggerSparkle)
    }

    func testEvaluateAnswerIncorrectResetsMastery() {
        viewModel.setupSampleDrill()
        viewModel.startDrillTimer()
        
        viewModel.evaluateAnswer("Wrong response")
        
        XCTAssertTrue(viewModel.state.isEvaluated)
        XCTAssertFalse(viewModel.state.isCorrect)
        XCTAssertEqual(viewModel.state.currentMastery, 0)
        XCTAssertFalse(viewModel.state.triggerSparkle)
    }

    func testStartVoiceRecognitionAutoEvaluatesOnExactMatchingAnswer() {
        viewModel.setupSampleDrill()
        viewModel.startVoiceRecognition()
        
        XCTAssertTrue(mockSTT.isListening)
        XCTAssertFalse(viewModel.state.isEvaluated)

        // Partial non-matching result -> should NOT trigger auto-evaluate
        mockSTT.simulateResult("A black dog")
        XCTAssertFalse(viewModel.state.isEvaluated)

        // Full matching result (with extra whitespace/punctuation) -> SHOULD trigger auto-evaluate
        mockSTT.simulateResult("A black dog jumps over the fence! ")
        XCTAssertTrue(viewModel.state.isEvaluated)
        XCTAssertTrue(viewModel.state.isCorrect)
    }

    func testHandleMicTapTogglesListeningAndEvaluates() {
        viewModel.setupSampleDrill()
        viewModel.startDrillTimer()

        // Tap 1: Start listening
        viewModel.handleMicTap()
        XCTAssertTrue(viewModel.isListening)
        XCTAssertFalse(viewModel.state.isEvaluated)

        // Simulate intermediate speech (non-matching so it doesn't auto-evaluate before tap)
        mockSTT.simulateResult("A black cat")

        // Tap 2: Stop listening & evaluate
        viewModel.handleMicTap()
        XCTAssertFalse(viewModel.isListening)
        XCTAssertTrue(viewModel.state.isEvaluated)
    }
}
