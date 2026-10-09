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
        #expect(output.isConcluded == false)
    }

    @Test("OnDeviceContextDialogueEngine avoids false positives for short substrings")
    func test_contextDialogueEngine_detectTargetWords_guardsShortWordSubstrings() {
        let engine = OnDeviceContextDialogueEngine()
        let detected = engine.detectTargetWords(in: "I love this warm scarf today", candidateWords: ["car"])
        #expect(detected.isEmpty)
    }

    @Test("AppleDefaultPack makeLLMProvider returns working provider on all platforms without throwing")
    func test_appleDefaultPack_makeLLMProvider_doesNotThrow() throws {
        let pack = AppleDefaultPack()
        let provider = try pack.makeLLMProvider()
        #expect(provider.providerIdentifier == "apple_intelligence_or_local")
    }

    @Test("OnDeviceContextDialogueEngine generateTurn from messages and prompt handles multi-turn cafe order")
    func test_contextDialogueEngine_generateTurn_fromMessagesAndSystemPrompt() async throws {
        let engine = OnDeviceContextDialogueEngine()
        let systemPrompt = "Target vocabulary for the user: beverage, pastry, complimentary. Scenario: cafe-order"
        let messages = [
            LLMChatMessage(role: .system, content: systemPrompt),
            LLMChatMessage(role: .user, content: "I would like to order a fresh pastry and a hot beverage.")
        ]

        let output = try await engine.generateTurn(messages: messages, systemPrompt: systemPrompt)
        #expect(!output.characterReply.isEmpty)
        #expect(output.characterReply != "Hello! Welcome to our conversation. How can I help you today?")
        #expect(output.targetWordsUsed.contains("pastry") || output.targetWordsUsed.contains("beverage"))
        #expect(output.suggestedResponses.count == 3)
    }

    @Test("Dining FSM transitions naturally without premature billing on inquiry")
    func testDiningFSMInquiryAndOrdering() async throws {
        let engine = OnDeviceContextDialogueEngine()
        let scenario = RoleplayScenario.cafeMock

        // Turn 1: User asks about Wi-Fi
        let output1 = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: "Do you have free wifi here?",
            conversationHistory: []
        )
        #expect(!output1.characterReply.contains("$6.50"))
        #expect(output1.isConcluded == false)

        // Turn 2: User orders beverage and pastry
        let history1 = [
            RoleplayMessage(sender: .character(name: "Emma"), text: output1.characterReply),
            RoleplayMessage(sender: .user, text: "Do you have free wifi here?")
        ]
        let output2 = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: "I'd like a hot beverage and a pastry please",
            conversationHistory: history1
        )
        #expect(output2.targetWordsUsed.contains("beverage") || output2.targetWordsUsed.contains("pastry"))
        #expect(output2.isConcluded == false)
    }

    @Test("Vietnamese utterance triggers pedagogical nudge with English suggested responses")
    func testVietnamesePedagogicalNudgeIntegration() async throws {
        let engine = OnDeviceContextDialogueEngine()
        let scenario = RoleplayScenario.cafeMock

        let output = try await engine.generateTurn(
            scenario: scenario,
            userUtterance: "Cho tôi một ly cà phê và bánh ngọt",
            conversationHistory: []
        )
        #expect(output.characterReply.contains("I only speak English here"))
        #expect(output.suggestedResponses.count == 3)
        #expect(output.isConcluded == false)
    }
}
