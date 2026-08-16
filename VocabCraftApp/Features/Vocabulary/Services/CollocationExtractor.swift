import Foundation

public enum CollocationExtractor {
    public static func extract(for word: WordItem) -> String {
        if let explicit = word.collocationEn?.trimmingCharacters(in: .whitespacesAndNewlines), !explicit.isEmpty {
            return explicit
        }
        
        let example = word.exampleSentenceEn.trimmingCharacters(in: .whitespacesAndNewlines)
        if !example.isEmpty {
            if let chunk = extractChunk(lemma: word.lemma, from: example) {
                return chunk
            }
        }
        
        return ruleBasedFallback(lemma: word.lemma, pos: word.pos)
    }

    private static func extractChunk(lemma: String, from sentence: String) -> String? {
        let cleanSentence = sentence.components(separatedBy: .punctuationCharacters).joined()
        let tokens = cleanSentence.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard let index = tokens.firstIndex(where: { $0.caseInsensitiveCompare(lemma) == .orderedSame }) else {
            return nil
        }
        
        let start = max(0, index - 1)
        let end = min(tokens.count, index + 2)
        let chunk = tokens[start..<end].joined(separator: " ")
        return chunk.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : chunk.lowercased()
    }

    private static func ruleBasedFallback(lemma: String, pos: String) -> String {
        let normalizedPos = pos.lowercased()
        if normalizedPos.contains("adverb") || normalizedPos.contains("adv.") || normalizedPos.contains("adv") {
            return "\(lemma.lowercased()) in practice"
        }
        if normalizedPos.contains("verb") || normalizedPos.contains("v.") {
            return "to \(lemma.lowercased()) actively"
        }
        if normalizedPos.contains("noun") || normalizedPos.contains("n.") {
            return "great \(lemma.lowercased())"
        }
        if normalizedPos.contains("adj") {
            return "\(lemma.lowercased()) situation"
        }
        return "\(lemma.lowercased()) in practice"
    }
}
