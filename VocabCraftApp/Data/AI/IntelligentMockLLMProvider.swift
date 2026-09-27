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

        // 1. Extract Target Words from dialogue history and user utterance
        let targetWordsUsed = extractTargetWords(from: lowercasedUser)

        // 2. Determine scenario context
        let reply: String
        let refinement: String?
        let tip: String?
        let userTurnCount = messages.filter({ $0.role == .user }).count

        if lowercasedUser.contains("espresso") || lowercasedUser.contains("coffee") || lowercasedUser.contains("croissant") {
            // Cafe Scenario Turn
            if userTurnCount <= 1 {
                reply = "Great choice! Would you like a single or double espresso? And should I warm up the croissant for you?"
                refinement = "You could say: 'I'd like a double espresso and a warmed croissant, please.'"
                tip = "In a cafe, specifying 'single or double shot' makes ordering seamless!"
            } else {
                reply = "Coming right up! That will be $6.50. You can tap your card right on the reader. Have a wonderful day!"
                refinement = "Native tip: 'Keep the change!' is common if paying cash."
                tip = "Great job finishing your cafe order using your target vocabulary!"
            }
        } else if lowercasedUser.contains("interview")
                    || lowercasedUser.contains("experience")
                    || lowercasedUser.contains("strength")
                    || lowercasedUser.contains("deadline")
                    || lowercasedUser.contains("leadership")
                    || lowercasedUser.contains("collaboration") {
            // Job Interview Scenario Turn
            if userTurnCount <= 1 {
                reply = "Thank you for sharing that. Could you tell me about a time you handled a tight deadline or challenge?"
                refinement = "Consider using the STAR method (Situation, Task, Action, Result) when answering."
                tip = "Strong action verbs like 'managed', 'developed', and 'collaborated' elevate your response."
            } else {
                reply = "That demonstrates excellent leadership and problem-solving skills under pressure. Do you have any questions for us about the role or team?"
                refinement = "Ask a thoughtful closing question like: 'What does success look like in the first 90 days?'"
                tip = "Asking informed questions at the end of an interview reinforces your enthusiasm and preparation."
            }
        } else if lowercasedUser.contains("hotel")
                    || lowercasedUser.contains("reservation")
                    || lowercasedUser.contains("check in")
                    || lowercasedUser.contains("passport")
                    || lowercasedUser.contains("amenities") {
            // Hotel Check-In Scenario Turn
            if userTurnCount <= 1 {
                reply = "I found your reservation right here. May I have your passport or ID card, please?"
                refinement = "Try: 'I have a reservation under the name [Your Name].'"
                tip = "'Under the name' is the standard polite phrasing for reservations."
            } else {
                reply = "Thank you. Here is your keycard for room 402. Complimentary breakfast and amenities like the pool are on the 5th floor. Enjoy your stay!"
                refinement = "Polite inquiry: 'Could you tell me what time breakfast is served?'"
                tip = "'Complimentary' means provided free of charge by the establishment."
            }
        } else {
            // Adaptive Fallback
            reply = "That's very interesting! Could you elaborate more on that, or should we move to the next step?"
            refinement = "Natural phrasing: 'Could you give me more details on that?'"
            tip = "Keep speaking naturally. Notice how rhythm and intonation help convey meaning."
        }

        let output = RoleplayTurnOutput(
            characterReply: reply,
            targetWordsUsed: targetWordsUsed,
            refinementSuggestion: refinement,
            pedagogicalNote: tip
        )

        if let typedResult = output as? T {
            return typedResult
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Unsupported output schema for IntelligentMockLLMProvider")
        )
    }

    public func extractTargetWords(from text: String) -> [String] {
        let catalogTargetWords = [
            "espresso", "croissant", "recommendation", "decaf", "receipt",
            "experience", "collaboration", "strength", "deadline", "leadership",
            "reservation", "passport", "amenities", "checkout", "complimentary"
        ]
        return catalogTargetWords.filter { word in
            text.localizedStandardContains(word)
        }
    }
}
