import Foundation
import Observation

/// ViewModel managing a focused smart review session for weak words needing reinforcement.
@MainActor
@Observable
public final class SmartReviewViewModel {
    public private(set) var weakWords: [PersonalWord]
    public private(set) var currentIndex: Int = 0
    public private(set) var isCompleted: Bool = false
    public private(set) var isRevealed: Bool = false

    private let reviewUseCase: ReviewWeakWordsUseCaseProtocol
    private let ttsService: TextToSpeechProtocol?

    public var currentWord: PersonalWord? {
        guard currentIndex >= 0 && currentIndex < weakWords.count else { return nil }
        return weakWords[currentIndex]
    }

    public init(
        weakWords: [PersonalWord] = [],
        reviewUseCase: ReviewWeakWordsUseCaseProtocol,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.weakWords = weakWords
        self.reviewUseCase = reviewUseCase
        self.ttsService = ttsService
    }

    public func loadWeakWords() async {
        if weakWords.isEmpty {
            do {
                weakWords = try await reviewUseCase.fetchWeakWords()
            } catch {
                weakWords = []
            }
        }
    }

    public func revealDefinition() {
        isRevealed = true
    }

    public func markCurrentReviewed(isCorrect: Bool) async {
        guard let current = currentWord else { return }
        try? await reviewUseCase.markWordReviewed(wordId: current.id, isCorrect: isCorrect)
        isRevealed = false
        if currentIndex + 1 < weakWords.count {
            currentIndex += 1
        } else {
            isCompleted = true
        }
    }

    public func playAudio() {
        guard let current = currentWord else { return }
        ttsService?.speak(text: current.lemma)
    }
}
