import AVFoundation
import Foundation
import Observation
import Speech
import SpeechKit

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

    // MARK: - Request layer (word-scoped)
    private var activeRequest: SFSpeechAudioBufferRecognitionRequest?
    private var activeTask: SFSpeechRecognitionTask?
    private var currentTargetLemma: String = ""
    private var currentWordSessionToken: UUID = UUID()

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

        activeRequest?.endAudio()
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
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP]
            )
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0 else {
                throw NSError(
                    domain: "ResilientReflexSpeech",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid microphone format."]
                )
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                // Forward buffer to active request (nil-safe: discarded when no word active)
                self?.activeRequest?.append(buffer)
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

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation

        var biasedPhrases = sessionContextualPhrases + contextualPhrases
        if !biasedPhrases.contains(targetLemma) {
            biasedPhrases.append(targetLemma)
        }
        request.contextualStrings = Array(Set(biasedPhrases.filter { !$0.isEmpty }))

        #if os(iOS)
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        #endif

        self.activeRequest = request

        let task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self,
                      self.isWordActive,
                      self.currentWordSessionToken == sessionToken else { return }

                if let error = error {
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
                    return
                }

                guard let result else { return }
                let spoken = result.bestTranscription.formattedString
                self.liveTranscript = spoken
                self.onTranscriptUpdate?(spoken)

                // Evaluate match
                if ReflexSpeechMatcher.isReflexMatch(
                    spokenText: spoken,
                    targetLemma: targetLemma
                ) {
                    self.onMatchDetected?(targetLemma)
                }
            }
        }

        self.activeTask = task
    }
    #endif
}
