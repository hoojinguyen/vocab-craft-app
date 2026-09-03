import Foundation

/// Represents segmented parts of a cloze sentence (prefix, slot, suffix).
public struct ClozeSentenceParts: Equatable, Sendable {
    public let prefix: String
    public let slot: String
    public let suffix: String

    public init(prefix: String, slot: String = "[ _________ ]", suffix: String) {
        self.prefix = prefix
        self.slot = slot
        self.suffix = suffix
    }
}

/// Pure utility for creating and parsing cloze sentence blanks.
public struct ReflexClozeFormatter: Sendable {
    private static let clozeRegex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: "\\[\\s*_{3,}\\s*\\]|_{3,}")
    }()

    public static func extractTemplateParts(from sentence: String) -> ClozeSentenceParts? {
        guard let regex = clozeRegex else { return nil }
        let nsRange = NSRange(sentence.startIndex..., in: sentence)
        guard let match = regex.firstMatch(in: sentence, options: [], range: nsRange),
              let matchRange = Range(match.range, in: sentence) else {
            return nil
        }
        let prefix = String(sentence[..<matchRange.lowerBound])
        let slot = String(sentence[matchRange])
        let suffix = String(sentence[matchRange.upperBound...])
        return ClozeSentenceParts(prefix: prefix, slot: slot, suffix: suffix)
    }

    /// Extracts cloze parts by first checking template blanks, and falling back to locating the lemma in the sentence.
    public static func extractClozeOrLemmaParts(sentenceEn: String, lemma: String, pos: String? = nil) -> ClozeSentenceParts? {
        // 1. Try extracting template blanks like [ _________ ]
        if let templateParts = extractTemplateParts(from: sentenceEn) {
            return templateParts
        }
        guard !sentenceEn.isEmpty, !lemma.isEmpty else { return nil }

        // 2. Try exact and inflection patterns
        let cleanLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanLemma.isEmpty else { return nil }

        for pattern in inflectionPatterns(for: cleanLemma, pos: pos) {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: sentenceEn, options: [], range: NSRange(sentenceEn.startIndex..., in: sentenceEn)),
               let matchRange = Range(match.range, in: sentenceEn) {
                let prefix = String(sentenceEn[..<matchRange.lowerBound])
                let slot = String(sentenceEn[matchRange])
                let suffix = String(sentenceEn[matchRange.upperBound...])
                return ClozeSentenceParts(prefix: prefix, slot: slot, suffix: suffix)
            }
        }

        return nil
    }

    public static func formatCloze(sentenceEn: String, lemma: String, pos: String? = nil) -> String {
        guard !sentenceEn.isEmpty, !lemma.isEmpty else { return sentenceEn }

        let cleanLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanLemma.isEmpty else { return sentenceEn }

        var currentText = sentenceEn
        for pattern in inflectionPatterns(for: cleanLemma, pos: pos) {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(currentText.startIndex..., in: currentText)
                currentText = regex.stringByReplacingMatches(in: currentText, options: [], range: range, withTemplate: "[ _________ ]")
            }
        }

        return currentText
    }

    private static let irregularForms: [String: [String]] = [
        "be": ["am", "is", "are", "was", "were", "been", "being"],
        "do": ["does", "did", "done", "doing"],
        "go": ["goes", "went", "gone", "going"],
        "have": ["has", "had", "having"],
        "see": ["sees", "saw", "seen", "seeing"],
        "take": ["takes", "took", "taken", "taking"],
        "get": ["gets", "got", "gotten", "getting"],
        "make": ["makes", "made", "making"],
        "know": ["knows", "knew", "known", "knowing"],
        "think": ["thinks", "thought", "thinking"],
        "come": ["comes", "came", "coming"],
        "find": ["finds", "found", "finding"],
        "give": ["gives", "gave", "given", "giving"],
        "tell": ["tells", "told", "telling"],
        "feel": ["feels", "felt", "feeling"],
        "become": ["becomes", "became", "becoming"],
        "leave": ["leaves", "left", "leaving"],
        "bring": ["brings", "brought", "bringing"],
        "buy": ["buys", "bought", "buying"],
        "write": ["writes", "wrote", "written", "writing"],
        "run": ["runs", "ran", "running"],
        "speak": ["speaks", "spoke", "spoken", "speaking"],
        "fall": ["falls", "fell", "fallen", "falling"],
        "send": ["sends", "sent", "sending"],
        "build": ["builds", "built", "building"],
        "spend": ["spends", "spent", "spending"],
        "draw": ["draws", "drew", "drawn", "drawing"],
        "break": ["breaks", "broke", "broken", "breaking"],
        "teach": ["teaches", "taught", "teaching"],
        "catch": ["catches", "caught", "catching"],
        "choose": ["chooses", "chose", "chosen", "choosing"],
        "drive": ["drives", "drove", "driven", "driving"],
        "eat": ["eats", "ate", "eaten", "eating"],
        "drink": ["drinks", "drank", "drunk", "drinking"],
        "sing": ["sings", "sang", "sung", "singing"],
        "sleep": ["sleeps", "slept", "sleeping"],
        "swim": ["swims", "swam", "swum", "swimming"],
        "wear": ["wears", "wore", "worn", "wearing"],
        "win": ["wins", "won", "winning"],
        "forget": ["forgets", "forgot", "forgotten", "forgetting"]
    ]

    /// Generates regex patterns for exact match, irregular variants, and English inflection variants with spelling alternations.
    private static func inflectionPatterns(for cleanLemma: String, pos: String? = nil) -> [String] {
        var patterns: [String] = []
        let escapedLemma = NSRegularExpression.escapedPattern(for: cleanLemma)
        let isAdjective = pos?.lowercased().contains("adj") == true

        if let forms = irregularForms[cleanLemma] {
            for form in forms {
                patterns.append("(?i)\\b" + NSRegularExpression.escapedPattern(for: form) + "\\b")
            }
        }

        // Short lemmas (<= 2 letters, e.g. "be") should not use generic suffix appending to avoid false matches (e.g. "bees")
        guard cleanLemma.count > 2 else {
            patterns.append("(?i)\\b" + escapedLemma + "\\b")
            return patterns
        }

        if isAdjective {
            // Adjective comparatives / superlatives
            patterns.append("(?i)\\b" + escapedLemma + "(?:er|est)?\\b")
            if cleanLemma.hasSuffix("e") {
                let stem = String(cleanLemma.dropLast())
                let escapedStem = NSRegularExpression.escapedPattern(for: stem)
                patterns.append("(?i)\\b" + escapedStem + "(?:er|est)\\b")
            }
            if cleanLemma.hasSuffix("y") {
                let stem = String(cleanLemma.dropLast())
                let escapedStem = NSRegularExpression.escapedPattern(for: stem)
                patterns.append("(?i)\\b" + escapedStem + "(?:ier|iest)\\b")
            }
            if let lastChar = cleanLemma.last, "bcdfghjklmnpqrstvwxyz".contains(lastChar) {
                patterns.append("(?i)\\b" + escapedLemma + String(lastChar) + "(?:er|est)\\b")
            }
        } else {
            // General verbs and nouns
            patterns.append("(?i)\\b" + escapedLemma + "(?:s|es|ed|ing|d)?\\b")
            if cleanLemma.hasSuffix("e") {
                let stem = String(cleanLemma.dropLast())
                let escapedStem = NSRegularExpression.escapedPattern(for: stem)
                patterns.append("(?i)\\b" + escapedStem + "(?:ing|ed|en)\\b")
            }
            if cleanLemma.hasSuffix("y") {
                let stem = String(cleanLemma.dropLast())
                let escapedStem = NSRegularExpression.escapedPattern(for: stem)
                patterns.append("(?i)\\b" + escapedStem + "(?:ies|ied)\\b")
            }
            if let lastChar = cleanLemma.last, "bcdfghjklmnpqrstvwxyz".contains(lastChar) {
                patterns.append("(?i)\\b" + escapedLemma + String(lastChar) + "(?:ed|ing)\\b")
            }
        }

        return patterns
    }
}
