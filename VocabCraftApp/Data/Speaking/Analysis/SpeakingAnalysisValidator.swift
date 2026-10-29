import Foundation

public enum SpeakingAnalysisValidator {
    public static func validate(_ raw: SpeakingAnalysis, plan: SpeakingSessionPlan) throws -> SpeakingAnalysis {
        let scores = [raw.scores.fluency, raw.scores.grammar, raw.scores.vocabulary, raw.scores.pronunciation]
        guard scores.allSatisfy({ (1...5).contains($0.value) }) else {
            throw SpeakingAnalysisError.invalidResponse
        }

        let transcript = QuoteNormalizer.normalize(
            raw.learnerTranscript.map(\.text).joined(separator: " ")
        )
        let corrections = raw.corrections.filter { containsQuote($0.original, in: transcript) }.prefix(5)
        let naturalPhrasings = raw.naturalPhrasings.filter { containsQuote($0.original, in: transcript) }.prefix(3)
        let pronunciation = raw.pronunciation.prefix(3)
        let reportedTargetWords = Dictionary(
            raw.targetWords.map { (QuoteNormalizer.normalize($0.lemma), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let targetWords = plan.targetWords.prefix(3).map { requestedWord in
            let lemma = requestedWord.lemma
            guard let reportedWord = reportedTargetWords[QuoteNormalizer.normalize(lemma)],
                  reportedWord.used,
                  let quote = reportedWord.quote,
                  containsQuote(quote, in: transcript),
                  containsLemma(lemma, in: quote) else {
                return SpeakingAnalysis.TargetWordUse(
                    lemma: lemma, used: false, usedCorrectly: false, quote: nil
                )
            }
            return SpeakingAnalysis.TargetWordUse(
                lemma: lemma, used: true, usedCorrectly: reportedWord.usedCorrectly, quote: quote
            )
        }

        return SpeakingAnalysis(
            learnerTranscript: raw.learnerTranscript,
            scores: raw.scores,
            corrections: Array(corrections),
            naturalPhrasings: Array(naturalPhrasings),
            pronunciation: Array(pronunciation),
            targetWords: targetWords,
            objective: raw.objective,
            summary: raw.summary
        )
    }

    private static func containsQuote(_ quote: String, in transcript: String) -> Bool {
        let normalizedQuote = QuoteNormalizer.normalize(quote)
        return !normalizedQuote.isEmpty && transcript.contains(normalizedQuote)
    }

    private static func containsLemma(_ lemma: String, in quote: String) -> Bool {
        let normalizedLemma = QuoteNormalizer.normalize(lemma)
        let normalizedQuote = QuoteNormalizer.normalize(quote)
        guard !normalizedLemma.isEmpty else { return false }
        return (" \(normalizedQuote) ").contains(" \(normalizedLemma) ")
    }
}
