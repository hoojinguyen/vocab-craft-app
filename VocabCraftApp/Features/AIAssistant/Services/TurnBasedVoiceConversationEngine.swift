import Foundation
import Observation
import SpeechKit

private final class LegacyTTSAdapter: TTSEngineProtocol, @unchecked Sendable {
    let engineName: String = "Legacy TTS Service"
    var isReady: Bool { true }
    private let service: any TextToSpeechProtocol

    init(service: any TextToSpeechProtocol) {
        self.service = service
    }

    func synthesizeAndPlay(text: String, voice: VoiceConfiguration) async throws {
        await service.speakAsync(
            text: text,
            context: .conversation(persona: voice.gender == .male ? .friendlyMale : .friendlyFemale, locale: voice.locale),
            rate: 1.0
        )
    }

    func stop() {
        let service = self.service
        Task { @MainActor in
            service.stop()
        }
    }
}

private final class ServiceBox: @unchecked Sendable {
    let service: any SpeechRecognitionProtocol
    init(_ service: any SpeechRecognitionProtocol) { self.service = service }
}

private final class LegacySTTAdapter: STTEngineProtocol, @unchecked Sendable {
    let engineName: String = "Legacy Speech Service"
    var isReady: Bool { true }
    private let box: ServiceBox

    init(service: any SpeechRecognitionProtocol) {
        self.box = ServiceBox(service)
    }

    func startRecognition(locale: String) -> AsyncThrowingStream<String, Error> {
        let box = self.box
        return AsyncThrowingStream { continuation in
            Task { @MainActor in
                box.service.startListening(
                    onResult: { text in continuation.yield(text) },
                    onAudioLevel: nil,
                    onError: { error in continuation.finish(throwing: error) }
                )
            }
            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    box.service.stopListening()
                }
            }
        }
    }

    func stopRecognition() {
        let box = self.box
        Task { @MainActor in
            box.service.stopListening()
        }
    }
}

/// Orchestrates turn-based voice conversations between the user and an AI roleplay character,
/// coordinating TTS, speech recognition, silence detection, and LLM turn execution with fail-fast zero-fallback semantics.
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
    public var onSessionAutoConcluded: ((RoleplaySessionSummary) -> Void)?
    public private(set) var activeError: AIPackError?

    private let llmProvider: any LLMProviderProtocol
    private let ttsEngine: any TTSEngineProtocol
    private let sttEngine: any STTEngineProtocol
    private let executeTurnUseCase: ExecuteRoleplayTurnUseCase
    private let completeSessionUseCase: CompleteRoleplaySessionUseCase
    private let silenceDelaySeconds: Double
    private let initialSilenceDuration: Duration
    public let audioSessionCoordinator: (any AudioSessionCoordinating)?

    private var legacySpeechService: (any SpeechRecognitionProtocol)?
    private var legacyTTSService: (any TextToSpeechProtocol)?

    private var silenceDetector: SilenceDetector?
    private var activeSpeechTask: Task<Void, Never>?
    private var recognitionTask: Task<Void, Never>?

    public init(
        scenario: RoleplayScenario,
        llmProvider: any LLMProviderProtocol,
        ttsEngine: any TTSEngineProtocol,
        sttEngine: any STTEngineProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase? = nil,
        completeSessionUseCase: CompleteRoleplaySessionUseCase = CompleteRoleplaySessionUseCase(),
        silenceDelaySeconds: Double = 1.5,
        initialSilenceDuration: Duration = .seconds(10),
        audioSessionCoordinator: (any AudioSessionCoordinating)? = nil
    ) {
        self.scenario = scenario
        self.llmProvider = llmProvider
        self.ttsEngine = ttsEngine
        self.sttEngine = sttEngine
        self.executeTurnUseCase = executeTurnUseCase ?? ExecuteRoleplayTurnUseCase(llmProvider: llmProvider)
        self.completeSessionUseCase = completeSessionUseCase
        self.silenceDelaySeconds = silenceDelaySeconds
        self.initialSilenceDuration = initialSilenceDuration
        self.audioSessionCoordinator = audioSessionCoordinator
        self.suggestedResponses = scenario.starterSuggestions
    }

    /// Convenience initializer maintaining compatibility for legacy callers passing TextToSpeechProtocol and SpeechRecognitionProtocol.
    public convenience init(
        scenario: RoleplayScenario,
        ttsService: any TextToSpeechProtocol,
        speechService: any SpeechRecognitionProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase,
        silenceDelaySeconds: Double = 1.5,
        initialSilenceDuration: Duration = .seconds(10)
    ) {
        self.init(
            scenario: scenario,
            llmProvider: MockLLMProvider(),
            ttsEngine: LegacyTTSAdapter(service: ttsService),
            sttEngine: LegacySTTAdapter(service: speechService),
            executeTurnUseCase: executeTurnUseCase,
            completeSessionUseCase: completeSessionUseCase,
            silenceDelaySeconds: silenceDelaySeconds,
            initialSilenceDuration: initialSilenceDuration
        )
        self.legacySpeechService = speechService
        self.legacyTTSService = ttsService
    }

    /// Convenience initializer maintaining compatibility for callers passing speechDelaySeconds.
    public convenience init(
        scenario: RoleplayScenario,
        ttsService: any TextToSpeechProtocol,
        speechService: any SpeechRecognitionProtocol,
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
        guard state == .idle else { return }
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

    public func playCharacterSpeech(_ text: String, isConcluded: Bool = false) async {
        guard state != .ended else { return }
        audioLevel = 0.0
        silenceDetector?.cancel()
        state = .speaking(characterText: text)

        let persona: VoicePersona = scenario.voicePersona
        let voice = VoiceConfiguration(
            gender: persona == .friendlyMale ? .male : .female,
            style: .friendly,
            locale: "en-US"
        )

        do {
            try await ttsEngine.synthesizeAndPlay(text: text, voice: voice)
        } catch let error as AIPackError {
            self.activeError = error
            self.audioErrorMessage = error.localizedDescription
            self.state = .error(error)
            return
        } catch {
            let wrapped = AIPackError.ttsFailed(packName: ttsEngine.engineName, underlyingMessage: error.localizedDescription)
            self.activeError = wrapped
            self.audioErrorMessage = wrapped.localizedDescription
            self.state = .error(wrapped)
            return
        }

        guard state != .ended else { return }
        if !isConcluded, case .speaking = state {
            startListening()
        }
    }

    public func startListening() {
        guard state != .ended else { return }
        audioLevel = 0.0
        audioErrorMessage = nil
        state = .listening(liveTranscript: "")
        guard !isMuted else { return }

        silenceDetector?.cancel()
        silenceDetector = SilenceDetector(
            initialSilenceDuration: initialSilenceDuration,
            trailingSilenceDuration: .milliseconds(Int(silenceDelaySeconds * 1000)),
            firesSilenceOnInitialTimeout: false,
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

        if let speechService = legacySpeechService {
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
                            self.silenceDetector?.cancel()
                            let packError = (error as? AIPackError) ?? .sttFailed(packName: "Speech Recognition", underlyingMessage: error.localizedDescription)
                            self.activeError = packError
                            self.audioErrorMessage = error.localizedDescription
                            self.state = .error(packError)
                        }
                    }
                }
            )
            return
        }

        recognitionTask?.cancel()
        recognitionTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let stream = self.sttEngine.startRecognition(locale: "en-US")
            do {
                for try await transcript in stream {
                    guard !Task.isCancelled else { break }
                    self.handleTranscriptUpdate(transcript)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.audioLevel = 0.0
                self.silenceDetector?.cancel()
                let packError: AIPackError
                if let err = error as? AIPackError {
                    packError = err
                } else {
                    packError = .sttFailed(packName: self.sttEngine.engineName, underlyingMessage: error.localizedDescription)
                }
                self.activeError = packError
                self.audioErrorMessage = packError.localizedDescription
                self.state = .error(packError)
            }
        }
    }

    public func handleTranscriptUpdate(_ transcript: String) {
        guard case .listening = state else { return }
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
        activeError = nil
        audioErrorMessage = nil
        startListening()
    }

    public func updateAudioLevel(_ level: Float) {
        guard case .listening = state, !isMuted else {
            self.audioLevel = 0.0
            return
        }
        self.audioLevel = min(max(level, 0.0), 1.0)
    }

    public func injectAudioLevelForTesting(_ level: Float) {
        updateAudioLevel(level)
    }

    public func processUserUtterance(_ utterance: String) async {
        guard state != .ended else { return }
        audioLevel = 0.0
        legacySpeechService?.stopListening()
        recognitionTask?.cancel()
        recognitionTask = nil
        sttEngine.stopRecognition()
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
            let output = try await executeTurnUseCase.execute(
                scenario: scenario,
                conversation: messages,
                suggestedResponses: suggestedResponses
            )
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

            let isConcluded = output.isConcluded
            activeSpeechTask = Task { @MainActor [weak self] in
                await self?.playCharacterSpeech(output.characterReply, isConcluded: isConcluded)
            }
            await activeSpeechTask?.value

            if isConcluded {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard state != .ended else { return }
                if case .error = state { return }
                let summary = await endCall()
                onSessionAutoConcluded?(summary)
            }
        } catch let error as AIPackError {
            self.activeError = error
            self.audioErrorMessage = error.localizedDescription
            self.state = .error(error)
        } catch {
            let wrapped = AIPackError.llmFailed(packName: llmProvider.providerIdentifier, underlyingMessage: error.localizedDescription)
            self.activeError = wrapped
            self.audioErrorMessage = wrapped.localizedDescription
            self.state = .error(wrapped)
        }
    }

    public func toggleMute() {
        isMuted.toggle()
        if isMuted {
            audioLevel = 0.0
            legacySpeechService?.stopListening()
            recognitionTask?.cancel()
            recognitionTask = nil
            sttEngine.stopRecognition()
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

    public func cancelCall() {
        activeSpeechTask?.cancel()
        activeSpeechTask = nil
        legacySpeechService?.stopListening()
        recognitionTask?.cancel()
        recognitionTask = nil
        silenceDetector?.cancel()
        silenceDetector = nil
        audioLevel = 0.0
        legacyTTSService?.stop()
        sttEngine.stopRecognition()
        ttsEngine.stop()
        state = .ended
    }

    public func endCall() async -> RoleplaySessionSummary {
        activeSpeechTask?.cancel()
        activeSpeechTask = nil
        legacySpeechService?.stopListening()
        recognitionTask?.cancel()
        recognitionTask = nil
        silenceDetector?.cancel()
        silenceDetector = nil
        audioLevel = 0.0
        legacyTTSService?.stop()
        sttEngine.stopRecognition()
        ttsEngine.stop()
        state = .ended

        return await completeSessionUseCase.execute(
            scenario: scenario,
            messages: messages,
            masteredWords: masteredTargetWords
        )
    }
}
