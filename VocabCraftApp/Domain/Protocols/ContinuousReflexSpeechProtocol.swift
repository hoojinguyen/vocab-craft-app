import Foundation

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
