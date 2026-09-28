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

    @Test("RoleplayTurnOutput suggestedResponses and decoding fallback")
    func testRoleplayTurnOutputSuggestedResponses() throws {
        let defaultOutput = RoleplayTurnOutput(
            characterReply: "Hi",
            targetWordsUsed: []
        )
        #expect(defaultOutput.suggestedResponses.isEmpty)

        let suggestions = ["I would like a coffee, please.", "Can I see the pastry menu?"]
        let outputWithSuggestions = RoleplayTurnOutput(
            characterReply: "Hi",
            targetWordsUsed: ["beverage"],
            suggestedResponses: suggestions
        )
        #expect(outputWithSuggestions.suggestedResponses == suggestions)

        let encoded = try JSONEncoder().encode(outputWithSuggestions)
        let decoded = try JSONDecoder().decode(RoleplayTurnOutput.self, from: encoded)
        #expect(decoded.suggestedResponses == suggestions)

        // Decoding fallback when suggestedResponses is missing from JSON
        let legacyJson = """
        {
            "characterReply": "Welcome!",
            "targetWordsUsed": ["beverage"]
        }
        """
        let legacyDecoded = try JSONDecoder().decode(RoleplayTurnOutput.self, from: Data(legacyJson.utf8))
        #expect(legacyDecoded.suggestedResponses.isEmpty)
        #expect(legacyDecoded.characterReply == "Welcome!")
    }

    @Test("RoleplayScenario starterSuggestions and decoding fallback")
    func testRoleplayScenarioStarterSuggestions() throws {
        let defaultScenario = RoleplayScenario(
            id: "test",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hello",
            targetWordIds: ["beverage"],
            iconSymbol: "cup.fill"
        )
        #expect(defaultScenario.starterSuggestions.isEmpty)

        let starterPhrases = ["Can I get a beverage?", "I'd like to order."]
        let scenarioWithStarters = RoleplayScenario(
            id: "test",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hello",
            targetWordIds: ["beverage"],
            iconSymbol: "cup.fill",
            starterSuggestions: starterPhrases
        )
        #expect(scenarioWithStarters.starterSuggestions == starterPhrases)

        let encoded = try JSONEncoder().encode(scenarioWithStarters)
        let decoded = try JSONDecoder().decode(RoleplayScenario.self, from: encoded)
        #expect(decoded.starterSuggestions == starterPhrases)

        // Decoding fallback when starterSuggestions is missing from JSON
        let legacyJson = """
        {
            "id": "legacy",
            "titleKey": "t",
            "descriptionKey": "d",
            "topic": "dining",
            "difficulty": "beginner",
            "characterName": "E",
            "characterRole": "B",
            "userRole": "C",
            "initialGreeting": "Hi",
            "targetWordIds": ["beverage"],
            "iconSymbol": "cup"
        }
        """
        let legacyDecoded = try JSONDecoder().decode(RoleplayScenario.self, from: Data(legacyJson.utf8))
        #expect(legacyDecoded.starterSuggestions.isEmpty)
    }

    @Test("RoleplayScenarioCatalog provides starter suggestions for all standard scenarios")
    func testRoleplayScenarioCatalogStarterSuggestions() {
        let standard = RoleplayScenarioCatalog.standardScenarios
        #expect(!standard.isEmpty)
        for scenario in standard {
            #expect(scenario.starterSuggestions.count >= 2, "Scenario \(scenario.id) must have at least 2 starter suggestions")
            for suggestion in scenario.starterSuggestions {
                #expect(!suggestion.isEmpty, "Starter suggestion in \(scenario.id) should not be empty")
            }
        }
    }
}
