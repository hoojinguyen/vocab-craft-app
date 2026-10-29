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
        let targetWords: [SpeakingAnalysis.TargetWordUse]
        if plan.targetWords.isEmpty {
            targetWords = []
        } else {
            targetWords = raw.targetWords.prefix(3).map { word in
                guard word.used, let quote = word.quote, containsQuote(quote, in: transcript) else {
                    return .init(lemma: word.lemma, used: false, usedCorrectly: false, quote: nil)
                }
                return word
            }
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
}
