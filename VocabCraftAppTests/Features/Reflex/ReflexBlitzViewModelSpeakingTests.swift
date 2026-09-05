import CraftUIKit
import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("ReflexBlitzViewModel Speaking Tests")
@MainActor
struct ReflexBlitzViewModelSpeakingTests {
    private let sampleWords = [
        ReflexBlitzWordItem(
            id: 1, lemma: "ephemeral", pos: "adj.",
            definitionVi: "Phù du", exampleSentenceEn: "Fame is ephemeral",
            exampleSentenceVi: "Danh tiếng thì phù du"
        ),
        ReflexBlitzWordItem(
            id: 2, lemma: "vital", pos: "adj.",
            definitionVi: "Quan trọng", exampleSentenceEn: "Water is vital",
            exampleSentenceVi: "Nước là sống còn"
        )
    ]

    private func makeSUT() -> (
        viewModel: ReflexBlitzViewModel,
        speechEngine: MockResilientReflexSpeechEngine,
        tts: MockTextToSpeechService,
        sound: MockSoundEffectService
    ) {
        let mockSpeechEngine = MockResilientReflexSpeechEngine()
        let mockTTS = MockTextToSpeechService()
        let mockSRS = MockEvaluateSRSUseCase()
        let mockSound = MockSoundEffectService()

        let viewModel = ReflexBlitzViewModel(
            words: sampleWords,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS,
            soundEffectService: mockSound,
            speechEngine: mockSpeechEngine
        )
        return (viewModel, mockSpeechEngine, mockTTS, mockSound)
    }

    // MARK: - Readiness-Gated Lifecycle Tests

    @Test("Speaking countdown does not start audio session or capture")
    func speakingCountdownDoesNotStartAudioSessionOrCapture() {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        viewModel.selectMode(.speaking)
        #expect(mockSpeechEngine.isWordActive == false)
        #expect(mockSpeechEngine.startListeningCallCount == 0)
        #expect(mockSpeechEngine.beginWordCallCount == 0)
        #expect(mockSpeechEngine.lastStartSessionWasLazy == true)
    }

    @Test("Reflex stopwatch waits for speech readiness")
    func reflexStopwatchWaitsForSpeechReadiness() async {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        mockSpeechEngine.shouldSuspendStartListening = true
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        await Task.yield()

        #expect(mockSpeechEngine.startListeningCallCount == 1)
        #expect(mockSpeechEngine.isWordActive == false)
        #expect(viewModel.speechState == .preparing)
        #expect(viewModel.wordStartTime == nil)
        #expect(viewModel.elapsedTimeMs == 0)
        #expect(viewModel.hintStage == 0)

        // Resume startListening
        mockSpeechEngine.startListeningContinuation?.resume()
        mockSpeechEngine.startListeningContinuation = nil
        mockSpeechEngine.shouldSuspendStartListening = false

        // Yield to allow async task to complete
        try? await Task.sleep(for: .milliseconds(30))

        #expect(viewModel.speechState.isListening)
        #expect(viewModel.wordStartTime != nil)
        #expect(mockSpeechEngine.isWordActive == true)
    }

    @Test("Reflex cancellation during start does not load stale word")
    func reflexCancellationDuringStartDoesNotLoadStaleWord() async {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        mockSpeechEngine.shouldSuspendStartListening = true
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        await Task.yield()

        #expect(mockSpeechEngine.startListeningCallCount == 1)
        let word0Continuation = mockSpeechEngine.startListeningContinuation

        // Advance to next word while word 0 is still starting
        mockSpeechEngine.shouldSuspendStartListening = false
        viewModel.advanceToNextWord()
        await Task.yield()

        #expect(viewModel.currentWordIndex == 1)
        #expect(viewModel.currentWord?.lemma == "vital")

        // Resume word 0 continuation
        word0Continuation?.resume()
        try? await Task.sleep(for: .milliseconds(30))

        #expect(viewModel.currentWordIndex == 1)
        #expect(viewModel.currentWord?.lemma == "vital")
    }

    @Test("Reflex permission denial falls back to typing mode for remaining items")
    func reflexPermissionDenialFallsBackToTyping() async {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        mockSpeechEngine.simulatedStartListeningError = SpeechCaptureError.microphoneDenied
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        await Task.yield()

        try? await Task.sleep(for: .milliseconds(30))

        #expect(viewModel.selectedMode == .typing)
        #expect(viewModel.speechState == .unavailable)
        #expect(viewModel.isPermissionNoticePresented == true)
    }

    // MARK: - Match Detection

    @Test("Speaking mode match detected transitions to reviewed")
    func testSpeakingMode_matchDetected_transitionsToReviewed() async {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        await Task.yield()
        mockSpeechEngine.simulateMatch("ephemeral")

        if case .reviewed(let result) = viewModel.cardPhase {
            #expect(result.isCorrect == true)
            #expect(result.isTimeout == false)
        } else {
            Issue.record("Expected reviewed state")
        }
    }

    @Test("Speaking mode match detected calls end word")
    func testSpeakingMode_matchDetected_callsEndWord() async {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        await Task.yield()
        mockSpeechEngine.simulateMatch("ephemeral")
        #expect(mockSpeechEngine.endWordCallCount == 1)
        #expect(mockSpeechEngine.isWordActive == false)
    }

    @Test("Speaking mode match detected plays success chime")
    func testSpeakingMode_matchDetected_playsSuccessChime() async {
        let (viewModel, mockSpeechEngine, _, mockSound) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        await Task.yield()
        mockSpeechEngine.simulateMatch("ephemeral")
        #expect(mockSound.successChimePlayed == true)
    }

    // MARK: - Timeout

    @Test("Speaking mode timeout transitions to reviewed")
    func testSpeakingMode_timeout_transitionsToReviewed() {
        let (viewModel, _, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 6000)

        if case .reviewed(let result) = viewModel.cardPhase {
            #expect(result.isCorrect == false)
            #expect(result.isTimeout == true)
        } else {
            Issue.record("Expected reviewed state")
        }
    }

    @Test("Speaking mode timeout calls end word")
    func testSpeakingMode_timeout_callsEndWord() {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 6000)
        #expect(mockSpeechEngine.endWordCallCount >= 1)
    }

    // MARK: - Transcript Updates

    @Test("Speaking mode transcript update reflected in view model")
    func testSpeakingMode_transcriptUpdate_reflectedInViewModel() async {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        await Task.yield()
        mockSpeechEngine.simulateTranscript("hello world")
        #expect(viewModel.liveTranscript == "hello world")
    }

    // MARK: - Word Transition

    @Test("Speaking mode advance to next word cycles begin/end word")
    func testSpeakingMode_advanceToNextWord_cyclesBeginEndWord() async {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        await Task.yield()
        let initialStartCount = mockSpeechEngine.startListeningCallCount

        mockSpeechEngine.simulateMatch("ephemeral")
        viewModel.advanceToNextWord()
        await Task.yield()

        #expect(mockSpeechEngine.startListeningCallCount >= initialStartCount + 1)
        #expect(mockSpeechEngine.lastTargetLemma == "vital")
    }

    // MARK: - Hint Progression

    @Test("Speaking mode hint stage 1 at 2500ms")
    func testSpeakingMode_hintStage1_at2500ms() {
        let (viewModel, _, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 2500)
        #expect(viewModel.hintStage >= 1)
    }

    @Test("Speaking mode hint stage 2 at 4000ms")
    func testSpeakingMode_hintStage2_at4000ms() {
        let (viewModel, _, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 4000)
        #expect(viewModel.hintStage >= 2)
    }

    @Test("Speaking mode hint stage 3 at 5000ms")
    func testSpeakingMode_hintStage3_at5000ms() {
        let (viewModel, _, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.simulateElapsedTime(ms: 5000)
        #expect(viewModel.hintStage >= 3)
    }

    // MARK: - Error Handling

    @Test("Speaking mode speech engine error does not trigger keyboard fallback")
    func testSpeakingMode_speechEngineError_doesNotTriggerKeyboardFallback() {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        let testError = NSError(domain: "test", code: 403, userInfo: nil)
        mockSpeechEngine.simulateError(testError)
        #expect(viewModel.selectedMode == .speaking)
        #expect(viewModel.cardPhase == .activeCountdown)
    }

    // MARK: - Session End

    @Test("Speaking mode finish session stops engine")
    func testSpeakingMode_finishSession_stopsEngine() {
        let (viewModel, mockSpeechEngine, _, _) = makeSUT()
        viewModel.startDrillSession(mode: .speaking, words: sampleWords)
        viewModel.finishSession()
        #expect(mockSpeechEngine.stopSessionCallCount == 1)
        #expect(mockSpeechEngine.isSessionActive == false)
    }
}
#endif
