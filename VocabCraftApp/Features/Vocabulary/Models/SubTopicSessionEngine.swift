import Foundation
import Observation

public struct SubmitResult: Sendable {
    public let isCorrect: Bool
    public let attemptsRemaining: Int
    public let xpDelta: Int
    public let isSessionFinished: Bool
}

@MainActor
@Observable
public final class SubTopicSessionEngine {
    public private(set) var activeWords: [TopicWord]
    public private(set) var initialWords: [TopicWord]
    public private(set) var currentIndex: Int = 0
    public private(set) var attemptsLeft: Int = 2
    public private(set) var comboCount: Int = 0
    public private(set) var xpEarned: Int = 0
    public private(set) var correctCount: Int = 0
    public private(set) var passedCount: Int = 0
    public private(set) var totalQuestionsCount: Int = 0
    public private(set) var questionPassedResults: [Int: Bool] = [:]

    public var currentWord: TopicWord? {
        guard currentIndex < activeWords.count else { return nil }
        return activeWords[currentIndex]
    }

    public var isSessionComplete: Bool {
        return currentIndex >= activeWords.count
    }

    public var accuracyPercentage: Int {
        guard totalQuestionsCount > 0 else { return 100 }
        return Int((Double(passedCount) / Double(totalQuestionsCount)) * 100)
    }

    public var isPassed: Bool {
        return accuracyPercentage >= 80
    }

    public init(words: [TopicWord]) {
        self.activeWords = words
        self.initialWords = words
        self.totalQuestionsCount = words.count
    }

    public func submitAnswer(selectedVietnamese: String) -> SubmitResult {
        guard let word = currentWord else {
            return SubmitResult(isCorrect: false, attemptsRemaining: 0, xpDelta: 0, isSessionFinished: true)
        }

        let isCorrect = selectedVietnamese == word.vietnamese
        let originalIndex = currentIndex

        if isCorrect {
            let xp = (attemptsLeft == 2) ? 10 : 5
            xpEarned += xp
            comboCount += 1
            correctCount += 1
            passedCount += 1
            questionPassedResults[originalIndex] = true

            return SubmitResult(isCorrect: true, attemptsRemaining: attemptsLeft, xpDelta: xp, isSessionFinished: false)
        } else {
            attemptsLeft -= 1
            if attemptsLeft <= 0 {
                xpEarned -= 5
                comboCount = 0
                questionPassedResults[originalIndex] = false
                return SubmitResult(isCorrect: false, attemptsRemaining: 0, xpDelta: -5, isSessionFinished: false)
            } else {
                return SubmitResult(isCorrect: false, attemptsRemaining: 1, xpDelta: 0, isSessionFinished: false)
            }
        }
    }


    public func advanceToNextWord() {
        currentIndex += 1
        attemptsLeft = 2
    }


    public func generateDistractors(for word: TopicWord) -> [String] {
        let correctMeaning = word.vietnamese

        // Get unique vietnamese meanings from activeWords excluding correctMeaning
        var availableDistractors = Array(Set(activeWords.map { $0.vietnamese }).subtracting([correctMeaning]))

        // Fallback options in case activeWords doesn't have enough unique words
        let defaultFallbacks = [
            "Sự tự động hóa", "Thuật toán", "Hệ sinh thái",
            "Đa dạng sinh học", "Sự bền vững", "Sự đổi mới sáng tạo",
            "Hạ tầng", "Nhân tạo", "Trí tuệ", "Kiến trúc"
        ]

        for fallback in defaultFallbacks {
            if availableDistractors.count >= 3 { break }
            if fallback != correctMeaning && !availableDistractors.contains(fallback) {
                availableDistractors.append(fallback)
            }
        }

        let selectedDistractors = Array(availableDistractors.shuffled().prefix(3))
        var allOptions = selectedDistractors + [correctMeaning]
        allOptions.shuffle()
        return allOptions
    }
}

