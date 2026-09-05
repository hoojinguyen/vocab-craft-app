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

    /// Initializes the engine for a specific locale (defaults to "en-US").
    public init(locale: Locale = Locale(identifier: "en-US")) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
        super.init()
    }

    deinit {
        stop()
    }

    /// Requests user authorization for microphone and speech recognition.
    public func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async {
            completion(true)
        }
        #elseif os(iOS)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { micGranted in
                guard micGranted else {
                    completion(false)
                    return
                }
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    completion(authStatus == .authorized)
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { micGranted in
                guard micGranted else {
                    completion(false)
                    return
                }
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    completion(authStatus == .authorized)
                }
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

        #if targetEnvironment(simulator)
        startSimulatorTask(
            phrases: contextualPhrases,
            onPartialResult: onPartialResult,
            onFinalResult: onFinalResult
        )
        #else
        try startDeviceRecognition(
            contextualPhrases: contextualPhrases,
            onPartialResult: onPartialResult,
            onFinalResult: onFinalResult,
            onError: onError
        )
        #endif
    }

    #if targetEnvironment(simulator)
    private func startSimulatorTask(
        phrases: [String],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void
    ) {
        _isRecording = true
        let sessionId = UUID()
        self.currentSessionId = sessionId

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
        contextualPhrases: [String],
        onPartialResult: @escaping @Sendable (String) -> Void,
        onFinalResult: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void
    ) throws {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechKitError.recognizerUnavailable
        }

        do {
            #if os(iOS)
            try configureAudioSession()
            #endif

            let request = makeRecognitionRequest(
                supportsOnDevice: recognizer.supportsOnDeviceRecognition,
                contextualPhrases: contextualPhrases
            )
            self.recognitionRequest = request

            let engine = try setupAudioEngine(for: request)
            self.audioEngine = engine

            let sessionId = UUID()
            self.currentSessionId = sessionId

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

            _isRecording = true
        } catch {
            stopInternal()
            throw error
        }
    }

    #if os(iOS)
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try? audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            throw SpeechKitError.audioSessionConfigurationFailed
        }
    }
    #endif

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

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}
