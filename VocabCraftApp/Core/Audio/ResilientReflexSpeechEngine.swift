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
        os_signpost(.event, log: signpostLog, name: name, "%{public}@", detail as NSString)
        #endif
    }

    static func error(_ operation: String, error: Error) {
        #if DEBUG
        let nsError = error as NSError
        logger.error(
            "operation=\(operation, privacy: .public) domain=\(nsError.domain, privacy: .public) code=\(nsError.code)"
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
    private var speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioController: any SpeechAudioEngineControlling
    public private(set) var isEngineReady: Bool = false
    private var sessionContextualPhrases: [String] = []
    private var pendingPreparationTask: Task<Void, Never>?
    private var audioLifecycleTask: Task<Void, Never>?
    private let bufferRelay = AudioBufferRelay()

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

    public init() {
        self.audioController = SpeechAudioEngineController()
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    init(
        audioController: any SpeechAudioEngineControlling = SpeechAudioEngineController(),
        speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    ) {
        self.audioController = audioController
        self.speechRecognizer = speechRecognizer
    }

    // MARK: - Session Lifecycle

    public func startSession(contextualPhrases: [String], lazy: Bool = false) {
        guard !isSessionActive else { return }
        LessonPerformanceDiagnostics.event("SpeechSessionStart", detail: "lazy=\(lazy)")
        self.sessionContextualPhrases = contextualPhrases
        self.isListeningPaused = false
        self.isSessionActive = true
        self.isEngineReady = false
        setupInterruptionObserver()

        if !lazy {
            pendingPreparationTask = Task { [weak self] in
                try? await self?.prepareEngineIfNeeded()
            }
        }
    }

    public func startSession(contextualPhrases: [String]) {
        startSession(contextualPhrases: contextualPhrases, lazy: false)
    }

    public func stopSession() {
        LessonPerformanceDiagnostics.event("SpeechSessionStop")
        removeInterruptionObserver()
        pendingPreparationTask?.cancel()
        pendingPreparationTask = nil
        isListeningPaused = false
        isSessionActive = false
        isEngineReady = false
        endWord()
        enqueueAudioTransition { controller in
            await controller.teardown()
        }
        #if os(iOS)
        Task.detached(priority: .userInitiated) {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        }
        #endif
        sessionContextualPhrases = []
    }

    public func pauseListening() {
        isListeningPaused = true
        pendingPreparationTask?.cancel()
        pendingPreparationTask = nil
        bufferRelay.mute()
        endWord()
        enqueueAudioTransition { controller in
            await controller.pause()
        }
    }

    public func resumeListening() {
        isListeningPaused = false
        bufferRelay.unmute()
        if isSessionActive {
            if !isEngineReady {
                pendingPreparationTask?.cancel()
                pendingPreparationTask = Task { [weak self] in
                    try? await self?.prepareEngineIfNeeded()
                }
            } else {
                enqueueAudioTransition { [weak self] controller in
                    do {
                        try await controller.resume()
                    } catch {
                        Task { @MainActor [weak self] in
                            self?.onError?(error)
                        }
                    }
                }
            }
        }
    }

    private func enqueueAudioTransition(_ operation: @escaping @Sendable (any SpeechAudioEngineControlling) async -> Void) {
        let previousTask = audioLifecycleTask
        let controller = audioController
        audioLifecycleTask = Task {
            _ = await previousTask?.value
            await operation(controller)
        }
    }

    private func requestAuthorizationIfNeeded() async throws {
        #if os(iOS) && !targetEnvironment(simulator)
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        switch speechStatus {
        case .authorized:
            if speechRecognizer == nil {
                self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
            }
        case .notDetermined:
            let speechGranted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            guard speechGranted else {
                throw NSError(
                    domain: "ResilientReflexSpeech",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized."]
                )
            }
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        default:
            throw NSError(
                domain: "ResilientReflexSpeech",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Speech recognition not authorized."]
            )
        }

        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        guard micGranted else {
            throw NSError(
                domain: "ResilientReflexSpeech",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied."]
            )
        }
        #endif
    }

    public func prepareEngineIfNeeded() async throws {
        guard isSessionActive else { return }
        if let audioLifecycleTask {
            await audioLifecycleTask.value
        }
        guard isSessionActive else { return }
        try await requestAuthorizationIfNeeded()
        guard isSessionActive, !Task.isCancelled else {
            throw CancellationError()
        }
        #if os(iOS) && !targetEnvironment(simulator)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.defaultToSpeaker, .allowBluetoothHFP]
        )
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        try? session.overrideOutputAudioPort(.speaker)
        try await Task.sleep(for: .milliseconds(100))
        #endif
        do {
            try await audioController.prepare(relay: bufferRelay)
        } catch {
            if !(error is CancellationError) {
                onError?(error)
            }
            throw error
        }
        guard isSessionActive, !Task.isCancelled else {
            isEngineReady = false
            await audioController.teardown()
            if Task.isCancelled {
                throw CancellationError()
            }
            return
        }
        isEngineReady = true
        isListeningPaused = false
        bufferRelay.unmute()
    }

    // MARK: - Word Lifecycle

    public func beginWord(targetLemma: String, contextualPhrases: [String]) {
        LessonPerformanceDiagnostics.event(
            "SpeechWordBegin",
            detail: "engineReady=\(isEngineReady) sessionActive=\(isSessionActive)"
        )
        // End previous word if still active
        if isWordActive {
            endWord()
        }

        isListeningPaused = false

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
        guard let recognizer = resolveSpeechRecognizer(), recognizer.isAvailable else {
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
                    } else if nsError.code != 216 && nsError.code != 203 && nsError.code != 301 {
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
