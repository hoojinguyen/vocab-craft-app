import Foundation

@MainActor
public protocol ReflexSpeechEngineProtocol: AnyObject {
    var isSessionActive: Bool { get }
    var isWordActive: Bool { get }
    var liveTranscript: String { get }
    var onMatchDetected: ((String) -> Void)? { get set }
    var onTranscriptUpdate: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }

    func startSession(contextualPhrases: [String])
    func stopSession()
    func pauseListening()
    func resumeListening()
    func prepareEngineIfNeeded()
    func beginWord(targetLemma: String, contextualPhrases: [String])
    func endWord()
    /// Signal end of audio input without cancelling the recognition task.
    /// Allows in-flight audio buffers to be processed before full teardown.
    func finalizeWordAudio()
}

public extension ReflexSpeechEngineProtocol {
    func pauseListening() {}
    func resumeListening() {}
    func prepareEngineIfNeeded() {}
}
