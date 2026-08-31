import AVFoundation
import Foundation
import Observation
import Speech
import SpeechKit

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
        let requestToEnd = activeRequest
        activeRequest = nil
        isMuted = true
        lock.unlock()

        requestToEnd?.endAudio()
    }

    public func append(_ buffer: AVAudioPCMBuffer) {
        lock.lock()
        guard !isMuted, let request = activeRequest else {
            lock.unlock()
            return
        }
        lock.unlock()
        request.append(buffer)
    }
}

@MainActor
@Observable
public final class ResilientReflexSpeechEngine: ReflexSpeechEngineProtocol {
    // MARK: - Observable State
    public private(set) var isSessionActive: Bool = false
    public private(set) var isWordActive: Bool = false
    public private(set) var liveTranscript: String = ""

    // MARK: - Callbacks
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    // MARK: - Engine layer (session-scoped)
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var sessionContextualPhrases: [String] = []
    private var sessionStartTime: Date?
    private var needsEngineRenew: Bool = false
    private let bufferRelay = AudioBufferRelay()

    // MARK: - Request layer (word-scoped)
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var activeTask: SFSpeechRecognitionTask?
    private var currentTargetLemma: String = ""
    private var currentWordSessionToken: UUID = UUID()

    // MARK: - Throttle (nonisolated for real-time callback)
    private let throttleLock = NSLock()
    private var lastDispatchTime: CFAbsoluteTime = 0
    /// Minimum interval between MainActor dispatches for partial results (seconds)
    private let throttleInterval: CFAbsoluteTime = 0.15

    public init() {}

    deinit {
        // Clean up is handled by stopSession
    }

    // MARK: - Session Lifecycle

    public func startSession(contextualPhrases: [String]) {
        guard !isSessionActive else { return }
        self.sessionContextualPhrases = contextualPhrases
        self.sessionStartTime = Date()
        self.needsEngineRenew = false
        self.isSessionActive = true

        #if targetEnvironment(simulator) || os(macOS)
        // Simulator: no real audio engine
        #else
        requestAuthorizationAndStartEngine()
        #endif
    }

    public func stopSession() {
        endWord()
        teardownEngine()
        isSessionActive = false
        sessionContextualPhrases = []
        sessionStartTime = nil
        needsEngineRenew = false
    }

    // MARK: - Word Lifecycle

    public func beginWord(targetLemma: String, contextualPhrases: [String]) {
        // End previous word if still active
        if isWordActive {
            endWord()
        }

        // Proactive engine renewal if near 60s limit
        if needsEngineRenew {
            renewEngine()
        }

        let token = UUID()
        currentWordSessionToken = token
        currentTargetLemma = targetLemma
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        liveTranscript = ""
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

        // Check if engine needs renewal for next word
        if let start = sessionStartTime,
           Date().timeIntervalSince(start) > 50 {
            needsEngineRenew = true
        }
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
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self, self.isSessionActive else { return }
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
        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(
                .playAndRecord,
                mode: .voiceChat,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP, .duckOthers]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

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
            self.sessionStartTime = Date()
        } catch {
            onError?(error)
        }
    }
    #endif

    private func teardownEngine() {
        #if !targetEnvironment(simulator) && !os(macOS)
        bufferRelay.detachAndEnd()
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
        #endif
    }

    private func renewEngine() {
        #if !targetEnvironment(simulator) && !os(macOS)
        teardownEngine()
        setupAndStartEngine()
        #endif
        needsEngineRenew = false
        sessionStartTime = Date()
    }
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
