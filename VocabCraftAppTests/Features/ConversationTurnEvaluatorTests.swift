import Testing
@testable import VocabCraftApp

@Suite("Conversation turn evaluator")
struct ConversationTurnEvaluatorTests {
    private let evaluator = ConversationTurnEvaluator()

    @Test("a complete sentence passes after normalization")
    func completeSentencePasses() {
        let result = evaluator.evaluate(
            transcript: "Yes, the deadline is Friday, so we'll collaborate closely!",
            target: "Yes. The deadline is Friday, so we will collaborate closely.",
            requiredTerms: ["deadline", "collaborate"]
        )

        #expect(result.isPassed)
    }

    @Test("a small recognition spelling error is tolerated")
    func fuzzySentencePasses() {
        let result = evaluator.evaluate(
            transcript: "A reliable test build by tomorrow afternon",
            target: "A reliable test build by tomorrow afternoon.",
            requiredTerms: ["reliable"]
        )

        #expect(result.isPassed)
    }

    @Test("contractions and expanded forms match correctly")
    func contractionsMatch() {
        let result = evaluator.evaluate(
            transcript: "I don't think we can't collaborate today",
            target: "I do not think we cannot collaborate today.",
            requiredTerms: ["collaborate"]
        )

        #expect(result.isPassed)
    }

    @Test("missing the start of a sentence fails")
    func missingStartFails() {
        let result = evaluator.evaluate(
            transcript: "prioritize the launch checklist today",
            target: "Could we prioritize the launch checklist today?",
            requiredTerms: ["prioritize"]
        )

        #expect(!result.isPassed)
        #expect(result.failure == .missingBoundary)
    }

    @Test("missing the end of a sentence fails")
    func missingEndFails() {
        let result = evaluator.evaluate(
            transcript: "Could we prioritize the launch checklist",
            target: "Could we prioritize the launch checklist today?",
            requiredTerms: ["prioritize"]
        )

        #expect(!result.isPassed)
        #expect(result.failure == .missingBoundary)
    }

    @Test("missing a required target word fails despite high sentence similarity")
    func missingRequiredTermFails() {
        let result = evaluator.evaluate(
            transcript: "Yes the deadline is Friday so we should work closely",
            target: "Yes. The deadline is Friday, so we should collaborate closely.",
            requiredTerms: ["deadline", "collaborate"]
        )

        #expect(!result.isPassed)
        #expect(result.failure == .missingRequiredTerm)
    }

    @Test("omitted target cannot pass even if similarity is high")
    func omittedTargetCannotPass() {
        let result = ConversationTurnEvaluator().evaluate(
            transcript: "We should closely today",
            target: "We should collaborate closely today",
            requiredTerms: ["collaborate"]
        )
        #expect(!result.isPassed)
    }

    @Test("adding or removing negation fails")
    func negationMismatchFails() {
        let removed = evaluator.evaluate(
            transcript: "We can finish the tests by Friday",
            target: "We cannot finish the tests by Friday.",
            requiredTerms: []
        )
        let added = evaluator.evaluate(
            transcript: "We cannot finish the tests by Friday",
            target: "We can finish the tests by Friday.",
            requiredTerms: []
        )

        #expect(!removed.isPassed)
        #expect(removed.failure == .negationMismatch)
        #expect(!added.isPassed)
        #expect(added.failure == .negationMismatch)
    }

    @Test("silence never passes")
    func silenceFails() {
        let result = evaluator.evaluate(
            transcript: "   ",
            target: "What is our next milestone?",
            requiredTerms: ["milestone"]
        )

        #expect(!result.isPassed)
        #expect(result.failure == .silence)
    }
}
