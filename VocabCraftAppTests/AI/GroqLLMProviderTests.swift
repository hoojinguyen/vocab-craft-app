import Foundation
import Testing
@testable import VocabCraftApp

@Suite("GroqLLMProvider Tests")
struct GroqLLMProviderTests {
    @Test("GroqLLMProvider throws missingApiKey when key is empty")
    func testMissingApiKeyThrows() async {
        let provider = GroqLLMProvider(apiKey: "")
        await #expect(throws: GroqError.self) {
            _ = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "Hello")],
                systemPrompt: "You are a barista",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }

    @Test("GroqLLMProvider successfully parses OpenAI-compatible JSON chat response")
    func testSuccessfulParsing() async throws {
        let contentDict: [String: Any] = [
            "characterReply": "Welcome to the coffee shop!",
            "targetWordsUsed": ["espresso"],
            "refinementSuggestion": NSNull(),
            "pedagogicalNote": "Great order!",
            "suggestedResponses": ["I want an espresso"],
            "isConcluded": false
        ]
        let contentData = try JSONSerialization.data(withJSONObject: contentDict)
        let contentString = String(data: contentData, encoding: .utf8)!

        let responseDict: [String: Any] = [
            "id": "chatcmpl-123",
            "choices": [
                [
                    "message": [
                        "role": "assistant",
                        "content": contentString
                    ]
                ]
            ]
        ]
        let responseData = try JSONSerialization.data(withJSONObject: responseDict)

        let (session, mockId) = MockURLProtocol.register { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, responseData)
        }
        defer { MockURLProtocol.unregister(id: mockId) }

        let provider = GroqLLMProvider(apiKey: "gsk_test_key", session: session)
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: [LLMChatMessage(role: .user, content: "Hi")],
            systemPrompt: "Prompt",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.characterReply == "Welcome to the coffee shop!")
        #expect(output.targetWordsUsed == ["espresso"])
        #expect(!output.isConcluded)
    }

    @Test("GroqLLMProvider prioritizes llama-3.1-8b-instant for fast low-latency turns")
    func testDefaultModelsPriority() {
        #expect(GroqLLMProvider.defaultModels.first == "llama-3.1-8b-instant")
        #expect(GroqLLMProvider.defaultModels.contains("llama-3.3-70b-versatile"))
    }

    @Test("GroqLLMProvider falls back to fallback provider on HTTP 429 rate limit")
    func testFallbackOnRateLimit() async throws {
        let (session, mockId) = MockURLProtocol.register { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, Data("Rate limit exceeded".utf8))
        }
        defer { MockURLProtocol.unregister(id: mockId) }

        let mockFallback = MockLLMProvider(mockTurnOutput: RoleplayTurnOutput(characterReply: "Fallback invoked", targetWordsUsed: []))
        let provider = GroqLLMProvider(apiKey: "gsk_test_key", session: session, fallbackProvider: mockFallback)

        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: [LLMChatMessage(role: .user, content: "Hi")],
            systemPrompt: "Prompt",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.characterReply == "Fallback invoked")
    }
}
