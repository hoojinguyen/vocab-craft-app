import Foundation
import Testing
@testable import VocabCraftApp

@Suite("WidgetPresentation")
struct WidgetPresentationTests {
    @Test(arguments: [
        (0, 0, 0.0, 0),
        (0, 5, 0.0, 0),
        (3, 2, 0.6, 3),
        (5, 0, 1.0, 5),
        (1, 2, 1.0 / 3.0, 2)
    ])
    func progress(practiced: Int, due: Int, fraction: Double, dots: Int) {
        let result = WidgetProgress.make(practiced: practiced, due: due)
        #expect(abs(result.fraction - fraction) < 0.0001)
        #expect(result.filledDots == dots)
        #expect(result.total == practiced + due)
    }

    @Test func progressClampsNegativeInputs() {
        let result = WidgetProgress.make(practiced: -3, due: 2)
        #expect(result.fraction == 0)
        #expect(result.filledDots == 0)
    }

    @Test func partOfSpeechMapsAllEightValues() {
        for raw in ["noun", "verb", "adjective", "adverb", "pronoun", "preposition", "conjunction", "determiner"] {
            #expect(WidgetPartOfSpeech.abbreviationKey(for: raw) == "app.widget.pos.\(raw)")
        }
    }

    @Test func partOfSpeechUnknownOrNilIsNil() {
        #expect(WidgetPartOfSpeech.abbreviationKey(for: "interjection") == nil)
        #expect(WidgetPartOfSpeech.abbreviationKey(for: "") == nil)
        #expect(WidgetPartOfSpeech.abbreviationKey(for: nil) == nil)
    }

    @Test func metaHidesEmptyParts() {
        let none = WidgetCardMeta.parts(partOfSpeech: nil, ipa: "")
        #expect(none.posKey == nil && none.ipa == nil)

        let blank = WidgetCardMeta.parts(partOfSpeech: nil, ipa: "  ")
        #expect(blank.posKey == nil && blank.ipa == nil)

        let posOnly = WidgetCardMeta.parts(partOfSpeech: "noun", ipa: "")
        #expect(posOnly.posKey == "app.widget.pos.noun" && posOnly.ipa == nil)

        let both = WidgetCardMeta.parts(partOfSpeech: "verb", ipa: "/rʌn/")
        #expect(both.posKey == "app.widget.pos.verb" && both.ipa == "/rʌn/")
    }

    @Test func footerHiddenWhenNothingPracticed() {
        #expect(WidgetProgress.showsPracticedFooter(0) == false)
        #expect(WidgetProgress.showsPracticedFooter(1) == true)
    }
}
