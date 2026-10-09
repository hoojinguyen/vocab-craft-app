import Foundation
import Testing
@testable import VocabCraftApp

@Suite("TargetWordPrompter Tests")
struct TargetWordPrompterTests {
    @Test("Prompts complimentary pastry when complimentary is missing in cafe")
    func testPromptsComplimentary() {
        let scenario = RoleplayScenario.cafeMock
        let prompt = TargetWordPrompter.generatePrompt(missingWords: ["complimentary"], scenario: scenario)

        #expect(prompt != nil)
        #expect(prompt?.characterSpeech.localizedCaseInsensitiveContains("complimentary") == true)
        #expect(prompt?.suggestedResponse.localizedCaseInsensitiveContains("complimentary") == true)
        #expect(prompt?.targetWord == "complimentary")
    }

    @Test("Returns nil when no missing words remain")
    func testReturnsNilWhenAllWordsUsed() {
        let scenario = RoleplayScenario.cafeMock
        let prompt = TargetWordPrompter.generatePrompt(missingWords: [], scenario: scenario)
        #expect(prompt == nil)
    }

    @Test("Returns nil when missing words do not belong to scenario")
    func testReturnsNilWhenWordsDoNotBelongToScenario() {
        let scenario = RoleplayScenario.cafeMock
        let prompt = TargetWordPrompter.generatePrompt(missingWords: ["unrelatedWord", "randomWord"], scenario: scenario)
        #expect(prompt == nil)
    }

    @Test("Prompts for other dining words like pastry and beverage")
    func testPromptsOtherDiningWords() {
        let scenario = RoleplayScenario.cafeMock

        let pastryPrompt = TargetWordPrompter.generatePrompt(missingWords: ["pastry"], scenario: scenario)
        #expect(pastryPrompt != nil)
        #expect(pastryPrompt?.characterSpeech.localizedCaseInsensitiveContains("pastry") == true)
        #expect(pastryPrompt?.suggestedResponse.localizedCaseInsensitiveContains("pastry") == true)
        #expect(pastryPrompt?.targetWord == "pastry")

        let beveragePrompt = TargetWordPrompter.generatePrompt(missingWords: ["beverage"], scenario: scenario)
        #expect(beveragePrompt != nil)
        #expect(beveragePrompt?.characterSpeech.localizedCaseInsensitiveContains("beverage") == true)
        #expect(beveragePrompt?.suggestedResponse.localizedCaseInsensitiveContains("beverage") == true)
        #expect(beveragePrompt?.targetWord == "beverage")
    }

    @Test("Prompts for travel scenario words")
    func testPromptsTravelWords() {
        let travelScenario = RoleplayScenario(
            id: "travel-test",
            titleKey: "test",
            descriptionKey: "test",
            topic: .travel,
            difficulty: .intermediate,
            characterName: "David",
            characterRole: "Concierge",
            userRole: "Guest",
            initialGreeting: "Welcome",
            targetWordIds: ["amenities", "reservation", "accommodate", "luggage"],
            iconSymbol: "building.2.fill"
        )

        let amenitiesPrompt = TargetWordPrompter.generatePrompt(missingWords: ["amenities"], scenario: travelScenario)
        #expect(amenitiesPrompt != nil)
        #expect(amenitiesPrompt?.characterSpeech.localizedCaseInsensitiveContains("amenities") == true)
        #expect(amenitiesPrompt?.suggestedResponse.localizedCaseInsensitiveContains("amenities") == true)

        let reservationPrompt = TargetWordPrompter.generatePrompt(missingWords: ["reservation"], scenario: travelScenario)
        #expect(reservationPrompt != nil)
        #expect(reservationPrompt?.characterSpeech.localizedCaseInsensitiveContains("reservation") == true)
        #expect(reservationPrompt?.suggestedResponse.localizedCaseInsensitiveContains("reservation") == true)

        let accommodatePrompt = TargetWordPrompter.generatePrompt(missingWords: ["accommodate"], scenario: travelScenario)
        #expect(accommodatePrompt != nil)
        #expect(accommodatePrompt?.characterSpeech.localizedCaseInsensitiveContains("accommodate") == true)
        #expect(accommodatePrompt?.suggestedResponse.localizedCaseInsensitiveContains("accommodate") == true)

        let fallbackTravelPrompt = TargetWordPrompter.generatePrompt(missingWords: ["luggage"], scenario: travelScenario)
        #expect(fallbackTravelPrompt != nil)
        #expect(fallbackTravelPrompt?.characterSpeech.localizedCaseInsensitiveContains("luggage") == true)
    }

    @Test("Prompts for interview and workplace scenarios")
    func testPromptsInterviewWords() {
        let interviewScenario = RoleplayScenario(
            id: "interview-test",
            titleKey: "test",
            descriptionKey: "test",
            topic: .interview,
            difficulty: .advanced,
            characterName: "Interviewer",
            characterRole: "Manager",
            userRole: "Candidate",
            initialGreeting: "Welcome",
            targetWordIds: ["collaborate", "innovative", "leadership"],
            iconSymbol: "briefcase.fill"
        )

        let collaboratePrompt = TargetWordPrompter.generatePrompt(missingWords: ["collaborate"], scenario: interviewScenario)
        #expect(collaboratePrompt != nil)
        #expect(collaboratePrompt?.characterSpeech.localizedCaseInsensitiveContains("collaborate") == true)
        #expect(collaboratePrompt?.suggestedResponse.localizedCaseInsensitiveContains("collaborate") == true)

        let innovativePrompt = TargetWordPrompter.generatePrompt(missingWords: ["innovative"], scenario: interviewScenario)
        #expect(innovativePrompt != nil)
        #expect(innovativePrompt?.characterSpeech.localizedCaseInsensitiveContains("innovative") == true)
        #expect(innovativePrompt?.suggestedResponse.localizedCaseInsensitiveContains("innovative") == true)

        let fallbackWorkplacePrompt = TargetWordPrompter.generatePrompt(missingWords: ["leadership"], scenario: interviewScenario)
        #expect(fallbackWorkplacePrompt != nil)
        #expect(fallbackWorkplacePrompt?.characterSpeech.localizedCaseInsensitiveContains("leadership") == true)
    }

    @Test("Prompts for daily life topic and matches case-insensitively")
    func testDailyLifeAndCaseInsensitivity() {
        let dailyLifeScenario = RoleplayScenario(
            id: "daily-life-test",
            titleKey: "test",
            descriptionKey: "test",
            topic: .dailyLife,
            difficulty: .beginner,
            characterName: "Neighbor",
            characterRole: "Friend",
            userRole: "Neighbor",
            initialGreeting: "Good morning",
            targetWordIds: ["neighborhood", "groceries"],
            iconSymbol: "house.fill"
        )

        let dailyPrompt = TargetWordPrompter.generatePrompt(missingWords: ["Neighborhood"], scenario: dailyLifeScenario)
        #expect(dailyPrompt != nil)
        #expect(dailyPrompt?.characterSpeech == "What are your thoughts on neighborhood?")
        #expect(dailyPrompt?.suggestedResponse == "I think neighborhood is very helpful.")
        #expect(dailyPrompt?.targetWord == "neighborhood")

        let travelPrompt = TargetWordPrompter.generatePrompt(missingWords: ["LUGGAGE"], scenario: RoleplayScenario(
            id: "travel-cap",
            titleKey: "test",
            descriptionKey: "test",
            topic: .travel,
            difficulty: .beginner,
            characterName: "Agent",
            characterRole: "Agent",
            userRole: "Guest",
            initialGreeting: "Hi",
            targetWordIds: ["luggage"],
            iconSymbol: "bag"
        ))
        #expect(travelPrompt?.characterSpeech == "Please let us know if you need assistance with luggage.")
        #expect(travelPrompt?.suggestedResponse == "Thank you for the help with luggage.")
    }
}
