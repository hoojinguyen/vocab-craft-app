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
    private let lock = NSLock()

    private var _isSessionActive: Bool = false
    public var isSessionActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isSessionActive
    }

    private var _isRecognitionMuted: Bool = false
    public var isRecognitionMuted: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isRecognitionMuted
    }

    private var _currentTranscript: String = ""
    public var currentTranscript: String {
        lock.lock()
        defer { lock.unlock() }
        return _currentTranscript
    }

    private var currentTargetLemma: String = ""
    private var contextualPhrases: [String] = []
    private var sessionContextualPhrases: [String] = []
    private var transcriptOffset: Int = 0

    private var currentSessionId = UUID()
    private var simulationTask: Task<Void, Never>?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private var _onMatchDetected: ((String) -> Void)?
    public var onMatchDetected: ((String) -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _onMatchDetected
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _onMatchDetected = newValue
        }
    }

    private var _onTranscriptUpdate: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _onTranscriptUpdate
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _onTranscriptUpdate = newValue
        }
    }

    private var _onError: ((Error) -> Void)?
    public var onError: ((Error) -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _onError
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _onError = newValue
        }
    }

    public init() {}

    deinit {
        stopSession()
    }

    public func startSession(contextualPhrases: [String]) {
        lock.lock()
        guard !_isSessionActive else {
            lock.unlock()
            return
        }
        _isSessionActive = true
        _isRecognitionMuted = false
        self.sessionContextualPhrases = contextualPhrases
        self.transcriptOffset = 0
        self._currentTranscript = ""
        let sessionId = UUID()
        self.currentSessionId = sessionId
        lock.unlock()

        #if targetEnvironment(simulator) || os(macOS)
        startAudioStream()
        #else
        requestAuthorization { [weak self] authorized in
            guard let self = self else { return }
            self.lock.lock()
            guard self._isSessionActive, self.currentSessionId == sessionId else {
                self.lock.unlock()
                return
            }
            self.lock.unlock()

            if authorized {
                self.startAudioStream()
            } else {
                let error = NSError(
                    domain: "ContinuousReflexSpeech",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "Microphone or Speech Recognition permission not authorized."]
                )
                self.dispatchError(error)
            }
        }
        #endif
    }

    public func startSession() {
        startSession(contextualPhrases: [])
    }

    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        #if targetEnvironment(simulator) || os(macOS)
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

    public func stopSession() {
        lock.lock()
        _isSessionActive = false
        _isRecognitionMuted = false
        _currentTranscript = ""
        currentTargetLemma = ""
        sessionContextualPhrases = []
        contextualPhrases = []
        transcriptOffset = 0

        simulationTask?.cancel()
        simulationTask = nil

        let taskToCancel = recognitionTask
        recognitionTask = nil

        let requestToEnd = recognitionRequest
        recognitionRequest = nil

        let engineToStop = audioEngine
        audioEngine = nil
        lock.unlock()

        taskToCancel?.cancel()
        requestToEnd?.endAudio()

        if let engine = engineToStop {
            if engine.isRunning {
                engine.stop()
            }
            #if !targetEnvironment(simulator) && !os(macOS)
            engine.inputNode.removeTap(onBus: 0)
            #endif
        }

        #if os(iOS) && !targetEnvironment(simulator)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    public func pauseListening() {
        lock.lock()
        defer { lock.unlock() }
        _isRecognitionMuted = true
    }

    public func resumeListening() {
        lock.lock()
        defer { lock.unlock() }
        _isRecognitionMuted = false
    }

    public func setTargetWord(lemma: String, contextualPhrases: [String]) {
        lock.lock()
        defer { lock.unlock() }
        self.currentTargetLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.contextualPhrases = contextualPhrases
        self.transcriptOffset = _currentTranscript.count
    }

    public func resetBuffer() {
        lock.lock()
        defer { lock.unlock() }
        self.transcriptOffset = _currentTranscript.count
    }

    public func simulateTranscript(_ text: String) {
        lock.lock()
        guard _isSessionActive, !_isRecognitionMuted else {
            lock.unlock()
            return
        }
        _currentTranscript = text
        let offset = transcriptOffset
        let target = currentTargetLemma
        lock.unlock()

        let newSpoken = extractNewlySpoken(from: text, offset: offset)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        dispatchTranscriptUpdate(newSpoken)
        evaluateSpokenText(spoken: text, target: target, offset: offset)
    }

    private func checkSessionActive(sessionId: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isSessionActive && currentSessionId == sessionId
    }

    private func startAudioStream() {
        #if targetEnvironment(simulator) || os(macOS)
        lock.lock()
        simulationTask?.cancel()
        let sessionId = currentSessionId
        simulationTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self = self else { return }
                if !self.checkSessionActive(sessionId: sessionId) {
                    break
                }
            }
        }
        lock.unlock()
        #else
        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif

            let engine = AVAudioEngine()
            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            request.taskHint = .confirmation

            lock.lock()
            if !sessionContextualPhrases.isEmpty {
                request.contextualStrings = Array(Set(sessionContextualPhrases.filter { !$0.isEmpty }))
            }
            self.audioEngine = engine
            self.recognitionRequest = request
            let sessionId = currentSessionId
            lock.unlock()

            #if os(iOS)
            if #available(iOS 16.0, *) {
                request.addsPunctuation = false
            }
            #endif

            let inputNode = engine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
                let error = NSError(
                    domain: "ContinuousReflexSpeech",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid microphone sample rate or format."]
                )
                dispatchError(error)
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                guard let self = self else { return }
                self.lock.lock()
                let muted = self._isRecognitionMuted
                let req = self.recognitionRequest
                self.lock.unlock()
                guard !muted else { return }
                req?.append(buffer)
            }

            try engine.start()
            let task = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code != 216 { // 216 = canceled on stop
                        self.dispatchError(error)
                    }
                    return
                }

                self.lock.lock()
                guard self._isSessionActive, self.currentSessionId == sessionId, !self._isRecognitionMuted else {
                    self.lock.unlock()
                    return
                }

                if let result = result {
                    let spoken = result.bestTranscription.formattedString
                    self._currentTranscript = spoken
                    let offset = self.transcriptOffset
                    let target = self.currentTargetLemma
                    self.lock.unlock()

                    let newSpoken = self.extractNewlySpoken(from: spoken, offset: offset)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    self.dispatchTranscriptUpdate(newSpoken)
                    self.evaluateSpokenText(spoken: spoken, target: target, offset: offset)
                } else {
                    self.lock.unlock()
                }
            }

            lock.lock()
            self.recognitionTask = task
            lock.unlock()
        } catch {
            dispatchError(error)
        }
        #endif
    }

    private func evaluateSpokenText(spoken: String, target: String, offset: Int) {
        guard !target.isEmpty else { return }
        let newSpoken = extractNewlySpoken(from: spoken, offset: offset)
        if ReflexSpeechMatcher.isReflexMatch(spokenText: newSpoken, targetLemma: target) {
            dispatchMatchDetected(target)
        }
    }

    private func extractNewlySpoken(from fullTranscript: String, offset: Int) -> String {
        guard fullTranscript.count >= offset else {
            return fullTranscript
        }
        let index = fullTranscript.index(fullTranscript.startIndex, offsetBy: offset, limitedBy: fullTranscript.endIndex) ?? fullTranscript.endIndex
        return String(fullTranscript[index...])
    }

    private func dispatchTranscriptUpdate(_ transcript: String) {
        lock.lock()
        let callback = _onTranscriptUpdate
        lock.unlock()
        guard let callback = callback else { return }
        DispatchQueue.main.async {
            callback(transcript)
        }
    }

    private func dispatchMatchDetected(_ lemma: String) {
        lock.lock()
        let callback = _onMatchDetected
        lock.unlock()
        guard let callback = callback else { return }
        DispatchQueue.main.async {
            callback(lemma)
        }
    }

    private func dispatchError(_ error: Error) {
        lock.lock()
        let callback = _onError
        lock.unlock()
        guard let callback = callback else { return }
        DispatchQueue.main.async {
            callback(error)
        }
    }
}
