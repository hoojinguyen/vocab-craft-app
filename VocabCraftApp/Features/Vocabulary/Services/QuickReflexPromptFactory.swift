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
            hints: [word.lemma]
        )

        return QuickReflexPrompts(retrieve: retrieve, use: use)
    }
}
