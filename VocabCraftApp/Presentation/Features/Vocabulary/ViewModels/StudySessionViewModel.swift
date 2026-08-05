import Foundation
import Observation

@MainActor
@Observable
public final class StudySessionViewModel {
    public private(set) var engine: SubTopicSessionEngine
    public var isFlipped: Bool = false
    public var isSuccess: Bool = true
    public var selectedAnswer: String? = nil
    public var options: [String] = []
    public var lastXPDelta: Int = 10
    public var attemptedWrongAnswers: Set<String> = []
    
    public let ttsService: TextToSpeechProtocol

    public init(words: [TopicWord], ttsService: TextToSpeechProtocol? = nil) {
        self.engine = SubTopicSessionEngine(words: words)
        self.ttsService = ttsService ?? TextToSpeechService()
        self.loadCurrentQuestion()
    }

    public func loadCurrentQuestion() {
        guard let current = engine.currentWord else { return }
        options = engine.generateDistractors(for: current)
        selectedAnswer = nil
        isFlipped = false
        attemptedWrongAnswers.removeAll()
    }

    public func speakCurrentWord() {
        guard let word = engine.currentWord else { return }
        ttsService.speak(text: word.english)
    }

    public func submitAnswer(_ option: String) {
        guard selectedAnswer == nil || attemptedWrongAnswers.contains(option) == false else { return }
        
        let result = engine.submitAnswer(selectedVietnamese: option)
        selectedAnswer = option
        lastXPDelta = result.xpDelta

        if result.isCorrect {
            isSuccess = true
            isFlipped = true
            speakCurrentWord()
            
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                advanceToNext()
            }
        } else {
            isSuccess = false
            attemptedWrongAnswers.insert(option)
            if result.attemptsRemaining == 0 {
                isFlipped = true
                speakCurrentWord()
                
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    advanceToNext()
                }
            }
        }
    }

    public func advanceToNext() {
        engine.advanceToNextWord()
        if !engine.isSessionComplete {
            loadCurrentQuestion()
        }
    }
}
