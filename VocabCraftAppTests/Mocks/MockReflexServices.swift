import Foundation
import SpeechKit
@testable import VocabCraftApp

final class MockSpeechRecognitionService: SpeechRecognitionProtocol {
    var isListening: Bool = false
    var recognizedText: String = ""
    var onResultCallback: ((String) -> Void)?
    var onErrorCallback: ((Error) -> Void)?

    func startListening(onResult: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
        self.isListening = true
        self.onResultCallback = onResult
        self.onErrorCallback = onError
    }

    func stopListening() {
        self.isListening = false
    }

    func simulateResult(_ text: String) {
        self.recognizedText = text
        onResultCallback?(text)
    }

    func simulateError(_ error: Error) {
        onErrorCallback?(error)
    }
}

final class MockSoundEffectService: SoundEffectServiceProtocol, @unchecked Sendable {
    var playSuccessChimeCallCount: Int = 0
    var playIncorrectChimeCallCount: Int = 0

    var successChimePlayed: Bool {
        playSuccessChimeCallCount > 0
    }

    var incorrectChimePlayed: Bool {
        playIncorrectChimeCallCount > 0
    }

    func playSuccessChime() {
        playSuccessChimeCallCount += 1
    }

    func playIncorrectChime() {
        playIncorrectChimeCallCount += 1
    }
}

final class MockTextToSpeechService: TextToSpeechProtocol {
    var isSpeaking: Bool = false
    var lastSpokenText: String?
    var lastSpokenRate: Float?
    var lastSpokenLocale: String?
    var speakCallCount: Int = 0
    var speakAsyncCallCount: Int = 0
    var onSpeakAsync: ((String, Float, String) async -> Void)?

    func speak(text: String, rate: Float, locale: String) {
        speakCallCount += 1
        isSpeaking = true
        lastSpokenText = text
        lastSpokenRate = rate
        lastSpokenLocale = locale
    }

    func speakAsync(text: String, rate: Float, locale: String) async {
        speakAsyncCallCount += 1
        isSpeaking = true
        lastSpokenText = text
        lastSpokenRate = rate
        lastSpokenLocale = locale
        if let onSpeakAsync = onSpeakAsync {
            await onSpeakAsync(text, rate, locale)
        }
        isSpeaking = false
    }

    func stop() {
        isSpeaking = false
    }
}

final class MockEvaluateSRSUseCase: EvaluateSRSUseCaseProtocol {
    func evaluateResponse(currentMastery: Int, easeFactor: Double, isCorrect: Bool, responseTimeMs: Int) -> SRSResult {
        SRSResult(
            nextMastery: isCorrect ? currentMastery + 1 : max(0, currentMastery - 1),
            easeFactor: isCorrect ? easeFactor + 0.1 : max(1.3, easeFactor - 0.2),
            intervalDays: isCorrect ? max(1, currentMastery + 1) : 1
        )
    }
    func recordReview(wordId: Int64, isCorrect: Bool, responseTimeMs: Int) async throws -> SRSResult {
        evaluateResponse(currentMastery: 0, easeFactor: 2.5, isCorrect: isCorrect, responseTimeMs: responseTimeMs)
    }
}

final class MockSpeechAssessmentService: SpeechAssessmentProtocol {
    var isListening: Bool = false
    var currentEvaluation: SpeechEvaluationResult?
    var targetSentence: String?
    var toleranceThreshold: Double?
    var contextualPhrases: [String] = []
    var onProgressHandler: ((SpeechEvaluationResult) -> Void)?
    var onCompletionHandler: ((SpeechEvaluationResult) -> Void)?
    var onErrorHandler: ((Error) -> Void)?

    func startAssessing(
        targetSentence: String,
        toleranceThreshold: Double,
        contextualPhrases: [String],
        onProgress: @escaping (SpeechEvaluationResult) -> Void,
        onCompletion: @escaping (SpeechEvaluationResult) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.isListening = true
        self.targetSentence = targetSentence
        self.toleranceThreshold = toleranceThreshold
        self.contextualPhrases = contextualPhrases
        self.onProgressHandler = onProgress
        self.onCompletionHandler = onCompletion
        self.onErrorHandler = onError
    }

    func stopAssessing() {
        self.isListening = false
    }

    func simulateProgress(_ result: SpeechEvaluationResult) {
        self.currentEvaluation = result
        onProgressHandler?(result)
    }

    func simulateCompletion(_ result: SpeechEvaluationResult) {
        self.currentEvaluation = result
        self.isListening = false
        onCompletionHandler?(result)
    }

    func simulateError(_ error: Error) {
        self.isListening = false
        onErrorHandler?(error)
    }
}

typealias MockSpeechAssessmentServiceForViewModel = MockSpeechAssessmentService

@MainActor
final class SuspendedMockReflexSpeechEngine: ReflexSpeechEngineProtocol {
    var isSessionActive: Bool = true
    var isWordActive: Bool = false
    var liveTranscript: String = ""
    var isListeningPaused: Bool = false
    var onMatchDetected: ((String) -> Void)?
    var onTranscriptUpdate: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    private(set) var prepareCallCount = 0
    private(set) var beginWordCallCount = 0
    private(set) var resumeListeningCallCount = 0
    private(set) var pauseListeningCallCount = 0
    private(set) var stopSessionCallCount = 0
    private var preparationContinuation: CheckedContinuation<Void, Error>?
    private var preparationStartWaiters: [CheckedContinuation<Void, Never>] = []
    private var isCompleted = false
    private var pendingError: Error?

    func startSession(contextualPhrases: [String]) { isSessionActive = true }
    func startSession(contextualPhrases: [String], lazy: Bool) { isSessionActive = true }
    func stopSession() { isSessionActive = false; stopSessionCallCount += 1 }
    func pauseListening() { isListeningPaused = true; pauseListeningCallCount += 1 }
    func resumeListening() { isListeningPaused = false; resumeListeningCallCount += 1 }

    func waitUntilPreparationStarts(expectedCount: Int = 1) async {
        guard prepareCallCount < expectedCount else { return }
        await withCheckedContinuation { continuation in
            preparationStartWaiters.append(continuation)
        }
    }

    func prepareEngineIfNeeded() async throws {
        prepareCallCount += 1
        for waiter in preparationStartWaiters {
            waiter.resume()
        }
        preparationStartWaiters.removeAll()

        if let pendingError {
            throw pendingError
        }
        if isCompleted {
            return
        }

        try await withCheckedThrowingContinuation { continuation in
            preparationContinuation = continuation
        }
    }

    func completePreparation() {
        isCompleted = true
        preparationContinuation?.resume()
        preparationContinuation = nil
    }

    func failPreparation(with error: Error) {
        pendingError = error
        preparationContinuation?.resume(throwing: error)
        preparationContinuation = nil
    }

    func beginWord(targetLemma: String, contextualPhrases: [String]) {
        beginWordCallCount += 1
        isWordActive = true
    }

    func endWord() {
        isWordActive = false
    }

    func finalizeWordAudio() {}
}
