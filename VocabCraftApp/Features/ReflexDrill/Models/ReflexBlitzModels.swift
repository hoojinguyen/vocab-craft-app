import Foundation

public enum ReflexSpeedTier: String, Sendable, Codable, CaseIterable {
    case flash
    case hinted
    case needsPractice

    public static func from(responseTimeMs: Int, usedHint: Bool) -> ReflexSpeedTier {
        if responseTimeMs < 2500 && !usedHint {
            return .flash
        } else if responseTimeMs < 6000 {
            return .hinted
        } else {
            return .needsPractice
        }
    }
}

public struct ReflexClozeFormatter: Sendable {
    public static func formatCloze(sentenceEn: String, lemma: String) -> String {
        guard !sentenceEn.isEmpty, !lemma.isEmpty else { return sentenceEn }
        let pattern = "(?i)\\b" + NSRegularExpression.escapedPattern(for: lemma) + "\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return sentenceEn.replacingOccurrences(of: lemma, with: "[ _________ ]", options: .caseInsensitive)
        }
        let range = NSRange(sentenceEn.startIndex..., in: sentenceEn)
        return regex.stringByReplacingMatches(in: sentenceEn, options: [], range: range, withTemplate: "[ _________ ]")
    }
}

public struct ReflexBlitzWordItem: Identifiable, Equatable, Sendable {
    public let id: Int
    public let lemma: String
    public let pos: String
    public let definitionVi: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let clozeSentenceEn: String
    public let initialLetterHint: String

    public init(
        id: Int,
        lemma: String,
        pos: String,
        definitionVi: String,
        exampleSentenceEn: String,
        exampleSentenceVi: String
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.definitionVi = definitionVi
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = exampleSentenceVi
        self.clozeSentenceEn = ReflexClozeFormatter.formatCloze(sentenceEn: exampleSentenceEn, lemma: lemma)
        let firstLetter = lemma.prefix(1).lowercased()
        self.initialLetterHint = "\(pos). • \(firstLetter)..."
    }

    public init(from wordItem: WordItem) {
        self.init(
            id: Int(wordItem.id),
            lemma: wordItem.lemma,
            pos: wordItem.pos,
            definitionVi: wordItem.definition,
            exampleSentenceEn: wordItem.exampleSentenceEn,
            exampleSentenceVi: wordItem.exampleSentenceVi
        )
    }

    public init(from word: Word) {
        let sentenceEn = word.example ?? "The word is \(word.lemma)."
        self.init(
            id: Int(word.id),
            lemma: word.lemma,
            pos: word.pos ?? "word",
            definitionVi: word.definitionVi ?? word.definitionEn ?? "",
            exampleSentenceEn: sentenceEn,
            exampleSentenceVi: word.definitionVi ?? ""
        )
    }

    public static var defaultStarterWords: [ReflexBlitzWordItem] {
        [
            ReflexBlitzWordItem(id: 1, lemma: "ephemeral", pos: "adj.", definitionVi: "Phù du, chóng tàn", exampleSentenceEn: "Her fame is ephemeral in nature.", exampleSentenceVi: "Danh tiếng của cô ấy phù du."),
            ReflexBlitzWordItem(id: 2, lemma: "serendipity", pos: "n.", definitionVi: "Sự may mắn bất ngờ", exampleSentenceEn: "Finding this book was pure serendipity.", exampleSentenceVi: "Tìm thấy cuốn sách này là may mắn bất ngờ."),
            ReflexBlitzWordItem(id: 3, lemma: "ubiquitous", pos: "adj.", definitionVi: "Phổ biến khắp nơi", exampleSentenceEn: "Smartphones are ubiquitous today.", exampleSentenceVi: "Điện thoại thông minh phổ biến khắp nơi."),
            ReflexBlitzWordItem(id: 4, lemma: "resilience", pos: "n.", definitionVi: "Sự kiên cường phục hồi", exampleSentenceEn: "She showed great resilience in crisis.", exampleSentenceVi: "Cô ấy thể hiện sự kiên cường trong khủng hoảng."),
            ReflexBlitzWordItem(id: 5, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện lưu loát", exampleSentenceEn: "He gave an eloquent speech.", exampleSentenceVi: "Anh ấy đã có bài phát biểu hùng biện.")
        ]
    }
}

public struct ReflexBlitzAttempt: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let wordId: Int
    public let lemma: String
    public let responseTimeMs: Int
    public let usedHint: Bool
    public let isCorrect: Bool
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        wordId: Int,
        lemma: String,
        responseTimeMs: Int,
        usedHint: Bool,
        isCorrect: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.lemma = lemma
        self.responseTimeMs = responseTimeMs
        self.usedHint = usedHint
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }

    public var speedTier: ReflexSpeedTier {
        ReflexSpeedTier.from(responseTimeMs: responseTimeMs, usedHint: usedHint)
    }
}

public struct ReflexBlitzSessionSummary: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let totalWords: Int
    public let correctWords: Int
    public let averageResponseTimeMs: Int
    public let maxComboStreak: Int
    public let attempts: [ReflexBlitzAttempt]
    public let weakWordAttempts: [ReflexBlitzAttempt]
    public let speedRating: String

    public init(
        id: UUID = UUID(),
        totalWords: Int,
        correctWords: Int,
        averageResponseTimeMs: Int,
        maxComboStreak: Int,
        attempts: [ReflexBlitzAttempt],
        weakWordAttempts: [ReflexBlitzAttempt],
        speedRating: String
    ) {
        self.id = id
        self.totalWords = totalWords
        self.correctWords = correctWords
        self.averageResponseTimeMs = averageResponseTimeMs
        self.maxComboStreak = maxComboStreak
        self.attempts = attempts
        self.weakWordAttempts = weakWordAttempts
        self.speedRating = speedRating
    }

    public static func create(from attempts: [ReflexBlitzAttempt], maxCombo: Int) -> ReflexBlitzSessionSummary {
        let total = attempts.count
        let correct = attempts.filter { $0.isCorrect }.count
        let avgTime = total > 0 ? attempts.reduce(0) { $0 + $1.responseTimeMs } / total : 0
        let weak = attempts.filter { !$0.isCorrect || $0.speedTier == .needsPractice }

        let rating: String
        if total > 0 && avgTime <= 2500 && correct == total {
            rating = "⚡️ Reflex Master"
        } else if total > 0 && avgTime <= 4000 && Double(correct) / Double(max(1, total)) >= 0.7 {
            rating = "🔥 Swift Reflex"
        } else {
            rating = "🌱 Steady Learner"
        }

        return ReflexBlitzSessionSummary(
            id: UUID(),
            totalWords: total,
            correctWords: correct,
            averageResponseTimeMs: avgTime,
            maxComboStreak: maxCombo,
            attempts: attempts,
            weakWordAttempts: weak,
            speedRating: rating
        )
    }
}
