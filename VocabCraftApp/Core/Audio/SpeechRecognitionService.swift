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

private final class AudioMeterState: @unchecked Sendable {
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

@MainActor
@Observable
public final class SpeechRecognitionService: NSObject, SpeechRecognitionProtocol {
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var isTapInstalled = false
    private var onResultCallback: ((String) -> Void)?
    private var onAudioLevelCallback: ((Float) -> Void)?
    private var onErrorCallback: ((Error) -> Void)?
    private var simulationTask: Task<Void, Never>?
    private var authorizationRequestID = 0
    private var eventSubscriptionTask: Task<Void, Never>?
    private let cleanupBox: ServiceCleanupBox
    private let meterState = AudioMeterState()

    public let audioSessionCoordinator: any AudioSessionCoordinating
    private(set) var activeLease: AudioSessionLease?
    public private(set) var leaseAcquisitionTask: Task<Void, Never>?
    public private(set) var leaseReleaseTask: Task<Void, Never>?

    public var isRecording: Bool = false
    public var isListening: Bool { isRecording }
    public var recognizedText: String = ""
    public private(set) var audioLevel: Float = 0.0

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

    public static func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
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

    public static func calculateNormalizedAudioLevel(rms: Float) -> Float {
        let db = 20.0 * log10(max(rms, 0.0001))
        let normalized = (db + 50.0) / 50.0
        return min(max(normalized, 0.0), 1.0)
    }

    public func injectAudioLevelForTesting(_ level: Float) {
        let clamped = min(max(level, 0.0), 1.0)
        self.audioLevel = clamped
        self.onAudioLevelCallback?(clamped)
    }

    public func processAudioBufferForTesting(_ buffer: AVAudioPCMBuffer) {
        let rms = Self.calculateRMS(buffer: buffer)
        let normalized = Self.calculateNormalizedAudioLevel(rms: rms)
        self.audioLevel = normalized
        self.onAudioLevelCallback?(normalized)
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard meterState.shouldProcessMeter() else { return }
        let rms = Self.calculateRMS(buffer: buffer)
        let normalized = Self.calculateNormalizedAudioLevel(rms: rms)

        Task { @MainActor [weak self] in
            guard let self, self.isRecording else { return }
            self.audioLevel = normalized
            self.onAudioLevelCallback?(normalized)
        }
    }

    public func requestAuthorization(completion: @escaping @Sendable @MainActor (Bool) -> Void) {
        #if targetEnvironment(simulator)
        completion(true)
        #else
        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            completion(true)
            return
        }
        SFSpeechRecognizer.requestAuthorization { status in
            guard status == .authorized else {
                Task { @MainActor in completion(false) }
                return
            }

            #if os(iOS)
            AVAudioApplication.requestRecordPermission { granted in
                Task { @MainActor in completion(granted) }
            }
            #else
            Task { @MainActor in completion(true) }
            #endif
        }
        #endif
    }

    public func startListening(
        onResult: @escaping (String) -> Void,
        onAudioLevel: ((Float) -> Void)? = nil,
        onError: @escaping (Error) -> Void
    ) {
        authorizationRequestID += 1
        let requestID = authorizationRequestID
        self.onResultCallback = onResult
        self.onAudioLevelCallback = onAudioLevel
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

    public func startListening(onResult: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        startListening(onResult: onResult, onAudioLevel: nil, onError: onError)
    }

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
                try self.startCaptureSession()
            } catch {
                self.stopListening()
                self.onErrorCallback?(error)
            }
        }
        self.leaseAcquisitionTask = task
    }

    private func startCaptureSession() throws {
        #if targetEnvironment(simulator)
        isRecording = true
        recognizedText = ""
        simulationTask?.cancel()
        simulationTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard let self, !Task.isCancelled, self.isRecording else { return }
            self.recognizedText = "A black dog"
            self.onResultCallback?("A black dog")

            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled, self.isRecording else { return }
            self.recognizedText = "A black dog jumps over the fence"
            self.onResultCallback?("A black dog jumps over the fence")
        }
        return
        #else
        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting {
            isRecording = true
            recognizedText = ""
            return
        }

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
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hardwareFormat) { [weak self] buffer, _ in
            guard buffer.frameLength > 0 else { return }
            request.append(buffer)
            self?.processAudioBuffer(buffer)
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

        audioLevel = 0.0
        meterState.reset()

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
