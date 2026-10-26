import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("VocabWidgetView")
struct VocabWidgetViewTests {
    @Test("maskedExample hides the lemma case-insensitively")
    func maskedExampleHidesLemma() {
        #expect(MaskedExampleText.maskedExample("I Run every day", lemma: "run") == "I _____ every day")
    }

    @Test("maskedExample leaves the example unchanged when the lemma is absent")
    func maskedExampleWithoutMatchIsUnchanged() {
        #expect(MaskedExampleText.maskedExample("She walks home", lemma: "run") == "She walks home")
    }

    @Test("maskedAttributed highlights every occurrence")
    func maskedAttributedHighlightsEveryOccurrence() {
        let result = MaskedExampleText.maskedAttributed("Run, run! She runs.", lemma: "run", highlight: .red)
        #expect(String(result.characters) == "_____, _____! She _____s.")
        #expect(result.runs.filter { $0.backgroundColor != nil }.count == 3)
    }

    @Test("maskedAttributed without a match has no highlight")
    func maskedAttributedWithoutMatchHasNoHighlight() {
        let result = MaskedExampleText.maskedAttributed("She walks home", lemma: "run", highlight: .red)
        #expect(String(result.characters) == "She walks home")
        #expect(result.runs.filter { $0.backgroundColor != nil }.isEmpty)
    }

    @Test("maskedAttributed with an empty lemma returns the example")
    func maskedAttributedEmptyLemma() {
        let result = MaskedExampleText.maskedAttributed("She walks home", lemma: "", highlight: .red)
        #expect(String(result.characters) == "She walks home")
    }

    @Test("VoiceOver text replaces the lemma with the spoken blank, never the answer")
    func accessibilityTextNeverContainsLemma() {
        let spoken = MaskedExampleText.accessibilityText("Run, run! She runs.", lemma: "run", blank: "blank")
        #expect(spoken == "blank, blank! She blanks.")
        #expect(!spoken.lowercased().contains("run"))
    }
}
