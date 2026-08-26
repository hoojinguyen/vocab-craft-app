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

        let targetCount = targetTokens.count
        let spokenCount = spokenTokens.count

        // Precompute similarity matrix between targetTokens and spokenTokens
        var simMatrix = Array(repeating: Array(repeating: 0.0, count: spokenCount), count: targetCount)
        for i in 0..<targetCount {
            for spokenCol in 0..<spokenCount {
                simMatrix[i][spokenCol] = FuzzySpeechMatcher.similarityRatio(targetTokens[i], spokenTokens[spokenCol])
            }
        }

        // DP table: dpTable[i][j] stores the maximum cumulative similarity score
        // aligning targetTokens[0..<i] with spokenTokens[0..<j]
        var dpTable = Array(repeating: Array(repeating: 0.0, count: spokenCount + 1), count: targetCount + 1)

        for i in 1...targetCount {
            for spokenIndex in 1...spokenCount {
                var best = max(dpTable[i - 1][spokenIndex], dpTable[i][spokenIndex - 1])
                let sim = simMatrix[i - 1][spokenIndex - 1]
                if sim >= fuzzyThreshold {
                    let matchScore = dpTable[i - 1][spokenIndex - 1] + sim
                    if matchScore > best {
                        best = matchScore
                    }
                }
                dpTable[i][spokenIndex] = best
            }
        }

        // Backtracking to find aligned pairs (targetIndex -> spokenIndex)
        var targetToSpoken: [Int: Int] = [:]
        var targetIdx = targetCount
        var spokenIdx = spokenCount

        while targetIdx > 0 && spokenIdx > 0 {
            let sim = simMatrix[targetIdx - 1][spokenIdx - 1]
            let matchScore = dpTable[targetIdx - 1][spokenIdx - 1] + sim

            if sim >= fuzzyThreshold && abs(dpTable[targetIdx][spokenIdx] - matchScore) < 1e-9 {
                // Matched targetTokens[targetIdx-1] with spokenTokens[spokenIdx-1]
                targetToSpoken[targetIdx - 1] = spokenIdx - 1
                targetIdx -= 1
                spokenIdx -= 1
            } else if dpTable[targetIdx][spokenIdx - 1] >= dpTable[targetIdx - 1][spokenIdx] {
                // Spoken token spokenIdx-1 was filler/extra or better skipped
                spokenIdx -= 1
            } else {
                // Target token targetIdx-1 was missing/omitted
                targetIdx -= 1
            }
        }

        // Construct [WordTokenResult]
        return targetTokens.enumerated().map { index, targetWord in
            if let spokenIndex = targetToSpoken[index] {
                let spokenWord = spokenTokens[spokenIndex]
                let sim = simMatrix[index][spokenIndex]
                let status: WordMatchStatus = (sim == 1.0 || targetWord == spokenWord) ? .exactMatch : .fuzzyMatch
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
