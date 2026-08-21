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
    public private(set) var selectedAnswer: String? = nil
    public private(set) var isAnswerSubmitted: Bool = false
    public private(set) var isCompleted: Bool = false
    public private(set) var summary: StageCompletionSummary?
    public private(set) var streakCount: Int = 0

    private let completeUseCase: CompleteStageChallengeUseCaseProtocol
    private let ttsService: TextToSpeechProtocol?

    public var currentQuestion: WordChallengeQuestion? {
        guard currentIndex >= 0 && currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    public var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentIndex) / Double(questions.count)
    }

    public var isLastQuestion: Bool {
        guard !questions.isEmpty else { return true }
        return currentIndex == questions.count - 1
    }

    public var correctCount: Int {
        results.filter(\.isCorrect).count
    }

    public var totalCount: Int {
        questions.count
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
            let numericId = Int64(word.id.filter(\.isNumber)) ?? (Int64(word.id) ?? 0)
            let allVietnamese = words.map(\.vietnamese)
            let distractors = allVietnamese.filter { $0 != word.vietnamese }.shuffled()
            let wrongOptions = Array(distractors.prefix(3))
            var options = wrongOptions + [word.vietnamese]
            options.shuffle()
            return WordChallengeQuestion(
                wordId: numericId,
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
        selectedAnswer = answer
        isAnswerSubmitted = true
        let isCorrect = (answer == question.correctAnswer)
        lastAnswerCorrect = isCorrect
        streakCount = isCorrect ? streakCount + 1 : 0
        results.append(WordChallengeResult(wordId: question.wordId, isCorrect: isCorrect, timeTakenMs: timeTakenMs))
    }

    public func nextQuestion() {
        guard currentIndex + 1 < questions.count else { return }
        currentIndex += 1
        selectedAnswer = nil
        isAnswerSubmitted = false
        lastAnswerCorrect = false
    }

    public func completeStage() async {
        do {
            summary = try await completeUseCase.execute(stageId: stage.id, deckId: stage.deckId, results: results)
            isCompleted = true
        } catch {
            let total = results.count
            let correct = results.filter(\.isCorrect).count
            let weakWordIds = results.filter { !$0.isCorrect }.map(\.wordId)
            summary = StageCompletionSummary(
                stageId: stage.id,
                totalQuestions: total,
                correctCount: correct,
                xpEarned: correct * 10,
                weakWordIds: weakWordIds
            )
            isCompleted = true
        }
    }

    public func restartQuiz() {
        currentIndex = 0
        results = []
        lastAnswerCorrect = false
        selectedAnswer = nil
        isAnswerSubmitted = false
        isCompleted = false
        summary = nil
        streakCount = 0
        questions = StageChallengeViewModel.generateQuestions(from: stage.words)
    }

    public func playAudio() {
        guard let question = currentQuestion else { return }
        ttsService?.speak(text: question.prompt)
    }

    public func playWordAudio(text: String) {
        ttsService?.speak(text: text)
    }
}
