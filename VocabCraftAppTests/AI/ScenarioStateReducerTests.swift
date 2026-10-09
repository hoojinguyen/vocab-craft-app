import Foundation
import Testing
@testable import VocabCraftApp

@Suite("ScenarioStateReducer Tests")
struct ScenarioStateReducerTests {
    @Test("In-domain Wi-Fi inquiry transitions to inquiry state and does not charge money")
    func testInDomainWifiInquiry() {
        let result = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .inDomainInquiry(topic: .wifi),
            userUtterance: "Do you have wifi?",
            userTurnCount: 1,
            missingWords: ["beverage", "pastry"],
            scenario: RoleplayScenario.cafeMock
        )

        #expect(result.nextState == .dining(.inquiry))
        #expect(!result.characterReply.localizedCaseInsensitiveContains("$6.50"))
        #expect(result.characterReply.localizedCaseInsensitiveContains("wifi") || result.characterReply.localizedCaseInsensitiveContains("craftguest"))
        #expect(result.isConcluded == false)
    }

    @Test("Vietnamese speech returns in-character pedagogical nudge and keeps state")
    func testVietnamesePedagogicalNudge() {
        let result = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .nonEnglish(detectedText: "Cho tôi một ly cà phê"),
            userUtterance: "Cho tôi một ly cà phê",
            userTurnCount: 1,
            missingWords: ["beverage"],
            scenario: RoleplayScenario.cafeMock
        )

        #expect(result.nextState == .dining(.greeting))
        #expect(result.characterReply.contains("I only speak English here"))
        #expect(result.suggestedResponses.first?.contains("beverage") == true || result.suggestedResponses.first?.contains("coffee") == true)
        #expect(result.isConcluded == false)
    }

    @Test("Safety cap forces conclusion at turn 6")
    func testSafetyCapAtTurnSix() {
        let result = ScenarioStateReducer.reduce(
            currentState: .dining(.inquiry),
            intent: .generalStatement,
            userUtterance: "Tell me more",
            userTurnCount: 6,
            missingWords: [],
            scenario: RoleplayScenario.cafeMock
        )

        #expect(result.isConcluded == true)
        #expect(result.nextState.isCompleted == true)
    }

    @Test("Explicit closing intent triggers completion when user turn count is 2 or more")
    func testExplicitClosingIntent() {
        let resultConcluded = ScenarioStateReducer.reduce(
            currentState: .dining(.customizing),
            intent: .closing,
            userUtterance: "Thank you, goodbye!",
            userTurnCount: 2,
            missingWords: [],
            scenario: RoleplayScenario.cafeMock
        )

        #expect(resultConcluded.isConcluded == true)
        #expect(resultConcluded.nextState == .dining(.completed))

        let resultEarly = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .closing,
            userUtterance: "Bye",
            userTurnCount: 1,
            missingWords: [],
            scenario: RoleplayScenario.cafeMock
        )

        // Turn count < 2 should not trigger immediate rule-2 conclusion
        #expect(resultEarly.isConcluded == false)
        #expect(resultEarly.nextState == .dining(.customizing))
    }

    @Test("Pedagogical nudge provides scenario-appropriate English suggestions for travel and interview")
    func testPedagogicalNudgeForOtherTopics() {
        let travelScenario = RoleplayScenarioCatalog.standardScenarios.first(where: { $0.topic == .travel })!
        let travelResult = ScenarioStateReducer.reduce(
            currentState: .travel(.greeting),
            intent: .nonEnglish(detectedText: "Tôi có phòng đặt trước"),
            userUtterance: "Tôi có phòng đặt trước",
            userTurnCount: 1,
            missingWords: ["reservation"],
            scenario: travelScenario
        )
        #expect(travelResult.nextState == .travel(.greeting))
        #expect(travelResult.characterReply.contains("I only speak English here"))
        #expect(travelResult.characterReply.contains("reservation"))
        #expect(travelResult.suggestedResponses.first?.contains("reservation") == true)

        let interviewScenario = RoleplayScenarioCatalog.standardScenarios.first(where: { $0.topic == .interview })!
        let interviewResult = ScenarioStateReducer.reduce(
            currentState: .interview(.greeting),
            intent: .nonEnglish(detectedText: "Dạ xin chào"),
            userUtterance: "Dạ xin chào",
            userTurnCount: 1,
            missingWords: ["collaborate"],
            scenario: interviewScenario
        )
        #expect(interviewResult.nextState == .interview(.greeting))
        #expect(interviewResult.characterReply.contains("I only speak English here"))
        #expect(interviewResult.characterReply.contains("experience"))
    }

    @Test("Dining flow progresses from greeting to customizing, payment, and completion")
    func testDiningFlowProgression() {
        let cafe = RoleplayScenario.cafeMock

        // Greeting -> Customizing
        let step1 = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .ordering,
            userUtterance: "I'd like a coffee",
            userTurnCount: 1,
            missingWords: ["beverage", "pastry"],
            scenario: cafe
        )
        #expect(step1.nextState == .dining(.customizing))
        #expect(step1.isConcluded == false)

        // Customizing -> Payment with missing words (prompts for missing word)
        let step2WithMissing = ScenarioStateReducer.reduce(
            currentState: .dining(.customizing),
            intent: .customizing,
            userUtterance: "I'll have it hot",
            userTurnCount: 2,
            missingWords: ["pastry"],
            scenario: cafe
        )
        #expect(step2WithMissing.nextState == .dining(.payment))
        #expect(step2WithMissing.characterReply.contains("$6.50"))
        #expect(step2WithMissing.characterReply.contains("pastry"))
        #expect(step2WithMissing.isConcluded == false)

        // Customizing -> Payment without missing words
        let step2NoMissing = ScenarioStateReducer.reduce(
            currentState: .dining(.customizing),
            intent: .customizing,
            userUtterance: "I'll take it hot",
            userTurnCount: 2,
            missingWords: [],
            scenario: cafe
        )
        #expect(step2NoMissing.nextState == .dining(.payment))
        #expect(step2NoMissing.characterReply.contains("$6.50"))
        #expect(step2NoMissing.isConcluded == false)

        // Payment -> Completed
        let step3 = ScenarioStateReducer.reduce(
            currentState: .dining(.payment),
            intent: .paymentAction,
            userUtterance: "Here is my card",
            userTurnCount: 3,
            missingWords: [],
            scenario: cafe
        )
        #expect(step3.nextState == .dining(.completed))
        #expect(step3.isConcluded == true)

        // Already completed
        let step4 = ScenarioStateReducer.reduce(
            currentState: .dining(.completed),
            intent: .generalStatement,
            userUtterance: "Goodbye",
            userTurnCount: 4,
            missingWords: [],
            scenario: cafe
        )
        #expect(step4.nextState == .dining(.completed))
        #expect(step4.isConcluded == true)
    }

    @Test("Dining in-domain inquiries cover opening hours, restroom, decaf, and recommendations")
    func testDiningInquiries() {
        let cafe = RoleplayScenario.cafeMock

        let hoursResult = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .inDomainInquiry(topic: .openingHours),
            userUtterance: "What time do you close?",
            userTurnCount: 1,
            missingWords: [],
            scenario: cafe
        )
        #expect(hoursResult.nextState == .dining(.inquiry))
        #expect(hoursResult.characterReply.contains("9 PM"))

        let restroomResult = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .inDomainInquiry(topic: .restroom),
            userUtterance: "Where is the restroom?",
            userTurnCount: 1,
            missingWords: [],
            scenario: cafe
        )
        #expect(restroomResult.nextState == .dining(.inquiry))
        #expect(restroomResult.characterReply.contains("restroom"))

        let decafResult = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .inDomainInquiry(topic: .decaf),
            userUtterance: "Do you have decaf espresso?",
            userTurnCount: 1,
            missingWords: [],
            scenario: cafe
        )
        #expect(decafResult.nextState == .dining(.inquiry))
        #expect(decafResult.characterReply.contains("decaf"))

        let recoResult = ScenarioStateReducer.reduce(
            currentState: .dining(.greeting),
            intent: .inDomainInquiry(topic: .recommendation),
            userUtterance: "What do you recommend?",
            userTurnCount: 1,
            missingWords: [],
            scenario: cafe
        )
        #expect(recoResult.nextState == .dining(.inquiry))
        #expect(recoResult.characterReply.contains("caramel latte"))
    }

    @Test("Travel flow progresses through ID verification, key handover, and completion")
    func testTravelFlowProgression() {
        let hotel = RoleplayScenarioCatalog.standardScenarios.first(where: { $0.topic == .travel })!

        // Greeting -> ID verification
        let step1 = ScenarioStateReducer.reduce(
            currentState: .travel(.greeting),
            intent: .generalStatement,
            userUtterance: "Hi, I have a reservation",
            userTurnCount: 1,
            missingWords: ["amenities"],
            scenario: hotel
        )
        #expect(step1.nextState == .travel(.idVerification))
        #expect(step1.characterReply.contains("passport"))
        #expect(step1.isConcluded == false)

        // ID verification -> Key handover with missing word prompt
        let step2WithMissing = ScenarioStateReducer.reduce(
            currentState: .travel(.idVerification),
            intent: .generalStatement,
            userUtterance: "Here is my passport",
            userTurnCount: 2,
            missingWords: ["amenities"],
            scenario: hotel
        )
        #expect(step2WithMissing.nextState == .travel(.keyHandover))
        #expect(step2WithMissing.characterReply.contains("keycard"))
        #expect(step2WithMissing.characterReply.contains("amenities"))
        #expect(step2WithMissing.isConcluded == false)

        // ID verification -> Key handover without missing words (intermediate reply does not contain terminal phrase)
        let step2WithoutMissing = ScenarioStateReducer.reduce(
            currentState: .travel(.idVerification),
            intent: .generalStatement,
            userUtterance: "Here is my passport",
            userTurnCount: 2,
            missingWords: [],
            scenario: hotel
        )
        #expect(step2WithoutMissing.nextState == .travel(.keyHandover))
        #expect(step2WithoutMissing.characterReply.contains("keycard"))
        #expect(!step2WithoutMissing.characterReply.localizedCaseInsensitiveContains("enjoy your stay"))
        #expect(!step2WithoutMissing.characterReply.localizedCaseInsensitiveContains("have a wonderful stay with us"))
        #expect(step2WithoutMissing.isConcluded == false)

        // Key handover -> Completed
        let step3 = ScenarioStateReducer.reduce(
            currentState: .travel(.keyHandover),
            intent: .generalStatement,
            userUtterance: "Thank you for the key",
            userTurnCount: 3,
            missingWords: [],
            scenario: hotel
        )
        #expect(step3.nextState == .travel(.completed))
        #expect(step3.isConcluded == true)
    }

    @Test("Interview flow progresses through behavioral challenge, candidate questions, and completion")
    func testInterviewFlowProgression() {
        let interview = RoleplayScenarioCatalog.standardScenarios.first(where: { $0.topic == .interview })!

        // Greeting -> Behavioral challenge with missing word prompt
        let step1 = ScenarioStateReducer.reduce(
            currentState: .interview(.greeting),
            intent: .generalStatement,
            userUtterance: "I worked as a lead engineer",
            userTurnCount: 1,
            missingWords: ["collaborate"],
            scenario: interview
        )
        #expect(step1.nextState == .interview(.behavioralChallenge))
        #expect(step1.characterReply.contains("collaborate"))
        #expect(step1.isConcluded == false)

        // Behavioral challenge -> Candidate questions
        let step2 = ScenarioStateReducer.reduce(
            currentState: .interview(.behavioralChallenge),
            intent: .generalStatement,
            userUtterance: "I collaborated closely with designers",
            userTurnCount: 2,
            missingWords: [],
            scenario: interview
        )
        #expect(step2.nextState == .interview(.candidateQuestions))
        #expect(step2.characterReply.contains("questions"))
        #expect(step2.isConcluded == false)

        // Candidate questions -> Completed
        let step3 = ScenarioStateReducer.reduce(
            currentState: .interview(.candidateQuestions),
            intent: .generalStatement,
            userUtterance: "What is your engineering culture?",
            userTurnCount: 3,
            missingWords: [],
            scenario: interview
        )
        #expect(step3.nextState == .interview(.completed))
        #expect(step3.isConcluded == true)
    }

    @Test("Daily life flow handles follow up and concludes after multiple turns")
    func testDailyLifeFlowProgression() {
        let dailyScenario = RoleplayScenario(
            id: "daily-chat",
            titleKey: "daily.title",
            descriptionKey: "daily.desc",
            topic: .dailyLife,
            difficulty: .beginner,
            characterName: "Sam",
            characterRole: "Neighbor",
            userRole: "Friend",
            initialGreeting: "How was your weekend?",
            targetWordIds: ["relaxing"],
            iconSymbol: "sun.max.fill"
        )

        let step1 = ScenarioStateReducer.reduce(
            currentState: .dailyLife(.greeting),
            intent: .generalStatement,
            userUtterance: "It was really nice and quiet.",
            userTurnCount: 1,
            missingWords: ["relaxing"],
            scenario: dailyScenario
        )
        #expect(step1.nextState == .dailyLife(.followUp))
        #expect(step1.isConcluded == false)

        let step2 = ScenarioStateReducer.reduce(
            currentState: .dailyLife(.followUp),
            intent: .generalStatement,
            userUtterance: "I went for a walk in the park.",
            userTurnCount: 2,
            missingWords: [],
            scenario: dailyScenario
        )
        #expect(step2.nextState == .dailyLife(.completed))
        #expect(step2.isConcluded == true)
    }

    @Test("inferCurrentState correctly determines state across scenarios and history lengths")
    func testInferCurrentState() {
        // Empty history
        #expect(ScenarioStateReducer.inferCurrentState(from: [], topic: .dining) == .dining(.greeting))
        #expect(ScenarioStateReducer.inferCurrentState(from: [], topic: .travel) == .travel(.greeting))
        #expect(ScenarioStateReducer.inferCurrentState(from: [], topic: .interview) == .interview(.greeting))
        #expect(ScenarioStateReducer.inferCurrentState(from: [], topic: .dailyLife) == .dailyLife(.greeting))

        // Completed AI message
        let completedHistory = [
            RoleplayMessage(sender: .character(name: "Alex"), text: "Thank you for visiting! Have a wonderful day!"),
            RoleplayMessage(sender: .user, text: "Thanks!")
        ]
        #expect(ScenarioStateReducer.inferCurrentState(from: completedHistory, topic: .dining) == .dining(.completed))

        let travelCompletedHistory = [
            RoleplayMessage(sender: .character(name: "David"), text: "Here are your keys, have a wonderful stay with us!"),
            RoleplayMessage(sender: .user, text: "Thanks!")
        ]
        #expect(ScenarioStateReducer.inferCurrentState(from: travelCompletedHistory, topic: .travel) == .travel(.completed))

        // Intermediate key handover AI message does not falsely classify as completed
        let travelIntermediateHistory = [
            RoleplayMessage(sender: .character(name: "David"), text: "Welcome!"),
            RoleplayMessage(sender: .user, text: "Here is my passport"),
            RoleplayMessage(sender: .character(name: "David"), text: "Thank you. Here is your keycard for room 402. Complimentary breakfast is served from 6:30 to 10 AM."),
            RoleplayMessage(sender: .user, text: "Where is the elevator?")
        ]
        #expect(ScenarioStateReducer.inferCurrentState(from: travelIntermediateHistory, topic: .travel) == .travel(.keyHandover))

        // Safety cap closures via phrase or turn cap count >= 6
        let safetyCapPhraseHistory = [
            RoleplayMessage(sender: .character(name: "Alex"), text: "It has been so wonderful chatting with you! I will get everything finalized for you now, have a fantastic day ahead!"),
            RoleplayMessage(sender: .user, text: "Thanks!")
        ]
        #expect(ScenarioStateReducer.inferCurrentState(from: safetyCapPhraseHistory, topic: .dining) == .dining(.completed))

        var sixTurnHistory: [RoleplayMessage] = []
        for i in 1...6 {
            sixTurnHistory.append(RoleplayMessage(sender: .character(name: "Alex"), text: "AI speech \(i)"))
            sixTurnHistory.append(RoleplayMessage(sender: .user, text: "User utterance \(i)"))
        }
        #expect(ScenarioStateReducer.inferCurrentState(from: sixTurnHistory, topic: .dining) == .dining(.completed))
        #expect(ScenarioStateReducer.inferCurrentState(from: sixTurnHistory, topic: .travel) == .travel(.completed))

        // History progress inference
        let oneTurnHistory = [
            RoleplayMessage(sender: .character(name: "Alex"), text: "Welcome!"),
            RoleplayMessage(sender: .user, text: "I'd like a latte")
        ]
        #expect(ScenarioStateReducer.inferCurrentState(from: oneTurnHistory, topic: .dining) == .dining(.customizing))
        #expect(ScenarioStateReducer.inferCurrentState(from: oneTurnHistory, topic: .travel) == .travel(.idVerification))
        #expect(ScenarioStateReducer.inferCurrentState(from: oneTurnHistory, topic: .interview) == .interview(.behavioralChallenge))
        #expect(ScenarioStateReducer.inferCurrentState(from: oneTurnHistory, topic: .dailyLife) == .dailyLife(.followUp))

        let twoTurnHistory = [
            RoleplayMessage(sender: .character(name: "Alex"), text: "Welcome!"),
            RoleplayMessage(sender: .user, text: "I'd like a latte"),
            RoleplayMessage(sender: .character(name: "Alex"), text: "Hot or iced?"),
            RoleplayMessage(sender: .user, text: "Hot please")
        ]
        #expect(ScenarioStateReducer.inferCurrentState(from: twoTurnHistory, topic: .dining) == .dining(.payment))
        #expect(ScenarioStateReducer.inferCurrentState(from: twoTurnHistory, topic: .travel) == .travel(.keyHandover))
        #expect(ScenarioStateReducer.inferCurrentState(from: twoTurnHistory, topic: .interview) == .interview(.candidateQuestions))
        #expect(ScenarioStateReducer.inferCurrentState(from: twoTurnHistory, topic: .dailyLife) == .dailyLife(.closing))
    }
}
