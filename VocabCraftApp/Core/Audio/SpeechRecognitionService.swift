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

private final class ServiceCleanupBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _eventSubscriptionTask: Task<Void, Never>?
    private var _activeLease: AudioSessionLease?
    let audioSessionCoordinator: any AudioSessionCoordinating

    init(audioSessionCoordinator: any AudioSessionCoordinating) {
        self.audioSessionCoordinator = audioSessionCoordinator
    }

    var eventSubscriptionTask: Task<Void, Never>? {
        get { lock.withLock { _eventSubscriptionTask } }
        set { lock.withLock { _eventSubscriptionTask = newValue } }
    }

    var activeLease: AudioSessionLease? {
        get { lock.withLock { _activeLease } }
        set { lock.withLock { _activeLease = newValue } }
    }

    func cleanup() {
        let (task, lease) = lock.withLock { () -> (Task<Void, Never>?, AudioSessionLease?) in
            let task = _eventSubscriptionTask
            _eventSubscriptionTask = nil
            let lease = _activeLease
            _activeLease = nil
            return (task, lease)
        }
        task?.cancel()
        if let lease {
            let coordinator = audioSessionCoordinator
            Task {
                await coordinator.release(lease)
            }
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
    private var eventSubscriptionTask: Task<Void, Never>?
    private let cleanupBox: ServiceCleanupBox

    public let audioSessionCoordinator: any AudioSessionCoordinating
    private(set) var activeLease: AudioSessionLease?
    public private(set) var leaseAcquisitionTask: Task<Void, Never>?
    public private(set) var leaseReleaseTask: Task<Void, Never>?

    public var isRecording: Bool = false
    public var isListening: Bool { isRecording }
    public var recognizedText: String = ""

    public init(
        locale: String = "en-US",
        audioSessionCoordinator: any AudioSessionCoordinating = AudioSessionCoordinator()
    ) {
        self.audioSessionCoordinator = audioSessionCoordinator
        self.cleanupBox = ServiceCleanupBox(audioSessionCoordinator: audioSessionCoordinator)
        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            self.speechRecognizer = nil
        } else {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
        }
        super.init()
        subscribeToAudioSessionEvents()
    }

    deinit {
        cleanupBox.cleanup()
    }

    private func subscribeToAudioSessionEvents() {
        let task = Task { @MainActor [weak self, events = audioSessionCoordinator.events] in
            for await event in events {
                guard let self else { break }
                guard self.isRecording else { continue }
                switch event {
                case .interruptionBegan:
                    self.stopListening()
                    self.onErrorCallback?(SpeechRecognitionError.notAuthorized)
                case .mediaServicesReset:
                    self.stopListening()
                    self.onErrorCallback?(SpeechRecognitionError.recognizerUnavailable)
                default:
                    break
                }
            }
        }
        self.eventSubscriptionTask = task
        self.cleanupBox.eventSubscriptionTask = task
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
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
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

        authorizationRequestID += 1
        let requestID = authorizationRequestID
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let lease = try await self.audioSessionCoordinator.acquire(.speechCapture)
                guard !Task.isCancelled, self.authorizationRequestID == requestID else {
                    await self.audioSessionCoordinator.release(lease)
                    return
                }
                self.activeLease = lease
                self.cleanupBox.activeLease = lease
            } catch {
                self.stopListening()
                self.onErrorCallback?(error)
            }
        }
        self.leaseAcquisitionTask = task

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
        guard AVAudioApplication.shared.recordPermission == .granted else {
            throw SpeechRecognitionError.notAuthorized
        }
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
        leaseAcquisitionTask?.cancel()
        leaseAcquisitionTask = nil
        simulationTask?.cancel()
        simulationTask = nil

        if let lease = activeLease {
            activeLease = nil
            cleanupBox.activeLease = nil
            let task = Task { [coordinator = audioSessionCoordinator] in
                await coordinator.release(lease)
            }
            leaseReleaseTask = task
        }

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
    }
}
