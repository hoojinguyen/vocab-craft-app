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

    public var isRecording: Bool = false
    public var isListening: Bool { isRecording }
    public var recognizedText: String = ""

    public init(locale: String = "en-US") {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
        super.init()
    }

    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                completion(status == .authorized)
            }
        }
    }

    public func startListening(onResult: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
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

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }

        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.requestCreationFailed
        }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                DispatchQueue.main.async {
                    self.stopListening()
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        isTapInstalled = true

        audioEngine.prepare()
        try audioEngine.start()
        isRecording = true
        recognizedText = ""
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
