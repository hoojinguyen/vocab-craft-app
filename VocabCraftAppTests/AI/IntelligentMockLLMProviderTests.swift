import Testing
@testable import VocabCraftApp

@Suite("Intelligent Mock LLM Provider Tests")
struct IntelligentMockLLMProviderTests {
    @Test("Extracts target words and advances cafe dialogue")
    func cafeScenarioTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .system, content: "Scenario: scenario_cafe_order. Target words: espresso, croissant, recommendation, decaf."),
            LLMChatMessage(role: .model, content: "Hi! Welcome to The Daily Roast. What can I get started for you today?"),
            LLMChatMessage(role: .user, content: "Can I have a hot espresso and a fresh croissant?")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are Alex the barista.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("espresso"))
        #expect(output.targetWordsUsed.contains("croissant"))
        #expect(!output.characterReply.isEmpty)
        #expect(output.refinementSuggestion != nil)
    }

    @Test("Advances cafe dialogue to checkout on second turn")
    func cafeScenarioSecondTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .system, content: "Scenario: scenario_cafe_order. Target words: espresso, croissant, recommendation, decaf."),
            LLMChatMessage(role: .model, content: "Hi! Welcome to The Daily Roast. What can I get started for you today?"),
            LLMChatMessage(role: .user, content: "Can I have an espresso?"),
            LLMChatMessage(role: .model, content: "Sure, single or double?"),
            LLMChatMessage(role: .user, content: "Double espresso and that's all, thank you.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are Alex the barista.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("espresso"))
        #expect(output.characterReply.contains("$6.50") || output.characterReply.contains("reader"))
        #expect(output.refinementSuggestion != nil)
        #expect(output.pedagogicalNote != nil)
    }

    @Test("Handles job interview scenario turn")
    func interviewScenarioTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "In my previous experience, I led cross-functional team collaboration.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are the hiring manager.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("experience"))
        #expect(output.targetWordsUsed.contains("collaboration"))
        #expect(!output.characterReply.isEmpty)
        #expect(output.refinementSuggestion?.contains("STAR") == true)
    }

    @Test("Handles hotel check-in scenario turn")
    func hotelScenarioTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Hello, I have a hotel reservation and here is my passport.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are the hotel concierge.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("reservation"))
        #expect(output.targetWordsUsed.contains("passport"))
        #expect(!output.characterReply.isEmpty)
        #expect(output.refinementSuggestion != nil)
    }

    @Test("Fallback response handles free-form speech outside script")
    func freeFormFallback() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Tell me about the weather outside.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "General conversation",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(!output.characterReply.isEmpty)
        #expect(output.pedagogicalNote != nil)
    }

    @Test("Verify provider identifier and unsupported schema handling")
    func providerIdentifierAndUnsupportedSchema() async throws {
        let provider = IntelligentMockLLMProvider()
        #expect(provider.providerIdentifier == "intelligent_mock")

        struct UnrelatedSchema: Codable, Sendable {
            let id: String
        }

        let messages = [
            LLMChatMessage(role: .user, content: "Hello")
        ]

        await #expect(throws: DecodingError.self) {
            _ = try await provider.sendStructuredMessage(
                messages: messages,
                systemPrompt: "test",
                responseSchema: UnrelatedSchema.self
            )
        }
    }
}
