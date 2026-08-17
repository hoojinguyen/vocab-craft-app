import AVFoundation
import Foundation
import Speech

public protocol ContinuousReflexSpeechProtocol: AnyObject, Sendable {
    var isSessionActive: Bool { get }
    var currentTranscript: String { get }
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

    public init() {}

    public func startSession() {
        isSessionActive = true
    }

    public func stopSession() {
        isSessionActive = false
        currentTranscript = ""
        currentTargetLemma = ""
    }

    public func setTargetWord(lemma: String, contextualPhrases: [String]) {
        self.currentTargetLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.contextualPhrases = contextualPhrases
        self.currentTranscript = ""
    }

    public func resetBuffer() {
        self.currentTranscript = ""
    }

    public func simulateTranscript(_ text: String) {
        self.currentTranscript = text
        let clean = text.lowercased()
        if !currentTargetLemma.isEmpty && (clean == currentTargetLemma || clean.contains(currentTargetLemma)) {
            onMatchDetected?(currentTargetLemma)
        }
    }
}

public final class ContinuousReflexSpeechService: ContinuousReflexSpeechProtocol, @unchecked Sendable {
    public private(set) var isSessionActive: Bool = false
    public private(set) var currentTranscript: String = ""

    private var currentTargetLemma: String = ""
    private var contextualPhrases: [String] = []

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
    }

    public func setTargetWord(lemma: String, contextualPhrases: [String]) {
        self.currentTargetLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.contextualPhrases = contextualPhrases
        self.currentTranscript = ""
    }

    public func resetBuffer() {
        self.currentTranscript = ""
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
        let clean = spoken.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        if clean == currentTargetLemma || clean.contains(currentTargetLemma) {
            onMatchDetected?(currentTargetLemma)
        }
    }
}
