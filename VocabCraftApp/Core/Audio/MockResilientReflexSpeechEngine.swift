import Foundation

@MainActor
public final class MockResilientReflexSpeechEngine: ReflexSpeechEngineProtocol {
    public var isSessionActive: Bool = false
    public var isWordActive: Bool = false
    public var liveTranscript: String = ""
    public var onMatchDetected: ((String) -> Void)?
    public var onTranscriptUpdate: ((String) -> Void)?
    public var onError: ((Error) -> Void)?

    // Test tracking
    public var startSessionCallCount: Int = 0
    public var stopSessionCallCount: Int = 0
    public var beginWordCallCount: Int = 0
    public var endWordCallCount: Int = 0
    public var lastTargetLemma: String = ""
    public var lastContextualPhrases: [String] = []

    public init() {}

    public func startSession(contextualPhrases: [String]) {
        isSessionActive = true
        startSessionCallCount += 1
    }

    public func stopSession() {
        isSessionActive = false
        isWordActive = false
        liveTranscript = ""
        stopSessionCallCount += 1
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
