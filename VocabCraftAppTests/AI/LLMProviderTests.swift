import Foundation
import Testing
@testable import VocabCraftApp

@Suite("LLM Provider Tests", .serialized)
struct LLMProviderTests {
    // MARK: - MockLLMProvider Tests

    @Test("MockLLMProvider returns configured structured output")
    func testMockProviderReturnsStructuredOutput() async throws {
        let expectedOutput = RoleplayTurnOutput(
            characterReply: "Here is your latte!",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: nil,
            pedagogicalNote: "Good request"
        )
        let mock = MockLLMProvider(mockTurnOutput: expectedOutput)

        let result: RoleplayTurnOutput = try await mock.sendStructuredMessage(
            messages: [LLMChatMessage(role: .user, content: "Can I get a beverage?")],
            systemPrompt: "You are a barista",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(result.characterReply == "Here is your latte!")
        #expect(result.targetWordsUsed.contains("beverage"))
    }

    @Test("MockLLMProvider throws when error is injected")
    func testMockProviderErrorInjection() async {
        let mock = MockLLMProvider()
        mock.shouldThrowError = true

        await #expect(throws: Error.self) {
            let _: RoleplayTurnOutput = try await mock.sendStructuredMessage(
                messages: [],
                systemPrompt: "",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }

    @Test("MockLLMProvider returns default mock output when none provided")
    func testMockProviderDefaultOutput() async throws {
        let mock = MockLLMProvider()

        let result: RoleplayTurnOutput = try await mock.sendStructuredMessage(
            messages: [LLMChatMessage(role: .user, content: "Hello")],
            systemPrompt: "Default prompt",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(!result.characterReply.isEmpty)
        #expect(result.pedagogicalNote == "Keep going!")
    }

    @Test("MockLLMProvider throws when requested schema is unsupported")
    func testMockProviderUnsupportedSchema() async {
        struct UnsupportedSchema: Decodable, Sendable {}

        let mock = MockLLMProvider()

        await #expect(throws: DecodingError.self) {
            _ = try await mock.sendStructuredMessage(
                messages: [],
                systemPrompt: "",
                responseSchema: UnsupportedSchema.self
            )
        }
    }

    // MARK: - GeminiLLMProvider Tests

    @Test("GeminiLLMProvider throws missingApiKey when key is empty")
    func testGeminiProviderMissingApiKey() async {
        let provider = GeminiLLMProvider(apiKey: "")

        await #expect(throws: GeminiError.self) {
            let _: RoleplayTurnOutput = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "Hello")],
                systemPrompt: "Prompt",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }

    @Test("GeminiLLMProvider throws missingApiKey immediately without fallback")
    func testGeminiThrowsMissingApiKeyWithoutFallback() async {
        let provider = GeminiLLMProvider(apiKey: "")
        await #expect(throws: GeminiError.self) {
            let _: RoleplayTurnOutput = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "hi")],
                systemPrompt: "sys",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }

    @Test("GeminiLLMProvider successfully parses valid Gemini response")
    func testGeminiProviderSuccess() async throws {
        let (session, mockId) = MockURLProtocol.register { request in
            #expect(request.url?.absoluteString.contains("gemini-2.5-flash") == true)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "fake-key")

            let responseJSON: [String: Any] = [
                "candidates": [
                    [
                        "content": [
                            "parts": [
                                [
                                    "text": """
                                    {
                                        "characterReply": "Welcome to the cafe!",
                                        "targetWordsUsed": ["beverage"],
                                        "refinementSuggestion": null,
                                        "pedagogicalNote": "Well asked"
                                    }
                                    """
                                ]
                            ]
                        ]
                    ]
                ]
            ]
            let data = try JSONSerialization.data(withJSONObject: responseJSON)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
        defer { MockURLProtocol.unregister(id: mockId) }

        let provider = GeminiLLMProvider(apiKey: "fake-key", session: session)
        let result: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: [LLMChatMessage(role: .user, content: "I would like a beverage.")],
            systemPrompt: "You are a cafe server.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(result.characterReply == "Welcome to the cafe!")
        #expect(result.targetWordsUsed == ["beverage"])
        #expect(result.pedagogicalNote == "Well asked")
    }

    @Test("GeminiLLMProvider falls back to next model on 503 error")
    func testGeminiProviderModelFallback() async throws {
        var requestedModels: [String] = []
        let (session, mockId) = MockURLProtocol.register { request in
            let urlString = request.url?.absoluteString ?? ""
            if urlString.contains("gemini-2.5-flash") {
                requestedModels.append("gemini-2.5-flash")
                let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
                return (response, Data("Unavailable".utf8))
            } else {
                requestedModels.append("secondary")
                let responseJSON: [String: Any] = [
                    "candidates": [
                        [
                            "content": [
                                "parts": [
                                    ["text": "{\"characterReply\": \"Hello from secondary!\", \"targetWordsUsed\": []}"]
                                ]
                            ]
                        ]
                    ]
                ]
                let data = try JSONSerialization.data(withJSONObject: responseJSON)
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
                return (response, data)
            }
        }
        defer { MockURLProtocol.unregister(id: mockId) }

        let provider = GeminiLLMProvider(apiKey: "fake-key", session: session)
        let result: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: [LLMChatMessage(role: .user, content: "Hi")],
            systemPrompt: "Server",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(requestedModels.contains("gemini-2.5-flash"))
        #expect(requestedModels.contains("secondary"))
        #expect(result.characterReply == "Hello from secondary!")
    }

    @Test("GeminiLLMProvider throws error when all models fail without fallback")
    func testGeminiThrowsWhenAllModelsFailWithoutFallback() async {
        let (session, mockId) = MockURLProtocol.register { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, Data("Error".utf8))
        }
        defer { MockURLProtocol.unregister(id: mockId) }

        let provider = GeminiLLMProvider(apiKey: "fake-key", session: session)

        await #expect(throws: GeminiError.self) {
            let _: RoleplayTurnOutput = try await provider.sendStructuredMessage(
                messages: [LLMChatMessage(role: .user, content: "Hello")],
                systemPrompt: "Server",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }

    @Test("GeminiLLMProvider throws apiError on non-200 HTTP status")
    func testGeminiProviderHTTPError() async {
        let (session, mockId) = MockURLProtocol.register { request in
            let errorBody = Data("Quota exceeded".utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 429,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, errorBody)
        }
        defer { MockURLProtocol.unregister(id: mockId) }

        let provider = GeminiLLMProvider(apiKey: "fake-key", session: session)

        await #expect(throws: GeminiError.self) {
            let _: RoleplayTurnOutput = try await provider.sendStructuredMessage(
                messages: [],
                systemPrompt: "",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }

    @Test("GeminiLLMProvider throws invalidResponse on malformed payload")
    func testGeminiProviderMalformedResponse() async {
        let (session, mockId) = MockURLProtocol.register { request in
            let malformedBody = Data("{\"candidates\": []}".utf8)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, malformedBody)
        }
        defer { MockURLProtocol.unregister(id: mockId) }

        let provider = GeminiLLMProvider(apiKey: "fake-key", session: session)

        await #expect(throws: GeminiError.self) {
            let _: RoleplayTurnOutput = try await provider.sendStructuredMessage(
                messages: [],
                systemPrompt: "",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }

    @Test("GeminiError provides localized error descriptions")
    func testGeminiErrorDescriptions() {
        let missing = GeminiError.missingApiKey
        let invalid = GeminiError.invalidResponse
        let api = GeminiError.apiError(statusCode: 404, message: "Not found")

        #expect(missing.errorDescription?.contains("not configured") == true)
        #expect(invalid.errorDescription?.contains("Invalid response") == true)
        #expect(api.errorDescription?.contains("404") == true)
    }

    @Test("GeminiLLMProvider default models use official Google Gemini 2.5 Flash endpoints")
    func test_geminiDefaultModels_useOfficialEndpoints() {
        let models = GeminiLLMProvider.defaultModels
        #expect(models.contains("gemini-2.5-flash"))
        #expect(!models.contains("gemini-flash-lite-latest"))
        #expect(!models.contains("gemini-3.1-flash-lite"))
    }
}

// MARK: - Test URLProtocol Helper

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var handlers: [String: (URLRequest) throws -> (HTTPURLResponse, Data)] = [:]

    static func register(
        handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> (URLSession, String) {
        let id = UUID().uuidString
        lock.lock()
        handlers[id] = handler
        lock.unlock()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        config.httpAdditionalHeaders = ["X-Mock-ID": id]
        return (URLSession(configuration: config), id)
    }

    static func unregister(id: String) {
        lock.lock()
        handlers.removeValue(forKey: id)
        lock.unlock()
    }

    private static func handler(for id: String) -> ((URLRequest) throws -> (HTTPURLResponse, Data))? {
        lock.lock()
        defer { lock.unlock() }
        return handlers[id]
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let mockId = request.value(forHTTPHeaderField: "X-Mock-ID"),
              let currentHandler = Self.handler(for: mockId) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try currentHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
