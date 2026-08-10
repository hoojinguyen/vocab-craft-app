import Foundation
import Speech
import AVFoundation
import Observation

public enum SpeechRecognitionError: Error, LocalizedError {
    case recognizerUnavailable
    case requestCreationFailed
    case notAuthorized
    
    public var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is not available for the requested locale."
        case .requestCreationFailed:
            return "Failed to create speech recognition audio buffer request."
        case .notAuthorized:
            return "Speech recognition is not authorized."
        }
    }
}

@MainActor
@Observable
public final class SpeechRecognitionService: NSObject, SpeechRecognitionProtocol, @unchecked Sendable {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isTapInstalled = false
    private var onResultCallback: ((String) -> Void)?
    private var onErrorCallback: ((Error) -> Void)?
    private var simulationTask: Task<Void, Never>?

    public var isRecording: Bool = false
    public var isListening: Bool { isRecording }
    public var recognizedText: String = ""

    public init(locale: String = "en-US") {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
        super.init()
    }

    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        #if targetEnvironment(simulator)
        DispatchQueue.main.async { completion(true) }
        #else
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            #if os(iOS)
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    DispatchQueue.main.async { completion(granted) }
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    DispatchQueue.main.async { completion(granted) }
                }
            }
            #else
            DispatchQueue.main.async { completion(true) }
            #endif
        }
        #endif
    }

    public func startListening(onResult: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.onResultCallback = onResult
        self.onErrorCallback = onError

        requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            guard authorized else {
                onError(SpeechRecognitionError.notAuthorized)
                return
            }
            do {
                try self.startListening()
            } catch {
                onError(error)
            }
        }
    }

    public func startListening() throws {
        stopListening()

        #if targetEnvironment(simulator)
        isRecording = true
        recognizedText = ""
        simulationTask?.cancel()
        simulationTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(for: .milliseconds(400))
            if !Task.isCancelled && self.isRecording {
                self.recognizedText = "A black dog"
                self.onResultCallback?("A black dog")
            }
            try? await Task.sleep(for: .milliseconds(600))
            if !Task.isCancelled && self.isRecording {
                self.recognizedText = "A black dog jumps over the fence"
                self.onResultCallback?("A black dog jumps over the fence")
            }
        }
        return
        #else

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            throw SpeechRecognitionError.notAuthorized
        }

        #if os(iOS)
        let isRecordGranted: Bool
        if #available(iOS 17.0, *) {
            isRecordGranted = AVAudioApplication.shared.recordPermission == .granted
        } else {
            isRecordGranted = AVAudioSession.sharedInstance().recordPermission == .granted
        }
        guard isRecordGranted else {
            throw SpeechRecognitionError.notAuthorized
        }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        recognitionRequest.shouldReportPartialResults = true

        audioEngine.reset()
        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        isTapInstalled = false

        let hardwareFormat = inputNode.outputFormat(forBus: 0)
        guard hardwareFormat.sampleRate > 0 && hardwareFormat.channelCount > 0 else {
            throw SpeechRecognitionError.requestCreationFailed
        }

        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.recognizedText = text
                    self.onResultCallback?(text)
                }
            }
            if let error = error {
                let nsError = error as NSError
                let isCancelledError = !self.isRecording ||
                    (nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 216 || nsError.code == 1110)) ||
                    (nsError.domain == "com.apple.speech.speechrecognitionerror" && nsError.code == 203)
                
                DispatchQueue.main.async {
                    if !isCancelledError {
                        self.onErrorCallback?(error)
                    }
                    self.stopListening()
                }
            } else if result?.isFinal ?? false {
                DispatchQueue.main.async {
                    self.stopListening()
                }
            }
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        isTapInstalled = true

        do {
            audioEngine.prepare()
            try audioEngine.start()
            isRecording = true
            recognizedText = ""
        } catch {
            stopListening()
            throw error
        }
        #endif
    }

    public func stopListening() {
        simulationTask?.cancel()
        simulationTask = nil

        guard isRecording else { return }
        isRecording = false

        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        audioEngine.reset()

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}
