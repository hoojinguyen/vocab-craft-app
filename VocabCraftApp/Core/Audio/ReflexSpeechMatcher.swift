import Foundation
import SpeechKit

public enum ReflexSpeechMatcher {
    private static let allowedExtendedSuffixes: Set<String> = [
        "ing", "ed", "es", "s", "d", "ment", "tion", "ion", "ation"
    ]
    // Recognized inflectional suffixes after vowel drop (e.g. "hesitate" -> stem "hesitat" + "ing")
    // Vowel drop only occurs before vowel-initial suffixes ("ing", "ed", "tion", "ion", "ation")
    private static let allowedInflections: Set<String> = [
        "ing", "ed", "tion", "ion", "ation", "ment"
    ]
    private static let allowedYtoISuffixes: Set<String> = [
        "es", "ed", "er", "est", "ly", "ness", "ties", "fied", "able"
    ]

    /// Evaluates whether spoken text contains the target lemma or an acceptable phonetic / accent / inflection reflex match.
    public static func isReflexMatch(
        spokenText: String,
        targetLemma: String,
        toleranceThreshold: Double? = nil
    ) -> Bool {
        let normalizedTarget = StringNormalizer.normalize(targetLemma)
        guard !normalizedTarget.isEmpty, !spokenText.isEmpty else { return false }

        let tokens = StringNormalizer.tokenize(spokenText)
        guard !tokens.isEmpty else { return false }

        let targetTokens = StringNormalizer.tokenize(normalizedTarget)
        if targetTokens.count > 1 {
            return FuzzySpeechMatcher.evaluate(
                spokenText: spokenText,
                targetSentence: normalizedTarget,
                passThreshold: toleranceThreshold ?? 0.70
            ).isPassed
        }

        let targetLen = normalizedTarget.count
        for token in tokens {
            if token == normalizedTarget { return true }
            if matchesStemOrInflection(token: token, normalizedTarget: normalizedTarget, targetLen: targetLen) {
                return true
            }
            if matchesVowelDrop(token: token, normalizedTarget: normalizedTarget, targetLen: targetLen) {
                return true
            }
            if matchesYtoI(token: token, normalizedTarget: normalizedTarget, targetLen: targetLen) {
                return true
            }
            if matchesTieredFuzzy(token: token, normalizedTarget: normalizedTarget, targetLen: targetLen, toleranceThreshold: toleranceThreshold) {
                return true
            }
        }
        return false
    }

    private static func matchesStemOrInflection(token: String, normalizedTarget: String, targetLen: Int) -> Bool {
        guard targetLen >= 3, token.hasPrefix(normalizedTarget) else { return false }
        let suffix = String(token.dropFirst(targetLen))
        if targetLen >= 4 && allowedExtendedSuffixes.contains(suffix) { return true }
        // Handle c -> ck spelling transformation (e.g. "panic" -> "panicked", "panicking")
        if normalizedTarget.hasSuffix("c") && (suffix == "ked" || suffix == "king") {
            return true
        }
        if targetLen == 3 {
            if suffix == "s" { return true }
            if suffix == "es" {
                if let last = normalizedTarget.last, last == "s" || last == "x" || last == "z" {
                    return true
                }
                if normalizedTarget.hasSuffix("sh") || normalizedTarget.hasSuffix("ch") {
                    return true
                }
            }
            // 3-letter CVC monosyllables (e.g. "can", "pin", "run", "fit", "car") require consonant doubling.
            // Only non-CVC targets (ending in "x" or consonant clusters like "ask", "fix", "box") allow plain -ed/-ing/-d.
            let is3LetterCVC: Bool = {
                let chars = Array(normalizedTarget)
                guard chars.count == 3 else { return false }
                let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
                return vowels.contains(chars[1]) && !vowels.contains(chars[2]) && chars[2] != "x"
            }()
            if !is3LetterCVC && (suffix == "ed" || suffix == "ing" || suffix == "d") { return true }
        }
        if suffix.count >= 2, let last = normalizedTarget.last, suffix.first == last {
            let doubledSuffix = String(suffix.dropFirst())
            return allowedExtendedSuffixes.contains(doubledSuffix)
        }
        return false
    }

    private static func matchesVowelDrop(token: String, normalizedTarget: String, targetLen: Int) -> Bool {
        guard targetLen >= 3, normalizedTarget.hasSuffix("e") else { return false }
        let stemWithoutE = String(normalizedTarget.dropLast())
        guard token.hasPrefix(stemWithoutE) else { return false }
        let suffix = String(token.dropFirst(stemWithoutE.count))
        return allowedInflections.contains(suffix)
    }

    private static func matchesYtoI(token: String, normalizedTarget: String, targetLen: Int) -> Bool {
        guard targetLen >= 3, normalizedTarget.hasSuffix("y") else { return false }
        let chars = Array(normalizedTarget)
        let secondToLast = chars[targetLen - 2]
        let vowels: Set<Character> = ["a", "e", "i", "o", "u"]
        guard !vowels.contains(secondToLast) else { return false }

        let stem = String(normalizedTarget.dropLast())
        let stemWithI = stem + "i"
        guard token.hasPrefix(stemWithI) else { return false }
        let suffix = String(token.dropFirst(stemWithI.count))
        return allowedYtoISuffixes.contains(suffix)
    }

    private static func matchesTieredFuzzy(token: String, normalizedTarget: String, targetLen: Int, toleranceThreshold: Double?) -> Bool {
        if targetLen <= 4 || token.count <= 4 { return false }
        let threshold = toleranceThreshold ?? (targetLen <= 7 ? 0.80 : 0.70)
        return FuzzySpeechMatcher.similarityRatio(token, normalizedTarget) >= threshold
    }
}
