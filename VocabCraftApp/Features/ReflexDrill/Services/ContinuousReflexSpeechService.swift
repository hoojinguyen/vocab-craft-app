import AVFoundation
import Foundation
import Speech

public protocol ContinuousReflexSpeechProtocol: AnyObject, Sendable {
    var isSessionActive: Bool { get }
    var isRecognitionMuted: Bool { get }
    var currentTranscript: String { get }
    var onMatchDetected: ((String) -> Void)? { get set }
    var onTranscriptUpdate: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func startSession(contextualPhrases: [String])
    func startSession()
    func stopSession()
    func pauseListening()
    func resumeListening()
    func setTargetWord(lemma: String, contextualPhrases: [String])
    func resetBuffer()
}

public extension ContinuousReflexSpeechProtocol {
    func startSession() {
        startSession(contextualPhrases: [])
    }
}

public enum ReflexSpeechMatcher {
    /// Evaluates whether spoken text contains the target lemma or an acceptable phonetic / accent / inflection reflex match.
    public static func isReflexMatch(
        spokenText: String,
        targetLemma: String,
        toleranceThreshold: Double = 0.70
    ) -> Bool {
        let normalizedTarget = StringNormalizer.normalize(targetLemma)
        guard !normalizedTarget.isEmpty, !spokenText.isEmpty else { return false }

        // Tokenize the newly spoken stream
        let tokens = StringNormalizer.tokenize(spokenText)
        guard !tokens.isEmpty else { return false }

        // Multi-word lemma check (e.g. phrasal verbs "give up", "look forward to")
        let targetTokens = StringNormalizer.tokenize(normalizedTarget)
        if targetTokens.count > 1 {
            let eval = FuzzySpeechMatcher.evaluate(
                spokenText: spokenText,
                targetSentence: normalizedTarget,
                passThreshold: toleranceThreshold
            )
            if eval.isPassed { return true }
        }

        // Single-word lemma evaluation (most common case in Reflex Blitz)
        for token in tokens {
            // 1. Exact normalized token match
            if token == normalizedTarget {
                return true
            }

            // 2. Stemming / Inflection / Prefix match (e.g. "hesitate" vs "hesitated" / "hesitating")
            if normalizedTarget.count >= 4 {
                if token.hasPrefix(normalizedTarget) {
                    return true
                }
                if token.count >= 4 && normalizedTarget.hasPrefix(token) {
                    return true
                }
            }

            // 3. Fuzzy phonetic & accent tolerance via Levenshtein similarity ratio
            let ratio = FuzzySpeechMatcher.similarityRatio(token, normalizedTarget)
            if ratio >= toleranceThreshold {
                return true
            }
        }

        return false
    }
}

public final class MockContinuousReflexSpeechService: ContinuousReflexSpeechProtocol, @unchecked Sendable {
    public var isSessionActive: Bool = false
    public var isRecognitionMuted: Bool = false
    public var currentTranscript: String = ""
    public var currentTargetLemma: String = ""
    public var contextualPhrases: [String] = []
    public var sessionContextualPhrases: [String] = []
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    private var transcriptOffset: Int = 0

    public init() {}

    public func startSession(contextualPhrases: [String]) {
        self.isSessionActive = true
        self.sessionContextualPhrases = contextualPhrases
        self.transcriptOffset = 0
    }

    public func startSession() {
        startSession(contextualPhrases: [])
    }

    public func stopSession() {
        isSessionActive = false
        isRecognitionMuted = false
        currentTranscript = ""
        currentTargetLemma = ""
        sessionContextualPhrases = []
        transcriptOffset = 0
    }

    public func pauseListening() {
        isRecognitionMuted = true
    }

    public func resumeListening() {
        isRecognitionMuted = false
    }

    public func setTargetWord(lemma: String, contextualPhrases: [String]) {
        self.currentTargetLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.contextualPhrases = contextualPhrases
        self.transcriptOffset = currentTranscript.count
    }

    public func resetBuffer() {
        self.currentTranscript = ""
        self.transcriptOffset = 0
    }

    public func simulateTranscript(_ text: String) {
        guard !isRecognitionMuted else { return }
        self.currentTranscript = text
        let newSpoken = extractNewlySpoken(from: text, offset: transcriptOffset)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        onTranscriptUpdate?(newSpoken)

        if !currentTargetLemma.isEmpty && ReflexSpeechMatcher.isReflexMatch(spokenText: newSpoken, targetLemma: currentTargetLemma) {
            onMatchDetected?(currentTargetLemma)
        }
    }

    private func extractNewlySpoken(from fullTranscript: String, offset: Int) -> String {
        guard fullTranscript.count >= offset else {
            return fullTranscript
        }
        let index = fullTranscript.index(fullTranscript.startIndex, offsetBy: offset, limitedBy: fullTranscript.endIndex) ?? fullTranscript.endIndex
        return String(fullTranscript[index...])
    }
}

public final class ContinuousReflexSpeechService: ContinuousReflexSpeechProtocol, @unchecked Sendable {
    public private(set) var isSessionActive: Bool = false
    public private(set) var isRecognitionMuted: Bool = false
    public private(set) var currentTranscript: String = ""

    private var currentTargetLemma: String = ""
    private var contextualPhrases: [String] = []
    private var sessionContextualPhrases: [String] = []
    private var transcriptOffset: Int = 0

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    public init() {}

    public func startSession(contextualPhrases: [String]) {
        guard !isSessionActive else { return }
        isSessionActive = true
        self.sessionContextualPhrases = contextualPhrases
        transcriptOffset = 0

        #if targetEnvironment(simulator)
        startAudioStream()
        #else
        requestAuthorization { [weak self] authorized in
            guard let self = self, self.isSessionActive else { return }
            if authorized {
                self.startAudioStream()
            } else {
                let error = NSError(domain: "ContinuousReflexSpeech", code: 401, userInfo: [NSLocalizedDescriptionKey: "Microphone or Speech Recognition permission not authorized."])
                self.onError?(error)
            }
        }
        #endif
    }

    public func startSession() {
        startSession(contextualPhrases: [])
    }

    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        #if targetEnvironment(simulator)
        completion(true)
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

    public func stopSession() {
        isSessionActive = false
        isRecognitionMuted = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        currentTranscript = ""
        currentTargetLemma = ""
        sessionContextualPhrases = []
        transcriptOffset = 0
    }

    public func pauseListening() {
        isRecognitionMuted = true
    }

    public func resumeListening() {
        isRecognitionMuted = false
    }

    public func setTargetWord(lemma: String, contextualPhrases: [String]) {
        self.currentTargetLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.contextualPhrases = contextualPhrases
        self.transcriptOffset = currentTranscript.count
    }

    public func resetBuffer() {
        self.transcriptOffset = currentTranscript.count
    }

    private func startAudioStream() {
        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            let engine = AVAudioEngine()
            self.audioEngine = engine
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.taskHint = .confirmation

            // Contextual biasing with session words and phrases for acoustic accuracy
            if !sessionContextualPhrases.isEmpty {
                request.contextualStrings = Array(Set(sessionContextualPhrases.filter { !$0.isEmpty }))
            }

            #if os(iOS)
            if #available(iOS 16.0, *) {
                request.addsPunctuation = false
            }
            #endif

            self.recognitionRequest = request

            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
                let error = NSError(domain: "ContinuousReflexSpeech", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid microphone sample rate or format."])
                self.onError?(error)
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self, !self.isRecognitionMuted else { return }
                self.recognitionRequest?.append(buffer)
            }

            try engine.start()
            self.recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code != 216 { // 216 = canceled on stop
                        self.onError?(error)
                    }
                    return
                }
                guard !self.isRecognitionMuted else { return }
                if let result = result {
                    let spoken = result.bestTranscription.formattedString
                    self.currentTranscript = spoken
                    let newSpoken = self.extractNewlySpoken(from: spoken, offset: self.transcriptOffset)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    self.onTranscriptUpdate?(newSpoken)
                    self.evaluateSpokenText(spoken)
                }
            }
        } catch {
            self.onError?(error)
        }
    }

    private func evaluateSpokenText(_ spoken: String) {
        guard !currentTargetLemma.isEmpty else { return }
        let newSpoken = extractNewlySpoken(from: spoken, offset: transcriptOffset)
        if ReflexSpeechMatcher.isReflexMatch(spokenText: newSpoken, targetLemma: currentTargetLemma) {
            onMatchDetected?(currentTargetLemma)
        }
    }

    private func extractNewlySpoken(from fullTranscript: String, offset: Int) -> String {
        guard fullTranscript.count >= offset else {
            return fullTranscript
        }
        let index = fullTranscript.index(fullTranscript.startIndex, offsetBy: offset, limitedBy: fullTranscript.endIndex) ?? fullTranscript.endIndex
        return String(fullTranscript[index...])
    }
}

