import Foundation

/// Alignment engine that matches spoken tokens to target tokens using sequence alignment dynamic programming.
///
/// Designed to tolerate ESL accent variations, omitted words, and extraneous filler words ("um", "ah", "like")
/// without desynchronizing subsequent target word matching.
public enum SequenceAligner {

    /// Aligns spoken tokens against target tokens in left-to-right order.
    ///
    /// - Parameters:
    ///   - targetTokens: Array of normalized target word tokens.
    ///   - spokenTokens: Array of normalized spoken word tokens from speech recognition.
    ///   - fuzzyThreshold: Minimum similarity ratio to qualify as a fuzzy match (default 0.75).
    /// - Returns: Array of `WordTokenResult`, one for each target token in original order.
    public static func align(
        targetTokens: [String],
        spokenTokens: [String],
        fuzzyThreshold: Double = 0.75
    ) -> [WordTokenResult] {
        guard !targetTokens.isEmpty else { return [] }

        guard !spokenTokens.isEmpty else {
            return targetTokens.enumerated().map { index, word in
                WordTokenResult(
                    id: index,
                    targetWord: word,
                    spokenWord: nil,
                    status: .missing,
                    similarityScore: 0.0
                )
            }
        }

        let m = targetTokens.count
        let n = spokenTokens.count

        // Precompute similarity matrix between targetTokens and spokenTokens
        var simMatrix = Array(repeating: Array(repeating: 0.0, count: n), count: m)
        for i in 0..<m {
            for j in 0..<n {
                simMatrix[i][j] = FuzzySpeechMatcher.similarityRatio(targetTokens[i], spokenTokens[j])
            }
        }

        // DP table: dp[i][j] stores the maximum cumulative similarity score
        // aligning targetTokens[0..<i] with spokenTokens[0..<j]
        var dp = Array(repeating: Array(repeating: 0.0, count: n + 1), count: m + 1)

        for i in 1...m {
            for j in 1...n {
                var best = max(dp[i - 1][j], dp[i][j - 1])
                let sim = simMatrix[i - 1][j - 1]
                if sim >= fuzzyThreshold {
                    let matchScore = dp[i - 1][j - 1] + sim
                    if matchScore > best {
                        best = matchScore
                    }
                }
                dp[i][j] = best
            }
        }

        // Backtracking to find aligned pairs (targetIndex -> spokenIndex)
        var targetToSpoken: [Int: Int] = [:]
        var i = m
        var j = n

        while i > 0 && j > 0 {
            let sim = simMatrix[i - 1][j - 1]
            let matchScore = dp[i - 1][j - 1] + sim

            if sim >= fuzzyThreshold && abs(dp[i][j] - matchScore) < 1e-9 {
                // Matched targetTokens[i-1] with spokenTokens[j-1]
                targetToSpoken[i - 1] = j - 1
                i -= 1
                j -= 1
            } else if dp[i][j - 1] >= dp[i - 1][j] {
                // Spoken token j-1 was filler/extra or better skipped
                j -= 1
            } else {
                // Target token i-1 was missing/omitted
                i -= 1
            }
        }

        // Construct [WordTokenResult]
        return targetTokens.enumerated().map { index, targetWord in
            if let spokenIndex = targetToSpoken[index] {
                let spokenWord = spokenTokens[spokenIndex]
                let sim = simMatrix[index][spokenIndex]
                let status: WordMatchStatus = (sim >= 0.99) ? .exactMatch : .fuzzyMatch
                return WordTokenResult(
                    id: index,
                    targetWord: targetWord,
                    spokenWord: spokenWord,
                    status: status,
                    similarityScore: sim
                )
            } else {
                return WordTokenResult(
                    id: index,
                    targetWord: targetWord,
                    spokenWord: nil,
                    status: .missing,
                    similarityScore: 0.0
                )
            }
        }
    }
}
