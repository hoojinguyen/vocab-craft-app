import Foundation
import Testing
@testable import VocabCraftApp

@Suite("VocabWidgetView")
struct VocabWidgetViewTests {
    @Test("maskedExample hides the lemma case-insensitively")
    func maskedExampleHidesLemma() {
        #expect(VocabWidgetView.maskedExample("I Run every day", lemma: "run") == "I _____ every day")
    }

    @Test("maskedExample leaves the example unchanged when the lemma is absent")
    func maskedExampleWithoutMatchIsUnchanged() {
        #expect(VocabWidgetView.maskedExample("She walks home", lemma: "run") == "She walks home")
    }
}
