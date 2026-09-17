import AVFoundation
import Foundation
import Observation
import Speech
import SpeechKit

final class ReflexCleanupBox: @unchecked Sendable {
    private let lock = NSLock()
    private var _eventSubscriptionTask: Task<Void, Never>?

    var eventSubscriptionTask: Task<Void, Never>? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _eventSubscriptionTask
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _eventSubscriptionTask = newValue
        }
    }

    func cleanup() {
        lock.lock()
        let task = _eventSubscriptionTask
        _eventSubscriptionTask = nil
        lock.unlock()
        task?.cancel()
    }
}

@MainActor
@Observable
public final class ResilientReflexSpeechEngine: ReflexSpeechEngineProtocol {
    // MARK: - Observable State
    public internal(set) var isSessionActive: Bool = false
    public internal(set) var isWordActive: Bool = false
    public internal(set) var isListeningPaused: Bool = false
    public internal(set) var liveTranscript: String = ""

    // MARK: - Callbacks
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    // MARK: - Engine layer (session-scoped)
    var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    let audioController: any SpeechAudioEngineControlling
    public internal(set) var isEngineReady: Bool = false
    var sessionContextualPhrases: [String] = []
    var pendingPreparationTask: Task<Void, Never>?
    public internal(set) var audioLifecycleTask: Task<Void, Never>?
    public internal(set) var sessionReleaseTask: Task<Void, Never>?
    public internal(set) var activeLease: AudioSessionLease?
    var activeStartTask: Task<Void, Error>?
    var wordGeneration: UInt = 0
    let authorizer: any SpeechAuthorizing
    let bufferRelay = AudioBufferRelay()

    var currentSpeechRecognizer: SFSpeechRecognizer? {
        speechRecognizer
    }

    @discardableResult
    func resolveSpeechRecognizer() -> SFSpeechRecognizer? {
        if let recognizer = speechRecognizer, recognizer.isAvailable {
            return recognizer
        }
        let refreshed = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.speechRecognizer = refreshed
        return refreshed
    }

    // MARK: - Request layer (word-scoped)
    var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    var activeTask: SFSpeechRecognitionTask?
    var currentTargetLemma: String = ""
    var currentWordSessionToken: UUID = UUID()
    var hasReportedFirstRecognitionResult: Bool = false

    // MARK: - Throttle (nonisolated for real-time callback)
    let throttleLock = NSLock()
    var lastDispatchTime: CFAbsoluteTime = 0
    /// Minimum interval between MainActor dispatches for partial results (seconds)
    let throttleInterval: CFAbsoluteTime = 0.15

    let cleanupBox = ReflexCleanupBox()
    var eventSubscriptionTask: Task<Void, Never>? {
        get { cleanupBox.eventSubscriptionTask }
        set { cleanupBox.eventSubscriptionTask = newValue }
    }

    public var hasEventSubscription: Bool {
        eventSubscriptionTask != nil
    }

    @available(*, deprecated, renamed: "hasEventSubscription")
    public var hasInterruptionObserver: Bool {
        hasEventSubscription
    }

    public let audioSessionCoordinator: (any AudioSessionCoordinating)?

    public convenience init(audioSessionCoordinator: (any AudioSessionCoordinating)? = AudioSessionCoordinator()) {
        self.init(
            audioController: SpeechAudioEngineController(),
            audioSessionCoordinator: audioSessionCoordinator
        )
    }

    init(
        audioController: any SpeechAudioEngineControlling = SpeechAudioEngineController(),
        audioSessionCoordinator: (any AudioSessionCoordinating)? = nil,
        speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
        authorizer: any SpeechAuthorizing = LiveSpeechAuthorizer()
    ) {
        self.audioController = audioController
        self.audioSessionCoordinator = audioSessionCoordinator
        self.speechRecognizer = speechRecognizer
        self.authorizer = authorizer
    }

    deinit {
        cleanupBox.cleanup()
    }
}
