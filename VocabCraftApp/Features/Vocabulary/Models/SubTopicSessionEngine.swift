import Foundation
import Observation

public struct SubmitResult: Sendable {
    public let isCorrect: Bool
    public let attemptsRemaining: Int
    public let xpDelta: Int
    public let isSessionFinished: Bool
}

@Observable
public final class SubTopicSessionEngine: @unchecked Sendable {
    public private(set) var activeWords: [TopicWord]
    public private(set) var retryQueue: [TopicWord] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var attemptsLeft: Int = 2
    public private(set) var comboCount: Int = 0
    public private(set) var xpEarned: Int = 0
    public private(set) var correctCount: Int = 0
    public private(set) var totalQuestionsCount: Int = 0

    public var currentWord: TopicWord? {
        guard currentIndex < activeWords.count else { return nil }
        return activeWords[currentIndex]
    }

    public var isSessionComplete: Bool {
        return currentIndex >= activeWords.count
    }

    public init(words: [TopicWord]) {
        self.activeWords = words
        self.totalQuestionsCount = words.count
    }

    public func submitAnswer(selectedVietnamese: String) -> SubmitResult {
        guard let word = currentWord else {
            return SubmitResult(isCorrect: false, attemptsRemaining: 0, xpDelta: 0, isSessionFinished: true)
        }

        let isCorrect = selectedVietnamese == word.vietnamese

        if isCorrect {
            let xp = (attemptsLeft == 2) ? 10 : 5
            xpEarned += xp
            comboCount += 1
            correctCount += 1
            return SubmitResult(isCorrect: true, attemptsRemaining: attemptsLeft, xpDelta: xp, isSessionFinished: false)
        } else {
            attemptsLeft -= 1
            if attemptsLeft <= 0 {
                xpEarned -= 5
                comboCount = 0
                retryQueue.append(word)
                return SubmitResult(isCorrect: false, attemptsRemaining: 0, xpDelta: -5, isSessionFinished: false)
            } else {
                return SubmitResult(isCorrect: false, attemptsRemaining: 1, xpDelta: 0, isSessionFinished: false)
            }
        }
    }

    public func advanceToNextWord() {
        currentIndex += 1
        attemptsLeft = 2
        if currentIndex >= activeWords.count && !retryQueue.isEmpty {
            activeWords.append(contentsOf: retryQueue)
            retryQueue.removeAll()
        }
    }
}
