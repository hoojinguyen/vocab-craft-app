import AVFoundation
import Foundation
import Speech

/// Protocol defining the interface for the acoustic speech recognition engine.
public protocol SpeechRecognitionEngineProtocol: AnyObject, Sendable {
    var isRecording: Bool { get }
    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void)
    func start(
        contextualPhrases: [String],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws
    func stop()
}

/// Acoustic speech recognition engine leveraging Apple's Speech and AVFoundation frameworks
/// with contextual string biasing for language learning vocabulary.
public final class SpeechRecognitionEngine: NSObject, SpeechRecognitionEngineProtocol, @unchecked Sendable {
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioCoordinator: (any AudioSessionCoordinating)?
    private var activeLease: AudioSessionLease?
    private var leaseAcquisitionTask: Task<Void, Never>?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let lock = NSLock()
    private var _isRecording = false
    private var currentSessionId = UUID()
    private var simulationTask: Task<Void, Never>?

    public var isRecording: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isRecording
    }

    /// Initializes the engine for a specific locale (defaults to "en-US") and optional audio session coordinator.
    public init(
        locale: Locale = Locale(identifier: "en-US"),
        audioCoordinator: (any AudioSessionCoordinating)? = nil
    ) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        self.audioCoordinator = audioCoordinator
        super.init()
    }

    deinit {
        stop()
    }

    /// Requests user authorization for microphone and speech recognition.
    public func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        #if targetEnvironment(simulator) || os(macOS)
        DispatchQueue.main.async {
            completion(true)
        }
        #elseif os(iOS)
        AVAudioApplication.requestRecordPermission { micGranted in
            guard micGranted else {
                completion(false)
                return
            }
            SFSpeechRecognizer.requestAuthorization { authStatus in
                completion(authStatus == .authorized)
            }
        }
        #else
        SFSpeechRecognizer.requestAuthorization { authStatus in
            completion(authStatus == .authorized)
        }
        #endif
    }

    private func isSessionActiveAndRecording(sessionId: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return currentSessionId == sessionId && _isRecording
    }

    /// Starts audio recording and real-time speech transcription.
    ///
    /// - Parameters:
    ///   - contextualPhrases: Targeted sentence or keywords passed into `contextualStrings` for acoustic biasing.
    ///   - onPartialResult: Callback for real-time partial transcription hypotheses.
    ///   - onFinalResult: Callback when recognition finishes a complete utterance.
    ///   - onError: Callback if audio engine or recognition fails.
    public func start(
        contextualPhrases: [String] = [],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {
        lock.lock()
        defer { lock.unlock() }

        if _isRecording {
            stopInternal()
        }

        let sessionId = UUID()
        self.currentSessionId = sessionId
        self._isRecording = true

        if let coordinator = audioCoordinator {
            leaseAcquisitionTask?.cancel()
            leaseAcquisitionTask = Task { [weak self, sessionId] in
                let lease = try? await coordinator.acquire(.speechCapture)
                guard let self else {
                    if let lease {
                        await coordinator.release(lease)
                    }
                    return
                }
                let leaseToRelease: AudioSessionLease? = self.lock.withLock {
                    guard self.currentSessionId == sessionId, self._isRecording else {
                        return lease
                    }
                    self.activeLease = lease
                    return nil
                }
                if let leaseToRelease {
                    await coordinator.release(leaseToRelease)
                }
            }
        }

        #if targetEnvironment(simulator) || os(macOS)
        startSimulatorTask(
            sessionId: sessionId,
            phrases: contextualPhrases,
            onPartialResult: onPartialResult,
            onFinalResult: onFinalResult
        )
        #else
        try startDeviceRecognition(
            sessionId: sessionId,
            contextualPhrases: contextualPhrases,
            onPartialResult: onPartialResult,
            onFinalResult: onFinalResult,
            onError: onError
        )
        #endif
    }

    #if targetEnvironment(simulator) || os(macOS)
    private func startSimulatorTask(
        sessionId: UUID,
        phrases: [String],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void
    ) {
        simulationTask?.cancel()
        simulationTask = Task { [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(for: .milliseconds(400))
            guard self.isSessionActiveAndRecording(sessionId: sessionId) else { return }

            let target = phrases.first ?? "Sample utterance"
            let words = target.split(separator: " ")
            if words.count > 1 {
                let partial = words.prefix(max(1, words.count / 2)).joined(separator: " ")
                onPartialResult(partial)
            }

            try? await Task.sleep(for: .milliseconds(600))
            guard self.isSessionActiveAndRecording(sessionId: sessionId) else { return }

            onFinalResult(target)
        }
    }
    #else
    private struct RecognitionHandlers: Sendable {
        let onPartialResult: @Sendable (String) -> Void
        let onFinalResult: @Sendable (String) -> Void
        let onError: @Sendable (Error) -> Void
    }

    private func startDeviceRecognition(
        sessionId: UUID,
        contextualPhrases: [String],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {
        do {
            guard let recognizer = speechRecognizer, recognizer.isAvailable else {
                throw SpeechKitError.recognizerUnavailable
            }

            let request = makeRecognitionRequest(
                supportsOnDevice: recognizer.supportsOnDeviceRecognition,
                contextualPhrases: contextualPhrases
            )
            self.recognitionRequest = request

            let engine = try setupAudioEngine(for: request)
            self.audioEngine = engine

            let handlers = RecognitionHandlers(
                onPartialResult: onPartialResult,
                onFinalResult: onFinalResult,
                onError: onError
            )

            self.recognitionTask = makeRecognitionTask(
                recognizer: recognizer,
                request: request,
                sessionId: sessionId,
                handlers: handlers
            )
        } catch {
            stopInternal()
            throw error
        }
    }

    private func makeRecognitionRequest(
        supportsOnDevice: Bool,
        contextualPhrases: [String]
    ) -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = supportsOnDevice
        request.shouldReportPartialResults = true
        if !contextualPhrases.isEmpty {
            request.contextualStrings = contextualPhrases
        }
        #if os(iOS)
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        #elseif os(macOS)
        if #available(macOS 13.0, *) {
            request.addsPunctuation = false
        }
        #endif
        return request
    }

    private func setupAudioEngine(
        for request: SFSpeechAudioBufferRecognitionRequest
    ) throws -> AVAudioEngine {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw SpeechKitError.audioBufferCreationFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard buffer.frameLength > 0 else { return }
            self?.recognitionRequest?.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
            return engine
        } catch {
            throw SpeechKitError.audioSessionConfigurationFailed
        }
    }

    private func makeRecognitionTask(
        recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        sessionId: UUID,
        handlers: RecognitionHandlers
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            self.lock.lock()
            guard self.currentSessionId == sessionId, self._isRecording else {
                self.lock.unlock()
                return
            }
            self.lock.unlock()

            if let result {
                let transcription = result.bestTranscription.formattedString
                if result.isFinal {
                    handlers.onFinalResult(transcription)
                } else {
                    handlers.onPartialResult(transcription)
                }
            }
            if let error {
                let nsError = error as NSError
                if nsError.code != 216 { // 216 = canceled on stop
                    handlers.onError(error)
                }
            }
        }
    }
    #endif

    /// Stops audio capture and finalizes the current recognition session.
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        stopInternal()
    }

    private func stopInternal() {
        _isRecording = false
        currentSessionId = UUID()

        leaseAcquisitionTask?.cancel()
        leaseAcquisitionTask = nil

        if let lease = activeLease, let coordinator = audioCoordinator {
            activeLease = nil
            Task {
                await coordinator.release(lease)
            }
        }

        simulationTask?.cancel()
        simulationTask = nil

        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            if engine.isRunning {
                engine.stop()
            }
        }
        audioEngine = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        recognitionTask?.cancel()
        recognitionTask = nil
    }
}
