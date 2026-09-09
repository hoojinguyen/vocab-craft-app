import Foundation

/// Core stimulus model for Reflex blitz and modality drills, conforming to `ReflexDrillable`.
public struct ReflexBlitzWordItem: Identifiable, Equatable, Sendable, ReflexDrillable {
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
    public let level: String
    public let audioResourceUrl: String?

    public var cefrLevel: String {
        level
    }

    public var cleanPos: String {
        let trimmed = pos.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ".", with: "").lowercased()
        switch trimmed {
        case "v", "verb": return "verb"
        case "n", "noun": return "noun"
        case "adj", "adjective": return "adj"
        case "adv", "adverb": return "adv"
        case "prep", "preposition": return "prep"
        case "conj", "conjunction": return "conj"
        case "pron", "pronoun": return "pron"
        default: return trimmed.isEmpty ? "word" : trimmed
        }
    }

    public var cleanLevel: String {
        level.isEmpty ? "B2" : level
    }

    public var cleanInitialLetterHint: String {
        let firstLetter = lemma.prefix(1).lowercased()
        return "\(firstLetter)... • \(cleanPos)"
    }

    public init(
        id: Int = 0,
        lemma: String,
        pos: String = "",
        ipa: String = "",
        definitionVi: String,
        exampleSentenceEn: String = "",
        exampleSentenceVi: String = "",
        clozeSentenceEn: String? = nil,
        clozeSentenceVi: String? = nil,
        level: String = "B2",
        audioResourceUrl: String? = nil
    ) {
        self.id = id
        self.lemma = lemma
        self.pos = pos
        self.ipa = ipa
        self.definitionVi = definitionVi
        self.exampleSentenceEn = exampleSentenceEn
        self.exampleSentenceVi = !exampleSentenceVi.isEmpty ? exampleSentenceVi : (clozeSentenceVi ?? "")
        self.level = level
        self.audioResourceUrl = audioResourceUrl
        let cloze = clozeSentenceEn ?? ReflexClozeFormatter.formatCloze(sentenceEn: exampleSentenceEn, lemma: lemma)
        self.clozeSentenceEn = cloze
        let parts = ReflexClozeFormatter.extractTemplateParts(from: cloze)
        let prefix = parts?.prefix ?? cloze
        let suffix = parts?.suffix ?? ""
        self.clozePrefix = prefix
        self.clozeSuffix = suffix
        self.hasClozeSlot = (cloze != prefix) || !suffix.isEmpty
        let firstLetter = lemma.prefix(1).lowercased()
        let formattedPos = pos.hasSuffix(".") ? pos : "\(pos)."
        self.initialLetterHint = "\(firstLetter)... • \(formattedPos)"
    }

    public init(from vaultWord: VaultWordItem) {
        self.init(
            id: Int(vaultWord.id),
            lemma: vaultWord.lemma,
            pos: vaultWord.pos,
            ipa: vaultWord.phonetic,
            definitionVi: vaultWord.definitionVi,
            exampleSentenceEn: vaultWord.exampleSentenceEn,
            exampleSentenceVi: vaultWord.exampleSentenceVi,
            level: vaultWord.cefrLevel.isEmpty ? "B2" : vaultWord.cefrLevel
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
            exampleSentenceVi: word.definitionVi ?? "",
            level: word.cefrLevel ?? "B2"
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

    public init(from sense: SenseDetail) {
        let firstExample = sense.examples.first
        let sentenceEn = firstExample?.textEN.isEmpty == false ? (firstExample?.textEN ?? "") : "The word is \(sense.headword)."
        let sentenceVi = firstExample?.textVI ?? ""
        self.init(
            id: 0,
            lemma: sense.headword,
            pos: sense.partOfSpeech.rawValue,
            ipa: sense.ipa ?? "",
            definitionVi: sense.definitionVI.isEmpty ? sense.definitionEN : sense.definitionVI,
            exampleSentenceEn: sentenceEn,
            exampleSentenceVi: sentenceVi,
            level: sense.cefrLevel.rawValue
        )
    }

    public func generateOptions(mode: ReflexMode, allPool: [ReflexBlitzWordItem]) -> [ReflexBlitzOption] {
        ReflexDistractorGenerator.generateOptions(
            mode: mode,
            targetLemma: lemma,
            targetDefinition: definitionVi,
            pool: allPool
        )
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
