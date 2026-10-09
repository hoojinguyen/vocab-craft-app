import Foundation
import Testing
@testable import VocabCraftApp

@Suite("OnDeviceContextDialogueEngine Tests")
struct OnDeviceContextDialogueEngineTests {
    @Test("OnDeviceContextDialogueEngine detects target words and generates 3 branching suggestions")
    func test_contextDialogueEngine_generatesThreeBranchSuggestions() async throws {
        let engine = OnDeviceContextDialogueEngine()
        let scenario = RoleplayScenarioCatalog.standardScenarios[0] // cafe-order: beverage, pastry, complimentary

        let output = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: "I would like a warm beverage please",
            conversationHistory: []
        )

        #expect(!output.characterReply.isEmpty)
        #expect(output.targetWordsUsed.contains("beverage"))
        #expect(output.suggestedResponses.count == 3)
    }

    @Test("AppleIntelligenceOrLocalDialogueProvider conforms to LLMProviderProtocol and returns RoleplayTurnOutput")
    func test_appleIntelligenceOrLocalDialogueProvider_sendStructuredMessage() async throws {
        let provider = AppleIntelligenceOrLocalDialogueProvider()
        let scenario = RoleplayScenarioCatalog.standardScenarios[0]
        let messages = [
            LLMChatMessage(role: .system, content: "Scenario: \(scenario.title)\nCharacter: \(scenario.characterName)"),
            LLMChatMessage(role: .user, content: "Hello, could I have a pastry?")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "Expected target words: pastry, beverage",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(!output.characterReply.isEmpty)
        #expect(output.targetWordsUsed.contains("pastry"))
        #expect(output.suggestedResponses.count == 3)
    }

    @Test("AppleDefaultPack makeLLMProvider returns working provider on all platforms without throwing")
    func test_appleDefaultPack_makeLLMProvider_doesNotThrow() throws {
        let pack = AppleDefaultPack()
        let provider = try pack.makeLLMProvider()
        #expect(provider.providerIdentifier == "apple_intelligence_or_local")
    }
}
