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
        logger.notice("event=\(String(describing: name), privacy: .public) detail=\(detail, privacy: .public)")
        os_signpost(.event, log: signpostLog, name: name, "%{public}@", detail as NSString)
        #endif
    }

    static func error(_ operation: String, error: Error) {
        #if DEBUG
        let nsError = error as NSError
        logger.error("operation=\(operation, privacy: .public) domain=\(nsError.domain, privacy: .public) code=\(nsError.code)")
        #endif
    }
}

/// Thread-safe buffer relay to bridge AVAudioEngine real-time audio tap callbacks with
/// SFSpeechAudioBufferRecognitionRequest without capturing @MainActor isolated references.
public final class AudioBufferRelay: @unchecked Sendable {
    private let lock = NSLock()
    private weak var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var isMuted = false

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
        guard !isMuted, let request = activeRequest else { return }
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
    public private(set) var audioLifecycleTask: Task<Void, Never>?
    public private(set) var sessionReleaseTask: Task<Void, Never>?
    public private(set) var activeLease: AudioSessionLease?
    private var activeStartTask: Task<Void, Error>?
    private var wordGeneration: UInt = 0
    private let authorizer: any SpeechAuthorizing
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

    public let audioSessionCoordinator: (any AudioSessionCoordinating)?

    public init(
        audioSessionCoordinator: (any AudioSessionCoordinating)? = nil
    ) {
        self.audioController = SpeechAudioEngineController()
        self.audioSessionCoordinator = audioSessionCoordinator
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        self.authorizer = LiveSpeechAuthorizer()
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
        activeStartTask?.cancel()
        activeStartTask = nil
        wordGeneration &+= 1
        isListeningPaused = false
        isSessionActive = false
        isEngineReady = false
        endWord()
        let leaseToRelease = activeLease
        activeLease = nil
        let coordinator = audioSessionCoordinator
        self.sessionReleaseTask = enqueueAudioTransition { controller in
            await controller.teardown()
            if let leaseToRelease {
                await coordinator?.release(leaseToRelease)
            }
        }
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

    @discardableResult
    private func enqueueAudioTransition(
        _ operation: @escaping @Sendable (any SpeechAudioEngineControlling) async -> Void
    ) -> Task<Void, Never> {
        let previousTask = audioLifecycleTask
        let controller = audioController
        let transitionTask = Task {
            _ = await previousTask?.value
            await operation(controller)
        }
        audioLifecycleTask = transitionTask
        return transitionTask
    }

    private func requestAuthorizationIfNeeded() async throws {
        guard await authorizer.requestSpeechAuthorization() else {
            throw SpeechCaptureError.speechRecognitionDenied
        }
        guard await authorizer.requestMicrophoneAuthorization() else {
            throw SpeechCaptureError.microphoneDenied
        }
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

    private func ensureCurrentAndActive(generation: UInt) throws {
        guard isSessionActive, !Task.isCancelled, self.wordGeneration == generation else {
            throw SpeechCaptureError.cancelled
        }
    }

    private func checkPermissions(generation: UInt) async throws {
        try ensureCurrentAndActive(generation: generation)
        guard await authorizer.requestSpeechAuthorization() else {
            throw SpeechCaptureError.speechRecognitionDenied
        }
        try ensureCurrentAndActive(generation: generation)
        guard await authorizer.requestMicrophoneAuthorization() else {
            throw SpeechCaptureError.microphoneDenied
        }
        try ensureCurrentAndActive(generation: generation)
    }

    private func acquireDuplexLease(generation: UInt) async throws -> AudioSessionLease? {
        guard let coordinator = audioSessionCoordinator else { return nil }
        do {
            return try await coordinator.acquire(.duplexSpeech)
        } catch {
            if error is CancellationError {
                throw SpeechCaptureError.cancelled
            }
            throw SpeechCaptureError.audioSessionActivationFailed
        }
    }

    private func prepareAndResumeAudio(relay: AudioBufferRelay) async throws {
        do {
            try await audioController.prepare(relay: relay)
            try await audioController.resume()
        } catch {
            if error is CancellationError {
                throw SpeechCaptureError.cancelled
            }
            onError?(error)
            throw SpeechCaptureError.enginePreparationFailed
        }
    }

    private func activateWordCapture(targetLemma: String, contextualPhrases: [String]) throws {
        if isWordActive {
            endWord()
        }
        let token = UUID()
        currentWordSessionToken = token
        currentTargetLemma = targetLemma
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        liveTranscript = ""
        hasReportedFirstRecognitionResult = false
        isWordActive = true


        #if !targetEnvironment(simulator) && !os(macOS)
        guard let recognizer = resolveSpeechRecognizer(), recognizer.isAvailable else {
            isWordActive = false
            let error = SpeechCaptureError.recognizerUnavailable
            onError?(error)
            throw error
        }

        startRecognitionRequest(
            targetLemma: currentTargetLemma,
            contextualPhrases: contextualPhrases,
            sessionToken: token
        )
        #endif
    }

    public func startListening(targetLemma: String, contextualPhrases: [String]) async throws {
        guard isSessionActive else {
            throw SpeechCaptureError.cancelled
        }

        wordGeneration &+= 1
        let generation = wordGeneration
        activeStartTask?.cancel()

        let task = Task { [weak self] in
            guard let self else { throw SpeechCaptureError.cancelled }
            try await self.performStartListening(
                targetLemma: targetLemma,
                contextualPhrases: contextualPhrases,
                generation: generation
            )
        }
        self.activeStartTask = task

        do {
            try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
            if self.wordGeneration == generation {
                self.activeStartTask = nil
            }
        } catch {
            if self.wordGeneration == generation {
                self.activeStartTask = nil
            }
            throw error
        }
    }

    private func performStartListening(
        targetLemma: String,
        contextualPhrases: [String],
        generation: UInt
    ) async throws {
        if let audioLifecycleTask {
            await audioLifecycleTask.value
        }

        var acquiredLease: AudioSessionLease?
        do {
            try await checkPermissions(generation: generation)
            acquiredLease = try await acquireDuplexLease(generation: generation)
            try ensureCurrentAndActive(generation: generation)
            try await prepareAndResumeAudio(relay: bufferRelay)
            try ensureCurrentAndActive(generation: generation)

            let oldLease = self.activeLease
            self.activeLease = acquiredLease
            if let oldLease, oldLease != acquiredLease {
                await audioSessionCoordinator?.release(oldLease)
            }

            try ensureCurrentAndActive(generation: generation)

            isEngineReady = true
            isListeningPaused = false
            bufferRelay.unmute()

            try activateWordCapture(targetLemma: targetLemma, contextualPhrases: contextualPhrases)
        } catch {
            isEngineReady = false
            bufferRelay.mute()
            let lease = self.activeLease ?? acquiredLease
            let extraLease = (acquiredLease != lease) ? acquiredLease : nil
            self.activeLease = nil
            let coordinator = audioSessionCoordinator
            enqueueAudioTransition { controller in
                await controller.teardown()
                if let lease {
                    await coordinator?.release(lease)
                }
                if let extraLease {
                    await coordinator?.release(extraLease)
                }
            }
            throw error
        }
    }

    // MARK: - Word Lifecycle

    public func beginWord(targetLemma: String, contextualPhrases: [String]) {
        LessonPerformanceDiagnostics.event(
            "SpeechWordBegin",
            detail: "engineReady=\(isEngineReady) sessionActive=\(isSessionActive)"
        )
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
            onError?(SpeechCaptureError.recognizerUnavailable)
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
