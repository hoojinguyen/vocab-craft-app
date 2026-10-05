import AVFoundation
import Foundation
import Speech
import Testing
@testable import VocabCraftApp

@Suite("ResilientConversationSpeechEngine Tests", .serialized)
struct ResilientConversationSpeechEngineTests {
    private func makeTestScenario() -> RoleplayScenario {
        RoleplayScenario(
            id: "scenario_cafe",
            titleKey: "test_title",
            descriptionKey: "test_desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome to The Daily Roast! What can I get for you?",
            targetWordIds: ["espresso", "croissant"],
            iconSymbol: "cup.and.saucer.fill",
            starterSuggestions: [
                "I would like an espresso, please.",
                "Do you have fresh croissants?"
            ]
        )
    }

    private func makeAudioPCMBuffer(sampleValue: Float = 0.5) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1024)!
        buffer.frameLength = 1024
        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<1024 {
                channelData[i] = sampleValue
            }
        }
        return buffer
    }

    @Test("1. Engine initializes with warm duplex session and enters .speaking on startCall")
    @MainActor
    func testEngineInitializesWithWarmSessionAndEntersSpeakingOnStartCall() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        #expect(engine.state == .idle)
        #expect(engine.activeLease == nil)

        var stateWhileGreeting: VoiceCallState?
        mockTTS.onSpeakAsync = { _, _, _ in
            stateWhileGreeting = engine.state
        }

        await engine.startCall()

        #expect(stateWhileGreeting == .speaking(characterText: scenario.initialGreeting))
        #expect(engine.activeLease != nil)
        #expect(engine.activeLease?.intent == .duplexSpeech)
        #expect(engine.isEngineReady)
        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(engine.messages.count == 1)
        #expect(engine.messages.first?.text == scenario.initialGreeting)
    }

    @Test("2. BufferRelay is muted during TTS speaking and unmuted when listening starts")
    @MainActor
    func testBufferRelayMutedDuringSpeakingAndUnmutedWhenListeningStarts() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        var isMutedDuringTTS: Bool?
        mockTTS.onSpeakAsync = { _, _, _ in
            isMutedDuringTTS = engine.bufferRelay.isCurrentlyMuted
        }

        await engine.startCall()

        #expect(isMutedDuringTTS == true)
        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(engine.bufferRelay.isCurrentlyMuted == false)
    }

    @Test("3. When TTS completes, bufferRelay un-mutes and speech recognizer starts without recreating AVAudioEngine")
    @MainActor
    func testTTSCompletionStartsSpeechRecognizerWithoutRecreatingEngine() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        await engine.startCall()

        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(engine.bufferRelay.currentRequest != nil)
        #expect(engine.isEngineReady == true)
    }

    @Test("4. Audio level streams continuously to audioLevel property")
    @MainActor
    func testAudioLevelStreamsContinuously() async throws {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        await engine.startCall()
        #expect(engine.state == .listening(liveTranscript: ""))
        #expect(engine.audioLevel == 0.0)

        let buffer = makeAudioPCMBuffer(sampleValue: 0.5)
        engine.bufferRelay.append(buffer)

        try await Task.sleep(for: .milliseconds(50))
        await Task.yield()

        #expect(engine.audioLevel > 0.0)
        #expect(engine.audioLevel <= 1.0)

        // Resets to zero on mute
        engine.toggleMute()
        #expect(engine.isMuted)
        #expect(engine.audioLevel == 0.0)
    }

    @Test("5. VAD trailing silence triggers turn completion when user stops speaking")
    @MainActor
    func testVADTrailingSilenceTriggersTurnCompletion() async throws {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider(mockTurnOutput: RoleplayTurnOutput(
            characterReply: "One hot espresso coming right up!",
            targetWordsUsed: ["espresso"]
        ))
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator,
            silenceDuration: .milliseconds(60),
            initialSilenceDuration: .milliseconds(40)
        )

        await engine.startCall()
        #expect(engine.state == .listening(liveTranscript: ""))

        engine.simulateTranscript("I would like an espresso")
        #expect(engine.state == .listening(liveTranscript: "I would like an espresso"))

        // Wait past 60ms trailing silence duration
        try await Task.sleep(for: .milliseconds(120))
        await Task.yield()

        #expect(engine.messages.contains(where: { $0.text == "I would like an espresso" }))
        #expect(engine.masteredTargetWords.contains("espresso"))
    }

    @Test("6. finishUserTurnManually immediately triggers thinking without waiting for silence timer")
    @MainActor
    func testFinishUserTurnManuallyImmediatelyTriggersThinking() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider(mockTurnOutput: RoleplayTurnOutput(
            characterReply: "Sure, here is your croissant.",
            targetWordsUsed: ["croissant"]
        ))
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator,
            silenceDuration: .seconds(10)
        )

        await engine.startCall()
        engine.simulateTranscript("Do you have croissants?")

        engine.finishUserTurnManually()
        #expect(engine.state == .thinking)

        await Task.yield()
        #expect(engine.messages.contains(where: { $0.text == "Do you have croissants?" }))
    }

    @Test("7. endCall cleanly releases audio lease and returns session summary")
    @MainActor
    func testEndCallReleasesAudioLeaseAndReturnsSummary() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        await engine.startCall()
        #expect(engine.activeLease != nil)
        #expect(mockHardware.operations.contains(where: {
            if case .setCategory(let cat, _, _) = $0 { return cat == .playAndRecord }
            return false
        }))

        let summary = await engine.endCall()

        #expect(engine.state == .ended)
        #expect(engine.activeLease == nil)
        #expect(summary.scenarioId == scenario.id)
    }

    @Test("Toggling mute and subtitles updates engine state accordingly")
    @MainActor
    func testToggleMuteAndSubtitles() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        await engine.startCall()
        #expect(!engine.isMuted)
        #expect(engine.isSubtitlesVisible)

        engine.toggleSubtitles()
        #expect(!engine.isSubtitlesVisible)

        engine.toggleMute()
        #expect(engine.isMuted)
        #expect(engine.bufferRelay.isCurrentlyMuted)

        engine.toggleMute()
        #expect(!engine.isMuted)
        #expect(!engine.bufferRelay.isCurrentlyMuted)
    }

    @Test("cancelCall sets state to ended and releases resources")
    @MainActor
    func testCancelCallTransitionsToEnded() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        await engine.startCall()
        #expect(engine.activeLease != nil)

        engine.cancelCall()
        #expect(engine.state == .ended)
        #expect(engine.activeLease == nil)
    }

    @Test("Auto-conclusion triggers callback and transitions to ended when turn is concluded")
    @MainActor
    func testAutoConclusionTriggersCallbackWhenTurnOutputIsConcluded() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        mockLLM.mockTurnOutput = RoleplayTurnOutput(
            characterReply: "All set! Have a wonderful day!",
            targetWordsUsed: ["espresso"],
            isConcluded: true
        )
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        var autoConcludedSummary: RoleplaySessionSummary?
        engine.onSessionAutoConcluded = { summary in
            autoConcludedSummary = summary
        }

        await engine.startCall()
        await engine.processUserUtterance("Here is my card, thank you!")

        #expect(autoConcludedSummary != nil)
        #expect(engine.state == .ended)
    }

    @Test("Engine plays character speech using conversation context and friendly male persona for Alex")
    @MainActor
    func testCharacterSpeechUsesConversationContextWithMalePersona() async {
        let scenario = makeTestScenario() // characterName: "Alex"
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        await engine.startCall()

        #expect(mockTTS.lastSpokenContext == .conversation(persona: .friendlyMale, locale: "en-US"))
        #expect(mockTTS.lastSpokenRate == 1.0)
    }

    @Test("Engine plays character speech using conversation context and friendly female persona for Emma")
    @MainActor
    func testCharacterSpeechUsesConversationContextWithFemalePersona() async {
        let scenario = RoleplayScenario(
            id: "scenario_emma",
            titleKey: "test_title",
            descriptionKey: "test_desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hello! Welcome to the cafe.",
            targetWordIds: ["latte"],
            iconSymbol: "cup.fill"
        )
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider()
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        await engine.startCall()

        #expect(mockTTS.lastSpokenContext == .conversation(persona: .friendlyFemale, locale: "en-US"))
        #expect(mockTTS.lastSpokenRate == 1.0)
    }

    @Test("Character reply during conversation turn uses conversation context and appropriate persona")
    @MainActor
    func testCharacterTurnReplyUsesConversationContext() async {
        let scenario = makeTestScenario()
        let mockHardware = MockAudioSessionHardware()
        let coordinator = AudioSessionCoordinator(hardware: mockHardware)
        let mockTTS = MockTextToSpeechService()
        let mockLLM = MockLLMProvider(mockTurnOutput: RoleplayTurnOutput(
            characterReply: "Here is your hot espresso!",
            targetWordsUsed: ["espresso"]
        ))
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let engine = ResilientConversationSpeechEngine(
            scenario: scenario,
            ttsService: mockTTS,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase,
            audioSessionCoordinator: coordinator
        )

        engine.startListening()
        await engine.processUserUtterance("Can I get an espresso?")

        #expect(mockTTS.lastSpokenText == "Here is your hot espresso!")
        #expect(mockTTS.lastSpokenContext == .conversation(persona: .friendlyMale, locale: "en-US"))
        #expect(mockTTS.lastSpokenRate == 1.0)
    }
}
