import Foundation
import Observation

/// Orchestrates turn-based voice conversations between the user and an AI roleplay character,
/// coordinating TTS, speech recognition, silence detection, and LLM turn execution.
@MainActor
@Observable
public final class TurnBasedVoiceConversationEngine: VoiceConversationEngineProtocol {
    public private(set) var state: VoiceCallState = .idle
    public private(set) var isMuted: Bool = false
    public private(set) var isSubtitlesVisible: Bool = true
    public let scenario: RoleplayScenario
    public private(set) var messages: [RoleplayMessage] = []
    public private(set) var masteredTargetWords: Set<String> = []

    private let ttsService: TextToSpeechProtocol
    private let speechService: SpeechRecognitionProtocol
    private let executeTurnUseCase: ExecuteRoleplayTurnUseCase
    private let completeSessionUseCase: CompleteRoleplaySessionUseCase
    private let speechDelaySeconds: Double
    private let silenceDelaySeconds: Double

    private var silenceTask: Task<Void, Never>?
    private var speechTask: Task<Void, Never>?

    public init(
        scenario: RoleplayScenario,
        ttsService: TextToSpeechProtocol,
        speechService: SpeechRecognitionProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase,
        speechDelaySeconds: Double = 2.5,
        silenceDelaySeconds: Double = 1.5
    ) {
        self.scenario = scenario
        self.ttsService = ttsService
        self.speechService = speechService
        self.executeTurnUseCase = executeTurnUseCase
        self.completeSessionUseCase = completeSessionUseCase
        self.speechDelaySeconds = speechDelaySeconds
        self.silenceDelaySeconds = silenceDelaySeconds
    }

    public func startCall() async {
        let greeting = scenario.initialGreeting
        let initialMessage = RoleplayMessage(
            id: UUID(),
            sender: .character(name: scenario.characterName),
            text: greeting,
            timestamp: Date()
        )
        messages.append(initialMessage)
        state = .speaking(characterText: greeting)

        ttsService.speak(text: greeting)
        scheduleSpeechFinishedTransition()
    }

    public func startListening() {
        guard !isMuted else { return }
        speechTask?.cancel()
        speechTask = nil
        state = .listening(liveTranscript: "")
        speechService.startListening(
            onResult: { [weak self] transcript in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.handleTranscriptUpdate(transcript)
                }
            },
            onError: { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.finishUserTurnManually()
                }
            }
        )
    }

    private func handleTranscriptUpdate(_ transcript: String) {
        state = .listening(liveTranscript: transcript)
        silenceTask?.cancel()
        silenceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.silenceDelaySeconds))
            guard !Task.isCancelled else { return }
            if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await self.processUserUtterance(transcript)
            }
        }
    }

    public func finishUserTurnManually() {
        silenceTask?.cancel()
        silenceTask = nil
        if case .listening(let transcript) = state, !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task { @MainActor [weak self] in
                await self?.processUserUtterance(transcript)
            }
        }
    }

    public func processUserUtterance(_ utterance: String) async {
        speechService.stopListening()
        silenceTask?.cancel()
        silenceTask = nil
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
            for word in output.targetWordsUsed {
                masteredTargetWords.insert(word)
            }

            let aiMessage = RoleplayMessage(
                id: UUID(),
                sender: .character(name: scenario.characterName),
                text: output.characterReply,
                timestamp: Date(),
                refinementSuggestion: output.refinementSuggestion,
                pedagogicalNote: output.pedagogicalNote
            )
            messages.append(aiMessage)

            state = .speaking(characterText: output.characterReply)
            ttsService.speak(text: output.characterReply)
            scheduleSpeechFinishedTransition()
        } catch {
            state = .listening(liveTranscript: "")
        }
    }

    private func scheduleSpeechFinishedTransition() {
        speechTask?.cancel()
        speechTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.speechDelaySeconds))
            guard !Task.isCancelled else { return }
            if case .speaking = self.state {
                self.startListening()
            }
        }
    }

    public func toggleMute() {
        isMuted.toggle()
        if isMuted {
            speechService.stopListening()
            silenceTask?.cancel()
            silenceTask = nil
        } else if case .listening = state {
            startListening()
        }
    }

    public func toggleSubtitles() {
        isSubtitlesVisible.toggle()
    }

    public func endCall() async -> RoleplaySessionSummary {
        speechTask?.cancel()
        speechTask = nil
        silenceTask?.cancel()
        silenceTask = nil
        speechService.stopListening()
        ttsService.stop()
        state = .ended

        return completeSessionUseCase.execute(
            scenario: scenario,
            messages: messages,
            masteredWords: masteredTargetWords
        )
    }
}
