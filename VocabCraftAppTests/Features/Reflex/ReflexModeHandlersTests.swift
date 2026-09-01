import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("Reflex Mode Strategy Handlers Tests")
@MainActor
struct ReflexModeHandlersTests {
    private let sampleWord = ReflexBlitzWordItem(
        id: 1,
        lemma: "ephemeral",
        pos: "adj.",
        definitionVi: "Phù du, ngắn ngủi",
        exampleSentenceEn: "Fame is ephemeral in this modern era",
        exampleSentenceVi: "Danh tiếng thì phù du trong thời hiện đại"
    )

    private let samplePool = [
        ReflexBlitzWordItem(id: 1, lemma: "ephemeral", definitionVi: "Phù du"),
        ReflexBlitzWordItem(id: 2, lemma: "vital", definitionVi: "Quan trọng"),
        ReflexBlitzWordItem(id: 3, lemma: "serendipity", definitionVi: "Sự may mắn"),
        ReflexBlitzWordItem(id: 4, lemma: "resilient", definitionVi: "Kiên cường")
    ]

    // MARK: - Factory Tests

    @Test("ReflexModeHandlerFactory returns correct strategy for each mode")
    func testFactory() {
        #expect(ReflexModeHandlerFactory.handler(for: .multipleChoice) is MultipleChoiceModeHandler)
        #expect(ReflexModeHandlerFactory.handler(for: .typing) is TypingModeHandler)
        #expect(ReflexModeHandlerFactory.handler(for: .speaking) is SpeakingModeHandler)
        #expect(ReflexModeHandlerFactory.handler(for: .listening) is ListeningModeHandler)
    }

    // MARK: - Multiple Choice Handler Tests

    @Test("MultipleChoiceModeHandler properties and validation")
    func testMultipleChoiceHandler() {
        let handler = MultipleChoiceModeHandler()
        #expect(handler.mode == .multipleChoice)
        #expect(handler.timeLimitSeconds == 4.5)
        #expect(handler.shouldSpeakOnReviewFlip == true)
        #expect(handler.reviewSpeechRate == 1.0)
        #expect(handler.reviewSpeechDelayMs == 0)

        // Validation
        let correctOpt = ReflexBlitzOption(id: "1", text: "ephemeral", isCorrect: true)
        let wrongOpt = ReflexBlitzOption(id: "2", text: "vital", isCorrect: false)
        #expect(handler.validateOption(correctOpt) == true)
        #expect(handler.validateOption(wrongOpt) == false)

        // Hint stage calculation
        #expect(handler.hintStage(forElapsedTimeMs: 0) == 0)
        #expect(handler.hintStage(forElapsedTimeMs: 1599) == 0)
        #expect(handler.hintStage(forElapsedTimeMs: 1600) == 1)
        #expect(handler.hintStage(forElapsedTimeMs: 2500) == 2)
        #expect(handler.hintStage(forElapsedTimeMs: 3400) == 3)

        // Prepare word fallback generates options
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockResilientReflexSpeechEngine()
        let prep = handler.prepareWord(
            word: sampleWord,
            allWords: samplePool,
            planItem: nil,
            ttsService: mockTTS,
            speechEngine: mockSpeech,
            isKeyboardFallback: false
        )
        #expect(prep.options.count == 4)
        #expect(prep.options.contains(where: { $0.isCorrect && $0.text == "ephemeral" }))
    }

    // MARK: - Typing Handler Tests

    @Test("TypingModeHandler normalization, fuzzy comparison, and empty input handling")
    func testTypingHandler() {
        let handler = TypingModeHandler()
        #expect(handler.mode == .typing)
        #expect(handler.timeLimitSeconds == 7.5)
        #expect(handler.shouldSpeakOnReviewFlip == true)
        #expect(handler.reviewSpeechRate == 0.5)
        #expect(handler.reviewSpeechDelayMs == 250)

        // Empty input returns .empty
        #expect(handler.validateTyping(input: "", targetLemma: "ephemeral") == .empty)
        #expect(handler.validateTyping(input: "   \n\t", targetLemma: "ephemeral") == .empty)

        // Exact match with whitespace and case differences
        let correctResult = handler.validateTyping(input: "  EPHEMERAL \n", targetLemma: "ephemeral")
        #expect(correctResult == .evaluated(isCorrect: true, cleanInput: "EPHEMERAL"))

        // Incorrect input
        let wrongResult = handler.validateTyping(input: "ephemral", targetLemma: "ephemeral")
        #expect(wrongResult == .evaluated(isCorrect: false, cleanInput: "ephemral"))

        // Hint stage calculation
        #expect(handler.hintStage(forElapsedTimeMs: 0) == 0)
        #expect(handler.hintStage(forElapsedTimeMs: 2499) == 0)
        #expect(handler.hintStage(forElapsedTimeMs: 2500) == 1)
        #expect(handler.hintStage(forElapsedTimeMs: 4500) == 2)
    }

    // MARK: - Speaking Handler Tests

    @Test("SpeakingModeHandler transcript matching, speech engine lifecycle, and milestones")
    func testSpeakingHandler() {
        let handler = SpeakingModeHandler()
        #expect(handler.mode == .speaking)
        #expect(handler.timeLimitSeconds == 6.0)
        #expect(handler.shouldSpeakOnReviewFlip == true)
        #expect(handler.reviewSpeechRate == 0.5)
        #expect(handler.reviewSpeechDelayMs == 250)

        // Speech validation
        #expect(handler.validateSpokenMatch(spokenText: "ephemeral", targetLemma: "ephemeral") == true)
        #expect(handler.validateSpokenMatch(spokenText: "  EPHEMERAL \n", targetLemma: "ephemeral") == true)
        #expect(handler.validateSpokenMatch(spokenText: "I think it is ephemeral today", targetLemma: "ephemeral") == true)
        #expect(handler.validateSpokenMatch(spokenText: "unrelated words", targetLemma: "ephemeral") == false)
        #expect(handler.validateSpokenMatch(spokenText: "", targetLemma: "ephemeral") == false)

        // Lifecycle calls
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockResilientReflexSpeechEngine()

        _ = handler.prepareWord(
            word: sampleWord,
            allWords: samplePool,
            planItem: nil,
            ttsService: mockTTS,
            speechEngine: mockSpeech,
            isKeyboardFallback: false
        )
        #expect(mockSpeech.beginWordCallCount == 1)
        #expect(mockSpeech.lastTargetLemma == "ephemeral")

        handler.onWordCompleted(speechEngine: mockSpeech)
        #expect(mockSpeech.endWordCallCount == 1)

        handler.onTimeout(speechEngine: mockSpeech)
        #expect(mockSpeech.endWordCallCount == 2)

        // Hint stage calculation
        #expect(handler.hintStage(forElapsedTimeMs: 0) == 0)
        #expect(handler.hintStage(forElapsedTimeMs: 2500) == 1)
        #expect(handler.hintStage(forElapsedTimeMs: 4000) == 2)
        #expect(handler.hintStage(forElapsedTimeMs: 5000) == 3)
    }

    // MARK: - Listening Handler Tests

    @Test("ListeningModeHandler auto-speak on load, hint audio replay, and mute on review flip")
    func testListeningHandler() {
        let handler = ListeningModeHandler()
        #expect(handler.mode == .listening)
        #expect(handler.timeLimitSeconds == 5.5)
        #expect(handler.shouldSpeakOnReviewFlip == false)

        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockResilientReflexSpeechEngine()

        // Prepare word auto-speaks
        let prep = handler.prepareWord(
            word: sampleWord,
            allWords: samplePool,
            planItem: nil,
            ttsService: mockTTS,
            speechEngine: mockSpeech,
            isKeyboardFallback: false
        )
        #expect(mockTTS.speakCallCount == 1)
        #expect(mockTTS.lastSpokenText == "ephemeral")
        #expect(prep.options.count == 4)
        #expect(prep.options.contains(where: { $0.isCorrect && $0.text == sampleWord.definitionVi }))

        // Hint stage triggers audio replay
        handler.onHintStageReached(stage: 1, word: sampleWord, ttsService: mockTTS)
        #expect(mockTTS.speakCallCount == 2)

        handler.onHintStageReached(stage: 2, word: sampleWord, ttsService: mockTTS)
        #expect(mockTTS.speakCallCount == 3)

        // Hint stage calculation
        #expect(handler.hintStage(forElapsedTimeMs: 0) == 0)
        #expect(handler.hintStage(forElapsedTimeMs: 1800) == 1)
        #expect(handler.hintStage(forElapsedTimeMs: 3000) == 2)
    }
}
#endif
