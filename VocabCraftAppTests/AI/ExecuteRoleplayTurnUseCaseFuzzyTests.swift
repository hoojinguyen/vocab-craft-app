import Foundation
import Testing
@testable import VocabCraftApp

@Suite("ExecuteRoleplayTurnUseCase Fuzzy Tests", .serialized)
struct ExecuteRoleplayTurnUseCaseFuzzyTests {
    // MARK: - Test Helpers

    private func makeScenario(
        targetWordIds: [String],
        starterSuggestions: [String] = []
    ) -> RoleplayScenario {
        RoleplayScenario(
            id: "cafe-order",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi! What can I get for you?",
            targetWordIds: targetWordIds,
            iconSymbol: "cup.and.saucer",
            starterSuggestions: starterSuggestions
        )
    }

    // MARK: - Tests

    @Test("Target word with plural inflection is detected")
    func testPluralInflectionDetection() async throws {
        let spyProvider = SpyLLMProvider()
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: spyProvider)
        let scenario = makeScenario(targetWordIds: ["beverage", "pastry"])

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "I would like two warm beverages",
            chatHistory: []
        )

        #expect(result.targetWordsUsed.contains("beverage"))
    }

    @Test("Target word with past tense inflection is detected")
    func pastTenseInflectionDetection() async throws {
        let spyProvider = SpyLLMProvider()
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: spyProvider)
        let scenario = makeScenario(targetWordIds: ["order", "pastry"])

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "I ordered a pastry",
            chatHistory: []
        )

        #expect(result.targetWordsUsed.contains("order"))
        #expect(result.targetWordsUsed.contains("pastry"))
    }

    @Test("Target word with accent or phonetic variation is detected")
    func phoneticVariationDetection() async throws {
        let spyProvider = SpyLLMProvider()
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: spyProvider)
        let scenario = makeScenario(targetWordIds: ["complimentary"])

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "Could I get a complimentery cookie?",
            chatHistory: []
        )

        #expect(result.targetWordsUsed.contains("complimentary"))
    }

    @Test("Suggested response alignment credits embedded target words and passes to LLM prompt context")
    func suggestedResponseAlignmentCreditsTargetWordsAndPassesToLLM() async throws {
        let spyProvider = SpyLLMProvider()
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: spyProvider)
        let suggestion = "Could I have a complimentary beverage, please?"
        let scenario = makeScenario(
            targetWordIds: ["complimentary", "beverage"],
            starterSuggestions: [suggestion]
        )

        // User says "drink" instead of "beverage", but sentence is >= 70% similar to suggestion
        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "Could I have a complimentary drink, please?",
            chatHistory: []
        )

        // Embedded target words in suggestion must be credited even though "beverage" wasn't spoken
        #expect(result.targetWordsUsed.contains("complimentary"))
        #expect(result.targetWordsUsed.contains("beverage"))

        // Recognized suggestion must be passed to LLM in prompt context
        #expect(spyProvider.lastSystemPrompt?.contains(suggestion) == true)
    }

    @Test("Previous turn suggested responses align and credit target words with conversation overload")
    func previousTurnSuggestedResponsesWithConversationOverload() async throws {
        let spyProvider = SpyLLMProvider()
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: spyProvider)
        let scenario = makeScenario(
            targetWordIds: ["pastry", "beverage"],
            starterSuggestions: ["Hello there!"]
        )

        let previousSuggestions = [
            "Could I please order a fresh pastry?",
            "What kind of tea do you serve?"
        ]

        let conversation = [
            RoleplayMessage(sender: .character(name: "Barista"), text: "Welcome in! What can I get for you?"),
            RoleplayMessage(sender: .user, text: "Could I please order fresh pastry?")
        ]

        let result = try await useCase.execute(
            scenario: scenario,
            conversation: conversation,
            suggestedResponses: previousSuggestions
        )

        #expect(result.targetWordsUsed.contains("pastry"))
        #expect(spyProvider.lastSystemPrompt?.contains("Could I please order a fresh pastry?") == true)
    }
}

// MARK: - Spy LLM Provider

private final class SpyLLMProvider: LLMProviderProtocol, @unchecked Sendable {
    let providerIdentifier: String = "spy-mock"
    var lastMessages: [LLMChatMessage] = []
    var lastSystemPrompt: String?
    var mockTurnOutput: RoleplayTurnOutput

    init(mockTurnOutput: RoleplayTurnOutput? = nil) {
        self.mockTurnOutput = mockTurnOutput ?? RoleplayTurnOutput(
            characterReply: "Certainly! Here you go.",
            targetWordsUsed: [],
            refinementSuggestion: nil,
            pedagogicalNote: nil,
            suggestedResponses: []
        )
    }

    func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        self.lastMessages = messages
        self.lastSystemPrompt = systemPrompt
        if let output = mockTurnOutput as? T {
            return output
        }
        fatalError("Unsupported schema in SpyLLMProvider")
    }
}
