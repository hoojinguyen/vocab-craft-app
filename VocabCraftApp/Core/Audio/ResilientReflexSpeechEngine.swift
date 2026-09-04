import AVFoundation
import Foundation
import Observation
import os
import Speech
import SpeechKit

enum LessonPerformanceDiagnostics {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "VocabCraftApp"
    private static let logger = Logger(subsystem: subsystem, category: "LessonPerformance")
    private static let signpostLog = OSLog(subsystem: subsystem, category: .pointsOfInterest)

    static func event(_ name: StaticString, detail: String = "") {
        #if DEBUG
        let nameText = String(describing: name)
        logger.notice("event=\(nameText, privacy: .public) detail=\(detail, privacy: .public)")
        NSLog("[LessonPerformance] event=%@ detail=%@", nameText, detail)
        os_signpost(.event, log: signpostLog, name: name, "%{public}@", detail as NSString)
        #endif
    }

    static func error(_ operation: String, error: Error) {
        #if DEBUG
        let nsError = error as NSError
        logger.error(
            "operation=\(operation, privacy: .public) domain=\(nsError.domain, privacy: .public) code=\(nsError.code)"
        )
        NSLog(
            "[LessonPerformance] operation=%@ domain=%@ code=%ld",
            operation,
            nsError.domain,
            nsError.code
        )
        #endif
    }
}

/// Thread-safe buffer relay to bridge AVAudioEngine real-time audio tap callbacks with
/// SFSpeechAudioBufferRecognitionRequest without capturing @MainActor isolated references.
public final class AudioBufferRelay: @unchecked Sendable {
    private let lock = NSLock()
    private weak var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var isMuted: Bool = false

    public init() {}

    public var isCurrentlyMuted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isMuted
    }

    public var currentRequest: SFSpeechAudioBufferRecognitionRequest? {
        lock.lock()
        defer { lock.unlock() }
        return activeRequest
    }

    public func setRequest(_ request: SFSpeechAudioBufferRecognitionRequest?) {
        lock.lock()
        defer { lock.unlock() }
        activeRequest = request
        isMuted = false
    }

    public func mute() {
        lock.lock()
        defer { lock.unlock() }
        isMuted = true
    }

    public func unmute() {
        lock.lock()
        defer { lock.unlock() }
        isMuted = false
    }

    /// Atomically detaches the active request and invokes endAudio() on it.
    /// Guarantees that no background tap buffer can ever be appended after endAudio() is called.
    public func detachAndEnd() {
        lock.lock()
        defer { lock.unlock() }
        let requestToEnd = activeRequest
        activeRequest = nil
        isMuted = true
        requestToEnd?.endAudio()
    }

    public func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard !isMuted, let request = activeRequest else {
            return
        }
        request.append(buffer)
    }
}

/// Thread-safe holder for an NSNotificationCenter observer token.
/// Automatically removes the observer when deallocated or explicitly cancelled.
private final class InterruptionObserverToken: @unchecked Sendable {
    private let lock = NSLock()
    private var observer: (any NSObjectProtocol)?

    init(observer: (any NSObjectProtocol)?) {
        self.observer = observer
    }

    deinit {
        cancel()
    }

    func cancel() {
        #if os(iOS)
        lock.lock()
        let obs = observer
        observer = nil
        lock.unlock()
        if let obs {
            NotificationCenter.default.removeObserver(obs)
        }
        #endif
    }
}

@MainActor
@Observable
public final class ResilientReflexSpeechEngine: ReflexSpeechEngineProtocol {
    // MARK: - Observable State
    public private(set) var isSessionActive: Bool = false
    public private(set) var isWordActive: Bool = false
    public private(set) var isListeningPaused: Bool = false
    public private(set) var liveTranscript: String = ""

    // MARK: - Callbacks
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    // MARK: - Engine layer (session-scoped)
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var sessionContextualPhrases: [String] = []
    private var isStartingEngine: Bool = false
    private var pendingSetupTask: Task<Void, Never>?
    private let bufferRelay = AudioBufferRelay()

    // MARK: - Request layer (word-scoped)
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var activeTask: SFSpeechRecognitionTask?
    private var currentTargetLemma: String = ""
    private var currentWordSessionToken: UUID = UUID()
    private var hasReportedFirstRecognitionResult: Bool = false

    // MARK: - Throttle (nonisolated for real-time callback)
    private let throttleLock = NSLock()
    private var lastDispatchTime: CFAbsoluteTime = 0
    /// Minimum interval between MainActor dispatches for partial results (seconds)
    private let throttleInterval: CFAbsoluteTime = 0.15

    private var interruptionToken: InterruptionObserverToken?
    var hasInterruptionObserver: Bool {
        #if os(iOS)
        interruptionToken != nil
        #else
        false
        #endif
    }

    public init() {}

    // MARK: - Session Lifecycle

    public func startSession(contextualPhrases: [String], lazy: Bool = false) {
        guard !isSessionActive else { return }
        LessonPerformanceDiagnostics.event("SpeechSessionStart", detail: "lazy=\(lazy)")
        self.sessionContextualPhrases = contextualPhrases
        self.isStartingEngine = false
        self.isListeningPaused = false
        self.isSessionActive = true
        setupInterruptionObserver()

        #if os(iOS)
        Task.detached(priority: .userInitiated) {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(
                    .playAndRecord,
                    mode: .spokenAudio,
                    options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers]
                )
                try session.setActive(true, options: .notifyOthersOnDeactivation)
            } catch {
                LessonPerformanceDiagnostics.error("speech.session.prewarm", error: error)
                // Non-fatal early audio session configuration
            }
        }
        #endif

        if !lazy {
            #if targetEnvironment(simulator) || os(macOS)
            // Simulator: no real audio engine
            #else
            requestAuthorizationAndStartEngine()
            #endif
        }
    }

    public func startSession(contextualPhrases: [String]) {
        startSession(contextualPhrases: contextualPhrases, lazy: false)
    }

    public func stopSession() {
        LessonPerformanceDiagnostics.event("SpeechSessionStop")
        removeInterruptionObserver()
        pendingSetupTask?.cancel()
        pendingSetupTask = nil
        isStartingEngine = false
        isListeningPaused = false
        isSessionActive = false
        endWord()
        teardownEngine()
        sessionContextualPhrases = []
    }

    public func pauseListening() {
        isListeningPaused = true
        pendingSetupTask?.cancel()
        pendingSetupTask = nil
        isStartingEngine = false
        bufferRelay.mute()
        endWord()
        #if !targetEnvironment(simulator) && !os(macOS)
        if let engine = audioEngine, engine.isRunning {
            engine.stop()
        }
        #endif
    }

    public func resumeListening() {
        isListeningPaused = false
        bufferRelay.unmute()
        #if !targetEnvironment(simulator) && !os(macOS)
        if isSessionActive {
            if let engine = audioEngine {
                if !engine.isRunning {
                    do {
                        try engine.start()
                    } catch {
                        onError?(error)
                    }
                }
            } else if !isStartingEngine {
                prepareEngineIfNeeded()
            }
        }
        #endif
    }

    public func prepareEngineIfNeeded() {
        #if !targetEnvironment(simulator) && !os(macOS)
        guard isSessionActive, !isListeningPaused, audioEngine == nil, !isStartingEngine else { return }
        requestAuthorizationAndStartEngine()
        #endif
    }

    // MARK: - Word Lifecycle

    public func beginWord(targetLemma: String, contextualPhrases: [String]) {
        LessonPerformanceDiagnostics.event(
            "SpeechWordBegin",
            detail: "engineReady=\(audioEngine?.isRunning == true) sessionActive=\(isSessionActive)"
        )
        // End previous word if still active
        if isWordActive {
            endWord()
        }

        isListeningPaused = false

        #if !targetEnvironment(simulator) && !os(macOS)
        if isSessionActive, let engine = audioEngine, !engine.isRunning {
            do {
                try engine.start()
            } catch {
                onError?(error)
                return
            }
        }
        #endif

        let token = UUID()
        currentWordSessionToken = token
        currentTargetLemma = targetLemma
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        liveTranscript = ""
        hasReportedFirstRecognitionResult = false
        isWordActive = true

        #if targetEnvironment(simulator) || os(macOS)
        // Simulator: no real recognition, test via simulateTranscript
        #else
        startRecognitionRequest(
            targetLemma: currentTargetLemma,
            contextualPhrases: contextualPhrases,
            sessionToken: token
        )
        #endif
    }

    public func endWord() {
        currentWordSessionToken = UUID() // Invalidate current token

        bufferRelay.detachAndEnd()
        activeTask?.cancel()
        activeRequest = nil
        activeTask = nil
        isWordActive = false
    }

    public func finalizeWordAudio() {
        // Signal end of audio input but keep recognition task alive
        // so in-flight buffers can still be processed during grace period.
        bufferRelay.detachAndEnd()
    }

    // MARK: - Simulator support
    public func simulateTranscript(_ text: String) {
        guard isWordActive else { return }
        liveTranscript = text
        onTranscriptUpdate?(text)

        if !currentTargetLemma.isEmpty,
           ReflexSpeechMatcher.isReflexMatch(
               spokenText: text,
               targetLemma: currentTargetLemma
           ) {
            onMatchDetected?(currentTargetLemma)
        }
    }
}

// MARK: - Audio Engine Management

extension ResilientReflexSpeechEngine {
    #if !targetEnvironment(simulator) && !os(macOS)
    private func requestAuthorizationAndStartEngine() {
        LessonPerformanceDiagnostics.event("SpeechAuthorizationRequest")
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self, self.isSessionActive else { return }
                LessonPerformanceDiagnostics.event("SpeechAuthorizationResult", detail: "status=\(status.rawValue)")
                guard status == .authorized else {
                    self.onError?(NSError(
                        domain: "ResilientReflexSpeech",
                        code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized."]
                    ))
                    return
                }
                self.requestMicPermissionAndStartEngine()
            }
        }
    }

    private func requestMicPermissionAndStartEngine() {
        #if os(iOS)
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self, self.isSessionActive else { return }
                    if granted {
                        self.setupAndStartEngine()
                    } else {
                        self.onError?(NSError(
                            domain: "ResilientReflexSpeech",
                            code: 403,
                            userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied."]
                        ))
                    }
                }
            }
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                Task { @MainActor [weak self] in
                    guard let self, self.isSessionActive else { return }
                    if granted {
                        self.setupAndStartEngine()
                    } else {
                        self.onError?(NSError(
                            domain: "ResilientReflexSpeech",
                            code: 403,
                            userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied."]
                        ))
                    }
                }
            }
        }
        #else
        setupAndStartEngine()
        #endif
    }

    private func setupAndStartEngine() {
        guard !isStartingEngine, !isListeningPaused else { return }
        isStartingEngine = true
        let setupStartedAt = CFAbsoluteTimeGetCurrent()
        LessonPerformanceDiagnostics.event("SpeechEngineSetupStart")

        pendingSetupTask?.cancel()
        pendingSetupTask = Task(priority: .userInitiated) {
            #if os(iOS)
            let sessionResult = await Task.detached(priority: .userInitiated) { () -> Result<Void, Error> in
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(
                        .playAndRecord,
                        mode: .spokenAudio,
                        options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers]
                    )
                    try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
                    return .success(())
                } catch {
                    return .failure(error)
                }
            }.value

            self.isStartingEngine = false

            guard !Task.isCancelled, self.isSessionActive, !self.isListeningPaused else {
                if !self.isSessionActive {
                    // Session was stopped while audio session activation was in-flight.
                    // Switch back to playback category without deactivating shared session to protect CoreHaptics.
                    Task.detached(priority: .userInitiated) {
                        let session = AVAudioSession.sharedInstance()
                        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
                    }
                }
                return
            }

            switch sessionResult {
            case .success:
                let elapsed = CFAbsoluteTimeGetCurrent() - setupStartedAt
                LessonPerformanceDiagnostics.event(
                    "SpeechAudioSessionReady",
                    detail: "elapsedMs=\(Int(elapsed * 1_000))"
                )
                self.startAudioEngine()
            case .failure(let error):
                LessonPerformanceDiagnostics.error("speech.audioSession.activate", error: error)
                self.onError?(error)
            }
            #else
            self.isStartingEngine = false
            guard !Task.isCancelled, self.isSessionActive, !self.isListeningPaused else { return }
            self.startAudioEngine()
            #endif
        }
    }

    private func startAudioEngine() {
        let engineStartedAt = CFAbsoluteTimeGetCurrent()
        LessonPerformanceDiagnostics.event("SpeechAudioEngineStart")
        do {
            if let existingEngine = audioEngine {
                existingEngine.inputNode.removeTap(onBus: 0)
                if existingEngine.isRunning {
                    existingEngine.stop()
                }
                audioEngine = nil
            }

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode

            #if os(iOS)
            do {
                try inputNode.setVoiceProcessingEnabled(true)
            } catch {
                print("[ResilientReflexSpeechEngine] Voice processing unavailable: \(error)")
            }
            #endif

            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
                throw NSError(
                    domain: "ResilientReflexSpeech",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid microphone format."]
                )
            }

            let relay = self.bufferRelay
            inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { [relay] buffer, _ in
                // Forward buffer to active request (thread-safe, Sendable relay)
                relay.append(buffer)
            }

            engine.prepare()
            try engine.start()
            self.audioEngine = engine
            let elapsed = CFAbsoluteTimeGetCurrent() - engineStartedAt
            LessonPerformanceDiagnostics.event(
                "SpeechAudioEngineReady",
                detail: "elapsedMs=\(Int(elapsed * 1_000)) sampleRate=\(Int(recordingFormat.sampleRate)) channels=\(recordingFormat.channelCount)"
            )
        } catch {
            LessonPerformanceDiagnostics.error("speech.audioEngine.start", error: error)
            onError?(error)
        }
    }
    #endif

    private func teardownEngine() {
        #if !targetEnvironment(simulator) && !os(macOS)
        pendingSetupTask?.cancel()
        pendingSetupTask = nil
        isStartingEngine = false
        bufferRelay.detachAndEnd()
        if let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            if engine.isRunning {
                engine.stop()
            }
        }
        audioEngine = nil

        #if os(iOS)
        if !isSessionActive {
            Task.detached(priority: .userInitiated) {
                let session = AVAudioSession.sharedInstance()
                try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            }
        }
        #endif
        #endif
    }
}

// MARK: - Audio Interruption Management

extension ResilientReflexSpeechEngine {
    private func setupInterruptionObserver() {
        #if os(iOS)
        guard interruptionToken == nil else { return }
        let observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    self?.handleAudioInterruption(notification)
                }
            } else {
                Task { @MainActor [weak self] in
                    self?.handleAudioInterruption(notification)
                }
            }
        }
        interruptionToken = InterruptionObserverToken(observer: observer)
        #endif
    }

    private func removeInterruptionObserver() {
        #if os(iOS)
        interruptionToken?.cancel()
        interruptionToken = nil
        #endif
    }

    #if os(iOS)
    func handleAudioInterruption(_ notification: Notification) {
        guard isSessionActive, let userInfo = notification.userInfo else { return }
        let rawType = (userInfo[AVAudioSessionInterruptionTypeKey] as? UInt)
            ?? ((userInfo[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue)
        guard let rawType, let type = AVAudioSession.InterruptionType(rawValue: rawType) else {
            return
        }

        switch type {
        case .began:
            pauseListening()
        case .ended:
            let rawOptions = (userInfo[AVAudioSessionInterruptionOptionKey] as? UInt)
                ?? ((userInfo[AVAudioSessionInterruptionOptionKey] as? NSNumber)?.uintValue)
            if let rawOptions {
                let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
                if options.contains(.shouldResume) {
                    #if !targetEnvironment(simulator) && !os(macOS)
                    if isSessionActive {
                        let session = AVAudioSession.sharedInstance()
                        try? session.setActive(true, options: .notifyOthersOnDeactivation)
                    }
                    #endif
                    resumeListening()
                }
            }
        @unknown default:
            break
        }
    }
    #endif
}

// MARK: - Recognition Request Management

extension ResilientReflexSpeechEngine {
    #if !targetEnvironment(simulator) && !os(macOS)
    private func buildRecognitionRequest(
        targetLemma: String,
        contextualPhrases: [String]
    ) -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .search

        var biasedPhrases = (sessionContextualPhrases + contextualPhrases)
            .flatMap { phrase -> [String] in
                let trimmed = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return [] }
                if trimmed.split(separator: " ").count <= 2 {
                    return [trimmed]
                }
                return []
            }
        if !biasedPhrases.contains(targetLemma) {
            biasedPhrases.append(targetLemma)
        }
        request.contextualStrings = Array(Set(biasedPhrases))

        #if os(iOS)
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        #endif

        return request
    }

    private func startRecognitionRequest(
        targetLemma: String,
        contextualPhrases: [String],
        sessionToken: UUID
    ) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            onError?(NSError(
                domain: "ResilientReflexSpeech",
                code: 503,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable."]
            ))
            return
        }

        let request = buildRecognitionRequest(
            targetLemma: targetLemma,
            contextualPhrases: contextualPhrases
        )

        self.activeRequest = request
        self.bufferRelay.setRequest(request)

        // Reset throttle timestamp for new word
        throttleLock.lock()
        lastDispatchTime = 0
        throttleLock.unlock()

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            // Error handling — always dispatch immediately
            if let error {
                LessonPerformanceDiagnostics.error("speech.recognition", error: error)
                Task { @MainActor [weak self] in
                    guard let self,
                          self.isWordActive,
                          self.currentWordSessionToken == sessionToken else { return }

                    let nsError = error as NSError
                    // 216 = cancelled (normal), 1110 = timeout (60s limit)
                    if nsError.code == 1110 {
                        // 60s limit hit — auto-recover
                        self.endWord()
                        self.beginWord(
                            targetLemma: targetLemma,
                            contextualPhrases: contextualPhrases
                        )
                    } else if nsError.code != 216 {
                        self.onError?(error)
                    }
                }
                return
            }

            guard let result else { return }
            let spoken = result.bestTranscription.formattedString

            Task { @MainActor [weak self] in
                guard let self,
                      self.isWordActive,
                      self.currentWordSessionToken == sessionToken,
                      !self.hasReportedFirstRecognitionResult else { return }
                self.hasReportedFirstRecognitionResult = true
                LessonPerformanceDiagnostics.event("SpeechFirstRecognitionResult")
            }

            // Check match first — always dispatch match detection immediately
            let isMatch = ReflexSpeechMatcher.isReflexMatch(
                spokenText: spoken,
                targetLemma: targetLemma
            )

            if isMatch {
                // Match found — dispatch immediately, bypass throttle
                Task { @MainActor [weak self] in
                    guard let self,
                          self.isWordActive,
                          self.currentWordSessionToken == sessionToken else { return }
                    self.liveTranscript = spoken
                    self.onTranscriptUpdate?(spoken)
                    self.onMatchDetected?(targetLemma)
                }
                return
            }

            // Throttle non-match partial results to reduce MainActor pressure.
            // SFSpeechRecognizer fires 30-50 callbacks/sec; we cap UI updates at ~7/sec.
            let now = CFAbsoluteTimeGetCurrent()
            self.throttleLock.lock()
            let elapsed = now - self.lastDispatchTime
            let shouldDispatch = elapsed >= self.throttleInterval
            if shouldDispatch {
                self.lastDispatchTime = now
            }
            self.throttleLock.unlock()

            guard shouldDispatch else { return }

            Task { @MainActor [weak self] in
                guard let self,
                      self.isWordActive,
                      self.currentWordSessionToken == sessionToken else { return }
                self.liveTranscript = spoken
                self.onTranscriptUpdate?(spoken)
            }
        }

        self.activeTask = task
    }
    #endif
}
