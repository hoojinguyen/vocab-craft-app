import Foundation

/// Intelligent offline mock LLM provider simulating contextual multi-turn roleplay conversations
/// and target word detection without network access or an API key.
public final class IntelligentMockLLMProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "intelligent_mock"

    public init() {}

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        let lastUserMessage = messages.last(where: { $0.role == .user })?.content ?? ""
        let lowercasedUser = lastUserMessage.lowercased()

        // 1. Extract Target Words dynamically from prompt/messages and user utterance
        let expectedWords = parseExpectedWords(systemPrompt: systemPrompt, messages: messages)
        let targetWordsUsed = extractTargetWords(from: lowercasedUser, expectedWords: expectedWords)

        // 2. Determine scenario context
        let userTurnCount = messages.filter({ $0.role == .user }).count
        let turn = determineDialogueTurn(
            lowercasedUser: lowercasedUser,
            systemPrompt: systemPrompt,
            userTurnCount: userTurnCount,
            expectedWords: expectedWords
        )

        let output = RoleplayTurnOutput(
            characterReply: turn.reply,
            targetWordsUsed: targetWordsUsed,
            refinementSuggestion: turn.refinement,
            pedagogicalNote: turn.tip,
            suggestedResponses: turn.suggestedResponses,
            isConcluded: turn.isConcluded
        )

        if let typedResult = output as? T {
            return typedResult
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Unsupported output schema for IntelligentMockLLMProvider")
        )
    }

    public func extractTargetWords(from text: String, expectedWords: [String] = []) -> [String] {
        let catalogTargetWords = [
            "beverage", "pastry", "complimentary", "reservation", "amenities", "accommodate",
            "collaborate", "collaborating", "collaboration", "innovative", "initiative",
            "espresso", "croissant", "recommendation", "decaf", "receipt",
            "experience", "strength", "deadline", "leadership", "passport", "checkout"
        ]
        let combined = Set(expectedWords.map { $0.lowercased() } + catalogTargetWords)
        return combined.filter { word in
            text.localizedStandardContains(word)
        }.sorted()
    }

    private func parseExpectedWords(systemPrompt: String, messages: [LLMChatMessage]) -> [String] {
        var expectedWords: [String] = []

        if let range = systemPrompt.range(of: "Target vocabulary for the user:") {
            let substring = systemPrompt[range.upperBound...]
            let line = substring.split(separator: "\n").first ?? ""
            expectedWords = line.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
            }.filter { !$0.isEmpty }
        } else if let range = systemPrompt.range(of: "Target words:") {
            let substring = systemPrompt[range.upperBound...]
            let line = substring.split(separator: "\n").first ?? ""
            expectedWords = line.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
            }.filter { !$0.isEmpty }
        }

        if expectedWords.isEmpty {
            for msg in messages where msg.role == .system {
                let text = msg.content
                if let range = text.range(of: "Target vocabulary for the user:") ?? text.range(of: "Target words:") {
                    let substring = text[range.upperBound...]
                    let line = substring.split(separator: "\n").first ?? ""
                    let words = line.split(separator: ",").map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".")))
                    }.filter { !$0.isEmpty }
                    expectedWords.append(contentsOf: words)
                }
            }
        }

        return expectedWords
    }

    private struct DialogueTurnContent {
        let reply: String
        let refinement: String?
        let tip: String?
        let suggestedResponses: [String]
        let isConcluded: Bool
    }

    private enum ScenarioType {
        case cafe
        case interview
        case hotel
        case fallback
    }

    private func detectScenario(
        lowercasedUser: String,
        lowercasedPrompt: String,
        expectedWords: [String]
    ) -> ScenarioType {
        let lowercasedExpected = expectedWords.map { $0.lowercased() }

        let isCafe = lowercasedUser.contains("espresso")
            || lowercasedUser.contains("coffee")
            || lowercasedUser.contains("croissant")
            || lowercasedUser.contains("beverage")
            || lowercasedUser.contains("pastry")
            || lowercasedUser.contains("decaf")
            || lowercasedUser.contains("receipt")
            || lowercasedPrompt.contains("barista")
            || lowercasedPrompt.contains("cafe")
            || lowercasedExpected.contains(where: {
                ["beverage", "pastry", "espresso", "croissant", "decaf", "coffee", "complimentary"].contains($0)
            })

        if isCafe { return .cafe }

        let isInterview = lowercasedUser.contains("interview")
            || lowercasedUser.contains("experience")
            || lowercasedUser.contains("strength")
            || lowercasedUser.contains("deadline")
            || lowercasedUser.contains("leadership")
            || lowercasedUser.contains("collaboration")
            || lowercasedUser.contains("collaborate")
            || lowercasedUser.contains("collaborating")
            || lowercasedUser.contains("innovative")
            || lowercasedUser.contains("initiative")
            || lowercasedPrompt.contains("hiring manager")
            || lowercasedPrompt.contains("interview")
            || lowercasedExpected.contains(where: {
                ["collaborate", "collaborating", "collaboration", "innovative", "initiative", "experience", "strength", "deadline", "leadership"].contains($0)
            })

        if isInterview { return .interview }

        let isHotel = lowercasedUser.contains("hotel")
            || lowercasedUser.contains("reservation")
            || lowercasedUser.contains("check in")
            || lowercasedUser.contains("check-in")
            || lowercasedUser.contains("passport")
            || lowercasedUser.contains("amenities")
            || lowercasedUser.contains("accommodate")
            || lowercasedPrompt.contains("hotel")
            || lowercasedPrompt.contains("concierge")
            || lowercasedPrompt.contains("front desk")
            || lowercasedExpected.contains(where: {
                ["reservation", "amenities", "accommodate", "passport", "checkout"].contains($0)
            })

        if isHotel { return .hotel }

        return .fallback
    }

    private func determineDialogueTurn(
        lowercasedUser: String,
        systemPrompt: String,
        userTurnCount: Int,
        expectedWords: [String] = []
    ) -> DialogueTurnContent {
        let lowercasedPrompt = systemPrompt.lowercased()
        let scenario = detectScenario(
            lowercasedUser: lowercasedUser,
            lowercasedPrompt: lowercasedPrompt,
            expectedWords: expectedWords
        )
        let suggestions = generateSuggestedResponses(
            scenario: scenario,
            userTurnCount: userTurnCount,
            expectedWords: expectedWords
        )

        switch scenario {
        case .cafe:
            if userTurnCount <= 1 {
                let reply = lowercasedUser.contains("pastry") || lowercasedUser.contains("beverage")
                    ? "Great choice! Would you like your beverage hot or iced? And should I warm up the pastry for you?"
                    : "Great choice! Would you like a single or double espresso? And should I warm up the croissant for you?"
                let refinement = "You could say: 'I'd like a double espresso and a warmed croissant, please.'"
                let tip = "In a cafe, specifying 'single or double shot' makes ordering seamless!"
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: false)
            } else if userTurnCount == 2 {
                let reply = "Coming right up! That will be $6.50. You can tap your card right on the reader. Have a wonderful day!"
                let refinement = "Native tip: 'Keep the change!' is common if paying cash."
                let tip = "Great job finishing your cafe order using your target vocabulary!"
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: false)
            } else {
                let reply = "All set! Here is your receipt and your fresh order. Thank you for visiting Craft Cafe, have a wonderful day!"
                let refinement = "Polite wrap-up: 'Thank you so much, have a great day!' is warm and natural."
                let tip = "Congratulations on completing your cafe ordering practice with all target vocabulary!"
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: true)
            }
        case .interview:
            if userTurnCount <= 1 {
                let reply = "Thank you for sharing that. Could you tell me about a time you handled a tight deadline or challenge?"
                let refinement = "Consider using the STAR method (Situation, Task, Action, Result) when answering."
                let tip = "Strong action verbs like 'managed', 'developed', and 'collaborated' elevate your response."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: false)
            } else if userTurnCount == 2 {
                let reply = "That demonstrates excellent leadership and problem-solving skills under pressure. Do you have any questions for us about the role or team?"
                let refinement = "Ask a thoughtful closing question like: 'What does success look like in the first 90 days?'"
                let tip = "Asking informed questions at the end of an interview reinforces your enthusiasm and preparation."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: false)
            } else {
                let reply = "Thank you for those insightful questions. We are very excited about your background and our team will follow up with next steps soon. Have a great day!"
                let refinement = "Closing strong: 'Thank you for your time, I look forward to hearing from you!'"
                let tip = "Great job finishing your interview roleplay with compelling communication!"
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: true)
            }
        case .hotel:
            if userTurnCount <= 1 {
                let reply = "I found your reservation right here. May I have your passport or ID card, please?"
                let refinement = "Try: 'I have a reservation under the name [Your Name].'"
                let tip = "'Under the name' is the standard polite phrasing for reservations."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: false)
            } else if userTurnCount == 2 {
                let reply = "Thank you. Here is your keycard for room 402. Complimentary breakfast and amenities like the pool are on the 5th floor. Enjoy your stay!"
                let refinement = "Polite inquiry: 'Could you tell me what time breakfast is served?'"
                let tip = "'Complimentary' means provided free of charge by the establishment."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: false)
            } else {
                let reply = "You're all set! Don't hesitate to dial 0 from your room if you need anything at all. Have a wonderful stay with us!"
                let refinement = "Courteous finish: 'Thank you for your help, have a great day!'"
                let tip = "Excellent work completing your hotel check-in roleplay!"
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: true)
            }
        case .fallback:
            if userTurnCount <= 1 {
                let reply = "That's very interesting! Could you elaborate more on that, or should we move to the next step?"
                let refinement = "Natural phrasing: 'Could you give me more details on that?'"
                let tip = "Keep speaking naturally. Notice how rhythm and intonation help convey meaning."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: false)
            } else if userTurnCount == 2 {
                let reply = "Great practice! Do you have any final thoughts or questions before we wrap up?"
                let refinement = "Wrap-up inquiry: 'Thank you, that covers everything!'"
                let tip = "Summarizing key points reinforces spoken vocabulary mastery."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: false)
            } else {
                let reply = "Excellent job practicing today! You've made wonderful progress with your vocabulary. Have a wonderful day!"
                let refinement = "Friendly sign-off: 'Thank you, see you next time!'"
                let tip = "Consistent short speaking sessions build long-term fluency."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip, suggestedResponses: suggestions, isConcluded: true)
            }
        }
    }

    private func generateSuggestedResponses(
        scenario: ScenarioType,
        userTurnCount: Int,
        expectedWords: [String]
    ) -> [String] {
        switch scenario {
        case .cafe:
            return cafeSuggestedResponses(userTurnCount: userTurnCount, expectedWords: expectedWords)
        case .interview:
            return interviewSuggestedResponses(userTurnCount: userTurnCount, expectedWords: expectedWords)
        case .hotel:
            return hotelSuggestedResponses(userTurnCount: userTurnCount, expectedWords: expectedWords)
        case .fallback:
            return fallbackSuggestedResponses(userTurnCount: userTurnCount, expectedWords: expectedWords)
        }
    }

    private func cafeSuggestedResponses(userTurnCount: Int, expectedWords: [String]) -> [String] {
        if userTurnCount >= 3 {
            return [
                "Thank you, have a wonderful day!",
                "Thanks so much, goodbye!"
            ]
        }
        guard userTurnCount <= 1 else {
            return [
                "Thank you so much! Could I also get a receipt, please?",
                "Here is my card to tap. Thanks for the recommendation!",
                "That sounds perfect, thank you and have a wonderful day!"
            ]
        }

        let lowercasedExpected = expectedWords.map { $0.lowercased() }
        if lowercasedExpected.contains("espresso") || lowercasedExpected.contains("croissant") {
            return [
                "I would like a single espresso and a fresh croissant, please.",
                "Could I get an espresso? Do you have any decaf recommendation?",
                "What snack would you recommend to pair with an espresso?"
            ]
        } else if lowercasedExpected.contains("beverage") || lowercasedExpected.contains("pastry") || lowercasedExpected.contains("complimentary") {
            return [
                "I'd like to order a warm beverage and a fresh pastry, please.",
                "Could I get an iced beverage? Do you offer any complimentary snacks?",
                "What pastry would you recommend to pair with a hot beverage?"
            ]
        } else if !expectedWords.isEmpty {
            let firstWord = expectedWords[0]
            let secondWord = expectedWords.indices.contains(1) ? expectedWords[1] : firstWord
            return [
                "I'd like to order a warm \(firstWord) and a fresh \(secondWord), please.",
                "Could I get a \(firstWord)? Do you offer any recommendations?",
                "What would you recommend to pair with my \(firstWord)?"
            ]
        } else {
            return [
                "I'd like to order a warm beverage and a fresh pastry, please.",
                "Could I get an iced beverage? Do you offer any complimentary snacks?",
                "What pastry would you recommend to pair with a hot coffee?"
            ]
        }
    }

    private func interviewSuggestedResponses(userTurnCount: Int, expectedWords: [String]) -> [String] {
        if userTurnCount >= 3 {
            return [
                "Thank you so much for your time, goodbye!",
                "Thank you, I look forward to hearing from you!"
            ]
        }
        guard userTurnCount <= 1 else {
            return [
                "What opportunities are there to collaborate cross-functionally across teams?",
                "How does the team foster initiative and support innovative ideas?",
                "What does success look like for this position in the first 90 days?"
            ]
        }

        let lowercasedExpected = expectedWords.map { $0.lowercased() }
        let matchesStandard = lowercasedExpected.contains(where: {
            $0.contains("collaborat") || $0.contains("innovat") || $0.contains("initiat") ||
            $0.contains("experience") || $0.contains("strength") || $0.contains("deadline") || $0.contains("leadership")
        })

        if matchesStandard || expectedWords.isEmpty {
            return [
                "In my previous experience, I took the initiative to collaborate on an innovative solution.",
                "I had to collaborate closely with my team under a tight deadline to deliver results.",
                "I demonstrated leadership by taking the initiative on an innovative project."
            ]
        } else {
            let firstWord = expectedWords[0]
            let secondWord = expectedWords.indices.contains(1) ? expectedWords[1] : firstWord
            return [
                "In my previous experience, I demonstrated strong \(firstWord) when facing challenges.",
                "I worked closely with my team under pressure to demonstrate \(secondWord).",
                "I focused on delivering measurable results by leveraging my background and \(firstWord)."
            ]
        }
    }

    private func hotelSuggestedResponses(userTurnCount: Int, expectedWords: [String]) -> [String] {
        if userTurnCount >= 3 {
            return [
                "Thank you so much, goodbye!",
                "Thanks for your help, have a wonderful day!"
            ]
        }
        guard userTurnCount <= 1 else {
            return [
                "Thank you! What time is the complimentary breakfast served in the morning?",
                "Could the front desk accommodate a late checkout tomorrow afternoon?",
                "Thank you so much, where can I access the gym and pool amenities?"
            ]
        }

        let lowercasedExpected = expectedWords.map { $0.lowercased() }
        let matchesStandard = lowercasedExpected.contains(where: {
            $0.contains("reserv") || $0.contains("amenit") || $0.contains("accommodat") ||
            $0.contains("passport") || $0.contains("checkout")
        })

        if matchesStandard || expectedWords.isEmpty {
            return [
                "Here is my passport for the reservation under my name.",
                "Certainly, here is my ID. Could you accommodate an early check-in if possible?",
                "Here you go! Could you tell me more about the hotel amenities?"
            ]
        } else {
            let firstWord = expectedWords[0]
            let secondWord = expectedWords.indices.contains(1) ? expectedWords[1] : firstWord
            return [
                "Here is my passport for the reservation regarding \(firstWord).",
                "Could you accommodate our stay and tell me about the \(secondWord)?",
                "Here you go! Could you tell me more about the available services?"
            ]
        }
    }

    private func fallbackSuggestedResponses(userTurnCount: Int, expectedWords: [String]) -> [String] {
        if userTurnCount >= 3 {
            return [
                "Thank you, have a wonderful day!",
                "Thanks, goodbye!"
            ]
        }
        guard userTurnCount <= 1 else {
            return [
                "That makes a lot of sense, thank you for the helpful explanation!",
                "Could you give me another practice question to test my understanding?",
                "I appreciate your feedback! Let's continue to the next part."
            ]
        }

        if let firstWord = expectedWords.first {
            return [
                "Could you explain how to use '\(firstWord)' naturally in a sentence?",
                "I would like to practice using my target vocabulary in this conversation.",
                "Could we continue practicing spoken English with another prompt?"
            ]
        } else {
            return [
                "Could you give me an example of how a native speaker would say that?",
                "I would like to continue practicing our conversation topic.",
                "Could we practice another dialogue together?"
            ]
        }
    }
}
