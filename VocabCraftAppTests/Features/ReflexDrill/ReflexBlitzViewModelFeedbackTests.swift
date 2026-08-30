import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

// MARK: - Swift Testing 4 Modalities Feedback Suite

#if canImport(Testing)
@Suite("Reflex Blitz 4 Modalities Feedback Tests")
struct ReflexBlitzViewModelFeedbackTests {
    @Test("Speaking and Typing allow Skip; MC and Listening trigger instant feedback on choice")
    @MainActor
    func testModalityInteractions() {
        let viewModel = ReflexBlitzViewModel()
        let sampleWord = ReflexBlitzWordItem(id: 1, lemma: "capital", ipa: "/kæp/", definitionVi: "thủ đô", clozeSentenceEn: "Tokyo is a [capital].", clozeSentenceVi: "Tokyo là thủ đô.")
        viewModel.startDrillSession(mode: .speaking, words: [sampleWord])

        // Initially feedback is not presented
        #expect(viewModel.isFeedbackPresented == false)

        // Skip in Speaking should transition to reviewed with feedback
        viewModel.handleTimeout()
        #expect(viewModel.isFeedbackPresented == true)

        // Multiple Choice selection
        viewModel.startDrillSession(mode: .multipleChoice, words: [sampleWord])
        #expect(viewModel.isFeedbackPresented == false)
        let opt = ReflexBlitzOption(id: "1", text: "capital", isCorrect: true)
        viewModel.selectOption(opt)
        #expect(viewModel.isFeedbackPresented == true)
        #expect(viewModel.currentAttemptIsCorrect == true)
    }

    @Test("Typing submission handles empty, correct, and incorrect inputs")
    @MainActor
    func testTypingSubmission() async {
        let sampleWord = ReflexBlitzWordItem(
            id: 1, lemma: "apple", pos: "n.", ipa: "/ˈæpl/",
            definitionVi: "quả táo", exampleSentenceEn: "I eat an apple.",
            exampleSentenceVi: "Tôi ăn một quả táo.", level: "A1"
        )
        let viewModel = ReflexBlitzViewModel(words: [sampleWord])
        viewModel.selectMode(.typing)
        viewModel.beginSessionDirectly()

        // Empty string should be ignored
        viewModel.submitTypingAnswer("   ")
        #expect(viewModel.cardPhase == .activeCountdown)

        // Incorrect string should transition to reviewed with isCorrect = false
        viewModel.submitTypingAnswer("aple")
        if case .reviewed(let result) = viewModel.cardPhase {
            #expect(result.isCorrect == false)
            #expect(result.typedText == "aple")
        } else {
            Issue.record("Expected reviewed phase on incorrect typing")
        }
    }

    @Test("Typing submission triggers feedback presentation and case-insensitive check")
    @MainActor
    func testTypingFeedbackInteractions() {
        let viewModel = ReflexBlitzViewModel()
        let sampleWord = ReflexBlitzWordItem(id: 2, lemma: "eloquent", ipa: "/ˈel.ə.kwənt/", definitionVi: "Hùng biện", clozeSentenceEn: "He is [eloquent].", clozeSentenceVi: "Anh ấy rất hùng biện.")
        viewModel.startDrillSession(mode: .typing, words: [sampleWord])

        #expect(viewModel.isFeedbackPresented == false)

        // Empty typing should NOT trigger feedback
        viewModel.submitTypingAnswer("   ")
        #expect(viewModel.isFeedbackPresented == false)

        // Correct typing triggers feedback
        viewModel.submitTypingAnswer("  ELOQUENT \n")
        #expect(viewModel.isFeedbackPresented == true)
        #expect(viewModel.currentAttemptIsCorrect == true)
    }

    @Test("Listening mode auto-speaks lemma and option selection triggers feedback")
    @MainActor
    func testListeningFeedbackInteractions() {
        let mockSpeech = MockContinuousReflexSpeechService()
        let mockTTS = MockTextToSpeechService()
        let mockSRS = MockEvaluateSRSUseCase()
        let sampleWord = ReflexBlitzWordItem(id: 3, lemma: "resilient", ipa: "/rɪˈzɪl.jənt/", definitionVi: "Kiên cường", clozeSentenceEn: "They are [resilient].", clozeSentenceVi: "Họ kiên cường.")

        let viewModel = ReflexBlitzViewModel(
            words: [sampleWord],
            continuousSpeechService: mockSpeech,
            ttsService: mockTTS,
            evaluateSRSUseCase: mockSRS
        )
        viewModel.startDrillSession(mode: .listening, words: [sampleWord])

        #expect(mockTTS.lastSpokenText == "resilient")
        #expect(viewModel.isFeedbackPresented == false)

        let correctOpt = viewModel.currentOptions.first(where: { $0.isCorrect })!
        viewModel.selectOption(correctOpt)
        #expect(viewModel.isFeedbackPresented == true)
        #expect(viewModel.currentAttemptIsCorrect == true)
    }

    @Test("Advancing to next word resets isFeedbackPresented to false")
    @MainActor
    func testAdvanceResetsFeedbackState() {
        let viewModel = ReflexBlitzViewModel()
        let word1 = ReflexBlitzWordItem(id: 1, lemma: "first", definitionVi: "thứ nhất")
        let word2 = ReflexBlitzWordItem(id: 2, lemma: "second", definitionVi: "thứ hai")
        viewModel.startDrillSession(mode: .typing, words: [word1, word2])

        guard let firstWord = viewModel.currentWord else {
            Issue.record("No first word")
            return
        }

        viewModel.submitTypingAnswer(firstWord.lemma)
        #expect(viewModel.isFeedbackPresented == true)

        viewModel.advanceToNextWord()
        #expect(viewModel.isFeedbackPresented == false)
        #expect(viewModel.currentWordIndex == 1)
        #expect(viewModel.currentWord != nil)
    }
}

// MARK: - Pre-generation & Hint Scaffolding Tests

@Suite("Reflex Blitz ViewModel Pre-generation Tests")
struct ReflexBlitzViewModelPreGenerationTests {
    @Test("startDrillSession initializes sessionPlan and loads first plan item without runtime delay")
    @MainActor
    func testSessionPlanInitialization() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)
        #expect(viewModel.sessionPlan != nil)
        #expect(viewModel.sessionPlan?.items.count == ReflexBlitzWordItem.defaultStarterWords.count)
        #expect(viewModel.currentPlanItem != nil)
        #expect(viewModel.currentOptions.count == 4)
    }

    @Test("Hint stages progress from 0 -> 1 -> 2 -> 3 with simulated elapsed time")
    @MainActor
    func testProgressiveHintStages() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)

        viewModel.simulateElapsedTime(ms: 0)
        #expect(viewModel.hintStage == 0)

        viewModel.simulateElapsedTime(ms: 1700)
        #expect(viewModel.hintStage == 1)

        viewModel.simulateElapsedTime(ms: 2600)
        #expect(viewModel.hintStage == 2)

        viewModel.simulateElapsedTime(ms: 3500)
        #expect(viewModel.hintStage == 3)
    }

    @Test("loadWord binds planItem options, clozeStages, eliminatedOptionId, and hintBadgeText")
    @MainActor
    func testLoadWordBindsPlanItemProperties() {
        let viewModel = ReflexBlitzViewModel(words: ReflexBlitzWordItem.defaultStarterWords)
        viewModel.startDrillSession(mode: .multipleChoice)

        #expect(viewModel.currentPlanItem != nil)
        #expect(viewModel.currentClozeStages != nil)
        #expect(viewModel.currentEliminatedOptionId != nil)
        #expect(!viewModel.currentHintBadgeText.isEmpty)
        #expect(viewModel.currentOptions == viewModel.currentPlanItem?.options)
    }
}
#endif
