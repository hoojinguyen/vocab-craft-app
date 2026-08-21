import Foundation

public struct QuickReflexPromptFactory: Sendable {
    public init() {}

    public func makePrompts(for word: WordItem) -> QuickReflexPrompts {
        let firstLetter = String(word.lemma.prefix(1)).lowercased()
        let clozePrompt = Self.makeClozeSentence(lemma: word.lemma, sentence: word.exampleSentenceEn)
        let recallWordPromptText = clozePrompt ?? word.definition

        let recallWord = QuickReflexStagePrompt(
            phase: .recallWord,
            promptText: recallWordPromptText,
            targetExpression: word.lemma,
            hints: [word.pos, firstLetter].filter { !$0.isEmpty }
        )

        let collocation = CollocationExtractor.extract(for: word)
        let collocationVi = word.collocationVi?.trimmingCharacters(in: .whitespacesAndNewlines)
        let recallCollocationPromptText: String
        if let collocationVi, !collocationVi.isEmpty {
            recallCollocationPromptText = collocationVi
        } else {
            recallCollocationPromptText = word.definition
        }

        let recallCollocation = QuickReflexStagePrompt(
            phase: .recallCollocation,
            promptText: recallCollocationPromptText,
            targetExpression: collocation,
            hints: [word.pos, word.lemma].filter { !$0.isEmpty }
        )

        let vietnameseExample = word.exampleSentenceVi.trimmingCharacters(in: .whitespacesAndNewlines)
        let englishExample = word.exampleSentenceEn.trimmingCharacters(in: .whitespacesAndNewlines)
        let usePrompt: String
        if !vietnameseExample.isEmpty {
            usePrompt = vietnameseExample
        } else if !englishExample.isEmpty {
            usePrompt = AppStrings.Reflex.quickUsePromptFromExample(word.lemma, englishExample)
        } else {
            usePrompt = AppStrings.Reflex.quickUsePrompt(word.lemma)
        }

        let produceSentence = QuickReflexStagePrompt(
            phase: .produceSentence,
            promptText: usePrompt,
            targetExpression: word.lemma,
            hints: [],
            sentenceFrame: sentenceFrame(for: word.pos),
            modelAudioSentenceEn: !englishExample.isEmpty ? englishExample : nil
        )

        let modelSentence = !englishExample.isEmpty ? englishExample : word.lemma

        return QuickReflexPrompts(
            recallWord: recallWord,
            recallCollocation: recallCollocation,
            produceSentence: produceSentence,
            modelSentenceEn: modelSentence
        )
    }

    public static func makeClozeSentence(lemma: String, sentence: String) -> String? {
        let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLemma = lemma.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSentence.isEmpty, !trimmedLemma.isEmpty else { return nil }

        let pattern = "\\b" + NSRegularExpression.escapedPattern(for: trimmedLemma) + "\\b"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(location: 0, length: trimmedSentence.utf16.count)
            let matches = regex.matches(in: trimmedSentence, options: [], range: range)
            if !matches.isEmpty {
                return regex.stringByReplacingMatches(in: trimmedSentence, options: [], range: range, withTemplate: "[ ______ ]")
            }
        }

        if let range = trimmedSentence.range(of: trimmedLemma, options: .caseInsensitive) {
            var result = trimmedSentence
            result.replaceSubrange(range, with: "[ ______ ]")
            return result
        }

        return nil
    }

    private func sentenceFrame(for partOfSpeech: String) -> String {
        let normalizedPartOfSpeech = partOfSpeech.lowercased()
        if normalizedPartOfSpeech.contains("adverb") || normalizedPartOfSpeech.contains("adv") {
            return AppStrings.Reflex.quickAdverbSentenceFrame
        }
        if normalizedPartOfSpeech.contains("verb") || normalizedPartOfSpeech.contains("v.") {
            return AppStrings.Reflex.quickVerbSentenceFrame
        }
        if normalizedPartOfSpeech.contains("adjective") || normalizedPartOfSpeech.contains("adj") {
            return AppStrings.Reflex.quickAdjectiveSentenceFrame
        }
        if normalizedPartOfSpeech.contains("phrase") || normalizedPartOfSpeech.contains("idiom") {
            return AppStrings.Reflex.quickPhraseSentenceFrame
        }
        return AppStrings.Reflex.quickNounSentenceFrame
    }
}
