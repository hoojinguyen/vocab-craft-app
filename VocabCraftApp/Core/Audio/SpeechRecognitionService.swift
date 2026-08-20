import AVFoundation
import Foundation
import Observation
import Speech

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
public final class SpeechRecognitionService: NSObject, SpeechRecognitionProtocol {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isTapInstalled = false
    private var onResultCallback: ((String) -> Void)?
    private var onErrorCallback: ((Error) -> Void)?
    private var simulationTask: Task<Void, Never>?
    private var authorizationRequestID = 0
    private var interruptionObserver: (any NSObjectProtocol)?

    public var isRecording: Bool = false
    public var isListening: Bool { isRecording }
    public var recognizedText: String = ""

    public init(locale: String = "en-US") {
        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            self.speechRecognizer = nil
        } else {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
        }
        super.init()
        setupInterruptionObserver()
    }

    private func setupInterruptionObserver() {
        #if os(iOS)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            if type == .began {
                Task { @MainActor [weak self] in
                    guard let self = self, self.isRecording else { return }
                    self.stopListening()
                    self.onErrorCallback?(SpeechRecognitionError.notAuthorized)
                }
            }
        }
        #endif
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
        authorizationRequestID += 1
        let requestID = authorizationRequestID
        self.onResultCallback = onResult
        self.onErrorCallback = onError

        requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            guard self.authorizationRequestID == requestID else { return }
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

    // swiftlint:disable:next function_body_length
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
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
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
            Task { @MainActor in
                if let result = result {
                    let text = result.bestTranscription.formattedString
                    self.recognizedText = text
                    self.onResultCallback?(text)
                }
                if let error = error {
                    let nsError = error as NSError
                    let isCancelledError = !self.isRecording ||
                        (nsError.domain == "kAFAssistantErrorDomain" && (nsError.code == 216 || nsError.code == 1110)) ||
                        (nsError.domain == "com.apple.speech.speechrecognitionerror" && nsError.code == 203)

                    if !isCancelledError {
                        self.onErrorCallback?(error)
                    }
                    self.stopListening()
                } else if result?.isFinal ?? false {
                    self.stopListening()
                }
            }
        }

        let request = recognitionRequest
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { buffer, _ in
            guard buffer.frameLength > 0 else { return }
            request.append(buffer)
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
        // An authorization callback may arrive after cancellation. Advancing this
        // token prevents it from starting a new capture session.
        authorizationRequestID += 1
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
