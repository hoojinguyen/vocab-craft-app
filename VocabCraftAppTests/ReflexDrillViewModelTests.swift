@testable import VocabCraftApp
import XCTest

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

final class MockSoundEffectService: SoundEffectServiceProtocol, @unchecked Sendable {
    var playSuccessChimeCallCount: Int = 0
    var playIncorrectChimeCallCount: Int = 0

    func playSuccessChime() {
        playSuccessChimeCallCount += 1
    }

    func playIncorrectChime() {
        playIncorrectChimeCallCount += 1
    }
}

final class MockTextToSpeechService: TextToSpeechProtocol {
    var isSpeaking: Bool = false
    var lastSpokenText: String?
    var lastSpokenRate: Float?
    var lastSpokenLocale: String?
    var speakCallCount: Int = 0
    var speakAsyncCallCount: Int = 0
    var onSpeakAsync: ((String, Float, String) async -> Void)?

    func speak(text: String, rate: Float, locale: String) {
        speakCallCount += 1
        isSpeaking = true
        lastSpokenText = text
        lastSpokenRate = rate
        lastSpokenLocale = locale
    }

    func speakAsync(text: String, rate: Float, locale: String) async {
        speakAsyncCallCount += 1
        isSpeaking = true
        lastSpokenText = text
        lastSpokenRate = rate
        lastSpokenLocale = locale
        if let onSpeakAsync = onSpeakAsync {
            await onSpeakAsync(text, rate, locale)
        }
        isSpeaking = false
    }

    func stop() {
        isSpeaking = false
    }
}

// MARK: - Mock Use Cases

final class MockFetchVocabularyUseCase: FetchVocabularyUseCaseProtocol {
    func executeFetchWords(limit: Int) async throws -> [Word] { [] }
    func executeSearch(query: String) async throws -> [Word] { [] }
    func executeFetchDrills(cefrLevel: String) async throws -> [ReflexDrillRecord] { [] }
}

final class MockEvaluateSRSUseCase: EvaluateSRSUseCaseProtocol {
    func evaluateResponse(currentMastery: Int, easeFactor: Double, isCorrect: Bool, responseTimeMs: Int) -> SRSResult {
        SRSResult(
            nextMastery: isCorrect ? currentMastery + 1 : max(0, currentMastery - 1),
            easeFactor: isCorrect ? easeFactor + 0.1 : max(1.3, easeFactor - 0.2),
            intervalDays: isCorrect ? max(1, currentMastery + 1) : 1
        )
    }
    func recordReview(wordId: Int64, isCorrect: Bool, responseTimeMs: Int) async throws -> SRSResult {
        evaluateResponse(currentMastery: 0, easeFactor: 2.5, isCorrect: isCorrect, responseTimeMs: responseTimeMs)
    }
}

// MARK: - ViewModel Unit Tests

@MainActor
final class ReflexDrillViewModelTests: XCTestCase {
    private var mockSTT: MockSpeechRecognitionService!
    private var mockTTS: MockTextToSpeechService!
    private var mockFetchUseCase: MockFetchVocabularyUseCase!
    private var mockSRSUseCase: MockEvaluateSRSUseCase!
    private var viewModel: ReflexDrillViewModel!

    override func setUp() {
        super.setUp()
        mockSTT = MockSpeechRecognitionService()
        mockTTS = MockTextToSpeechService()
        mockFetchUseCase = MockFetchVocabularyUseCase()
        mockSRSUseCase = MockEvaluateSRSUseCase()
        viewModel = ReflexDrillViewModel(
            fetchVocabularyUseCase: mockFetchUseCase,
            evaluateSRSUseCase: mockSRSUseCase,
            ttsService: mockTTS,
            sttService: mockSTT,
            cefrLevel: "B1"
        )
    }

    override func tearDown() {
        viewModel = nil
        mockSTT = nil
        mockTTS = nil
        mockFetchUseCase = nil
        mockSRSUseCase = nil
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
