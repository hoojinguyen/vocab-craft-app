import Foundation

public struct ScenarioTurnResult: Sendable, Equatable {
    public let nextState: ScenarioDialogueState
    public let characterReply: String
    public let suggestedResponses: [String]
    public let isConcluded: Bool

    public init(
        nextState: ScenarioDialogueState,
        characterReply: String,
        suggestedResponses: [String],
        isConcluded: Bool
    ) {
        self.nextState = nextState
        self.characterReply = characterReply
        self.suggestedResponses = suggestedResponses
        self.isConcluded = isConcluded
    }
}

public struct ScenarioStateReducer: Sendable {
    public static let maxSafetyTurns: Int = 6

    public static func inferCurrentState(
        from history: [RoleplayMessage],
        topic: RoleplayTopic
    ) -> ScenarioDialogueState {
        let userTurns = history.filter { $0.sender == .user }
        guard !userTurns.isEmpty else {
            return initialGreetingState(for: topic)
        }

        if userTurns.count >= maxSafetyTurns {
            return completedState(for: topic)
        }

        if hasCompletedCharacterMessage(in: history) {
            return completedState(for: topic)
        }

        let nonAdvancingTurns = history.filter { msg in
            if case .character = msg.sender {
                return msg.text.contains("CraftGuest") ||
                       msg.text.contains("open until 9 PM") ||
                       msg.text.contains("I only speak English here") ||
                       msg.text.contains("restroom is right down")
            }
            return false
        }.count
        let effectiveCount = max(0, userTurns.count - nonAdvancingTurns)

        return progressedState(for: topic, userTurnCount: effectiveCount)
    }

    private static func initialGreetingState(for topic: RoleplayTopic) -> ScenarioDialogueState {
        switch topic {
        case .dining: return .dining(.greeting)
        case .travel: return .travel(.greeting)
        case .interview, .workplace: return .interview(.greeting)
        case .dailyLife: return .dailyLife(.greeting)
        }
    }

    private static func completedState(for topic: RoleplayTopic) -> ScenarioDialogueState {
        switch topic {
        case .dining: return .dining(.completed)
        case .travel: return .travel(.completed)
        case .interview, .workplace: return .interview(.completed)
        case .dailyLife: return .dailyLife(.completed)
        }
    }

    private static func hasCompletedCharacterMessage(in history: [RoleplayMessage]) -> Bool {
        guard let lastAi = history.last(where: { msg in
            if case .character = msg.sender { return true }
            return false
        }) else {
            return false
        }

        return lastAi.text.localizedCaseInsensitiveContains("have a wonderful day") ||
               lastAi.text.localizedCaseInsensitiveContains("have a wonderful stay with us") ||
               lastAi.text.localizedCaseInsensitiveContains("have a fantastic day") ||
               lastAi.text.localizedCaseInsensitiveContains("follow up soon")
    }

    private static func progressedState(for topic: RoleplayTopic, userTurnCount count: Int) -> ScenarioDialogueState {
        switch topic {
        case .dining:
            if count == 1 { return .dining(.customizing) }
            if count >= 2 { return .dining(.payment) }
            return .dining(.greeting)
        case .travel:
            if count == 1 { return .travel(.idVerification) }
            if count >= 2 { return .travel(.keyHandover) }
            return .travel(.greeting)
        case .interview, .workplace:
            if count == 1 { return .interview(.behavioralChallenge) }
            if count >= 2 { return .interview(.candidateQuestions) }
            return .interview(.greeting)
        case .dailyLife:
            if count == 1 { return .dailyLife(.followUp) }
            if count >= 2 { return .dailyLife(.closing) }
            return .dailyLife(.greeting)
        }
    }

    // swiftlint:disable:next function_parameter_count
    public static func reduce(
        currentState: ScenarioDialogueState,
        intent: UserIntent,
        userUtterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        // Rule 1: Safety Cap check
        if userTurnCount >= maxSafetyTurns {
            let reply = "It has been so wonderful chatting with you! I will get everything finalized for you now, have a fantastic day ahead!"
            return ScenarioTurnResult(
                nextState: completedState(for: scenario.topic),
                characterReply: reply,
                suggestedResponses: ["Thank you so much, goodbye!", "Have a great day!", "Take care!"],
                isConcluded: true
            )
        }

        // Rule 2: Explicit closing intent from user
        if intent == .closing && userTurnCount >= 2 {
            let reply = "Thank you so much! Here is your receipt and everything you need. Have a wonderful day!"
            return ScenarioTurnResult(
                nextState: completedState(for: scenario.topic),
                characterReply: reply,
                suggestedResponses: ["Thanks so much, goodbye!", "Have a great day!", "See you next time!"],
                isConcluded: true
            )
        }

        // Rule 3: Non-English (Vietnamese) pedagogical nudge
        if case .nonEnglish = intent {
            return pedagogicalNudgeTurnResult(for: currentState, scenario: scenario)
        }

        // Rule 4: Topic-specific transitions
        switch currentState {
        case .dining(let diningState):
            return reduceDining(
                state: diningState,
                intent: intent,
                utterance: userUtterance,
                userTurnCount: userTurnCount,
                missingWords: missingWords,
                scenario: scenario
            )
        case .travel(let travelState):
            return reduceTravel(
                state: travelState,
                intent: intent,
                utterance: userUtterance,
                userTurnCount: userTurnCount,
                missingWords: missingWords,
                scenario: scenario
            )
        case .interview(let interviewState):
            return reduceInterview(
                state: interviewState,
                intent: intent,
                utterance: userUtterance,
                userTurnCount: userTurnCount,
                missingWords: missingWords,
                scenario: scenario
            )
        case .dailyLife(let dailyState):
            return reduceDailyLife(
                state: dailyState,
                intent: intent,
                utterance: userUtterance,
                userTurnCount: userTurnCount,
                missingWords: missingWords,
                scenario: scenario
            )
        }
    }

    private static func pedagogicalNudgeTurnResult(
        for currentState: ScenarioDialogueState,
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        let recommendedPhrase: String
        if scenario.topic == .dining {
            recommendedPhrase = "Could I have a beverage and a pastry, please?"
        } else if scenario.topic == .travel {
            recommendedPhrase = "I have a reservation under my name, please."
        } else {
            recommendedPhrase = "I would like to share my experience on this project."
        }
        let reply = "I only speak English here, but I'd love to help! You can say: '\(recommendedPhrase)'"
        let suggestions = [
            recommendedPhrase,
            "Could you recommend something for me?",
            "Sorry, could you help me in English?"
        ]
        return ScenarioTurnResult(
            nextState: currentState,
            characterReply: reply,
            suggestedResponses: suggestions,
            isConcluded: false
        )
    }

    // swiftlint:disable:next function_parameter_count
    private static func reduceDining(
        state: DiningState,
        intent: UserIntent,
        utterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        if case .inDomainInquiry(let topic) = intent {
            return reduceDiningInquiry(topic: topic)
        }

        switch state {
        case .greeting, .inquiry, .ordering:
            let reply = "Great choice! Would you like your beverage hot or iced? And should I warm up the pastry for you?"
            return ScenarioTurnResult(
                nextState: .dining(.customizing),
                characterReply: reply,
                suggestedResponses: [
                    "I'd prefer it hot, and please warm the pastry.",
                    "Iced beverage, please.",
                    "Could I get that to go?"
                ],
                isConcluded: false
            )

        case .customizing:
            if let wordPrompt = TargetWordPrompter.generatePrompt(missingWords: missingWords, scenario: scenario) {
                return ScenarioTurnResult(
                    nextState: .dining(.payment),
                    characterReply: "Coming right up! That will be $6.50. " + wordPrompt.characterSpeech,
                    suggestedResponses: [
                        wordPrompt.suggestedResponse,
                        "Here is my card to tap.",
                        "Just the drink is fine, thanks!"
                    ],
                    isConcluded: false
                )
            } else {
                return ScenarioTurnResult(
                    nextState: .dining(.payment),
                    characterReply: "Coming right up! That will be $6.50. You can tap your card right on the reader.",
                    suggestedResponses: [
                        "Here is my card to tap.",
                        "Could I also have a receipt, please?",
                        "Keep the change, have a great day!"
                    ],
                    isConcluded: false
                )
            }

        case .payment:
            return ScenarioTurnResult(
                nextState: .dining(.completed),
                characterReply: "All set! Here is your receipt and your fresh order. Thank you for visiting Craft Cafe, have a wonderful day!",
                suggestedResponses: [
                    "Thank you so much, have a great day!",
                    "Thanks, goodbye!",
                    "See you next time!"
                ],
                isConcluded: true
            )

        case .completed:
            return ScenarioTurnResult(
                nextState: .dining(.completed),
                characterReply: "Have a wonderful day, goodbye!",
                suggestedResponses: ["Goodbye!"],
                isConcluded: true
            )
        }
    }

    private static func reduceDiningInquiry(topic: InDomainTopic) -> ScenarioTurnResult {
        let reply: String
        switch topic {
        case .wifi:
            reply = "Our Wi-Fi is CraftGuest with no password needed! What delicious drink can I get started for you while you connect?"
        case .openingHours:
            reply = "We're open until 9 PM every day! What can I prepare for you today?"
        case .restroom:
            reply = "The restroom is right down the hallway on the left! What drink or snack can I get started for you first?"
        case .decaf:
            reply = "Yes, all our espresso beverages can be prepared decaf! Would you like a decaf latte or americano?"
        case .recommendation, .amenities, .breakfast:
            reply = "Our hot caramel latte and fresh almond pastries are our customer favorites! Would you like to try one?"
        }
        return ScenarioTurnResult(
            nextState: .dining(.inquiry),
            characterReply: reply,
            suggestedResponses: [
                "I'd like a caramel beverage and a pastry.",
                "Do you have any decaf options?",
                "That sounds wonderful, thank you!"
            ],
            isConcluded: false
        )
    }

    // swiftlint:disable:next function_parameter_count
    private static func reduceTravel(
        state: TravelState,
        intent: UserIntent,
        utterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        switch state {
        case .greeting, .inquiry:
            return ScenarioTurnResult(
                nextState: .travel(.idVerification),
                characterReply: "Welcome! I found your reservation right here. May I please see your passport or ID card?",
                suggestedResponses: [
                    "Here is my passport and reservation details.",
                    "Could you confirm the reservation name?",
                    "Do you have room on a high floor?"
                ],
                isConcluded: false
            )
        case .reservationCheck, .idVerification:
            if let wordPrompt = TargetWordPrompter.generatePrompt(missingWords: missingWords, scenario: scenario) {
                return ScenarioTurnResult(
                    nextState: .travel(.keyHandover),
                    characterReply: "Thank you. Here is your keycard for room 402. " + wordPrompt.characterSpeech,
                    suggestedResponses: [
                        wordPrompt.suggestedResponse,
                        "Thank you for the keycard.",
                        "What time is checkout tomorrow?"
                    ],
                    isConcluded: false
                )
            } else {
                return ScenarioTurnResult(
                    nextState: .travel(.keyHandover),
                    characterReply: "Thank you. Here is your keycard for room 402. Complimentary breakfast is served from 6:30 to 10 AM.",
                    suggestedResponses: [
                        "Thank you, have a wonderful day!",
                        "Could you tell me where the elevator is?",
                        "Thanks for your help!"
                    ],
                    isConcluded: false
                )
            }
        case .keyHandover, .completed:
            return ScenarioTurnResult(
                nextState: .travel(.completed),
                characterReply: "You're all set! Don't hesitate to dial 0 if you need anything at all. Have a wonderful stay with us!",
                suggestedResponses: ["Thank you so much!", "Goodbye!"],
                isConcluded: true
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    private static func reduceInterview(
        state: InterviewState,
        intent: UserIntent,
        utterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        switch state {
        case .greeting, .experienceDiscussion:
            if let wordPrompt = TargetWordPrompter.generatePrompt(missingWords: missingWords, scenario: scenario) {
                return ScenarioTurnResult(
                    nextState: .interview(.behavioralChallenge),
                    characterReply: "Thank you for sharing that. " + wordPrompt.characterSpeech,
                    suggestedResponses: [
                        wordPrompt.suggestedResponse,
                        "I prioritize clear communication under deadlines.",
                        "I enjoy solving complex technical challenges."
                    ],
                    isConcluded: false
                )
            } else {
                return ScenarioTurnResult(
                    nextState: .interview(.behavioralChallenge),
                    characterReply: "That demonstrates excellent initiative. Could you tell me about a time you collaborated under a tight deadline?",
                    suggestedResponses: [
                        "I collaborated closely with the team to deliver on time.",
                        "We streamlined our tasks to meet the deadline.",
                        "Communication was key to our project success."
                    ],
                    isConcluded: false
                )
            }
        case .behavioralChallenge:
            return ScenarioTurnResult(
                nextState: .interview(.candidateQuestions),
                characterReply: "That is a great example of problem solving. Do you have any questions for us about the team or role?",
                suggestedResponses: [
                    "What does success look like in the first 90 days?",
                    "How does the team foster innovation?",
                    "Thank you, that covers my questions."
                ],
                isConcluded: false
            )
        case .candidateQuestions, .completed:
            return ScenarioTurnResult(
                nextState: .interview(.completed),
                characterReply: "Thank you for those insightful questions! We are very excited about your background and will follow up soon. Have a great day!",
                suggestedResponses: ["Thank you for your time, goodbye!", "I look forward to hearing from you!"],
                isConcluded: true
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    private static func reduceDailyLife(
        state: DailyLifeState,
        intent: UserIntent,
        utterance: String,
        userTurnCount: Int,
        missingWords: [String],
        scenario: RoleplayScenario
    ) -> ScenarioTurnResult {
        if userTurnCount <= 1 {
            return ScenarioTurnResult(
                nextState: .dailyLife(.followUp),
                characterReply: "That sounds very interesting! Could you tell me a little bit more about what you have in mind?",
                suggestedResponses: ["I was thinking about that yesterday.", "It really makes a big difference.", "What do you think?"],
                isConcluded: false
            )
        } else {
            return ScenarioTurnResult(
                nextState: .dailyLife(.completed),
                characterReply: "That covers everything wonderfully! Thank you for the great conversation, have a wonderful day!",
                suggestedResponses: ["Thank you, have a great day!", "See you soon!"],
                isConcluded: true
            )
        }
    }
}
