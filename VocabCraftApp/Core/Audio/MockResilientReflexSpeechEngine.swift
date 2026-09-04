import Foundation

@MainActor
public final class MockResilientReflexSpeechEngine: ReflexSpeechEngineProtocol {
    public var isSessionActive: Bool = false
    public var isWordActive: Bool = false
    public var isListeningPaused: Bool = false
    public var liveTranscript: String = ""
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    // Test tracking
    public var startSessionCallCount: Int = 0
    public var stopSessionCallCount: Int = 0
    public var pauseListeningCallCount: Int = 0
    public var resumeListeningCallCount: Int = 0
    public var prepareEngineIfNeededCallCount: Int = 0
    public var beginWordCallCount: Int = 0
    public var endWordCallCount: Int = 0
    public var lastTargetLemma: String = ""
    public var lastContextualPhrases: [String] = []
    public var lastStartSessionWasLazy: Bool = false

    public init() {}

    public func startSession(contextualPhrases: [String], lazy: Bool = false) {
        isSessionActive = true
        isListeningPaused = false
        startSessionCallCount += 1
        lastStartSessionWasLazy = lazy
    }

    public func startSession(contextualPhrases: [String]) {
        startSession(contextualPhrases: contextualPhrases, lazy: false)
    }

    public func stopSession() {
        isSessionActive = false
        isWordActive = false
        isListeningPaused = false
        liveTranscript = ""
        stopSessionCallCount += 1
    }

    public func pauseListening() {
        isListeningPaused = true
        pauseListeningCallCount += 1
        endWord()
    }

    public func resumeListening() {
        isListeningPaused = false
        resumeListeningCallCount += 1
    }

    public func prepareEngineIfNeeded() {
        prepareEngineIfNeededCallCount += 1
    }

    public func beginWord(targetLemma: String, contextualPhrases: [String]) {
        lastTargetLemma = targetLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        lastContextualPhrases = contextualPhrases
        isWordActive = true
        liveTranscript = ""
        beginWordCallCount += 1
    }

    public func endWord() {
        isWordActive = false
        endWordCallCount += 1
    }

    public func finalizeWordAudio() {}

    // Test helpers
    public func simulateTranscript(_ text: String) {
        guard isWordActive else { return }
        liveTranscript = text
        onTranscriptUpdate?(text)
    }

    public func simulateMatch(_ lemma: String) {
        guard isWordActive else { return }
        onMatchDetected?(lemma)
    }

    public func simulateError(_ error: Error) {
        onError?(error)
    }
}
