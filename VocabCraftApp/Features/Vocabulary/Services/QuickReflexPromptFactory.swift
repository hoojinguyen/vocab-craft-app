import Foundation

public struct QuickReflexPromptFactory: Sendable {
    public init() {}

    public func makePrompts(for word: WordItem) -> QuickReflexPrompts {
        let firstLetter = String(word.lemma.prefix(1)).lowercased()
        let retrieve = QuickReflexStagePrompt(
            phase: .retrieve,
            promptText: word.definition,
            targetExpression: word.lemma,
            hints: [word.pos, firstLetter]
        )

        let vietnameseExample = word.exampleSentenceVi.trimmingCharacters(in: .whitespacesAndNewlines)
        let usePrompt = vietnameseExample.isEmpty
            ? AppStrings.Reflex.quickUsePrompt(word.lemma)
            : word.exampleSentenceVi
        let use = QuickReflexStagePrompt(
            phase: .useInSentence,
            promptText: usePrompt,
            targetExpression: word.lemma,
            hints: [],
            sentenceFrame: sentenceFrame(for: word.pos)
        )

        return QuickReflexPrompts(retrieve: retrieve, use: use)
    }

    private func sentenceFrame(for partOfSpeech: String) -> String {
        let normalizedPartOfSpeech = partOfSpeech.lowercased()
        if normalizedPartOfSpeech.contains("verb") {
            return AppStrings.Reflex.quickVerbSentenceFrame
        }
        if normalizedPartOfSpeech.contains("adverb") {
            return AppStrings.Reflex.quickAdverbSentenceFrame
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
