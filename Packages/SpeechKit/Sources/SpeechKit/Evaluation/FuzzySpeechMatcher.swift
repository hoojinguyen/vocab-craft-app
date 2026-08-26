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
    public static func levenshteinDistance(_ first: String, _ second: String) -> Int {
        if first == second { return 0 }
        if first.isEmpty { return second.count }
        if second.isEmpty { return first.count }

        let firstChars = Array(first)
        let secondChars = Array(second)
        let firstCount = firstChars.count
        let secondCount = secondChars.count

        var previousRow = Array(0...secondCount)
        var currentRow = Array(repeating: 0, count: secondCount + 1)

        for i in 1...firstCount {
            currentRow[0] = i
            for targetIndex in 1...secondCount {
                if firstChars[i - 1] == secondChars[targetIndex - 1] {
                    currentRow[targetIndex] = previousRow[targetIndex - 1]
                } else {
                    currentRow[targetIndex] = 1 + min(
                        previousRow[targetIndex],     // deletion
                        currentRow[targetIndex - 1],  // insertion
                        previousRow[targetIndex - 1]  // substitution
                    )
                }
            }
            previousRow = currentRow
        }

        return previousRow[secondCount]
    }

    // MARK: - Similarity Ratio

    /// Computes the normalized similarity ratio between two strings from 0.0 to 1.0.
    ///
    /// Formula: `1.0 - (levenshteinDistance(first, second) / max(len(first), len(second)))`
    ///
    /// - Parameters:
    ///   - first: First string.
    ///   - second: Second string.
    /// - Returns: Similarity ratio between 0.0 (completely dissimilar) and 1.0 (exact match).
    public static func similarityRatio(_ first: String, _ second: String) -> Double {
        if first == second { return 1.0 }
        let maxLen = max(first.count, second.count)
        guard maxLen > 0 else { return 1.0 }

        let distance = levenshteinDistance(first, second)
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
