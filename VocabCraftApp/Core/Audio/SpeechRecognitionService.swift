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

    public var isRecording: Bool = false
    public var isListening: Bool { isRecording }
    public var recognizedText: String = ""

    public init(locale: String = "en-US") {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
        super.init()
    }

    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
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
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
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

        let inputNode = audioEngine.inputNode
        if isTapInstalled {
            inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        let hardwareFormat = inputNode.outputFormat(forBus: 0)
        let busFormat = inputNode.inputFormat(forBus: 0)
        let format: AVAudioFormat
        if hardwareFormat.sampleRate > 0 && hardwareFormat.channelCount > 0 {
            format = hardwareFormat
        } else if busFormat.sampleRate > 0 && busFormat.channelCount > 0 {
            format = busFormat
        } else if let standardFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1) {
            format = standardFormat
        } else {
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
                DispatchQueue.main.async {
                    self.onErrorCallback?(error)
                    self.stopListening()
                }
            } else if result?.isFinal ?? false {
                DispatchQueue.main.async {
                    self.stopListening()
                }
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
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
    }

    public func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }

        if isTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            isTapInstalled = false
        }

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}
