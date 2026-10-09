import Foundation

public struct TargetWordPromptResult: Sendable, Equatable {
    public let characterSpeech: String
    public let suggestedResponse: String
    public let targetWord: String

    public init(characterSpeech: String, suggestedResponse: String, targetWord: String) {
        self.characterSpeech = characterSpeech
        self.suggestedResponse = suggestedResponse
        self.targetWord = targetWord
    }
}

public struct TargetWordPrompter: Sendable {
    public static func generatePrompt(missingWords: [String], scenario: RoleplayScenario) -> TargetWordPromptResult? {
        guard let targetWord = missingWords.first(where: { word in
            scenario.targetWordIds.contains { $0.caseInsensitiveCompare(word) == .orderedSame }
        }) else {
            return nil
        }

        let normalized = targetWord.lowercased()

        switch scenario.topic {
        case .dining:
            return promptForDining(targetWord: targetWord, normalized: normalized)
        case .travel:
            return promptForTravel(targetWord: targetWord, normalized: normalized)
        case .interview, .workplace:
            return promptForWorkplace(targetWord: targetWord, normalized: normalized)
        case .dailyLife:
            return promptForDailyLife(targetWord: targetWord, normalized: normalized)
        }
    }

    private static func promptForDining(targetWord: String, normalized: String) -> TargetWordPromptResult {
        switch normalized {
        case "complimentary":
            return TargetWordPromptResult(
                characterSpeech: "Here is your drink! We also offer complimentary cookies today, would you like one?",
                suggestedResponse: "Yes, I would love a complimentary cookie, please!",
                targetWord: normalized
            )
        case "pastry":
            return TargetWordPromptResult(
                characterSpeech: "Coming right up! Would you like to add a fresh pastry to pair with your drink today?",
                suggestedResponse: "Yes, please add a fresh pastry.",
                targetWord: normalized
            )
        case "beverage":
            return TargetWordPromptResult(
                characterSpeech: "Should I prepare a delicious hot beverage for you as well?",
                suggestedResponse: "Yes, a warm beverage would be great.",
                targetWord: normalized
            )
        default:
            return TargetWordPromptResult(
                characterSpeech: "Would you like to try our \(targetWord) today?",
                suggestedResponse: "Yes, tell me more about the \(targetWord).",
                targetWord: normalized
            )
        }
    }

    private static func promptForTravel(targetWord: String, normalized: String) -> TargetWordPromptResult {
        switch normalized {
        case "amenities":
            return TargetWordPromptResult(
                characterSpeech: "Here is your keycard! Don't forget to check out our hotel amenities on the 5th floor.",
                suggestedResponse: "What time are the hotel amenities open?",
                targetWord: normalized
            )
        case "reservation":
            return TargetWordPromptResult(
                characterSpeech: "May I double check the name on your reservation?",
                suggestedResponse: "The reservation is under my full name.",
                targetWord: normalized
            )
        case "accommodate":
            return TargetWordPromptResult(
                characterSpeech: "Please let us know if there is anything else we can accommodate during your stay!",
                suggestedResponse: "Could you accommodate a late checkout tomorrow?",
                targetWord: normalized
            )
        default:
            return TargetWordPromptResult(
                characterSpeech: "Please let us know if you need assistance with \(targetWord).",
                suggestedResponse: "Thank you for the help with \(targetWord).",
                targetWord: normalized
            )
        }
    }

    private static func promptForWorkplace(targetWord: String, normalized: String) -> TargetWordPromptResult {
        switch normalized {
        case "collaborate":
            return TargetWordPromptResult(
                characterSpeech: "Could you tell me how you collaborate with teammates when facing tough deadlines?",
                suggestedResponse: "I actively collaborate with teammates to meet goals.",
                targetWord: normalized
            )
        case "innovative":
            return TargetWordPromptResult(
                characterSpeech: "Can you share an innovative approach you applied in your recent project?",
                suggestedResponse: "We implemented an innovative system to streamline work.",
                targetWord: normalized
            )
        default:
            return TargetWordPromptResult(
                characterSpeech: "How do you view \(targetWord) in your daily work?",
                suggestedResponse: "I value \(targetWord) in our project workflows.",
                targetWord: normalized
            )
        }
    }

    private static func promptForDailyLife(targetWord: String, normalized: String) -> TargetWordPromptResult {
        TargetWordPromptResult(
            characterSpeech: "What are your thoughts on \(targetWord)?",
            suggestedResponse: "I think \(targetWord) is very helpful.",
            targetWord: normalized
        )
    }
}
