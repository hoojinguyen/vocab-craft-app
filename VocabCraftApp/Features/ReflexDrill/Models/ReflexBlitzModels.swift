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
    public let ipa: String
    public let definitionVi: String
    public let exampleSentenceEn: String
    public let exampleSentenceVi: String
    public let clozeSentenceEn: String
    public let initialLetterHint: String

    public init(
        id: Int,
        lemma: String,
        pos: String,
        ipa: String = "",
        definitionVi: String,
        exampleSentenceEn: String,
        exampleSentenceVi: String,
        clozeSentenceEn: String? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.ipa = ipa
        self.definitionVi = definitionVi
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = exampleSentenceVi
        self.clozeSentenceEn = clozeSentenceEn ?? ReflexClozeFormatter.formatCloze(sentenceEn: exampleSentenceEn, lemma: lemma)
        let firstLetter = lemma.prefix(1).lowercased()
        let formattedPos = pos.hasSuffix(".") ? pos : "\(pos)."
        self.initialLetterHint = "\(firstLetter)... • \(formattedPos)"
    }

    public init(from wordItem: WordItem) {
        self.init(
            id: Int(wordItem.id),
            lemma: wordItem.lemma,
            pos: wordItem.pos,
            ipa: wordItem.phonetic,
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
            ipa: word.ipaUs ?? "",
            definitionVi: word.definitionVi ?? word.definitionEn ?? "",
            exampleSentenceEn: sentenceEn,
            exampleSentenceVi: word.definitionVi ?? ""
        )
    }

    public var completedSentenceWithTargetWord: String {
        if clozeSentenceEn.contains("[ _________ ]") {
            return clozeSentenceEn.replacingOccurrences(of: "[ _________ ]", with: lemma)
        } else if clozeSentenceEn.contains("[ ________ ]") {
            return clozeSentenceEn.replacingOccurrences(of: "[ ________ ]", with: lemma)
        } else if clozeSentenceEn.contains("[ ______ ]") {
            return clozeSentenceEn.replacingOccurrences(of: "[ ______ ]", with: lemma)
        } else if let regex = try? NSRegularExpression(pattern: "\\[\\s*_{3,}\\s*\\]") {
            let range = NSRange(clozeSentenceEn.startIndex..., in: clozeSentenceEn)
            let replaced = regex.stringByReplacingMatches(in: clozeSentenceEn, options: [], range: range, withTemplate: lemma)
            if replaced != clozeSentenceEn {
                return replaced
            }
        }

        if let regex = try? NSRegularExpression(pattern: "_{3,}") {
            let range = NSRange(clozeSentenceEn.startIndex..., in: clozeSentenceEn)
            let replaced = regex.stringByReplacingMatches(in: clozeSentenceEn, options: [], range: range, withTemplate: lemma)
            if replaced != clozeSentenceEn {
                return replaced
            }
        }

        return !exampleSentenceEn.isEmpty ? exampleSentenceEn : clozeSentenceEn
    }

    public static var defaultStarterWords: [ReflexBlitzWordItem] {
        [
            ReflexBlitzWordItem(
                id: 1,
                lemma: "habit",
                pos: "n.",
                ipa: "/ˈhæb.ɪt/",
                definitionVi: "Thói quen hàng ngày",
                exampleSentenceEn: "Reading books before bed is a great habit.",
                exampleSentenceVi: "Đọc sách trước khi ngủ là một thói quen tuyệt vời."
            ),
            ReflexBlitzWordItem(
                id: 2,
                lemma: "expand",
                pos: "v.",
                ipa: "/ɪkˈspænd/",
                definitionVi: "Mở rộng, phát triển",
                exampleSentenceEn: "Reading daily helps you expand your vocabulary.",
                exampleSentenceVi: "Đọc sách mỗi ngày giúp bạn mở rộng vốn từ vựng."
            ),
            ReflexBlitzWordItem(
                id: 3,
                lemma: "fluent",
                pos: "adj.",
                ipa: "/ˈfluː.ənt/",
                definitionVi: "Trôi chảy, lưu loát",
                exampleSentenceEn: "She is fluent in English and French.",
                exampleSentenceVi: "Cô ấy nói trôi chảy tiếng Anh và tiếng Pháp."
            ),
            ReflexBlitzWordItem(
                id: 4,
                lemma: "confident",
                pos: "adj.",
                ipa: "/ˈkɑːn.fə.dənt/",
                definitionVi: "Tự tin",
                exampleSentenceEn: "She feels very confident when speaking in public.",
                exampleSentenceVi: "Cô ấy cảm thấy rất tự tin khi phát biểu trước công chúng."
            ),
            ReflexBlitzWordItem(
                id: 5,
                lemma: "achieve",
                pos: "v.",
                ipa: "/əˈtʃiːv/",
                definitionVi: "Đạt được, hoàn thành",
                exampleSentenceEn: "Hard work will help you achieve your goals.",
                exampleSentenceVi: "Chăm chỉ sẽ giúp bạn đạt được mục tiêu."
            ),
            ReflexBlitzWordItem(
                id: 6,
                lemma: "resilient",
                pos: "adj.",
                ipa: "/rɪˈzɪl.jənt/",
                definitionVi: "Kiên cường, mau hồi phục",
                exampleSentenceEn: "They remained resilient during difficult times.",
                exampleSentenceVi: "Họ vẫn kiên cường trong suốt những giai đoạn khó khăn."
            ),
            ReflexBlitzWordItem(
                id: 7,
                lemma: "serendipity",
                pos: "n.",
                ipa: "/ˌser.ənˈdɪp.ə.ti/",
                definitionVi: "Sự tình cờ may mắn",
                exampleSentenceEn: "It was pure serendipity that we met today.",
                exampleSentenceVi: "Thật là một sự tình cờ may mắn khi chúng ta gặp nhau hôm nay."
            ),
            ReflexBlitzWordItem(
                id: 8,
                lemma: "ephemeral",
                pos: "adj.",
                ipa: "/ɪˈfem.ər.əl/",
                definitionVi: "Phù du, chóng tàn",
                exampleSentenceEn: "Fame can be ephemeral in the digital age.",
                exampleSentenceVi: "Danh tiếng có thể rất phù du trong thời đại số."
            ),
            ReflexBlitzWordItem(
                id: 9,
                lemma: "luminous",
                pos: "adj.",
                ipa: "/ˈluː.mə.nəs/",
                definitionVi: "Tỏa sáng, rực rỡ",
                exampleSentenceEn: "The night sky was filled with luminous stars.",
                exampleSentenceVi: "Bầu trời đêm ngập tràn những vì sao tỏa sáng."
            ),
            ReflexBlitzWordItem(
                id: 10,
                lemma: "meticulous",
                pos: "adj.",
                ipa: "/məˈtɪk.jə.ləs/",
                definitionVi: "Tỉ mỉ, cẩn thận",
                exampleSentenceEn: "She is meticulous about her work quality.",
                exampleSentenceVi: "Cô ấy rất tỉ mỉ về chất lượng công việc của mình."
            )
        ]
    }
}

public typealias ReflexBlitzWeakWordAttempt = ReflexBlitzAttempt

public struct ReflexBlitzAttempt: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let wordId: Int
    public let lemma: String
    public let pos: String
    public let ipa: String
    public let definitionVi: String
    public let responseTimeMs: Int
    public let usedHint: Bool
    public let isCorrect: Bool
    public let timestamp: Date

    public init(
        id: UUID = UUID(),
        wordId: Int,
        lemma: String,
        pos: String = "",
        ipa: String = "",
        definitionVi: String = "",
        responseTimeMs: Int,
        usedHint: Bool,
        isCorrect: Bool,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.wordId = wordId
        self.lemma = lemma
        self.pos = pos
        self.ipa = ipa
        self.definitionVi = definitionVi
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
