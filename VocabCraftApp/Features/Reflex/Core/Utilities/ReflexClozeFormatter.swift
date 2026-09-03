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
    public static func extractClozeOrLemmaParts(sentenceEn: String, lemma: String) -> ClozeSentenceParts? {
        // 1. Try extracting template blanks like [ _________ ]
        if let templateParts = extractTemplateParts(from: sentenceEn) {
            return templateParts
        }
        guard !sentenceEn.isEmpty, !lemma.isEmpty else { return nil }

        // 2. Try exact and inflection patterns
        let cleanLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanLemma.isEmpty else { return nil }

        for pattern in inflectionPatterns(for: cleanLemma) {
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

    public static func formatCloze(sentenceEn: String, lemma: String) -> String {
        guard !sentenceEn.isEmpty, !lemma.isEmpty else { return sentenceEn }

        let cleanLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanLemma.isEmpty else { return sentenceEn }

        var currentText = sentenceEn
        for pattern in inflectionPatterns(for: cleanLemma) {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(currentText.startIndex..., in: currentText)
                currentText = regex.stringByReplacingMatches(in: currentText, options: [], range: range, withTemplate: "[ _________ ]")
            }
        }

        return currentText
    }

    /// Generates regex patterns for exact match and English inflection variants with spelling alternations.
    private static func inflectionPatterns(for cleanLemma: String) -> [String] {
        var patterns: [String] = []
        let escapedLemma = NSRegularExpression.escapedPattern(for: cleanLemma)

        // 1. Exact match and direct suffixes (e.g. walk -> walks, walked, walking; focus -> focuses)
        patterns.append("(?i)\\b" + escapedLemma + "(?:s|es|ed|ing|d|er|est)?\\b")

        // 2. Silent 'e' dropped before suffix (e.g. take -> taking, create -> creating)
        if cleanLemma.hasSuffix("e") && cleanLemma.count > 2 {
            let stem = String(cleanLemma.dropLast())
            let escapedStem = NSRegularExpression.escapedPattern(for: stem)
            patterns.append("(?i)\\b" + escapedStem + "(?:ing|ed|en)\\b")
        }

        // 3. 'y' mutated to 'i' before suffix (e.g. study -> studies, studied; try -> tries, tried; happy -> happier)
        if cleanLemma.hasSuffix("y") && cleanLemma.count > 2 {
            let stem = String(cleanLemma.dropLast())
            let escapedStem = NSRegularExpression.escapedPattern(for: stem)
            patterns.append("(?i)\\b" + escapedStem + "(?:ies|ied|ier|iest)\\b")
        }

        // 4. Consonant doubling (e.g. stop -> stopped, stopping; plan -> planned, planning; run -> running)
        if let lastChar = cleanLemma.last, "bcdfghjklmnpqrstvwxyz".contains(lastChar), cleanLemma.count >= 3 {
            patterns.append("(?i)\\b" + escapedLemma + String(lastChar) + "(?:ed|ing)\\b")
        }

        return patterns
    }
}
