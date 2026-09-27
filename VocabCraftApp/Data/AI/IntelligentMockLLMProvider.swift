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
            userTurnCount: userTurnCount
        )

        let output = RoleplayTurnOutput(
            characterReply: turn.reply,
            targetWordsUsed: targetWordsUsed,
            refinementSuggestion: turn.refinement,
            pedagogicalNote: turn.tip
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
    }

    private func determineDialogueTurn(
        lowercasedUser: String,
        systemPrompt: String,
        userTurnCount: Int
    ) -> DialogueTurnContent {
        let lowercasedPrompt = systemPrompt.lowercased()

        let isCafe = lowercasedUser.contains("espresso")
            || lowercasedUser.contains("coffee")
            || lowercasedUser.contains("croissant")
            || lowercasedUser.contains("beverage")
            || lowercasedUser.contains("pastry")
            || lowercasedUser.contains("decaf")
            || lowercasedUser.contains("receipt")
            || lowercasedPrompt.contains("barista")
            || lowercasedPrompt.contains("cafe")

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

        if isCafe {
            if userTurnCount <= 1 {
                let reply = lowercasedUser.contains("pastry") || lowercasedUser.contains("beverage")
                    ? "Great choice! Would you like your beverage hot or iced? And should I warm up the pastry for you?"
                    : "Great choice! Would you like a single or double espresso? And should I warm up the croissant for you?"
                let refinement = "You could say: 'I'd like a double espresso and a warmed croissant, please.'"
                let tip = "In a cafe, specifying 'single or double shot' makes ordering seamless!"
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip)
            } else {
                let reply = "Coming right up! That will be $6.50. You can tap your card right on the reader. Have a wonderful day!"
                let refinement = "Native tip: 'Keep the change!' is common if paying cash."
                let tip = "Great job finishing your cafe order using your target vocabulary!"
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip)
            }
        } else if isInterview {
            if userTurnCount <= 1 {
                let reply = "Thank you for sharing that. Could you tell me about a time you handled a tight deadline or challenge?"
                let refinement = "Consider using the STAR method (Situation, Task, Action, Result) when answering."
                let tip = "Strong action verbs like 'managed', 'developed', and 'collaborated' elevate your response."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip)
            } else {
                let reply = "That demonstrates excellent leadership and problem-solving skills under pressure. Do you have any questions for us about the role or team?"
                let refinement = "Ask a thoughtful closing question like: 'What does success look like in the first 90 days?'"
                let tip = "Asking informed questions at the end of an interview reinforces your enthusiasm and preparation."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip)
            }
        } else if isHotel {
            if userTurnCount <= 1 {
                let reply = "I found your reservation right here. May I have your passport or ID card, please?"
                let refinement = "Try: 'I have a reservation under the name [Your Name].'"
                let tip = "'Under the name' is the standard polite phrasing for reservations."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip)
            } else {
                let reply = "Thank you. Here is your keycard for room 402. Complimentary breakfast and amenities like the pool are on the 5th floor. Enjoy your stay!"
                let refinement = "Polite inquiry: 'Could you tell me what time breakfast is served?'"
                let tip = "'Complimentary' means provided free of charge by the establishment."
                return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip)
            }
        } else {
            let reply = "That's very interesting! Could you elaborate more on that, or should we move to the next step?"
            let refinement = "Natural phrasing: 'Could you give me more details on that?'"
            let tip = "Keep speaking naturally. Notice how rhythm and intonation help convey meaning."
            return DialogueTurnContent(reply: reply, refinement: refinement, tip: tip)
        }
    }
}
