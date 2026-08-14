import Foundation
import Speech
import AVFoundation

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

    /// Requests user authorization for speech recognition.
    public func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            let authorized = (authStatus == .authorized)
            completion(authorized)
        }
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

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw SpeechKitError.recognizerUnavailable
        }

        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetoothHFP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            throw SpeechKitError.audioSessionConfigurationFailed
        }
        #endif

        let request = SFSpeechAudioBufferRecognitionRequest()
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

        self.recognitionRequest = request

        let engine = AVAudioEngine()
        self.audioEngine = engine
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
            throw SpeechKitError.audioBufferCreationFailed
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            throw SpeechKitError.audioSessionConfigurationFailed
        }

        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let transcription = result.bestTranscription.formattedString
                if result.isFinal {
                    onFinalResult(transcription)
                } else {
                    onPartialResult(transcription)
                }
            }
            if let error {
                let nsError = error as NSError
                if self.isRecording && nsError.code != 216 { // 216 = canceled on stop
                    onError(error)
                }
            }
        }

        _isRecording = true
    }

    /// Stops audio capture and finalizes the current recognition session.
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        stopInternal()
    }

    private func stopInternal() {
        guard _isRecording else { return }
        _isRecording = false

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
