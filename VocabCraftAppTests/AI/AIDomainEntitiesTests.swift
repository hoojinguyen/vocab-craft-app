import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AI Assistant Domain Entities Tests")
struct AIDomainEntitiesTests {
    @Test("RoleplayScenario initialization and topic modeling")
    func testRoleplayScenarioInitialization() {
        let scenario = RoleplayScenario(
            id: "cafe-order",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi! Welcome to Artisan Coffee. What can I get started for you?",
            targetWordIds: ["beverage", "pastry", "complimentary"],
            iconSymbol: "cup.and.saucer.fill"
        )
        #expect(scenario.id == "cafe-order")
        #expect(scenario.topic == .dining)
        #expect(scenario.difficulty == .beginner)
        #expect(scenario.targetWordIds.count == 3)
    }

    @Test("RoleplayTurnOutput codable roundtrip")
    func testRoleplayTurnOutputCodable() throws {
        let output = RoleplayTurnOutput(
            characterReply: "Sure, we have fresh croissants today!",
            targetWordsUsed: ["pastry"],
            refinementSuggestion: "You could say 'I'd like to try your pastry.'",
            pedagogicalNote: "Great job ordering politely!"
        )
        let data = try JSONEncoder().encode(output)
        let decoded = try JSONDecoder().decode(RoleplayTurnOutput.self, from: data)
        #expect(decoded == output)
        #expect(decoded.targetWordsUsed == ["pastry"])
    }

    @Test("RoleplaySessionSummary initialization and properties")
    func testRoleplaySessionSummary() {
        let refinement = SentenceRefinementPair(
            originalUserSentence: "I want coffee",
            refinedNativeSentence: "I would like a coffee, please."
        )
        let summary = RoleplaySessionSummary(
            scenarioId: "cafe-order",
            totalTurns: 5,
            targetWordsAttempted: ["beverage", "pastry"],
            targetWordsMastered: ["beverage"],
            fluencyScore: 85,
            xpEarned: 50,
            refinements: [refinement]
        )
        #expect(summary.id == "cafe-order")
        #expect(summary.totalTurns == 5)
        #expect(summary.targetWordsAttempted.count == 2)
        #expect(summary.targetWordsMastered == ["beverage"])
        #expect(summary.fluencyScore == 85)
        #expect(summary.xpEarned == 50)
        #expect(summary.refinements.count == 1)
        #expect(summary.refinements.first?.id == refinement.id)
        #expect(summary.refinements.first?.originalUserSentence == "I want coffee")
    }

    @Test("LLMChatMessage initialization and equality")
    func testLLMChatMessage() {
        let message = LLMChatMessage(role: .user, content: "Hello")
        #expect(message.role == .user)
        #expect(message.content == "Hello")
    }
}
