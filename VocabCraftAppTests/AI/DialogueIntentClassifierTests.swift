import Foundation
import Testing
@testable import VocabCraftApp

@Suite("DialogueIntentClassifier Tests")
struct DialogueIntentClassifierTests {
    @Test("Detects Vietnamese text with diacritics as nonEnglish")
    func testDetectsVietnameseWithDiacritics() {
        let classifier = DialogueIntentClassifier()
        let intent = classifier.classify(utterance: "Cho tôi một ly cà phê và bánh ngọt", scenario: RoleplayScenario.cafeMock)
        if case .nonEnglish(let detected) = intent {
            #expect(!detected.isEmpty)
        } else {
            Issue.record("Expected .nonEnglish intent, got \(intent)")
        }
    }

    @Test("Detects common unaccented Vietnamese phrases as nonEnglish")
    func testDetectsUnaccentedVietnamese() {
        let classifier = DialogueIntentClassifier()
        let intent = classifier.classify(utterance: "cho toi mot ly ca phe", scenario: RoleplayScenario.cafeMock)
        if case .nonEnglish = intent {
            // Success
        } else {
            Issue.record("Expected .nonEnglish intent for unaccented Vietnamese, got \(intent)")
        }
    }

    @Test("Detects in-domain inquiries for Wi-Fi and opening hours")
    func testDetectsInDomainInquiries() {
        let classifier = DialogueIntentClassifier()
        let wifiIntent = classifier.classify(utterance: "Do you have free wifi here?", scenario: RoleplayScenario.cafeMock)
        #expect(wifiIntent == .inDomainInquiry(topic: .wifi))

        let hoursIntent = classifier.classify(utterance: "What time do you close tonight?", scenario: RoleplayScenario.cafeMock)
        #expect(hoursIntent == .inDomainInquiry(topic: .openingHours))
    }

    @Test("Detects ordering and closing phrases correctly")
    func testDetectsOrderingAndClosing() {
        let classifier = DialogueIntentClassifier()
        let orderIntent = classifier.classify(utterance: "I would like a beverage and a pastry please", scenario: RoleplayScenario.cafeMock)
        #expect(orderIntent == .ordering)

        let closeIntent = classifier.classify(utterance: "Thank you so much, that is all, bye!", scenario: RoleplayScenario.cafeMock)
        #expect(closeIntent == .closing)
    }

    @Test("Detects other in-domain inquiry topics")
    func testDetectsOtherInDomainInquiries() {
        let classifier = DialogueIntentClassifier()
        let restroomIntent = classifier.classify(utterance: "Where is the restroom?", scenario: RoleplayScenario.cafeMock)
        #expect(restroomIntent == .inDomainInquiry(topic: .restroom))

        let recommendIntent = classifier.classify(utterance: "What is your specialty or recommendation?", scenario: RoleplayScenario.cafeMock)
        #expect(recommendIntent == .inDomainInquiry(topic: .recommendation))

        let decafIntent = classifier.classify(utterance: "Can I get decaf coffee?", scenario: RoleplayScenario.cafeMock)
        #expect(decafIntent == .inDomainInquiry(topic: .decaf))

        let amenitiesIntent = classifier.classify(utterance: "Do you have pool amenities?", scenario: RoleplayScenario.cafeMock)
        #expect(amenitiesIntent == .inDomainInquiry(topic: .amenities))

        let breakfastIntent = classifier.classify(utterance: "Is breakfast served now?", scenario: RoleplayScenario.cafeMock)
        #expect(breakfastIntent == .inDomainInquiry(topic: .breakfast))
    }

    @Test("Detects payment, greeting, customizing, out of domain, and empty utterances")
    func testDetectsVariousIntents() {
        let classifier = DialogueIntentClassifier()

        let paymentIntent = classifier.classify(utterance: "Here is my card to pay", scenario: RoleplayScenario.cafeMock)
        #expect(paymentIntent == .paymentAction)

        let greetingIntent = classifier.classify(utterance: "hello there", scenario: RoleplayScenario.cafeMock)
        #expect(greetingIntent == .greeting)

        let customIntent = classifier.classify(utterance: "Make it iced and large", scenario: RoleplayScenario.cafeMock)
        #expect(customIntent == .customizing)

        let oodIntent = classifier.classify(utterance: "Who won the football match?", scenario: RoleplayScenario.cafeMock)
        #expect(oodIntent == .outOfDomainQuestion)

        let emptyIntent = classifier.classify(utterance: "   ", scenario: RoleplayScenario.cafeMock)
        #expect(emptyIntent == .generalStatement)

        let generalIntent = classifier.classify(utterance: "Sounds wonderful", scenario: RoleplayScenario.cafeMock)
        #expect(generalIntent == .generalStatement)
    }
}
