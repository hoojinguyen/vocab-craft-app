import AVFoundation
import Foundation
import Observation
import os
import Speech
import SpeechKit

private final class ConversationCleanupBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _eventSubscriptionTask: Task<Void, Never>?
    private var _activeSpeechTask: Task<Void, Never>?

    var eventSubscriptionTask: Task<Void, Never>? {
        get { lock.withLock { _eventSubscriptionTask } }
        set { lock.withLock { _eventSubscriptionTask = newValue } }
    }

    var activeSpeechTask: Task<Void, Never>? {
        get { lock.withLock { _activeSpeechTask } }
        set { lock.withLock { _activeSpeechTask = newValue } }
    }

    func cleanup() {
        let (task1, task2) = lock.withLock { () -> (Task<Void, Never>?, Task<Void, Never>?) in
            let subscriptionTask = _eventSubscriptionTask
            _eventSubscriptionTask = nil
            let speechTask = _activeSpeechTask
            _activeSpeechTask = nil
            return (subscriptionTask, speechTask)
        }
        task1?.cancel()
        task2?.cancel()
    }
}

private final class ConversationMeterState: @unchecked Sendable {
    private let lock = NSLock()
    private var lastUpdateTime: ContinuousClock.Instant = .now - .seconds(1)
    private let throttleInterval: Duration = .milliseconds(30)

    func shouldProcessMeter(at now: ContinuousClock.Instant = .now) -> Bool {
        lock.withLock {
            if now - lastUpdateTime >= throttleInterval {
                lastUpdateTime = now
                return true
            }
            return false
        }
    }

    func reset() {
        lock.withLock {
            lastUpdateTime = .now - .seconds(1)
        }
    }
}

/// Resilient conversation speech engine maintaining a warm `.duplexSpeech` audio lease throughout
/// an AI voice call session, with sub-50ms buffer mute/unmute switching and real-time metering.
@MainActor
@Observable
// swiftlint:disable:next type_body_length
public final class ResilientConversationSpeechEngine: VoiceConversationEngineProtocol {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "ResilientVoiceEngine")

    // MARK: - State Properties
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

    // MARK: - Audio & Engine Infrastructure
    public let bufferRelay: AudioBufferRelay
    public let audioController: any SpeechAudioEngineControlling
    public let audioSessionCoordinator: (any AudioSessionCoordinating)?
    public let whisperEngine: WhisperKitSpeechEngine
    public private(set) var activeLease: AudioSessionLease?
    public private(set) var isEngineReady: Bool = false
    public private(set) var silenceDetector: SilenceDetector?

    private let ttsService: any TextToSpeechProtocol
    private let executeTurnUseCase: ExecuteRoleplayTurnUseCase
    private let completeSessionUseCase: CompleteRoleplaySessionUseCase
    private let authorizer: any SpeechAuthorizing
    private let silenceDuration: Duration
    private let initialSilenceDuration: Duration
    private var speechRecognizer: SFSpeechRecognizer?
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var activeRecognitionTask: SFSpeechRecognitionTask?

    private let cleanupBox = ConversationCleanupBox()
    private let meterState = ConversationMeterState()

    private var activeSpeechTask: Task<Void, Never>? {
        get { cleanupBox.activeSpeechTask }
        set { cleanupBox.activeSpeechTask = newValue }
    }

    public init(
        scenario: RoleplayScenario,
        ttsService: any TextToSpeechProtocol,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase,
        audioController: any SpeechAudioEngineControlling = SpeechAudioEngineController(),
        bufferRelay: AudioBufferRelay = AudioBufferRelay(),
        audioSessionCoordinator: (any AudioSessionCoordinating)? = AudioSessionCoordinator(),
        speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
        authorizer: any SpeechAuthorizing = LiveSpeechAuthorizer(),
        silenceDuration: Duration = .milliseconds(1800),
        initialSilenceDuration: Duration = .seconds(10),
        whisperEngine: WhisperKitSpeechEngine = WhisperKitSpeechEngine()
    ) {
        self.scenario = scenario
        self.ttsService = ttsService
        self.executeTurnUseCase = executeTurnUseCase
        self.completeSessionUseCase = completeSessionUseCase
        self.audioController = audioController
        self.bufferRelay = bufferRelay
        self.audioSessionCoordinator = audioSessionCoordinator
        self.speechRecognizer = speechRecognizer
        self.authorizer = authorizer
        self.silenceDuration = silenceDuration
        self.initialSilenceDuration = initialSilenceDuration
        self.whisperEngine = whisperEngine
        self.suggestedResponses = scenario.starterSuggestions

        installBufferListener()
    }

    deinit {
        cleanupBox.cleanup()
    }

    // MARK: - Audio Buffer Listener & Metering
    private func installBufferListener() {
        bufferRelay.setBufferListener { [weak self] buffer in
            guard let self else { return }
            self.processAudioBuffer(buffer)
        }
    }

    private struct AudioBufferSendBox: @unchecked Sendable {
        let buffer: AVAudioPCMBuffer
    }

    private nonisolated func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        let box = AudioBufferSendBox(buffer: buffer)
        Task { @MainActor [weak self] in
            guard let self else { return }
            if self.whisperEngine.isReady {
                self.whisperEngine.ingest(buffer: box.buffer)
            }
        }

        guard meterState.shouldProcessMeter() else { return }
        let rms = Self.calculateRMS(buffer: buffer)
        let level = Self.calculateNormalizedAudioLevel(rms: rms)

        Task { @MainActor [weak self] in
            guard let self, case .listening = self.state, !self.isMuted else { return }
            self.audioLevel = level
        }
    }

    public nonisolated static func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0], buffer.frameLength > 0 else {
            return 0.0
        }
        let frameCount = Int(buffer.frameLength)
        var sumSquares: Float = 0
        for i in 0..<frameCount {
            let sample = channelData[i]
            sumSquares += sample * sample
        }
        return sqrt(sumSquares / Float(frameCount))
    }

    public nonisolated static func calculateNormalizedAudioLevel(rms: Float) -> Float {
        let db = 20.0 * log10(max(rms, 0.0001))
        let normalized = (db + 50.0) / 50.0
        return min(max(normalized, 0.0), 1.0)
    }

    public func injectAudioLevelForTesting(_ level: Float) {
        let clamped = min(max(level, 0.0), 1.0)
        self.audioLevel = clamped
    }

    // MARK: - Call Lifecycle
    public func startCall() async {
        guard state == .idle else { return }
        suggestedResponses = scenario.starterSuggestions
        subscribeToAudioSessionEvents()

        if let coordinator = audioSessionCoordinator {
            do {
                activeLease = try await coordinator.acquire(.duplexSpeech)
            } catch {
                audioErrorMessage = error.localizedDescription
            }
        }

        do {
            _ = await authorizer.requestSpeechAuthorization()
            _ = await authorizer.requestMicrophoneAuthorization()
            try await audioController.prepare(relay: bufferRelay)
            isEngineReady = true
        } catch {
            audioErrorMessage = error.localizedDescription
        }

        let greeting = scenario.initialGreeting
        let initialMessage = RoleplayMessage(
            id: UUID(),
            sender: .character(name: scenario.characterName),
            text: greeting,
            timestamp: Date()
        )
        messages.append(initialMessage)

        let speechTask = Task { @MainActor [weak self] in
            await self?.playCharacterSpeech(greeting)
            return ()
        }
        activeSpeechTask = speechTask
        await speechTask.value
    }

    public func playCharacterSpeech(_ text: String, isConcluded: Bool = false) async {
        guard state != .ended else { return }
        audioLevel = 0.0
        silenceDetector?.cancel()
        bufferRelay.mute()
        endRecognition()
        state = .speaking(characterText: text)

        let persona: VoicePersona = scenario.voicePersona
        await ttsService.speakAsync(text: text, context: .conversation(persona: persona, locale: "en-US"), rate: 1.0)

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

        whisperEngine.clearBuffer()

        guard !isMuted else {
            bufferRelay.mute()
            return
        }

        bufferRelay.unmute()
        armSilenceDetector()
        startRecognition()
    }

    private func armSilenceDetector() {
        silenceDetector?.cancel()
        let detector = SilenceDetector(
            initialSilenceDuration: initialSilenceDuration,
            trailingSilenceDuration: silenceDuration,
            firesSilenceOnInitialTimeout: false,
            onSilence: { [weak self] in
                Task { @MainActor [weak self] in
                    guard let self, case .listening(let transcript) = self.state else { return }

                    var finalTranscript = transcript
                    if finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && self.whisperEngine.isReady {
                        do {
                            let whisperResult = try await self.whisperEngine.transcribeBufferedAudio()
                            if !whisperResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                finalTranscript = whisperResult
                            }
                        } catch {
                            Self.logger.error("Whisper fallback failed: \(error.localizedDescription)")
                        }
                    }

                    let trimmed = finalTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        await self.processUserUtterance(trimmed)
                    }
                }
            }
        )
        self.silenceDetector = detector
        detector.arm()
    }

    private func startRecognition() {
        endRecognition()
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        activeRequest = request
        bufferRelay.setRequest(request)

        #if !targetEnvironment(simulator) && !os(macOS)
        let isTesting = NSClassFromString("XCTestCase") != nil
        if !isTesting, let recognizer = speechRecognizer, recognizer.isAvailable {
            activeRecognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let error {
                        self.handleRecognitionError(error)
                    } else if let result {
                        let text = result.bestTranscription.formattedString
                        self.handleTranscriptUpdate(text)
                    }
                }
            }
        }
        #endif
    }

    private func endRecognition() {
        bufferRelay.setRequest(nil)
        activeRequest?.endAudio()
        activeRequest = nil
        activeRecognitionTask?.cancel()
        activeRecognitionTask = nil
    }

    private func handleRecognitionError(_ error: Error) {
        let nsError = error as NSError
        if nsError.code == 216 || nsError.code == 203 {
            return
        }
        if case .listening(let transcript) = state,
           !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task { @MainActor [weak self] in
                await self?.processUserUtterance(transcript)
            }
        } else {
            audioErrorMessage = error.localizedDescription
            silenceDetector?.cancel()
        }
    }

    public func simulateTranscript(_ transcript: String) {
        handleTranscriptUpdate(transcript)
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
        state = .thinking
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
        bufferRelay.mute()
        endRecognition()
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
            let speechTask = Task { @MainActor [weak self] in
                await self?.playCharacterSpeech(output.characterReply, isConcluded: isConcluded)
                return ()
            }
            activeSpeechTask = speechTask
            await speechTask.value

            if isConcluded {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                guard self.state != .ended else { return }
                let summary = await self.endCall()
                self.onSessionAutoConcluded?(summary)
            }
        } catch let error as AIPackError {
            Self.logger.error("Execute roleplay turn error: \(error.localizedDescription)")
            guard state == .thinking else { return }
            self.state = .error(error)
        } catch {
            Self.logger.error("Execute roleplay turn error: \(error.localizedDescription)")
            guard state == .thinking else { return }
            let wrapped = AIPackError.llmFailed(packName: "Active Provider", underlyingMessage: error.localizedDescription)
            self.state = .error(wrapped)
        }
    }

    public func toggleMute() {
        isMuted.toggle()
        if isMuted {
            audioLevel = 0.0
            bufferRelay.mute()
            endRecognition()
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
        cleanupBox.cleanup()
        silenceDetector?.cancel()
        silenceDetector = nil
        audioLevel = 0.0
        bufferRelay.detachAndEnd()
        endRecognition()
        ttsService.stop()

        if let lease = activeLease {
            activeLease = nil
            let coordinator = audioSessionCoordinator
            Task {
                await coordinator?.release(lease)
            }
        }
        let controller = audioController
        Task {
            await controller.teardown()
        }
        state = .ended
    }

    public func endCall() async -> RoleplaySessionSummary {
        cleanupBox.cleanup()
        silenceDetector?.cancel()
        silenceDetector = nil
        audioLevel = 0.0
        bufferRelay.detachAndEnd()
        endRecognition()
        ttsService.stop()

        if let lease = activeLease {
            activeLease = nil
            await audioSessionCoordinator?.release(lease)
        }
        await audioController.teardown()
        state = .ended

        return await completeSessionUseCase.execute(
            scenario: scenario,
            messages: messages,
            masteredWords: masteredTargetWords
        )
    }

    private func subscribeToAudioSessionEvents() {
        guard let coordinator = audioSessionCoordinator else { return }
        let events = coordinator.events
        let task = Task { @MainActor [weak self] in
            for await event in events {
                guard let self, self.state != .ended else { break }
                switch event {
                case .interruptionBegan:
                    self.bufferRelay.mute()
                    self.silenceDetector?.cancel()
                    self.endRecognition()
                case .interruptionEnded(let shouldResume):
                    if shouldResume, case .listening = self.state, !self.isMuted {
                        self.startListening()
                    }
                case .mediaServicesReset:
                    self.cancelCall()
                    self.audioErrorMessage = SpeechCaptureError.enginePreparationFailed.localizedDescription
                default:
                    break
                }
            }
        }
        cleanupBox.eventSubscriptionTask = task
    }
}
