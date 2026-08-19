@testable import VocabCraftApp
import XCTest

@MainActor
final class ReflexBlitzViewModelTests: XCTestCase {
    private var mockSpeech: MockContinuousReflexSpeechService!
    private var mockTTS: MockTextToSpeechService!
    private var mockSRS: MockEvaluateSRSUseCase!
    private var mockSound: MockSoundEffectService!
    private var viewModel: ReflexBlitzViewModel!

    private let sampleWords = [
        ReflexBlitzWordItem(
            id: 1,
            lemma: "ephemeral",
            pos: "adj.",
            definitionVi: "Phù du, ngắn ngủi",
            exampleSentenceEn: "Fame is ephemeral in this modern era",
            exampleSentenceVi: "Danh tiếng thì phù du trong thời hiện đại"
        ),
        ReflexBlitzWordItem(
            id: 2,
            lemma: "vital",
            pos: "adj.",
            definitionVi: "Quan trọng, sống còn",
            exampleSentenceEn: "Water is vital for all living things",
            exampleSentenceVi: "Nước là sống còn cho mọi sinh vật"
        ),
        ReflexBlitzWordItem(
            id: 3,
            lemma: "serendipity",
            pos: "n.",
            definitionVi: "Sự tình cờ may mắn",
            exampleSentenceEn: "Finding that book was pure serendipity",
            exampleSentenceVi: "Tìm thấy cuốn sách đó là sự tình cờ may mắn thuần túy"
        )
    ]

    override func setUp() {
        super.setUp()
        mockSpeech = MockContinuousReflexSpeechService()
        mockTTS = MockTextToSpeechService()
        mockSRS = MockEvaluateSRSUseCase()
        mockSound = MockSoundEffectService()

        viewModel = ReflexBlitzViewModel(
            words: sampleWords,
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS,
            soundEffectService: mockSound
        )
    }

    override func tearDown() {
        viewModel = nil
        mockSpeech = nil
        mockTTS = nil
        mockSRS = nil
        mockSound = nil
        super.tearDown()
    }

    func testInitialCountdownPhase() {
        XCTAssertEqual(viewModel.phase, .countdown)
        XCTAssertEqual(viewModel.countdownCount, 3)
        XCTAssertEqual(viewModel.words.count, 3)
        XCTAssertEqual(viewModel.currentWordIndex, 0)
        XCTAssertEqual(viewModel.progressFraction, 0.0)
    }

    func testStartDrillingAndAutoAdvanceOnCorrectMatch() async {
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.phase, .drilling)
        XCTAssertEqual(viewModel.currentWordIndex, 0)
        XCTAssertEqual(viewModel.currentWord?.lemma, "ephemeral")
        XCTAssertTrue(mockSpeech.isSessionActive)

        // Simulate correct speech recognition
        mockSpeech.simulateTranscript("ephemeral")

        XCTAssertTrue(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(mockSound.playSuccessChimeCallCount, 1)
        XCTAssertEqual(viewModel.comboStreak, 1)
        XCTAssertEqual(viewModel.maxComboStreak, 1)
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.attempts.first?.lemma, "ephemeral")
        XCTAssertTrue(viewModel.attempts.first?.isCorrect ?? false)
    }

    func testHandleSpokenMatchPlaysSuccessChimeAndAccurateResponseTime() async {
        viewModel.beginSessionDirectly()
        viewModel.simulateElapsedTime(ms: 1200)

        mockSpeech.simulateTranscript("ephemeral")

        XCTAssertEqual(mockSound.playSuccessChimeCallCount, 1, "Should play success chime on match")
        XCTAssertEqual(viewModel.attempts.first?.responseTimeMs, 1200, "Response time must record match time without including dwell delay")

        // Dwell time: 1000ms delay before advancing
        XCTAssertEqual(viewModel.currentWordIndex, 0, "Should remain on current word immediately after match")
        try? await Task.sleep(for: .milliseconds(500))
        XCTAssertEqual(viewModel.currentWordIndex, 0, "Should still be on word 0 during 1000ms dwell")
        try? await Task.sleep(for: .milliseconds(600))
        XCTAssertEqual(viewModel.currentWordIndex, 1, "Should advance to word 1 after 1000ms dwell")
    }

    func testHintRevealsAt3500ms() {
        viewModel.beginSessionDirectly()
        XCTAssertFalse(viewModel.showHint)

        viewModel.simulateElapsedTime(ms: 3600)
        XCTAssertTrue(viewModel.showHint)
    }

    func testSimulateElapsedTimeAt6000TriggersTimeout() async {
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.phase, .drilling)

        viewModel.simulateElapsedTime(ms: 6000)
        XCTAssertEqual(viewModel.phase, .timeoutRevealing)
        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertTrue(mockSpeech.isRecognitionMuted, "Speech recognition should be paused during timeout")

        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral")
    }

    func testTimeoutTriggersRevealTTSAndResetsCombo() async {
        viewModel.beginSessionDirectly()
        viewModel.comboStreak = 4
        viewModel.maxComboStreak = 4

        viewModel.handleTimeout()

        XCTAssertEqual(viewModel.phase, .timeoutRevealing)
        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(viewModel.maxComboStreak, 4)
        XCTAssertTrue(mockSpeech.isRecognitionMuted, "Recognition should be paused on timeout")
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertFalse(viewModel.attempts.first?.isCorrect ?? true)
        XCTAssertEqual(viewModel.attempts.first?.responseTimeMs, 6000)

        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral")
        XCTAssertEqual(mockTTS.speakAsyncCallCount, 1)
    }

    func testHandleTimeoutPausesListeningAwaitsTTSAndResumesAfterBuffer() async {
        viewModel.beginSessionDirectly()
        XCTAssertFalse(mockSpeech.isRecognitionMuted)

        viewModel.handleTimeout()

        XCTAssertTrue(mockSpeech.isRecognitionMuted, "Speech recognition must be paused immediately on timeout")
        XCTAssertEqual(viewModel.phase, .timeoutRevealing)

        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral")
        XCTAssertEqual(mockTTS.speakAsyncCallCount, 1)

        // 300ms buffer after TTS completes before resuming recognition and advancing
        try? await Task.sleep(for: .milliseconds(350))
        XCTAssertFalse(mockSpeech.isRecognitionMuted, "Speech recognition should resume after TTS and 300ms buffer")
        XCTAssertEqual(viewModel.currentWordIndex, 1, "Should advance to next word")
        XCTAssertEqual(viewModel.phase, .drilling, "Phase should return to drilling")
    }

    func testConsecutiveMatchesBuildComboStreak() {
        viewModel.beginSessionDirectly()

        // Match word 1
        mockSpeech.simulateTranscript("ephemeral")
        XCTAssertEqual(viewModel.comboStreak, 1)
        XCTAssertEqual(viewModel.maxComboStreak, 1)

        // Advance to word 2 manually / simulate
        viewModel.handleSpokenMatch("vital") // Not active word yet since index is 0, so should be ignored
        XCTAssertEqual(viewModel.comboStreak, 1)

        viewModel.loadWordForTesting(at: 1)
        mockSpeech.simulateTranscript("The answer is vital today")
        XCTAssertEqual(viewModel.comboStreak, 2)
        XCTAssertEqual(viewModel.maxComboStreak, 2)

        // Word 3 times out -> combo reset
        viewModel.loadWordForTesting(at: 2)
        viewModel.handleTimeout()
        XCTAssertEqual(viewModel.comboStreak, 0)
        XCTAssertEqual(viewModel.maxComboStreak, 2)
    }

    func testSpokenMatchCaseInsensitivityAndWhitespaceTrimming() {
        viewModel.beginSessionDirectly()
        viewModel.handleSpokenMatch("  EPHEMERAL\n")

        XCTAssertTrue(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    func testLiveTranscriptUpdatesPropagated() {
        viewModel.beginSessionDirectly()
        mockSpeech.simulateTranscript("Speaking some words...")

        XCTAssertEqual(viewModel.liveTranscript, "Speaking some words...")
    }

    func testLiveTranscriptResetsWhenLoadingNextWord() {
        viewModel.beginSessionDirectly()
        mockSpeech.simulateTranscript("first word speech")
        XCTAssertEqual(viewModel.liveTranscript, "first word speech")

        // Switch to next word
        viewModel.loadWordForTesting(at: 1)
        XCTAssertEqual(viewModel.liveTranscript, "", "liveTranscript should reset to empty upon loading next word")
    }

    func testKeyboardFallbackSubmission() {
        viewModel.beginSessionDirectly()
        viewModel.toggleKeyboardFallback()
        XCTAssertTrue(viewModel.isKeyboardFallbackActive)

        // Incorrect keyboard input
        viewModel.submitKeyboardInput("wrongword")
        XCTAssertFalse(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(viewModel.comboStreak, 0)

        // Correct keyboard input
        viewModel.submitKeyboardInput("  Ephemeral  ")
        XCTAssertTrue(viewModel.currentAttemptIsCorrect)
        XCTAssertEqual(viewModel.comboStreak, 1)
        XCTAssertEqual(mockSound.playSuccessChimeCallCount, 1, "Keyboard submission should play success chime")
    }

    func testToggleKeyboardFallbackControlsListeningState() {
        viewModel.beginSessionDirectly()
        XCTAssertFalse(viewModel.isKeyboardFallbackActive)
        XCTAssertFalse(mockSpeech.isRecognitionMuted)

        viewModel.toggleKeyboardFallback()
        XCTAssertTrue(viewModel.isKeyboardFallbackActive)
        XCTAssertTrue(mockSpeech.isRecognitionMuted, "Recognition should be paused when keyboard fallback is active")

        viewModel.toggleKeyboardFallback()
        XCTAssertFalse(viewModel.isKeyboardFallbackActive)
        XCTAssertFalse(mockSpeech.isRecognitionMuted, "Recognition should resume when keyboard fallback is deactivated")
    }

    func testDirectKeyboardFallbackActiveMutationControlsListeningState() {
        viewModel.beginSessionDirectly()
        XCTAssertFalse(mockSpeech.isRecognitionMuted)

        viewModel.isKeyboardFallbackActive = true
        XCTAssertTrue(mockSpeech.isRecognitionMuted, "Recognition should be paused when isKeyboardFallbackActive is set to true")

        viewModel.isKeyboardFallbackActive = false
        XCTAssertFalse(mockSpeech.isRecognitionMuted, "Recognition should resume when isKeyboardFallbackActive is set to false")
    }

    func testFinishSessionGeneratesSummary() {
        viewModel.beginSessionDirectly()

        // Attempt 1: Correct
        viewModel.handleSpokenMatch("ephemeral")

        // Attempt 2: Timeout
        viewModel.loadWordForTesting(at: 1)
        viewModel.handleTimeout()

        viewModel.finishSession()

        XCTAssertEqual(viewModel.phase, .summary)
        XCTAssertFalse(mockSpeech.isSessionActive)
        XCTAssertNotNil(viewModel.sessionSummary)
        XCTAssertEqual(viewModel.sessionSummary?.totalWords, 2)
        XCTAssertEqual(viewModel.sessionSummary?.correctWords, 1)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.count, 1)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.first?.lemma, "vital")
    }

    func testReDrillWeakWordsResetsSessionWithOnlyWeakWords() {
        viewModel.beginSessionDirectly()

        // Word 1: Correct
        viewModel.handleSpokenMatch("ephemeral")

        // Word 2: Timeout (weak)
        viewModel.loadWordForTesting(at: 1)
        viewModel.handleTimeout()

        // Word 3: Correct
        viewModel.loadWordForTesting(at: 2)
        viewModel.handleSpokenMatch("serendipity")

        viewModel.finishSession()

        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.count, 1)
        XCTAssertEqual(viewModel.sessionSummary?.weakWordAttempts.first?.wordId, 2)

        viewModel.reDrillWeakWords()

        XCTAssertEqual(viewModel.words.count, 1)
        XCTAssertEqual(viewModel.words.first?.id, 2)
        XCTAssertEqual(viewModel.words.first?.lemma, "vital")
        XCTAssertEqual(viewModel.phase, .countdown)
    }

    func testProgressFraction() {
        viewModel.beginSessionDirectly()
        XCTAssertEqual(viewModel.progressFraction, 0.0)

        viewModel.loadWordForTesting(at: 1)
        XCTAssertEqual(viewModel.progressFraction, 1.0 / 3.0, accuracy: 0.001)

        viewModel.loadWordForTesting(at: 2)
        XCTAssertEqual(viewModel.progressFraction, 2.0 / 3.0, accuracy: 0.001)

        let emptyVM = ReflexBlitzViewModel(
            words: [],
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
        XCTAssertEqual(emptyVM.progressFraction, 0.0)
        XCTAssertNil(emptyVM.currentWord)
    }

    func testCancelSessionStopsServices() {
        viewModel.beginSessionDirectly()
        XCTAssertTrue(mockSpeech.isSessionActive)

        viewModel.cancelSession()
        XCTAssertFalse(mockSpeech.isSessionActive)
        XCTAssertFalse(mockTTS.isSpeaking)
    }

    func testStartCountdownInitializesSession() {
        viewModel.startCountdown()
        XCTAssertEqual(viewModel.phase, .countdown)
        XCTAssertEqual(viewModel.countdownCount, 3)
        XCTAssertTrue(mockSpeech.isSessionActive)
    }

    func testRepeatedMatchIgnoredWhenCurrentAttemptAlreadyCorrect() {
        viewModel.beginSessionDirectly()
        viewModel.handleSpokenMatch("ephemeral")
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.comboStreak, 1)

        // Second match on same attempt before advance
        viewModel.handleSpokenMatch("ephemeral")
        XCTAssertEqual(viewModel.attempts.count, 1)
        XCTAssertEqual(viewModel.comboStreak, 1)
    }

    // MARK: - Task 2 Dynamic Timer & Audio Helper Tests

    func testFractionRemainingCalculations() {
        viewModel.beginSessionDirectly()
        viewModel.simulateElapsedTime(ms: 0)
        XCTAssertEqual(viewModel.fractionRemaining, 1.0, accuracy: 0.001)

        viewModel.simulateElapsedTime(ms: 3000)
        XCTAssertEqual(viewModel.fractionRemaining, 0.5, accuracy: 0.001)

        viewModel.simulateElapsedTime(ms: 6000)
        XCTAssertEqual(viewModel.fractionRemaining, 0.0, accuracy: 0.001)

        viewModel.simulateElapsedTime(ms: 7000)
        XCTAssertEqual(viewModel.fractionRemaining, 0.0, accuracy: 0.001)
    }

    func testTimerStagesAcrossIntervals() {
        viewModel.beginSessionDirectly()

        viewModel.simulateElapsedTime(ms: 0)
        XCTAssertEqual(viewModel.timerStage, .steady)

        viewModel.simulateElapsedTime(ms: 3499)
        XCTAssertEqual(viewModel.timerStage, .steady)

        viewModel.simulateElapsedTime(ms: 3500)
        XCTAssertEqual(viewModel.timerStage, .warning)

        viewModel.simulateElapsedTime(ms: 4999)
        XCTAssertEqual(viewModel.timerStage, .warning)

        viewModel.simulateElapsedTime(ms: 5000)
        XCTAssertEqual(viewModel.timerStage, .urgent)

        viewModel.simulateElapsedTime(ms: 5200)
        XCTAssertEqual(viewModel.timerStage, .urgent)

        viewModel.simulateElapsedTime(ms: 6000)
        XCTAssertEqual(viewModel.timerStage, .urgent)
    }

    func testSpeakLemmaInvokesTTSService() {
        mockTTS.lastSpokenText = nil
        mockTTS.isSpeaking = false

        viewModel.speakLemma("serendipity")
        XCTAssertTrue(mockTTS.isSpeaking)
        XCTAssertEqual(mockTTS.lastSpokenText, "serendipity")
    }

    func testSpeakCurrentWordSpeaksActiveLemma() {
        viewModel.beginSessionDirectly()
        mockTTS.lastSpokenText = nil

        viewModel.speakCurrentWord()
        XCTAssertEqual(mockTTS.lastSpokenText, "ephemeral")

        viewModel.loadWordForTesting(at: 1)
        viewModel.speakCurrentWord()
        XCTAssertEqual(mockTTS.lastSpokenText, "vital")

        let emptyVM = ReflexBlitzViewModel(
            words: [],
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
        mockTTS.lastSpokenText = nil
        emptyVM.speakCurrentWord()
        XCTAssertNil(mockTTS.lastSpokenText)
    }

    func testAttemptsAndSummaryContainRichWordMetadata() {
        let richWords = [
            ReflexBlitzWordItem(
                id: 101,
                lemma: "meticulous",
                pos: "adj.",
                ipa: "/məˈtɪk.jə.ləs/",
                definitionVi: "Tỉ mỉ, cẩn thận",
                exampleSentenceEn: "She is meticulous about detail.",
                exampleSentenceVi: "Cô ấy tỉ mỉ về từng chi tiết."
            ),
            ReflexBlitzWordItem(
                id: 102,
                lemma: "resilient",
                pos: "adj.",
                ipa: "/rɪˈzɪl.jənt/",
                definitionVi: "Kiên cường",
                exampleSentenceEn: "They are resilient.",
                exampleSentenceVi: "Họ rất kiên cường."
            )
        ]

        let richVM = ReflexBlitzViewModel(
            words: richWords,
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )

        richVM.beginSessionDirectly()

        // 1. Spoken match on word 0
        richVM.handleSpokenMatch("meticulous")
        XCTAssertEqual(richVM.attempts.count, 1)
        let firstAttempt = richVM.attempts[0]
        XCTAssertEqual(firstAttempt.wordId, 101)
        XCTAssertEqual(firstAttempt.lemma, "meticulous")
        XCTAssertEqual(firstAttempt.pos, "adj.")
        XCTAssertEqual(firstAttempt.ipa, "/məˈtɪk.jə.ləs/")
        XCTAssertEqual(firstAttempt.definitionVi, "Tỉ mỉ, cẩn thận")

        // 2. Timeout on word 1 (Weak word)
        richVM.loadWordForTesting(at: 1)
        richVM.handleTimeout()
        XCTAssertEqual(richVM.attempts.count, 2)
        let secondAttempt = richVM.attempts[1]
        XCTAssertEqual(secondAttempt.wordId, 102)
        XCTAssertEqual(secondAttempt.lemma, "resilient")
        XCTAssertEqual(secondAttempt.pos, "adj.")
        XCTAssertEqual(secondAttempt.ipa, "/rɪˈzɪl.jənt/")
        XCTAssertEqual(secondAttempt.definitionVi, "Kiên cường")

        // 3. Summary weak words contain metadata
        richVM.finishSession()
        guard let summary = richVM.sessionSummary else {
            XCTFail("Expected session summary to exist")
            return
        }

        XCTAssertEqual(summary.weakWordAttempts.count, 1)
        let weakAttempt = summary.weakWordAttempts[0]
        XCTAssertEqual(weakAttempt.wordId, 102)
        XCTAssertEqual(weakAttempt.lemma, "resilient")
        XCTAssertEqual(weakAttempt.pos, "adj.")
        XCTAssertEqual(weakAttempt.ipa, "/rɪˈzɪl.jənt/")
        XCTAssertEqual(weakAttempt.definitionVi, "Kiên cường")
    }
}
