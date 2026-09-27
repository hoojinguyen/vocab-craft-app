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
    public let scenario: RoleplayScenario
    public private(set) var messages: [RoleplayMessage] = []
    public private(set) var masteredTargetWords: Set<String> = []

    private let ttsService: TextToSpeechProtocol
    private let speechService: SpeechRecognitionProtocol
    private let executeTurnUseCase: ExecuteRoleplayTurnUseCase
    private let completeSessionUseCase: CompleteRoleplaySessionUseCase
    private let silenceDelaySeconds: Double

    private var silenceDetector: SilenceDetector?
    private var activeSpeechTask: Task<Void, Never>?

    public init(
        scenario: RoleplayScenario,
        ttsService: TextToSpeechProtocol,
        speechService: SpeechRecognitionProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase,
        silenceDelaySeconds: Double = 1.5
    ) {
        self.scenario = scenario
        self.ttsService = ttsService
        self.speechService = speechService
        self.executeTurnUseCase = executeTurnUseCase
        self.completeSessionUseCase = completeSessionUseCase
        self.silenceDelaySeconds = silenceDelaySeconds
    }

    /// Convenience initializer maintaining compatibility for callers passing speechDelaySeconds.
    public convenience init(
        scenario: RoleplayScenario,
        ttsService: TextToSpeechProtocol,
        speechService: SpeechRecognitionProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase,
        speechDelaySeconds: Double,
        silenceDelaySeconds: Double = 1.5
    ) {
        self.init(
            scenario: scenario,
            ttsService: ttsService,
            speechService: speechService,
            executeTurnUseCase: executeTurnUseCase,
            completeSessionUseCase: completeSessionUseCase,
            silenceDelaySeconds: silenceDelaySeconds
        )
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
        await playCharacterSpeech(greeting)
    }

    public func playCharacterSpeech(_ text: String) async {
        guard state != .ended else { return }
        silenceDetector?.cancel()
        state = .speaking(characterText: text)

        await ttsService.speakAsync(text: text)

        guard state != .ended else { return }
        if case .speaking = state {
            startListening()
        }
    }

    public func startListening() {
        guard !isMuted else { return }
        state = .listening(liveTranscript: "")

        silenceDetector?.cancel()
        silenceDetector = SilenceDetector(
            initialSilenceDuration: .seconds(10),
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
            onError: { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if case .listening(let transcript) = self.state,
                       !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        await self.processUserUtterance(transcript)
                    } else {
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
        silenceDetector?.cancel()
        if case .listening(let transcript) = state, !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task { @MainActor [weak self] in
                await self?.processUserUtterance(transcript)
            }
        }
    }

    public func processUserUtterance(_ utterance: String) async {
        guard state != .ended else { return }
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

            let aiMessage = RoleplayMessage(
                id: UUID(),
                sender: .character(name: scenario.characterName),
                text: output.characterReply,
                timestamp: Date(),
                refinementSuggestion: output.refinementSuggestion,
                pedagogicalNote: output.pedagogicalNote
            )
            messages.append(aiMessage)

            await playCharacterSpeech(output.characterReply)
        } catch {
            guard state == .thinking else { return }
            startListening()
        }
    }

    public func toggleMute() {
        isMuted.toggle()
        if isMuted {
            speechService.stopListening()
            silenceDetector?.cancel()
        } else if case .listening = state {
            startListening()
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
