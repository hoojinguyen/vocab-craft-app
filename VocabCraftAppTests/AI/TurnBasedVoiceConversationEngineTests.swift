import Foundation
import Testing
@testable import VocabCraftApp

@Suite("TurnBasedVoiceConversationEngine Tests", .serialized)
struct TurnBasedVoiceConversationEngineTests {
    private func makeTestScenario() -> RoleplayScenario {
        RoleplayScenario(
            id: "scenario_test",
            titleKey: "test_title",
            descriptionKey: "test_desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome to The Daily Roast! What can I get for you?",
            targetWordIds: ["espresso", "croissant"],
            iconSymbol: "cup.and.saucer.fill"
        )
    }

    @Test("Engine transitions from idle to speaking on startCall")
    @MainActor
    func startCallLifecycle() async {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            speechDelaySeconds: 0.05,
            silenceDelaySeconds: 0.05
        )

        #expect(engine.state == .idle)
        await engine.startCall()
        #expect(engine.messages.count == 1)
        #expect(engine.state == .speaking(characterText: scenario.initialGreeting))
        #expect(mockTTS.lastSpokenText == scenario.initialGreeting)
    }

    @Test("Engine transitions from speaking to listening after speech delay")
    @MainActor
    func transitionToListeningAfterSpeech() async throws {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            speechDelaySeconds: 0.02,
            silenceDelaySeconds: 0.02
        )

        await engine.startCall()
        #expect(engine.state == .speaking(characterText: scenario.initialGreeting))

        // Wait for speech delay task to fire
        try? await Task.sleep(for: .milliseconds(60))
        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(mockSpeech.isListening)
    }

    @Test("Transcript update sets listening live transcript")
    @MainActor
    func liveTranscriptUpdate() async {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            speechDelaySeconds: 1.0,
            silenceDelaySeconds: 1.0
        )

        engine.startListening()
        #expect(engine.state == .listening(liveTranscript: ""))

        mockSpeech.simulateResult("I would like an")
        // Yield to allow @MainActor Task to execute
        await Task.yield()
        #expect(engine.state == .listening(liveTranscript: "I would like an"))
    }

    @Test("Manual turn finish processes user utterance and triggers AI reply")
    @MainActor
    func manualTurnFinishFlow() async throws {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockTurnOutput = RoleplayTurnOutput(
            characterReply: "One hot espresso coming right up!",
            targetWordsUsed: ["espresso"],
            refinementSuggestion: "You could say: 'May I please have an espresso?'",
            pedagogicalNote: "Good use of espresso!"
        )
        let mockLLM = MockLLMProvider(mockTurnOutput: mockTurnOutput)
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            speechDelaySeconds: 1.0,
            silenceDelaySeconds: 1.0
        )

        engine.startListening()
        mockSpeech.simulateResult("Can I get an espresso?")
        await Task.yield()

        await engine.processUserUtterance("Can I get an espresso?")

        #expect(engine.masteredTargetWords.contains("espresso"))
        #expect(engine.messages.count == 2)
        #expect(engine.messages[0].sender == .user)
        #expect(engine.messages[0].text == "Can I get an espresso?")
        #expect(engine.messages[1].text == "One hot espresso coming right up!")
        #expect(engine.messages[1].refinementSuggestion == "You could say: 'May I please have an espresso?'")
        #expect(engine.state == .speaking(characterText: "One hot espresso coming right up!"))
        #expect(mockTTS.lastSpokenText == "One hot espresso coming right up!")
    }

    @Test("Toggle mute stops and resumes speech listening")
    @MainActor
    func toggleMuteBehavior() async {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        engine.startListening()
        #expect(mockSpeech.isListening)
        #expect(!engine.isMuted)

        engine.toggleMute()
        #expect(engine.isMuted)
        #expect(!mockSpeech.isListening)

        engine.toggleMute()
        #expect(!engine.isMuted)
        #expect(mockSpeech.isListening)
    }

    @Test("Toggle subtitles flips flag")
    @MainActor
    func toggleSubtitlesBehavior() {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        #expect(engine.isSubtitlesVisible)
        engine.toggleSubtitles()
        #expect(!engine.isSubtitlesVisible)
        engine.toggleSubtitles()
        #expect(engine.isSubtitlesVisible)
    }

    @Test("End call stops audio services and returns session summary")
    @MainActor
    func endCallLifecycle() async {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        await engine.startCall()
        engine.startListening()
        #expect(mockSpeech.isListening)

        let summary = await engine.endCall()

        #expect(engine.state == .ended)
        #expect(!mockSpeech.isListening)
        #expect(!mockTTS.isSpeaking)
        #expect(summary.scenarioId == scenario.id)
    }
}
