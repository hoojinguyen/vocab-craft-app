import AVFoundation
import Foundation
import Speech

public protocol ContinuousReflexSpeechProtocol: AnyObject, Sendable {
    var isSessionActive: Bool { get }
    var currentTranscript: String { get }
    var onMatchDetected: ((String) -> Void)? { get set }
    var onTranscriptUpdate: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func startSession()
    func stopSession()
    func setTargetWord(lemma: String, contextualPhrases: [String])
    func resetBuffer()
}

public final class MockContinuousReflexSpeechService: ContinuousReflexSpeechProtocol, @unchecked Sendable {
    public var isSessionActive: Bool = false
    public var currentTranscript: String = ""
    public var currentTargetLemma: String = ""
    public var contextualPhrases: [String] = []
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    private var transcriptOffset: Int = 0

    public init() {}

    public func startSession() {
        isSessionActive = true
        transcriptOffset = 0
    }

    public func stopSession() {
        isSessionActive = false
        currentTranscript = ""
        currentTargetLemma = ""
        transcriptOffset = 0
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
        self.currentTranscript = text
        onTranscriptUpdate?(text)

        let newSpoken = extractNewlySpoken(from: text, offset: transcriptOffset)
        if !currentTargetLemma.isEmpty && containsWordBoundaryMatch(text: newSpoken, lemma: currentTargetLemma) {
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

    private func containsWordBoundaryMatch(text: String, lemma: String) -> Bool {
        guard !lemma.isEmpty, !text.isEmpty else { return false }
        let escapedLemma = NSRegularExpression.escapedPattern(for: lemma)
        let pattern = "\\b\(escapedLemma)\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return false
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}

public final class ContinuousReflexSpeechService: ContinuousReflexSpeechProtocol, @unchecked Sendable {
    public private(set) var isSessionActive: Bool = false
    public private(set) var currentTranscript: String = ""

    private var currentTargetLemma: String = ""
    private var contextualPhrases: [String] = []
    private var transcriptOffset: Int = 0

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    public init() {}

    public func startSession() {
        guard !isSessionActive else { return }
        isSessionActive = true
        transcriptOffset = 0
        startAudioStream()
    }

    public func stopSession() {
        isSessionActive = false
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
        transcriptOffset = 0
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
        let engine = AVAudioEngine()
        self.audioEngine = engine
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .confirmation
        self.recognitionRequest = request

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        do {
            #if os(iOS)
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            #endif
            try engine.start()
            self.recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
                guard let self = self else { return }
                if let error = error {
                    self.onError?(error)
                    return
                }
                if let result = result {
                    let spoken = result.bestTranscription.formattedString
                    self.currentTranscript = spoken
                    self.onTranscriptUpdate?(spoken)
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
        if containsWordBoundaryMatch(text: newSpoken, lemma: currentTargetLemma) {
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

    private func containsWordBoundaryMatch(text: String, lemma: String) -> Bool {
        guard !lemma.isEmpty, !text.isEmpty else { return false }
        let escapedLemma = NSRegularExpression.escapedPattern(for: lemma)
        let pattern = "\\b\(escapedLemma)\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return false
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }
}
