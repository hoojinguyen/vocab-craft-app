import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Speaking analysis validator")
struct SpeakingAnalysisValidatorTests {
    @Test func curlyApostropheQuoteStillMatches() throws {
        let result = try validate("analysis-curly-apostrophe")
        #expect(result.corrections.count == 1)
        #expect(result.targetWords.first?.used == true)
    }

    @Test func fabricatedQuoteIsDropped() throws {
        let result = try validate("analysis-fabricated-quote")
        #expect(result.corrections.count == 1)
        #expect(result.naturalPhrasings.count == 1)
    }

    @Test func scoreOutOfRangeThrows() throws {
        let raw = try analysis("analysis-score-out-of-range")
        #expect(throws: SpeakingAnalysisError.invalidResponse) {
            try SpeakingAnalysisValidator.validate(raw, plan: .fixture())
        }
    }

    @Test func capsAreEnforced() throws {
        let result = try validate("analysis-over-caps")
        #expect(result.corrections.count == 5)
        #expect(result.naturalPhrasings.count == 3)
        #expect(result.pronunciation.count == 3)
    }

    @Test func invalidTargetWordQuoteMarksUseFalseAndClearsQuote() throws {
        let raw = try analysis("analysis-curly-apostrophe")
        let corrupted = SpeakingAnalysis(
            learnerTranscript: raw.learnerTranscript,
            scores: raw.scores,
            corrections: raw.corrections,
            naturalPhrasings: raw.naturalPhrasings,
            pronunciation: raw.pronunciation,
            targetWords: [.init(lemma: "latte", used: true, usedCorrectly: true, quote: "I drank tea")],
            objective: raw.objective,
            summary: raw.summary
        )
        let result = try SpeakingAnalysisValidator.validate(corrupted, plan: .fixture(words: ["latte"]))
        let targetWord = try #require(result.targetWords.first)
        #expect(targetWord.lemma == "latte")
        #expect(!targetWord.used)
        #expect(!targetWord.usedCorrectly)
        #expect(targetWord.quote == nil)
    }

    @Test func targetWordsAreRemovedWhenPlanHasNone() throws {
        let result = try validate("analysis-curly-apostrophe", plan: .fixture())
        #expect(result.targetWords.isEmpty)
    }

    @Test func unrequestedTargetLemmaIsDropped() throws {
        let raw = try analysis("analysis-curly-apostrophe")
        let result = try SpeakingAnalysisValidator.validate(raw, plan: .fixture(words: ["coffee"]))
        let targetWord = try #require(result.targetWords.first)
        #expect(targetWord.lemma == "coffee")
        #expect(!targetWord.used)
        #expect(targetWord.quote == nil)
    }

    @Test func groundedQuoteWithoutRequestedLemmaDoesNotCountAsUse() throws {
        let raw = try analysis("analysis-curly-apostrophe")
        let ungroundedTarget = SpeakingAnalysis.TargetWordUse(
            lemma: "latte", used: true, usedCorrectly: true, quote: "I’m want a latte"
        )
        let modified = SpeakingAnalysis(
            learnerTranscript: raw.learnerTranscript,
            scores: raw.scores,
            corrections: raw.corrections,
            naturalPhrasings: raw.naturalPhrasings,
            pronunciation: raw.pronunciation,
            targetWords: [SpeakingAnalysis.TargetWordUse(
                lemma: ungroundedTarget.lemma, used: ungroundedTarget.used,
                usedCorrectly: ungroundedTarget.usedCorrectly, quote: "I’m want a"
            )],
            objective: raw.objective,
            summary: raw.summary
        )
        let result = try SpeakingAnalysisValidator.validate(modified, plan: .fixture(words: ["latte"]))
        let targetWord = try #require(result.targetWords.first)
        #expect(targetWord.lemma == "latte")
        #expect(!targetWord.used)
        #expect(!targetWord.usedCorrectly)
        #expect(targetWord.quote == nil)
    }

    private func validate(_ name: String, plan: SpeakingSessionPlan = .fixture(words: ["latte"])) throws -> SpeakingAnalysis {
        try SpeakingAnalysisValidator.validate(analysis(name), plan: plan)
    }

    private func analysis(_ name: String) throws -> SpeakingAnalysis {
        try JSONDecoder().decode(SpeakingAnalysis.self, from: SpeakingFixtures.data("\(name).json"))
    }
}
