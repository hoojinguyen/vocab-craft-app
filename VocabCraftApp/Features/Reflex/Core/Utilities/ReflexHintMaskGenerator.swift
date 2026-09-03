import Foundation

public struct ReflexHintMaskGenerator: Sendable {
    private static let doubleConsonants = [
        "ll", "ss", "tt", "cc", "nn", "pp", "rr", "mm", "ff", "dd", "bb", "gg"
    ]
    private static let distinctiveDigraphs = [
        "ch", "sh", "th", "ph", "ng", "ck", "qu", "wh"
    ]
    private static let vowels: Set<Character> = ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]

    public static func generateStages(
        lemma: String,
        sentenceEn: String,
        pos: String = ""
    ) -> ReflexClozeStageSet {
        let cleanLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanLemma.isEmpty else {
            let empty = ClozeSentenceParts(prefix: sentenceEn, slot: "[ _________ ]", suffix: "")
            return ReflexClozeStageSet(
                initialParts: empty,
                lengthMaskedParts: empty,
                patternRevealedParts: empty,
                maskedWordString: "...",
                strategy: .shortWordPrefix
            )
        }

        // Generate length mask string: e.g. "_ _ _ _ _"
        let lengthMaskStr = formatLengthUnderscores(for: cleanLemma)
        let lengthSlotStr = "[ \(lengthMaskStr) ]"

        // Generate pattern mask strategy and string
        let (strategy, patternRevealedWord) = computePatternMask(for: cleanLemma)
        let patternSlotStr = "[ \(patternRevealedWord) ]"

        // Extract cloze sentence parts
        let formattedSentence = ReflexClozeFormatter.formatCloze(sentenceEn: sentenceEn, lemma: cleanLemma)
        let partsInitial = ReflexClozeFormatter.extractTemplateParts(from: formattedSentence)
            ?? ClozeSentenceParts(prefix: sentenceEn, slot: lengthSlotStr, suffix: "")

        let partsInitialStable = ClozeSentenceParts(
            prefix: partsInitial.prefix,
            slot: lengthSlotStr,
            suffix: partsInitial.suffix
        )
        let partsLength = ClozeSentenceParts(
            prefix: partsInitial.prefix,
            slot: lengthSlotStr,
            suffix: partsInitial.suffix
        )
        let partsPattern = ClozeSentenceParts(
            prefix: partsInitial.prefix,
            slot: patternSlotStr,
            suffix: partsInitial.suffix
        )

        return ReflexClozeStageSet(
            initialParts: partsInitialStable,
            lengthMaskedParts: partsLength,
            patternRevealedParts: partsPattern,
            maskedWordString: patternRevealedWord,
            strategy: strategy
        )
    }

    private static func formatLengthUnderscores(for text: String) -> String {
        text.map { char in
            char == " " ? "  " : "_"
        }.joined(separator: " ")
    }

    private static func computePatternMask(for lemma: String) -> (ReflexHintMaskStrategy, String) {
        let chars = Array(lemma)
        let count = chars.count

        if count <= 4 {
            let usePrefix = Bool.random()
            if usePrefix {
                let masked = chars.enumerated().map { index, char -> String in
                    if index == 0 { return String(char) }
                    return char == " " ? " " : "_"
                }
                return (.shortWordPrefix, masked.joined(separator: " "))
            } else {
                let masked = chars.enumerated().map { index, char -> String in
                    if index == count - 1 { return String(char) }
                    return char == " " ? " " : "_"
                }
                return (.shortWordSuffix, masked.joined(separator: " "))
            }
        }

        // Long words (>= 5): Check for middle cluster
        let lower = lemma.lowercased()
        let searchStartIndex = lower.index(after: lower.startIndex)
        let searchEndIndex = lower.endIndex
        for cluster in (doubleConsonants + distinctiveDigraphs) {
            if searchStartIndex < searchEndIndex,
               let range = lower.range(of: cluster, range: searchStartIndex..<searchEndIndex) {
                let startOffset = lower.distance(from: lower.startIndex, to: range.lowerBound)
                let endOffset = lower.distance(from: lower.startIndex, to: range.upperBound)

                // Must be an internal middle cluster (not starting at index 0 or ending at the very last letter)
                if startOffset > 0 && endOffset < count {
                    let rangeInt = startOffset..<endOffset
                    let masked = chars.enumerated().map { index, char -> String in
                        if rangeInt.contains(index) {
                            return String(char)
                        }
                        return char == " " ? " " : "_"
                    }.joined(separator: " ")
                    return (.middleCluster(text: cluster, range: rangeInt), masked)
                }
            }
        }

        // Fallback: Pick between prefix(2), suffix(2), or consonantScaffold
        let pick = Int.random(in: 0...2)
        switch pick {
        case 0:
            let masked = chars.enumerated().map { index, char -> String in
                if index < 2 { return String(char) }
                return char == " " ? " " : "_"
            }.joined(separator: " ")
            return (.prefix(count: 2), masked)

        case 1:
            let masked = chars.enumerated().map { index, char -> String in
                if index >= count - 2 { return String(char) }
                return char == " " ? " " : "_"
            }.joined(separator: " ")
            return (.suffix(count: 2), masked)

        default:
            let masked = chars.map { char -> String in
                if vowels.contains(char) {
                    return "_"
                }
                return String(char)
            }.joined(separator: " ")
            return (.consonantScaffold, masked)
        }
    }
}
