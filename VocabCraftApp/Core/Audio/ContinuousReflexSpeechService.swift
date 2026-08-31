import AVFoundation
import Foundation
import Speech
import SpeechKit

public enum ReflexSpeechMatcher {
    /// Evaluates whether spoken text contains the target lemma or an acceptable phonetic / accent / inflection reflex match.
    public static func isReflexMatch(
        spokenText: String,
        targetLemma: String,
        toleranceThreshold: Double? = nil
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
                passThreshold: toleranceThreshold ?? 0.70
            )
            return eval.isPassed
        }

        let targetLen = normalizedTarget.count

        // Single-word lemma evaluation with Tiered Length Matching
        for token in tokens {
            // 1. Exact normalized token match
            if token == normalizedTarget {
                return true
            }

            // 2. Stemming / Inflection / Prefix match (e.g. "walk" vs "walking", "hesitate" vs "hesitating")
            if targetLen >= 4 {
                // Token is an extended form of the target (e.g. target "walk" -> spoken "walked", "walking")
                if token.hasPrefix(normalizedTarget) {
                    let suffix = String(token.dropFirst(targetLen))
                    let allowedExtendedSuffixes: Set<String> = [
                        "ing", "ed", "es", "s", "er", "able", "d", "y", "ment", "tion", "ion", "ation"
                    ]
                    if allowedExtendedSuffixes.contains(suffix) {
                        return true
                    }
                }

                // Handle English vowel drop (e.g. "hesitate" -> stem "hesitat" vs "hesitating", "hesitation")
                // Suffix must be a non-empty recognized verbal/nominal inflection suffix
                if normalizedTarget.hasSuffix("e") && targetLen >= 5 {
                    let stemWithoutE = String(normalizedTarget.dropLast())
                    if token.hasPrefix(stemWithoutE) {
                        let suffix = String(token.dropFirst(stemWithoutE.count))
                        let allowedInflections: Set<String> = [
                            "ing", "ed", "es", "s", "er", "or", "tion", "ion", "ation", "ment"
                        ]
                        if allowedInflections.contains(suffix) {
                            return true
                        }
                    }
                }
            }

            // 3. Tiered fuzzy phonetic & accent tolerance
            if targetLen <= 4 || token.count <= 4 {
                // Short words or short spoken tokens (<= 4 letters): STRICT exact/stem only.
                // Do NOT apply loose Levenshtein distance to prevent ambient noise (breathing, whispers)
                // or distinct 4-letter lemmas (e.g. "past" vs "paste", "cast" vs "caste") from matching.
                continue
            } else if targetLen <= 7 {
                // Medium words (5-7 letters): Require high similarity (>= 0.80 default)
                let effectiveThreshold = toleranceThreshold ?? 0.80
                let ratio = FuzzySpeechMatcher.similarityRatio(token, normalizedTarget)
                if ratio >= effectiveThreshold {
                    return true
                }
            } else {
                // Long words (>= 8 letters): Allow accent tolerance (>= 0.70 default to tolerate common suffix/unstressed vowel variance like -ence vs -ant)
                let effectiveThreshold = toleranceThreshold ?? 0.70
                let ratio = FuzzySpeechMatcher.similarityRatio(token, normalizedTarget)
                if ratio >= effectiveThreshold {
                    return true
                }
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
    private var routeChangeObserver: (any NSObjectProtocol)?

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

    public init() {
        #if os(iOS)
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            self?.handleRouteChange(notification: notification)
        }
        #endif
    }

    deinit {
        #if os(iOS)
        if let observer = routeChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
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
}

// MARK: - Audio Stream & Speech Recognition Pipeline

extension ContinuousReflexSpeechService {
    private func startAudioStream() {
        #if targetEnvironment(simulator) || os(macOS)
        startSimulatorAudioStream()
        #else
        startDeviceAudioStream()
        #endif
    }

    #if targetEnvironment(simulator) || os(macOS)
    private func startSimulatorAudioStream() {
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
    }
    #else
    private func startDeviceAudioStream() {
        do {
            #if os(iOS)
            try configureAudioSession()
            #endif

            let engine = AVAudioEngine()
            let request = buildRecognitionRequest()

            lock.lock()
            self.audioEngine = engine
            self.recognitionRequest = request
            let sessionId = currentSessionId
            lock.unlock()

            try setupAudioEngineTap(engine: engine, request: request)

            engine.prepare()
            try engine.start()

            let task = makeContinuousRecognitionTask(request: request, sessionId: sessionId)

            lock.lock()
            self.recognitionTask = task
            lock.unlock()
        } catch {
            dispatchError(error)
        }
    }

    #if os(iOS)
    private func configureAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP, .allowBluetoothA2DP])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    #endif

    private func buildRecognitionRequest() -> SFSpeechAudioBufferRecognitionRequest {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation

        lock.lock()
        if !sessionContextualPhrases.isEmpty {
            request.contextualStrings = Array(Set(sessionContextualPhrases.filter { !$0.isEmpty }))
        }
        lock.unlock()

        #if os(iOS)
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        #endif
        return request
    }

    private func setupAudioEngineTap(
        engine: AVAudioEngine,
        request: SFSpeechAudioBufferRecognitionRequest
    ) throws {
        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            throw NSError(
                domain: "ContinuousReflexSpeech",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invalid microphone sample rate or format."]
            )
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
    }

    private func makeContinuousRecognitionTask(
        request: SFSpeechAudioBufferRecognitionRequest,
        sessionId: UUID
    ) -> SFSpeechRecognitionTask? {
        speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
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
    }
    #endif

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

    #if os(iOS)
    private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        lock.lock()
        guard _isSessionActive else {
            lock.unlock()
            return
        }
        lock.unlock()

        switch reason {
        case .newDeviceAvailable, .oldDeviceUnavailable, .categoryChange, .routeConfigurationChange:
            #if !targetEnvironment(simulator) && !os(macOS)
            restartAudioStream()
            #endif
        default:
            break
        }
    }
    #endif

    #if !targetEnvironment(simulator) && !os(macOS)
    private func restartAudioStream() {
        lock.lock()
        guard _isSessionActive else {
            lock.unlock()
            return
        }

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
            engine.inputNode.removeTap(onBus: 0)
        }

        startAudioStream()
    }
    #endif
}
