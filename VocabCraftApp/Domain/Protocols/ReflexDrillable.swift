import Foundation

/// Pure domain abstraction representing any vocabulary entity that can be practiced in Reflex drills.
public protocol ReflexDrillable: Sendable {
    var lemma: String { get }
    var pos: String { get }
    var ipa: String { get }
    var definitionVi: String { get }
    var exampleSentenceEn: String { get }
    var exampleSentenceVi: String { get }
    var clozeSentenceEn: String { get }
    var cefrLevel: String { get }
    var audioResourceUrl: String? { get }
}

public extension ReflexDrillable {
    /// Normalized clean Part of Speech tag for consistent badge display.
    var cleanPos: String {
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

    /// CEFR level with B2 fallback if unspecified.
    var cleanLevel: String {
        cefrLevel.isEmpty ? "B2" : cefrLevel
    }

    /// Clean initial letter hint formatted as "h... • noun".
    var cleanInitialLetterHint: String {
        let firstLetter = lemma.prefix(1).lowercased()
        return "\(firstLetter)... • \(cleanPos)"
    }
}
