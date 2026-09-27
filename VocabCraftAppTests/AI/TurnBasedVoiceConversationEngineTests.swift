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

    private func makeExecuteUseCase(llmProvider: MockLLMProvider = MockLLMProvider()) -> ExecuteRoleplayTurnUseCase {
        ExecuteRoleplayTurnUseCase(llmProvider: llmProvider)
    }

    private func makeCompleteUseCase() -> CompleteRoleplaySessionUseCase {
        CompleteRoleplaySessionUseCase()
    }

    @Test("Toggling mute while speaking transitions cleanly to listening state")
    @MainActor
    func muteWhileSpeakingTransitionsCleanly() async {
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let engine = TurnBasedVoiceConversationEngine(
            scenario: makeTestScenario(),
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: makeExecuteUseCase(),
            completeSessionUseCase: makeCompleteUseCase()
        )
        mockTTS.onSpeakAsync = { _, _, _ in
            engine.toggleMute()
            #expect(engine.isMuted)
        }
        await engine.startCall()
        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(!mockSpeech.isListening) // Mic should not be capturing while muted
    }

    @Test("finishUserTurnManually with empty transcript does not cancel silence detector")
    @MainActor
    func finishTurnWithEmptyTranscriptPreservesDetector() async {
        let mockSpeech = MockSpeechRecognitionService()
        let engine = TurnBasedVoiceConversationEngine(
            scenario: makeTestScenario(),
            ttsService: MockTextToSpeechService(),
            speechService: mockSpeech,
            executeTurnUseCase: makeExecuteUseCase(),
            completeSessionUseCase: makeCompleteUseCase()
        )
        engine.startListening()
        engine.finishUserTurnManually() // Empty transcript
        #expect(engine.state == .listening(liveTranscript: ""))
    }

    @Test("Speech recognition error with empty transcript records error message and retry restores listening")
    @MainActor
    func speechRecognitionErrorHandlingAndRetry() async {
        let mockSpeech = MockSpeechRecognitionService()
        let engine = TurnBasedVoiceConversationEngine(
            scenario: makeTestScenario(),
            ttsService: MockTextToSpeechService(),
            speechService: mockSpeech,
            executeTurnUseCase: makeExecuteUseCase(),
            completeSessionUseCase: makeCompleteUseCase()
        )
        engine.startListening()
        #expect(engine.audioErrorMessage == nil)

        let sampleError = NSError(domain: "SpeechTest", code: 101, userInfo: [NSLocalizedDescriptionKey: "Microphone access denied"])
        mockSpeech.simulateError(sampleError)
        await Task.yield()

        #expect(engine.audioErrorMessage == "Microphone access denied")

        engine.retryListening()
        #expect(engine.audioErrorMessage == nil)
        #expect(mockSpeech.isListening)
    }

    @Test("Speech recognition error with buffered transcript processes utterance")
    @MainActor
    func speechRecognitionErrorWithBufferedTranscriptProcessesUtterance() async {
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider(mockTurnOutput: RoleplayTurnOutput(
            characterReply: "Sure thing!",
            targetWordsUsed: ["espresso"],
            refinementSuggestion: nil,
            pedagogicalNote: nil
        ))
        let engine = TurnBasedVoiceConversationEngine(
            scenario: makeTestScenario(),
            ttsService: MockTextToSpeechService(),
            speechService: mockSpeech,
            executeTurnUseCase: makeExecuteUseCase(llmProvider: mockLLM),
            completeSessionUseCase: makeCompleteUseCase()
        )
        engine.startListening()
        mockSpeech.simulateResult("I want espresso")
        await Task.yield()

        let sampleError = NSError(domain: "SpeechTest", code: 500, userInfo: [NSLocalizedDescriptionKey: "Audio stream disrupted"])
        mockSpeech.simulateError(sampleError)
        await Task.yield()

        #expect(engine.audioErrorMessage == nil)
        #expect(engine.messages.contains(where: { $0.text == "I want espresso" }))
    }

    @Test("Unmuting while in listening state resumes speech listening")
    @MainActor
    func unmuteWhileListeningResumesMic() async {
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let engine = TurnBasedVoiceConversationEngine(
            scenario: makeTestScenario(),
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: makeExecuteUseCase(),
            completeSessionUseCase: makeCompleteUseCase()
        )
        mockTTS.onSpeakAsync = { _, _, _ in
            engine.toggleMute()
        }
        await engine.startCall()
        #expect(engine.isMuted)
        #expect(!mockSpeech.isListening)
        #expect(engine.state == .listening(liveTranscript: ""))

        engine.toggleMute()
        #expect(!engine.isMuted)
        #expect(mockSpeech.isListening)
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
            completeSessionUseCase: completeUseCase
        )

        var capturedStateDuringSpeech: VoiceCallState?
        mockTTS.onSpeakAsync = { _, _, _ in
            capturedStateDuringSpeech = engine.state
        }

        #expect(engine.state == .idle)
        await engine.startCall()
        #expect(engine.messages.count == 1)
        #expect(capturedStateDuringSpeech == .speaking(characterText: scenario.initialGreeting))
        #expect(mockTTS.lastSpokenText == scenario.initialGreeting)
        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(mockSpeech.isListening)
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
            completeSessionUseCase: completeUseCase
        )

        var stateWhileSpeaking: VoiceCallState?
        mockTTS.onSpeakAsync = { _, _, _ in
            stateWhileSpeaking = engine.state
        }

        await engine.startCall()
        #expect(stateWhileSpeaking == .speaking(characterText: scenario.initialGreeting))
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
            completeSessionUseCase: completeUseCase
        )

        engine.startListening()
        #expect(engine.state == .listening(liveTranscript: ""))

        mockSpeech.simulateResult("I would like an")
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
            completeSessionUseCase: completeUseCase
        )

        var stateDuringReply: VoiceCallState?
        mockTTS.onSpeakAsync = { _, _, _ in
            stateDuringReply = engine.state
        }

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
        #expect(stateDuringReply == .speaking(characterText: "One hot espresso coming right up!"))
        #expect(mockTTS.lastSpokenText == "One hot espresso coming right up!")
        #expect(engine.state == .listening(liveTranscript: ""))
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
        #expect(mockSpeech.isListening)

        let summary = await engine.endCall()

        #expect(engine.state == .ended)
        #expect(!mockSpeech.isListening)
        #expect(!mockTTS.isSpeaking)
        #expect(summary.scenarioId == scenario.id)
    }

    @Test("Turn error catches gracefully and reactivates speech recognition")
    @MainActor
    func turnErrorReactivatesListening() async {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let mockLLM = MockLLMProvider()
        mockLLM.shouldThrowError = true
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

        await engine.processUserUtterance("Trigger error utterance")

        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(mockSpeech.isListening)
    }

    @Test("End call during thinking state prevents resurrecting call to speaking")
    @MainActor
    func endCallDuringThinkingPreventsResurrection() async {
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
        _ = await engine.endCall()
        #expect(engine.state == .ended)

        await engine.processUserUtterance("Belated speech")

        #expect(engine.state == .ended)
        #expect(!mockTTS.isSpeaking)
    }

    @Test("End call during speaking state cancels active speech task and keeps engine ended")
    @MainActor
    func endCallDuringSpeakingCancelsActiveSpeechTask() async {
        let scenario = makeTestScenario()
        let mockTTS = MockTextToSpeechService()
        let mockSpeech = MockSpeechRecognitionService()
        let engine = TurnBasedVoiceConversationEngine(
            scenario: scenario,
            ttsService: mockTTS,
            speechService: mockSpeech,
            executeTurnUseCase: makeExecuteUseCase(),
            completeSessionUseCase: makeCompleteUseCase()
        )

        mockTTS.onSpeakAsync = { _, _, _ in
            _ = await engine.endCall()
        }

        await engine.startCall()

        #expect(engine.state == .ended)
        #expect(!mockTTS.isSpeaking)
        #expect(!mockSpeech.isListening)
    }
}
