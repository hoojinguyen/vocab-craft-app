import Foundation
import Observation
import SpeechKit

/// Orchestrates turn-based voice conversations between the user and an AI roleplay character,
/// coordinating TTS, speech recognition, silence detection, and LLM turn execution.
@MainActor
@Observable
public final class TurnBasedVoiceConversationEngine: VoiceConversationEngineProtocol {
    public private(set) var state: VoiceCallState = .idle
    public private(set) var isMuted: Bool = false
    public private(set) var isSubtitlesVisible: Bool = true
    public private(set) var audioErrorMessage: String?
    public private(set) var audioLevel: Float = 0.0
    public private(set) var suggestedResponses: [String] = []
    public let scenario: RoleplayScenario
    public private(set) var messages: [RoleplayMessage] = []
    public private(set) var masteredTargetWords: Set<String> = []

    private let ttsService: TextToSpeechProtocol
    private let speechService: SpeechRecognitionProtocol
    private let executeTurnUseCase: ExecuteRoleplayTurnUseCase
    private let completeSessionUseCase: CompleteRoleplaySessionUseCase
    private let silenceDelaySeconds: Double
    private let initialSilenceDuration: Duration

    private var silenceDetector: SilenceDetector?
    private var activeSpeechTask: Task<Void, Never>?

    public init(
        scenario: RoleplayScenario,
        ttsService: TextToSpeechProtocol,
        speechService: SpeechRecognitionProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase,
        silenceDelaySeconds: Double = 1.5,
        initialSilenceDuration: Duration = .seconds(10)
    ) {
        self.scenario = scenario
        self.ttsService = ttsService
        self.speechService = speechService
        self.executeTurnUseCase = executeTurnUseCase
        self.completeSessionUseCase = completeSessionUseCase
        self.silenceDelaySeconds = silenceDelaySeconds
        self.initialSilenceDuration = initialSilenceDuration
        self.suggestedResponses = scenario.starterSuggestions
    }

    /// Convenience initializer maintaining compatibility for callers passing speechDelaySeconds.
    public convenience init(
        scenario: RoleplayScenario,
        ttsService: TextToSpeechProtocol,
        speechService: SpeechRecognitionProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase,
        speechDelaySeconds: Double,
        silenceDelaySeconds: Double = 1.5,
        initialSilenceDuration: Duration = .seconds(10)
    ) {
        self.init(
            scenario: scenario,
            ttsService: ttsService,
            speechService: speechService,
            executeTurnUseCase: executeTurnUseCase,
            completeSessionUseCase: completeSessionUseCase,
            silenceDelaySeconds: silenceDelaySeconds,
            initialSilenceDuration: initialSilenceDuration
        )
    }

    public func startCall() async {
        suggestedResponses = scenario.starterSuggestions
        let greeting = scenario.initialGreeting
        let initialMessage = RoleplayMessage(
            id: UUID(),
            sender: .character(name: scenario.characterName),
            text: greeting,
            timestamp: Date()
        )
        messages.append(initialMessage)
        activeSpeechTask = Task { @MainActor [weak self] in
            await self?.playCharacterSpeech(greeting)
        }
        await activeSpeechTask?.value
    }

    public func playCharacterSpeech(_ text: String) async {
        guard state != .ended else { return }
        audioLevel = 0.0
        silenceDetector?.cancel()
        state = .speaking(characterText: text)

        await ttsService.speakAsync(text: text)

        guard state != .ended else { return }
        if case .speaking = state {
            startListening()
        }
    }

    public func startListening() {
        audioLevel = 0.0
        audioErrorMessage = nil
        state = .listening(liveTranscript: "")
        guard !isMuted else { return }

        silenceDetector?.cancel()
        silenceDetector = SilenceDetector(
            initialSilenceDuration: initialSilenceDuration,
            trailingSilenceDuration: .milliseconds(Int(silenceDelaySeconds * 1000)),
            onSilence: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self, case .listening(let transcript) = self.state else { return }
                    if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        await self.processUserUtterance(transcript)
                    }
                }
            }
        )
        silenceDetector?.arm()

        speechService.startListening(
            onResult: { [weak self] transcript in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.handleTranscriptUpdate(transcript)
                }
            },
            onAudioLevel: { [weak self] level in
                if Thread.isMainThread {
                    MainActor.assumeIsolated {
                        self?.audioLevel = level
                    }
                } else {
                    Task { @MainActor [weak self] in
                        self?.audioLevel = level
                    }
                }
            },
            onError: { [weak self] error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.audioLevel = 0.0
                    if case .listening(let transcript) = self.state,
                       !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        await self.processUserUtterance(transcript)
                    } else {
                        self.audioErrorMessage = error.localizedDescription
                        self.silenceDetector?.cancel()
                    }
                }
            }
        )
    }

    private func handleTranscriptUpdate(_ transcript: String) {
        state = .listening(liveTranscript: transcript)
        if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            silenceDetector?.registerActivity()
        }
    }

    public func finishUserTurnManually() {
        guard case .listening(let transcript) = state else { return }
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        silenceDetector?.cancel()
        Task { @MainActor [weak self] in
            await self?.processUserUtterance(trimmed)
        }
    }

    public func retryListening() {
        audioErrorMessage = nil
        startListening()
    }

    public func processUserUtterance(_ utterance: String) async {
        guard state != .ended else { return }
        audioLevel = 0.0
        speechService.stopListening()
        silenceDetector?.cancel()
        state = .thinking

        let userMessage = RoleplayMessage(
            id: UUID(),
            sender: .user,
            text: utterance,
            timestamp: Date()
        )
        messages.append(userMessage)

        do {
            let output = try await executeTurnUseCase.execute(scenario: scenario, conversation: messages)
            guard state == .thinking else { return }

            for word in output.targetWordsUsed {
                masteredTargetWords.insert(word)
            }

            suggestedResponses = output.suggestedResponses.isEmpty ? scenario.starterSuggestions : output.suggestedResponses

            let aiMessage = RoleplayMessage(
                id: UUID(),
                sender: .character(name: scenario.characterName),
                text: output.characterReply,
                timestamp: Date(),
                refinementSuggestion: output.refinementSuggestion,
                pedagogicalNote: output.pedagogicalNote
            )
            messages.append(aiMessage)

            activeSpeechTask = Task { @MainActor [weak self] in
                await self?.playCharacterSpeech(output.characterReply)
            }
            await activeSpeechTask?.value
        } catch {
            guard state == .thinking else { return }
            startListening()
        }
    }

    public func toggleMute() {
        isMuted.toggle()
        if isMuted {
            audioLevel = 0.0
            speechService.stopListening()
            silenceDetector?.cancel()
        } else {
            if case .listening = state {
                startListening()
            }
        }
    }

    public func toggleSubtitles() {
        isSubtitlesVisible.toggle()
    }

    public func endCall() async -> RoleplaySessionSummary {
        activeSpeechTask?.cancel()
        activeSpeechTask = nil
        silenceDetector?.cancel()
        silenceDetector = nil
        audioLevel = 0.0
        speechService.stopListening()
        ttsService.stop()
        state = .ended

        return await completeSessionUseCase.execute(
            scenario: scenario,
            messages: messages,
            masteredWords: masteredTargetWords
        )
    }
}
