import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("ReflexCoreUtilities Tests")
struct ReflexCoreUtilitiesTests {
    @Test("Cloze formatter creates template and extracts prefix/suffix")
    func testClozeFormatter() {
        let sentence = "Practice helps you improve your English skills."
        let formatted = ReflexClozeFormatter.formatCloze(sentenceEn: sentence, lemma: "improve")
        #expect(formatted.contains("[ _________ ]"))

        let parts = ReflexClozeFormatter.extractTemplateParts(from: formatted)
        #expect(parts != nil)
        #expect(parts?.prefix == "Practice helps you ")
        #expect(parts?.slot == "[ _________ ]")
        #expect(parts?.suffix == " your English skills.")
    }

    @Test("Cloze formatter handles case-insensitivity and empty inputs")
    func testClozeFormatterEdgeCases() {
        let sentence = "Ephemeral moments define life. Yes, EPHEMERAL."
        let formatted = ReflexClozeFormatter.formatCloze(sentenceEn: sentence, lemma: "ephemeral")
        #expect(formatted == "[ _________ ] moments define life. Yes, [ _________ ].")

        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "", lemma: "test") == "")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "Hello world", lemma: "") == "Hello world")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "Hello world", lemma: "   ") == "Hello world")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "The application crashed", lemma: "cat") == "The application crashed")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "This is a quiet place", lemma: "plant") == "This is a quiet place")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "She focuses on study", lemma: "focus") == "She [ _________ ] on study")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "She is creating art", lemma: "create") == "She is [ _________ ] art")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "He studied hard and tries again", lemma: "study") == "He [ _________ ] hard and tries again")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "The bus stopped suddenly", lemma: "stop") == "The bus [ _________ ] suddenly")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "I walk every day and I was walking yesterday", lemma: "walk") == "I [ _________ ] every day and I was [ _________ ] yesterday")
        #expect(ReflexClozeFormatter.formatCloze(sentenceEn: "He is an avid reader", lemma: "read") == "He is an avid reader")
    }

    @Test("Distractor generator creates 4 unique options including target")
    func testDistractorGenerator() {
        let options = ReflexDistractorGenerator.generateOptions(
            mode: .multipleChoice,
            targetLemma: "habit",
            targetDefinition: "Thói quen",
            pool: ReflexBlitzWordItem.defaultStarterWords
        )
        #expect(options.count == 4)
        #expect(options.filter { $0.isCorrect }.count == 1)
        #expect(options.first(where: { $0.isCorrect })?.text == "habit")

        let uniqueTexts = Set(options.map { $0.text })
        #expect(uniqueTexts.count == 4)
    }

    @Test("Distractor generator produces definition options for listening mode")
    func testDistractorGeneratorListeningMode() {
        let options = ReflexDistractorGenerator.generateOptions(
            mode: .listening,
            targetLemma: "habit",
            targetDefinition: "Thói quen",
            pool: ReflexBlitzWordItem.defaultStarterWords
        )
        #expect(options.count == 4)
        #expect(options.filter { $0.isCorrect }.count == 1)
        #expect(options.first(where: { $0.isCorrect })?.text == "Thói quen")

        let uniqueTexts = Set(options.map { $0.text })
        #expect(uniqueTexts.count == 4)
    }

    @Test("Distractor generator returns empty options for non-choice modes")
    func testDistractorGeneratorNonChoiceModes() {
        let speakingOptions = ReflexDistractorGenerator.generateOptions(
            mode: .speaking,
            targetLemma: "habit",
            targetDefinition: "Thói quen",
            pool: ReflexBlitzWordItem.defaultStarterWords
        )
        #expect(speakingOptions.isEmpty)

        let typingOptions = ReflexDistractorGenerator.generateOptions(
            mode: .typing,
            targetLemma: "habit",
            targetDefinition: "Thói quen",
            pool: ReflexBlitzWordItem.defaultStarterWords
        )
        #expect(typingOptions.isEmpty)
    }

    @Test("ReflexBlitzWordItem conforms to ReflexDrillable")
    func testWordItemDrillableConformance() {
        let item = ReflexBlitzWordItem(
            id: 1,
            lemma: "habit",
            pos: "n.",
            ipa: "/ˈhæb.ɪt/",
            definitionVi: "Thói quen",
            exampleSentenceEn: "Reading books is a great habit.",
            exampleSentenceVi: "Đọc sách là một thói quen tuyệt vời.",
            level: "B1"
        )

        let drillable: any ReflexDrillable = item
        #expect(drillable.lemma == "habit")
        #expect(drillable.cleanPos == "noun")
        #expect(drillable.cleanLevel == "B1")
        #expect(drillable.cleanInitialLetterHint == "h... • noun")
        #expect(drillable.audioResourceUrl == nil)
        #expect(drillable.clozeSentenceEn.contains("[ _________ ]"))
    }

    @Test("ReflexMode properties and time limits")
    func testReflexModeProperties() {
        #expect(ReflexMode.speaking.timeLimitSeconds == 6.0)
        #expect(ReflexMode.typing.timeLimitSeconds == 7.5)
        #expect(ReflexMode.multipleChoice.timeLimitSeconds == 4.5)
        #expect(ReflexMode.listening.timeLimitSeconds == 5.5)

        #expect(ReflexMode.allCases.count == 4)
        #expect(ReflexMode.speaking.id == "speaking")
        #expect(!ReflexMode.speaking.title.isEmpty)
        #expect(!ReflexMode.speaking.iconName.isEmpty)
        #expect(!ReflexMode.speaking.instructionPrompt.isEmpty)
    }

    @Test("ReflexSessionSummary calculations and speed rating")
    func testSessionSummaryCalculations() {
        let attempts = [
            ReflexBlitzAttempt(id: UUID(), wordId: 1, lemma: "ephemeral", responseTimeMs: 1500, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 2, lemma: "serendipity", responseTimeMs: 2200, usedHint: false, isCorrect: true, timestamp: Date()),
            ReflexBlitzAttempt(id: UUID(), wordId: 3, lemma: "ubiquitous", responseTimeMs: 6200, usedHint: true, isCorrect: false, timestamp: Date())
        ]

        let summary = ReflexSessionSummary.create(from: attempts, maxCombo: 2)
        #expect(summary.totalWords == 3)
        #expect(summary.correctWords == 2)
        #expect(summary.averageResponseTimeMs == 3300)
        #expect(summary.maxComboStreak == 2)
        #expect(summary.weakWordAttempts.count == 1)
        #expect(summary.weakWordAttempts.first?.lemma == "ubiquitous")
        #expect(summary.ratingTier == .steady)
        #expect(summary.speedRating.contains("rating_steady") || summary.speedRating.contains("Steady"))
    }
}
#endif
