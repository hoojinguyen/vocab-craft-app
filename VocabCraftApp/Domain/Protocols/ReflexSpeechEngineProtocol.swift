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
    func beginWord(targetLemma: String, contextualPhrases: [String])
    func endWord()
}
