import Foundation

public enum ReflexBlitzMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case speaking
    case typing
    case multipleChoice
    case listening

    public var id: String { rawValue }

    public var timeLimitSeconds: Double {
        switch self {
        case .multipleChoice: return 4.5
        case .listening:      return 5.5
        case .speaking:       return 6.0
        case .typing:         return 7.5
        }
    }

    public var title: String {
        switch self {
        case .speaking:       return AppStrings.ReflexBlitz.speakingTitleText
        case .typing:         return AppStrings.ReflexBlitz.typingTitleText
        case .multipleChoice: return AppStrings.ReflexBlitz.mcTitleText
        case .listening:      return AppStrings.ReflexBlitz.listeningTitleText
        }
    }

    public var iconName: String {
        switch self {
        case .speaking:       return "waveform.and.mic"
        case .typing:         return "keyboard"
        case .multipleChoice: return "square.grid.2x2.fill"
        case .listening:      return "headphones"
        }
    }

    public var instructionPrompt: String {
        switch self {
        case .speaking:       return AppStrings.ReflexBlitz.speakingInstructionText
        case .typing:         return AppStrings.ReflexBlitz.typingInstructionText
        case .multipleChoice: return AppStrings.ReflexBlitz.mcInstructionText
        case .listening:      return AppStrings.ReflexBlitz.listeningModeInstructionText
        }
    }
}

public enum ReflexCardPhase: Equatable, Sendable {
    case activeCountdown
    case reviewed(result: ReflexCardResult)
}

public struct ReflexCardResult: Equatable, Sendable {
    public let isCorrect: Bool
    public let responseTimeMs: Int
    public let isTimeout: Bool
    public let selectedOption: String?
    public let typedText: String?
    public let recognizedSpoken: String?

    public init(
        isCorrect: Bool,
        responseTimeMs: Int,
        isTimeout: Bool,
        selectedOption: String? = nil,
        typedText: String? = nil,
        recognizedSpoken: String? = nil
    ) {
        self.isCorrect = isCorrect
        self.responseTimeMs = responseTimeMs
        self.isTimeout = isTimeout
        self.selectedOption = selectedOption
        self.typedText = typedText
        self.recognizedSpoken = recognizedSpoken
    }
}

public struct ReflexBlitzOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let text: String
    public let isCorrect: Bool

    public init(id: String = UUID().uuidString, text: String, isCorrect: Bool) {
        self.id = id
        self.text = text
        self.isCorrect = isCorrect
    }
}

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
    private static let clozeRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\[\\s*_{3,}\\s*\\]|_{3,}")
    }()

    public static func extractTemplateParts(from sentence: String) -> (prefix: String, suffix: String) {
        guard let regex = clozeRegex else { return (sentence, "") }
        let nsRange = NSRange(sentence.startIndex..., in: sentence)
        guard let match = regex.firstMatch(in: sentence, options: [], range: nsRange),
              let matchRange = Range(match.range, in: sentence) else {
            return (sentence, "")
        }
        let prefix = String(sentence[..<matchRange.lowerBound])
        let suffix = String(sentence[matchRange.upperBound...])
        return (prefix, suffix)
    }

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
    public let clozePrefix: String
    public let clozeSuffix: String
    public let hasClozeSlot: Bool
    public let initialLetterHint: String

    public init(
        id: Int = 0,
        lemma: String,
        pos: String = "",
        ipa: String = "",
        definitionVi: String,
        exampleSentenceEn: String = "",
        exampleSentenceVi: String = "",
        clozeSentenceEn: String? = nil,
        clozeSentenceVi: String? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.ipa = ipa
        self.definitionVi = definitionVi
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = !exampleSentenceVi.isEmpty ? exampleSentenceVi : (clozeSentenceVi ?? "")
        let cloze = clozeSentenceEn ?? ReflexClozeFormatter.formatCloze(sentenceEn: exampleSentenceEn, lemma: lemma)
        self.clozeSentenceEn = cloze
        let (prefix, suffix) = ReflexClozeFormatter.extractTemplateParts(from: cloze)
        self.clozePrefix = prefix
        self.clozeSuffix = suffix
        self.hasClozeSlot = (cloze != prefix) || !suffix.isEmpty
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

    public init(from dto: TopicWordDTO) {
        let sentenceEn = dto.exampleEn.isEmpty ? "The word is \(dto.lemma)." : dto.exampleEn
        self.init(
            id: Int(dto.id),
            lemma: dto.lemma,
            pos: dto.pos.isEmpty ? "word" : dto.pos,
            ipa: dto.phonetic,
            definitionVi: dto.definitionVi.isEmpty ? dto.definitionEn : dto.definitionVi,
            exampleSentenceEn: sentenceEn,
            exampleSentenceVi: dto.exampleVi
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

    public func generateOptions(mode: ReflexBlitzMode, allPool: [ReflexBlitzWordItem]) -> [ReflexBlitzOption] {
        guard mode == .multipleChoice || mode == .listening else {
            return []
        }

        let isMultipleChoice = mode == .multipleChoice
        let correctText = isMultipleChoice ? lemma : definitionVi

        var distractorCandidates: [String] = []
        var seen = Set<String>([correctText])

        // Add from provided allPool first
        for item in allPool.shuffled() {
            let text = isMultipleChoice ? item.lemma : item.definitionVi
            if !text.isEmpty && !seen.contains(text) {
                seen.insert(text)
                distractorCandidates.append(text)
                if distractorCandidates.count == 3 { break }
            }
        }

        // If not enough distractors, fallback to defaultStarterWords
        if distractorCandidates.count < 3 {
            for item in Self.defaultStarterWords.shuffled() {
                let text = isMultipleChoice ? item.lemma : item.definitionVi
                if !text.isEmpty && !seen.contains(text) {
                    seen.insert(text)
                    distractorCandidates.append(text)
                    if distractorCandidates.count == 3 { break }
                }
            }
        }

        var options: [ReflexBlitzOption] = [
            ReflexBlitzOption(text: correctText, isCorrect: true)
        ]
        for distractor in distractorCandidates.prefix(3) {
            options.append(ReflexBlitzOption(text: distractor, isCorrect: false))
        }

        return options.shuffled()
    }

    public static var defaultStarterWords: [ReflexBlitzWordItem] {
        [
            ReflexBlitzWordItem(
                id: 1,
                lemma: "habit",
                pos: "n.",
                ipa: "/ˈhæb.ɪt/",
                definitionVi: "Thói quen",
                exampleSentenceEn: "Reading books daily is a great habit.",
                exampleSentenceVi: "Đọc sách mỗi ngày là một thói quen tuyệt vời."
            ),
            ReflexBlitzWordItem(
                id: 2,
                lemma: "improve",
                pos: "v.",
                ipa: "/ɪmˈpruːv/",
                definitionVi: "Cải thiện, nâng cao",
                exampleSentenceEn: "Practice helps you improve your English skills.",
                exampleSentenceVi: "Luyện tập giúp bạn cải thiện kỹ năng tiếng Anh."
            ),
            ReflexBlitzWordItem(
                id: 3,
                lemma: "focus",
                pos: "v.",
                ipa: "/ˈfoʊ.kəs/",
                definitionVi: "Tập trung",
                exampleSentenceEn: "Please focus on your main goal.",
                exampleSentenceVi: "Hãy tập trung vào mục tiêu chính của bạn."
            ),
            ReflexBlitzWordItem(
                id: 4,
                lemma: "create",
                pos: "v.",
                ipa: "/kriˈeɪt/",
                definitionVi: "Tạo ra, sáng tạo",
                exampleSentenceEn: "Artists always create beautiful paintings.",
                exampleSentenceVi: "Các nghệ sĩ luôn tạo ra những bức tranh tuyệt đẹp."
            ),
            ReflexBlitzWordItem(
                id: 5,
                lemma: "journey",
                pos: "n.",
                ipa: "/ˈdʒɜːr.ni/",
                definitionVi: "Hành trình, chuyến đi",
                exampleSentenceEn: "Learning a language is an exciting journey.",
                exampleSentenceVi: "Học một ngôn ngữ là một hành trình thú vị."
            ),
            ReflexBlitzWordItem(
                id: 6,
                lemma: "relax",
                pos: "v.",
                ipa: "/rɪˈlæks/",
                definitionVi: "Thư giãn, nghỉ ngơi",
                exampleSentenceEn: "Listening to music helps me relax after work.",
                exampleSentenceVi: "Nghe nhạc giúp tôi thư giãn sau giờ làm việc."
            ),
            ReflexBlitzWordItem(
                id: 7,
                lemma: "challenge",
                pos: "n.",
                ipa: "/ˈtʃæl.ɪndʒ/",
                definitionVi: "Thử thách",
                exampleSentenceEn: "Overcoming a challenge makes you stronger.",
                exampleSentenceVi: "Vượt qua thử thách giúp bạn mạnh mẽ hơn."
            ),
            ReflexBlitzWordItem(
                id: 8,
                lemma: "protect",
                pos: "v.",
                ipa: "/prəˈtekt/",
                definitionVi: "Bảo vệ",
                exampleSentenceEn: "We need to protect our environment.",
                exampleSentenceVi: "Chúng ta cần bảo vệ môi trường của mình."
            ),
            ReflexBlitzWordItem(
                id: 9,
                lemma: "connect",
                pos: "v.",
                ipa: "/kəˈnekt/",
                definitionVi: "Kết nối",
                exampleSentenceEn: "The internet helps people connect worldwide.",
                exampleSentenceVi: "Internet giúp mọi người kết nối trên toàn thế giới."
            ),
            ReflexBlitzWordItem(
                id: 10,
                lemma: "energy",
                pos: "n.",
                ipa: "/ˈen.ər.dʒi/",
                definitionVi: "Năng lượng",
                exampleSentenceEn: "A healthy breakfast gives you energy for the day.",
                exampleSentenceVi: "Bữa sáng lành mạnh cung cấp cho bạn năng lượng cho cả ngày."
            ),
            ReflexBlitzWordItem(
                id: 11,
                lemma: "simple",
                pos: "adj.",
                ipa: "/ˈsɪm.pəl/",
                definitionVi: "Đơn giản, dễ dàng",
                exampleSentenceEn: "Keeping things simple is often the best choice.",
                exampleSentenceVi: "Giữ mọi thứ đơn giản thường là sự lựa chọn tốt nhất."
            ),
            ReflexBlitzWordItem(
                id: 12,
                lemma: "success",
                pos: "n.",
                ipa: "/səkˈses/",
                definitionVi: "Thành công",
                exampleSentenceEn: "Hard work and patience lead to success.",
                exampleSentenceVi: "Chăm chỉ và kiên nhẫn dẫn đến thành công."
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

public struct ReflexBlitzDeepLinkConfig: Equatable, Sendable {
    public let mode: ReflexBlitzMode
    public let phase: ReflexBlitzPhase
    public let state: String?
    public let showHint: Bool
    public let combo: Int

    public init(
        mode: ReflexBlitzMode = .speaking,
        phase: ReflexBlitzPhase = .drilling,
        state: String? = nil,
        showHint: Bool = false,
        combo: Int = 0
    ) {
        self.mode = mode
        self.phase = phase
        self.state = state
        self.showHint = showHint
        self.combo = combo
    }
}
