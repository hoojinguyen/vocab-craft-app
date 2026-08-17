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
            ReflexBlitzWordItem(
                id: 1,
                lemma: "habit",
                pos: "n.",
                definitionVi: "Thói quen hàng ngày",
                exampleSentenceEn: "Reading books before bed is a great habit.",
                exampleSentenceVi: "Đọc sách trước khi ngủ là một thói quen tuyệt vời."
            ),
            ReflexBlitzWordItem(
                id: 2,
                lemma: "focus",
                pos: "v.",
                definitionVi: "Tập trung",
                exampleSentenceEn: "Please turn off the music so I can focus on studying.",
                exampleSentenceVi: "Làm ơn tắt nhạc để tôi có thể tập trung vào việc học."
            ),
            ReflexBlitzWordItem(
                id: 3,
                lemma: "comfortable",
                pos: "adj.",
                definitionVi: "Thoải mái, dễ chịu",
                exampleSentenceEn: "These new running shoes are extremely comfortable to wear.",
                exampleSentenceVi: "Đôi giày chạy mới này mang cực kỳ thoải mái."
            ),
            ReflexBlitzWordItem(
                id: 4,
                lemma: "improve",
                pos: "v.",
                definitionVi: "Cải thiện, nâng cao",
                exampleSentenceEn: "Daily practice will help you improve your speaking skills.",
                exampleSentenceVi: "Luyện tập hàng ngày sẽ giúp bạn cải thiện kỹ năng nói."
            ),
            ReflexBlitzWordItem(
                id: 5,
                lemma: "opportunity",
                pos: "n.",
                definitionVi: "Cơ hội tốt",
                exampleSentenceEn: "Studying abroad is a wonderful opportunity to learn.",
                exampleSentenceVi: "Du học là một cơ hội tuyệt vời để học hỏi."
            ),
            ReflexBlitzWordItem(
                id: 6,
                lemma: "confident",
                pos: "adj.",
                definitionVi: "Tự tin",
                exampleSentenceEn: "She feels very confident when speaking in public.",
                exampleSentenceVi: "Cô ấy cảm thấy rất tự tin khi phát biểu trước công chúng."
            ),
            ReflexBlitzWordItem(
                id: 7,
                lemma: "schedule",
                pos: "n.",
                definitionVi: "Lịch trình, thời gian biểu",
                exampleSentenceEn: "I have a very busy schedule this morning.",
                exampleSentenceVi: "Tôi có một lịch trình rất bận rộn vào sáng nay."
            ),
            ReflexBlitzWordItem(
                id: 8,
                lemma: "remind",
                pos: "v.",
                definitionVi: "Nhắc nhở",
                exampleSentenceEn: "Please remind me to call my mom tonight.",
                exampleSentenceVi: "Làm ơn nhắc tôi gọi điện cho mẹ tối nay."
            ),
            ReflexBlitzWordItem(
                id: 9,
                lemma: "delicious",
                pos: "adj.",
                definitionVi: "Thơm ngon",
                exampleSentenceEn: "This homemade cake smells great and tastes delicious.",
                exampleSentenceVi: "Chiếc bánh tự làm này thơm lừng và vị rất ngon."
            ),
            ReflexBlitzWordItem(
                id: 10,
                lemma: "flexible",
                pos: "adj.",
                definitionVi: "Linh hoạt",
                exampleSentenceEn: "Our company offers flexible working hours for everyone.",
                exampleSentenceVi: "Công ty chúng tôi có giờ làm việc linh hoạt cho mọi người."
            ),
            ReflexBlitzWordItem(
                id: 11,
                lemma: "protect",
                pos: "v.",
                definitionVi: "Bảo vệ",
                exampleSentenceEn: "You should wear a helmet to protect your head.",
                exampleSentenceVi: "Bạn nên đội mũ bảo hiểm để bảo vệ đầu của mình."
            ),
            ReflexBlitzWordItem(
                id: 12,
                lemma: "creative",
                pos: "adj.",
                definitionVi: "Sáng tạo",
                exampleSentenceEn: "He always comes up with creative solutions to problems.",
                exampleSentenceVi: "Anh ấy luôn đưa ra những giải pháp sáng tạo cho vấn đề."
            ),
            ReflexBlitzWordItem(
                id: 13,
                lemma: "experience",
                pos: "n.",
                definitionVi: "Trải nghiệm, kinh nghiệm",
                exampleSentenceEn: "Traveling alone was an unforgettable experience for him.",
                exampleSentenceVi: "Đi du lịch một mình là một trải nghiệm khó quên đối với anh ấy."
            ),
            ReflexBlitzWordItem(
                id: 14,
                lemma: "patient",
                pos: "adj.",
                definitionVi: "Kiên nhẫn",
                exampleSentenceEn: "A good teacher is always kind and patient with students.",
                exampleSentenceVi: "Một giáo viên giỏi luôn tốt bụng và kiên nhẫn với học sinh."
            ),
            ReflexBlitzWordItem(
                id: 15,
                lemma: "encourage",
                pos: "v.",
                definitionVi: "Động viên, khích lệ",
                exampleSentenceEn: "Parents should always encourage their children to read.",
                exampleSentenceVi: "Cha mẹ nên luôn động viên con cái đọc sách."
            ),
            ReflexBlitzWordItem(
                id: 16,
                lemma: "energy",
                pos: "n.",
                definitionVi: "Năng lượng",
                exampleSentenceEn: "A healthy breakfast gives you energy for the whole day.",
                exampleSentenceVi: "Bữa sáng lành mạnh cung cấp cho bạn năng lượng cho cả ngày."
            )
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
