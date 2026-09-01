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

        // 2. Try exact lemma word boundary match (case-insensitive)
        let exactPattern = "(?i)\\b" + NSRegularExpression.escapedPattern(for: lemma) + "\\b"
        if let regex = try? NSRegularExpression(pattern: exactPattern),
           let match = regex.firstMatch(in: sentenceEn, options: [], range: NSRange(sentenceEn.startIndex..., in: sentenceEn)),
           let matchRange = Range(match.range, in: sentenceEn) {
            let prefix = String(sentenceEn[..<matchRange.lowerBound])
            let slot = String(sentenceEn[matchRange])
            let suffix = String(sentenceEn[matchRange.upperBound...])
            return ClozeSentenceParts(prefix: prefix, slot: slot, suffix: suffix)
        }

        // 3. Try fuzzy stem matching for inflections (e.g. "overwhelmed" vs "overwhelm", "focuses" vs "focus")
        let cleanLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let stem = cleanLemma.count > 4 ? String(cleanLemma.prefix(cleanLemma.count - 2)) : cleanLemma
        let fuzzyPattern = "(?i)\\b" + NSRegularExpression.escapedPattern(for: stem) + "[a-z]*\\b"
        if let regex = try? NSRegularExpression(pattern: fuzzyPattern),
           let match = regex.firstMatch(in: sentenceEn, options: [], range: NSRange(sentenceEn.startIndex..., in: sentenceEn)),
           let matchRange = Range(match.range, in: sentenceEn) {
            let prefix = String(sentenceEn[..<matchRange.lowerBound])
            let slot = String(sentenceEn[matchRange])
            let suffix = String(sentenceEn[matchRange.upperBound...])
            return ClozeSentenceParts(prefix: prefix, slot: slot, suffix: suffix)
        }

        return nil
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
