import Foundation

/// Speech evaluation engine that computes Levenshtein distance, similarity ratios,
/// and token sequence alignments for accent-tolerant speech grading.
public enum FuzzySpeechMatcher {

    // MARK: - Levenshtein Distance

    /// Computes standard Levenshtein edit distance between two strings.
    ///
    /// - Parameters:
    ///   - s1: First string.
    ///   - s2: Second string.
    /// - Returns: Minimum number of single-character edits (insertions, deletions, substitutions).
    public static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        if s1 == s2 { return 0 }
        if s1.isEmpty { return s2.count }
        if s2.isEmpty { return s1.count }

        let a1 = Array(s1)
        let a2 = Array(s2)
        let m = a1.count
        let n = a2.count

        var previousRow = Array(0...n)
        var currentRow = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            currentRow[0] = i
            for j in 1...n {
                if a1[i - 1] == a2[j - 1] {
                    currentRow[j] = previousRow[j - 1]
                } else {
                    currentRow[j] = 1 + min(
                        previousRow[j],     // deletion
                        currentRow[j - 1],  // insertion
                        previousRow[j - 1]  // substitution
                    )
                }
            }
            previousRow = currentRow
        }

        return previousRow[n]
    }

    // MARK: - Similarity Ratio

    /// Computes the normalized similarity ratio between two strings from 0.0 to 1.0.
    ///
    /// Formula: `1.0 - (levenshteinDistance(s1, s2) / max(len(s1), len(s2)))`
    ///
    /// - Parameters:
    ///   - s1: First string.
    ///   - s2: Second string.
    /// - Returns: Similarity ratio between 0.0 (completely dissimilar) and 1.0 (exact match).
    public static func similarityRatio(_ s1: String, _ s2: String) -> Double {
        if s1 == s2 { return 1.0 }
        let maxLen = max(s1.count, s2.count)
        guard maxLen > 0 else { return 1.0 }

        let distance = levenshteinDistance(s1, s2)
        let ratio = 1.0 - (Double(distance) / Double(maxLen))
        return max(0.0, min(1.0, ratio))
    }

    // MARK: - Evaluation

    /// Evaluates spoken speech against a target sentence using normalized token sequence alignment.
    ///
    /// - Parameters:
    ///   - spokenText: Raw transcription from speech recognition.
    ///   - targetSentence: Expected target sentence.
    ///   - passThreshold: Tolerance threshold for reflex success (default 0.75).
    ///   - durationMs: Recorded duration in milliseconds.
    /// - Returns: `SpeechEvaluationResult` containing detailed token breakdowns, overall percentage score, and pass flag.
    public static func evaluate(
        spokenText: String,
        targetSentence: String,
        passThreshold: Double = 0.75,
        durationMs: Int = 0
    ) -> SpeechEvaluationResult {
        let targetTokens = StringNormalizer.tokenize(targetSentence)
        let spokenTokens = StringNormalizer.tokenize(spokenText)

        guard !targetTokens.isEmpty else {
            return SpeechEvaluationResult(
                targetSentence: targetSentence,
                spokenText: spokenText,
                tokens: [],
                overallScore: 0.0,
                isPassed: false,
                durationMs: durationMs
            )
        }

        let tokens = SequenceAligner.align(
            targetTokens: targetTokens,
            spokenTokens: spokenTokens,
            fuzzyThreshold: passThreshold
        )

        let totalScore = tokens.reduce(0.0) { sum, token in
            sum + token.similarityScore
        }
        let overallScore = (totalScore / Double(targetTokens.count)) * 100.0
        let isPassed = (overallScore / 100.0) >= (passThreshold - 1e-6)

        return SpeechEvaluationResult(
            targetSentence: targetSentence,
            spokenText: spokenText,
            tokens: tokens,
            overallScore: overallScore,
            isPassed: isPassed,
            durationMs: durationMs
        )
    }
}
