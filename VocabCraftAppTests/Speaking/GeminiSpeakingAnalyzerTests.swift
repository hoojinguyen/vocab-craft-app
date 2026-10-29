import Foundation
import Testing
@testable import VocabCraftApp

@Suite(.serialized)
struct GeminiSpeakingAnalyzerTests {
    @Test func requestUsesFlashModelInlineAudioAndSchema() throws {
        let request = try SpeakingAnalysisRequestBuilder.makeRequest(
            apiKey: "test-key", session: session(), audio: Data([1, 2, 3])
        )
        #expect(request.url?.path.hasSuffix("/models/gemini-3.8-flash:generateContent") == true)
        #expect(request.value(forHTTPHeaderField: "x-goog-api-key") == "test-key")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.timeoutInterval == 60)
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let contents = try #require(object["contents"] as? [[String: Any]])
        #expect(contents.first?["role"] as? String == "user")
        let content = try #require(contents.first)
        let parts = try #require(content["parts"] as? [[String: Any]])
        #expect(parts.count == 2)
        let inlinePart = try #require(parts.dropFirst().first)
        let inline = try #require(inlinePart["inline_data"] as? [String: Any])
        #expect(inline["mime_type"] as? String == "audio/m4a")
        #expect(inline["data"] as? String == Data([1, 2, 3]).base64EncodedString())
        let config = try #require(object["generationConfig"] as? [String: Any])
        #expect(config["responseMimeType"] as? String == "application/json")
        let schema = try #require(config["responseSchema"] as? [String: Any])
        #expect(schema["type"] as? String == "OBJECT")
        let required = try #require(schema["required"] as? [String])
        #expect(!required.contains("objective"))
        #expect(required.contains("targetWords"))
        let properties = try #require(schema["properties"] as? [String: [String: Any]])
        #expect(Set(properties.keys) == [
            "learnerTranscript", "scores", "corrections", "naturalPhrasings", "pronunciation", "targetWords", "objective", "summary"
        ])
        #expect(properties["corrections"]?["maxItems"] as? Int == 5)
        #expect(properties["naturalPhrasings"]?["maxItems"] as? Int == 3)
        #expect(properties["pronunciation"]?["maxItems"] as? Int == 3)
        #expect(properties["targetWords"]?["maxItems"] as? Int == 3)
    }

    @Test func requestSchemaOmitsTargetWordsRequirementWithoutTargetWords() throws {
        let request = try SpeakingAnalysisRequestBuilder.makeRequest(
            apiKey: "test-key", session: session(plan: .fixture()), audio: Data([1])
        )
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let config = try #require(object["generationConfig"] as? [String: Any])
        let schema = try #require(config["responseSchema"] as? [String: Any])
        let required = try #require(schema["required"] as? [String])
        #expect(!required.contains("targetWords"))
    }

    @Test func inlineAudioOverTwentyMegabytesIsRejected() {
        #expect(throws: SpeakingAnalysisError.invalidResponse) {
            try SpeakingAnalysisRequestBuilder.makeRequest(
                apiKey: "test-key", session: session(), audio: Data(repeating: 0, count: 16 * 1_024 * 1_024)
            )
        }
    }

    @Test func serializedBodyWithinLimitIsAcceptedNearBoundary() throws {
        let audio = Data(repeating: 0, count: 15_726_390)
        let request = try SpeakingAnalysisRequestBuilder.makeRequest(
            apiKey: "test-key", session: session(plan: .fixture()), audio: audio
        )
        let body = try #require(request.httpBody)
        #expect(body.count <= 20 * 1_024 * 1_024)
        #expect(0...(16) ~= (20 * 1_024 * 1_024 - body.count))
    }

    @Test func missingApiKeyIsRejectedWithoutSending() async throws {
        let urlSession = session(statusCode: 200, data: Data())
        let analyzer = GeminiSpeakingAnalyzer(apiKey: { " \n " }, session: urlSession)
        let file = try audioFile()
        defer { try? FileManager.default.removeItem(at: file) }
        await #expect(throws: SpeakingAnalysisError.missingKey) {
            try await analyzer.analyze(session(), audioURL: file)
        }
    }

    @Test(arguments: [(401, SpeakingAnalysisError.unauthorized), (403, .unauthorized), (429, .quotaExceeded)])
    func mapsHttpFailures(statusCode: Int, expected: SpeakingAnalysisError) async throws {
        let analyzer = GeminiSpeakingAnalyzer(apiKey: { "test-key" }, session: session(statusCode: statusCode, data: Data()))
        let file = try audioFile()
        defer { try? FileManager.default.removeItem(at: file) }
        await #expect(throws: expected) {
            try await analyzer.analyze(session(), audioURL: file)
        }
    }

    @Test func decodesWrappedGenerateContentTextAndValidates() async throws {
        let analyzer = GeminiSpeakingAnalyzer(
            apiKey: { "test-key" }, session: session(statusCode: 200, data: try SpeakingFixtures.data("generate-content-response.json"))
        )
        let file = try audioFile()
        defer { try? FileManager.default.removeItem(at: file) }
        let result = try await analyzer.analyze(session(), audioURL: file)
        #expect(result.learnerTranscript.first?.text == "I want coffee.")
        #expect(result.corrections.count == 1)
    }

    @Test func networkFailureMapsToNetwork() async throws {
        let urlSession = StubURLProtocol.makeSession { _ in throw URLError(.notConnectedToInternet) }
        let analyzer = GeminiSpeakingAnalyzer(apiKey: { "test-key" }, session: urlSession)
        let file = try audioFile()
        defer { try? FileManager.default.removeItem(at: file) }
        await #expect(throws: SpeakingAnalysisError.network) {
            try await analyzer.analyze(session(), audioURL: file)
        }
    }

    @Test func urlSessionCancellationRemainsCancellation() async throws {
        let urlSession = StubURLProtocol.makeSession { _ in throw URLError(.cancelled) }
        let analyzer = GeminiSpeakingAnalyzer(apiKey: { "test-key" }, session: urlSession)
        let file = try audioFile()
        defer { try? FileManager.default.removeItem(at: file) }
        await #expect(throws: CancellationError.self) {
            try await analyzer.analyze(session(), audioURL: file)
        }
    }

    @Test func invalidCandidateTextMapsToInvalidResponse() async throws {
        let analyzer = GeminiSpeakingAnalyzer(
            apiKey: { "test-key" }, session: session(statusCode: 200, data: Data(#"{"candidates":[{"content":{"parts":[{"text":"not JSON"}]}}]}"#.utf8))
        )
        let file = try audioFile()
        defer { try? FileManager.default.removeItem(at: file) }
        await #expect(throws: SpeakingAnalysisError.invalidResponse) {
            try await analyzer.analyze(session(), audioURL: file)
        }
    }

    @Test func unavailableAudioMapsToAudioUnavailable() async throws {
        let analyzer = GeminiSpeakingAnalyzer(apiKey: { "test-key" }, session: session(statusCode: 200, data: Data()))
        let missingFile = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        await #expect(throws: SpeakingAnalysisError.audioUnavailable) {
            try await analyzer.analyze(session(), audioURL: missingFile)
        }
    }

    @Test func requestPromptSnapshotIsStable() throws {
        let request = try SpeakingAnalysisRequestBuilder.makeRequest(apiKey: "test-key", session: session(), audio: Data([0]))
        let body = try #require(request.httpBody)
        let object = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let contents = try #require(object["contents"] as? [[String: Any]])
        let parts = try #require(contents.first?["parts"] as? [[String: Any]])
        let prompt = try #require(parts.first?["text"] as? String)
        let expected = try #require(
            String(bytes: SpeakingFixtures.data("prompt-analysis-cafe-a2.txt"), encoding: .utf8)
        )
        #expect(prompt == expected)
    }

    private func session(plan: SpeakingSessionPlan = .fixture(words: ["coffee"])) -> SpeakingSessionSnapshot {
        SpeakingSessionSnapshot(
            id: UUID(), plan: plan, startedAt: Date(timeIntervalSince1970: 0), duration: 12,
            status: .pendingAnalysis, endReason: .learnerEnded, hintCount: 1, audioFileName: "recording.m4a",
            turns: [
                SpeakingTurn(index: 0, speaker: .ai, text: "Hi!", startOffset: 0, endOffset: 2),
                SpeakingTurn(index: 1, speaker: .learner, text: "I want coffee.", startOffset: 3, endOffset: 5)
            ], analysis: nil
        )
    }

    private func audioFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("analysis-\(UUID().uuidString).m4a")
        try Data([1, 2, 3]).write(to: url)
        return url
    }

    private func session(statusCode: Int, data: Data) -> URLSession {
        StubURLProtocol.makeSession { request in
            let response = HTTPURLResponse(url: try #require(request.url), statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, data)
        }
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    private final class HandlerBox: @unchecked Sendable {
        private let lock = NSLock()
        private var handler: Handler?

        func set(_ handler: Handler?) {
            lock.lock()
            self.handler = handler
            lock.unlock()
        }

        func call(_ request: URLRequest) throws -> (HTTPURLResponse, Data) {
            lock.lock()
            let handler = self.handler
            lock.unlock()
            guard let handler else { throw URLError(.badServerResponse) }
            return try handler(request)
        }
    }

    private static let box = HandlerBox()

    static func makeSession(handler: @escaping Handler) -> URLSession {
        box.set(handler)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Self.self]
        return URLSession(configuration: configuration)
    }

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let (response, data) = try Self.box.call(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
