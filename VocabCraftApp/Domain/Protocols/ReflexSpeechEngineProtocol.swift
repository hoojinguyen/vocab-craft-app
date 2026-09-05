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
    func startSession(contextualPhrases: [String], lazy: Bool)
    func stopSession()
    func pauseListening()
    func resumeListening()
    func prepareEngineIfNeeded() async throws
    func startListening(targetLemma: String, contextualPhrases: [String]) async throws
    @available(*, deprecated, message: "Use startListening(targetLemma:contextualPhrases:) instead")
    func beginWord(targetLemma: String, contextualPhrases: [String])
    func endWord()
    /// Signal end of audio input without cancelling the recognition task.
    /// Allows in-flight audio buffers to be processed before full teardown.
    func finalizeWordAudio()
    var isListeningPaused: Bool { get }
}

public extension ReflexSpeechEngineProtocol {
    func startSession(contextualPhrases: [String], lazy: Bool) {
        startSession(contextualPhrases: contextualPhrases)
    }
    func pauseListening() {}
    func resumeListening() {}
    func prepareEngineIfNeeded() async throws {}
    var isListeningPaused: Bool { false }
}
