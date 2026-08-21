import Foundation
import Observation

/// ViewModel managing the interactive quiz challenge and completion evaluation for a subtopic stage.
@MainActor
@Observable
public final class StageChallengeViewModel {
    public let stage: SubTopicStage
    public private(set) var questions: [WordChallengeQuestion] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var results: [WordChallengeResult] = []
    public private(set) var lastAnswerCorrect: Bool = false
    public private(set) var isCompleted: Bool = false
    public private(set) var summary: StageCompletionSummary?

    private let completeUseCase: CompleteStageChallengeUseCaseProtocol
    private let ttsService: TextToSpeechProtocol?

    public var currentQuestion: WordChallengeQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    public init(
        stage: SubTopicStage,
        completeUseCase: CompleteStageChallengeUseCaseProtocol,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.stage = stage
        self.completeUseCase = completeUseCase
        self.ttsService = ttsService
        self.questions = StageChallengeViewModel.generateQuestions(from: stage.words)
    }

    public static func generateQuestions(from words: [TopicWord]) -> [WordChallengeQuestion] {
        words.map { word in
            let allVietnamese = words.map(\.vietnamese)
            let distractors = allVietnamese.filter { $0 != word.vietnamese }.shuffled()
            let wrongOptions = Array(distractors.prefix(3))
            var options = wrongOptions + [word.vietnamese]
            options.shuffle()
            return WordChallengeQuestion(
                wordId: Int64(word.id) ?? 0,
                prompt: word.english,
                hintPhonetic: word.phonetic,
                correctAnswer: word.vietnamese,
                options: options,
                exampleSentence: word.example
            )
        }
    }

    public func submitAnswer(_ answer: String, timeTakenMs: Int = 1000) {
        guard let question = currentQuestion else { return }
        let isCorrect = (answer == question.correctAnswer)
        lastAnswerCorrect = isCorrect
        results.append(WordChallengeResult(wordId: question.wordId, isCorrect: isCorrect, timeTakenMs: timeTakenMs))
        if currentIndex + 1 < questions.count {
            currentIndex += 1
        }
    }

    public func completeStage() async {
        do {
            summary = try await completeUseCase.execute(stageId: stage.id, deckId: stage.deckId, results: results)
            isCompleted = true
        } catch {
            // handle error
        }
    }

    public func playAudio() {
        guard let question = currentQuestion else { return }
        ttsService?.speak(text: question.prompt)
    }
}
