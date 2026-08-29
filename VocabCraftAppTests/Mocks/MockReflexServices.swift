import Foundation
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

final class MockFetchVocabularyUseCase: FetchVocabularyUseCaseProtocol {
    func executeFetchWords(limit: Int) async throws -> [Word] { [] }
    func executeSearch(query: String) async throws -> [Word] { [] }
    func executeFetchDrills(cefrLevel: String) async throws -> [ReflexDrillItem] { [] }
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
