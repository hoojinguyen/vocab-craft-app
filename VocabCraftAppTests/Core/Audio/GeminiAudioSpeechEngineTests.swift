import AVFoundation
import Foundation
import Testing
@testable import VocabCraftApp

private final class MockAudioURLProtocol: URLProtocol, @unchecked Sendable {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var _requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _requestHandler
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _requestHandler = newValue
        }
    }

    override static func canInit(with request: URLRequest) -> Bool {
        true
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class CallTracker: @unchecked Sendable {
    var wasCalled = false
}

@Suite("Gemini Audio Speech Engine Tests", .serialized)
struct GeminiAudioSpeechEngineTests {
    private func makeMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockAudioURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func makeGeminiAudioResponseJSON(base64Audio: String) throws -> Data {
        let json: [String: Any] = [
            "candidates": [
                [
                    "content": [
                        "parts": [
                            [
                                "inlineData": [
                                    "mimeType": "audio/wav",
                                    "data": base64Audio
                                ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
        return try JSONSerialization.data(withJSONObject: json)
    }

    @Test("Verify audio cache generates consistent key and stores audio")
    @MainActor
    func test_cacheKeyAndStorage() {
        let engine = GeminiAudioSpeechEngine()
        let fakeData = Data([0x52, 0x49, 0x46, 0x46]) // "RIFF"
        let key = engine.cacheKey(for: "Hello barista", persona: .friendlyFemale)

        #expect(!key.isEmpty)
        #expect(key == "Aoede::hello barista")
        engine.storeInCache(key: key, data: fakeData)
        #expect(engine.cachedData(for: key) == fakeData)
    }

    @Test("Verify request builder constructs correct REST URL and payload")
    @MainActor
    func test_requestBuilder() throws {
        let engine = GeminiAudioSpeechEngine()
        let request = try engine.buildRequest(text: "Welcome to London", persona: .friendlyMale, apiKey: "test-api-key")

        let urlString = request.url?.absoluteString ?? ""
        #expect(urlString.contains("generativelanguage.googleapis.com"))
        #expect(urlString.contains("gemini-3.1-flash-tts-preview") || urlString.contains("gemini-2.5-flash"))
        #expect(request.url?.query?.contains("key=test-api-key") == true)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.timeoutInterval == 8.0)

        guard let bodyData = request.httpBody,
              let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any] else {
            Issue.record("Expected valid JSON request body")
            return
        }

        if let contents = json["contents"] as? [[String: Any]],
           let firstContent = contents.first,
           let parts = firstContent["parts"] as? [[String: Any]],
           let firstPart = parts.first,
           let promptText = firstPart["text"] as? String {
            #expect(promptText.contains("Welcome to London"))
        } else {
            Issue.record("Missing contents in request body")
        }

        if let generationConfig = json["generationConfig"] as? [String: Any],
           let modalities = generationConfig["responseModalities"] as? [String] {
            #expect(modalities == ["AUDIO"])
        } else {
            Issue.record("Missing responseModalities")
        }

        if let generationConfig = json["generationConfig"] as? [String: Any],
           let speechConfig = generationConfig["speechConfig"] as? [String: Any],
           let voiceConfig = speechConfig["voiceConfig"] as? [String: Any],
           let prebuiltConfig = voiceConfig["prebuiltVoiceConfig"] as? [String: Any],
           let voiceName = prebuiltConfig["voiceName"] as? String {
            #expect(voiceName == VoicePersona.friendlyMale.rawValue)
        } else {
            Issue.record("Missing prebuiltVoiceConfig")
        }
    }

    @Test("Verify request builder maps all VoicePersonas correctly")
    @MainActor
    func test_requestBuilder_allPersonas() throws {
        let engine = GeminiAudioSpeechEngine()

        for persona in VoicePersona.allCases {
            let request = try engine.buildRequest(text: "Hello", persona: persona, apiKey: "test-key")
            guard let bodyData = request.httpBody,
                  let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
                  let generationConfig = json["generationConfig"] as? [String: Any],
                  let speechConfig = generationConfig["speechConfig"] as? [String: Any],
                  let voiceConfig = speechConfig["voiceConfig"] as? [String: Any],
                  let prebuiltConfig = voiceConfig["prebuiltVoiceConfig"] as? [String: Any],
                  let voiceName = prebuiltConfig["voiceName"] as? String else {
                Issue.record("Failed to parse request JSON for persona \(persona)")
                continue
            }

            #expect(voiceName == persona.rawValue)
        }
    }

    @Test("Verify request builder throws when API key is empty")
    @MainActor
    func test_requestBuilder_emptyApiKey() {
        let engine = GeminiAudioSpeechEngine()
        #expect(throws: URLError.self) {
            try engine.buildRequest(text: "Hello", persona: .friendlyFemale, apiKey: "   ")
        }
    }

    @Test("Verify synthesizeAndPlay fetches audio, decodes base64, and caches it")
    @MainActor
    func test_synthesizeAndPlay_successAndCaching() async throws {
        let fakeData = Data([0x52, 0x49, 0x46, 0x46, 0x01, 0x02, 0x03, 0x04])
        let jsonResponse = try makeGeminiAudioResponseJSON(base64Audio: fakeData.base64EncodedString())

        MockAudioURLProtocol.requestHandler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
            return (response, jsonResponse)
        }

        let session = makeMockSession()
        let engine = GeminiAudioSpeechEngine(urlSession: session)

        let text = "Good morning barista"
        let persona = VoicePersona.friendlyFemale
        try await engine.synthesizeAndPlay(text: text, persona: persona, apiKey: "valid-key")

        let key = engine.cacheKey(for: text, persona: persona)
        #expect(engine.cachedData(for: key) == fakeData)

        // Second call should hit cache without invoking network handler
        MockAudioURLProtocol.requestHandler = { _ in
            throw URLError(.cannotConnectToHost)
        }

        try await engine.synthesizeAndPlay(text: text, persona: persona, apiKey: "valid-key")
        #expect(engine.cachedData(for: key) == fakeData)
    }

    @Test("Verify synthesizeAndPlay throws on HTTP server error")
    @MainActor
    func test_synthesizeAndPlay_httpServerError() async {
        MockAudioURLProtocol.requestHandler = { request in
            guard let url = request.url else { throw URLError(.badURL) }
            let response = HTTPURLResponse(url: url, statusCode: 500, httpVersion: "HTTP/1.1", headerFields: nil)!
            return (response, Data())
        }

        let session = makeMockSession()
        let engine = GeminiAudioSpeechEngine(urlSession: session)

        await #expect(throws: URLError.self) {
            try await engine.synthesizeAndPlay(text: "Hello", persona: .friendlyMale, apiKey: "key")
        }
    }

    @Test("Verify synthesizeAndPlay throws on malformed JSON response")
    @MainActor
    func test_synthesizeAndPlay_malformedResponse() async {
        let session = makeMockSession()
        let engine = GeminiAudioSpeechEngine(urlSession: session)

        await #expect(throws: URLError.self) {
            let malformed = Data("{\"candidates\": []}".utf8)
            MockAudioURLProtocol.requestHandler = { request in
                guard let url = request.url else { throw URLError(.badURL) }
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
                return (response, malformed)
            }
            try await engine.synthesizeAndPlay(text: "Hello", persona: .friendlyMale, apiKey: "key")
        }
    }

    @Test("Verify synthesizeAndPlay with empty or whitespace text completes early")
    @MainActor
    func test_synthesizeAndPlay_emptyText() async throws {
        let tracker = CallTracker()
        MockAudioURLProtocol.requestHandler = { request in
            tracker.wasCalled = true
            guard let url = request.url else { throw URLError(.badURL) }
            return (HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data())
        }

        let session = makeMockSession()
        let engine = GeminiAudioSpeechEngine(urlSession: session)

        try await engine.synthesizeAndPlay(text: "   \n\t  ", persona: .friendlyFemale, apiKey: "key")
        #expect(!tracker.wasCalled)
        #expect(!engine.isSpeaking)
    }

    @Test("Verify cache eviction flushes entries when limit is exceeded")
    @MainActor
    func test_cacheEviction_limit() {
        let engine = GeminiAudioSpeechEngine()
        let fakeData = Data([0x01])

        for index in 0...51 {
            let key = "key_\(index)"
            engine.storeInCache(key: key, data: fakeData)
        }

        // Cache count should reset when exceeding 50, ending up small
        #expect(engine.cachedData(for: "key_51") != nil)
        #expect(engine.cachedData(for: "key_0") == nil)
    }

    @Test("Verify stop resets speaking state")
    @MainActor
    func test_stop_resetsState() {
        let engine = GeminiAudioSpeechEngine()
        #expect(!engine.isSpeaking)
        engine.stop()
        #expect(!engine.isSpeaking)
    }

    private func makeValidWavData() -> Data {
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        let fileSize: UInt32 = 44 + 100 - 8
        withUnsafeBytes(of: fileSize.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: "WAVEfmt ".utf8)
        let subchunk1Size: UInt32 = 16
        withUnsafeBytes(of: subchunk1Size.littleEndian) { data.append(contentsOf: $0) }
        let audioFormat: UInt16 = 1
        withUnsafeBytes(of: audioFormat.littleEndian) { data.append(contentsOf: $0) }
        let numChannels: UInt16 = 1
        withUnsafeBytes(of: numChannels.littleEndian) { data.append(contentsOf: $0) }
        let sampleRate: UInt32 = 8000
        withUnsafeBytes(of: sampleRate.littleEndian) { data.append(contentsOf: $0) }
        let byteRate: UInt32 = 8000 * 1 * 2
        withUnsafeBytes(of: byteRate.littleEndian) { data.append(contentsOf: $0) }
        let blockAlign: UInt16 = 2
        withUnsafeBytes(of: blockAlign.littleEndian) { data.append(contentsOf: $0) }
        let bitsPerSample: UInt16 = 16
        withUnsafeBytes(of: bitsPerSample.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: "data".utf8)
        let subchunk2Size: UInt32 = 100
        withUnsafeBytes(of: subchunk2Size.littleEndian) { data.append(contentsOf: $0) }
        data.append(contentsOf: [UInt8](repeating: 0, count: 100))
        return data
    }

    private func makeValidTestPlayer() throws -> AVAudioPlayer {
        try AVAudioPlayer(data: makeValidWavData())
    }

    @Test("Verify delegate didFinish callbacks reset state when player matches")
    @MainActor
    func test_delegateDidFinishPlaying() async throws {
        let engine = GeminiAudioSpeechEngine()
        let player = try makeValidTestPlayer()
        engine.attachPlayerForTesting(player)
        #expect(engine.isSpeaking)

        engine.audioPlayerDidFinishPlaying(player, successfully: true)
        await Task.yield()
        #expect(!engine.isSpeaking)
    }

    @Test("Verify delegate didFinish ignores stale callbacks from mismatched player")
    @MainActor
    func test_delegateDidFinishPlaying_staleIgnored() async throws {
        let engine = GeminiAudioSpeechEngine()
        let activePlayer = try makeValidTestPlayer()
        let stalePlayer = try makeValidTestPlayer()
        engine.attachPlayerForTesting(activePlayer)
        #expect(engine.isSpeaking)

        engine.audioPlayerDidFinishPlaying(stalePlayer, successfully: true)
        await Task.yield()
        #expect(engine.isSpeaking)
    }

    @Test("Verify delegate decodeError callback resets state when player matches")
    @MainActor
    func test_delegateDecodeError() async throws {
        let engine = GeminiAudioSpeechEngine()
        let player = try makeValidTestPlayer()
        engine.attachPlayerForTesting(player)
        #expect(engine.isSpeaking)

        engine.audioPlayerDecodeErrorDidOccur(player, error: URLError(.cannotDecodeContentData))
        await Task.yield()
        #expect(!engine.isSpeaking)
    }

    @Test("Verify delegate decodeError ignores stale callbacks from mismatched player")
    @MainActor
    func test_delegateDecodeError_staleIgnored() async throws {
        let engine = GeminiAudioSpeechEngine()
        let activePlayer = try makeValidTestPlayer()
        let stalePlayer = try makeValidTestPlayer()
        engine.attachPlayerForTesting(activePlayer)
        #expect(engine.isSpeaking)

        engine.audioPlayerDecodeErrorDidOccur(stalePlayer, error: URLError(.cannotDecodeContentData))
        await Task.yield()
        #expect(engine.isSpeaking)
    }

    @Test("Verify pcmToWav wraps raw PCM in valid RIFF WAV container")
    func test_pcmToWav_wrapsRawPCM() throws {
        let rawPCM = Data(repeating: 0x20, count: 4800) // 100ms of 24kHz 16-bit mono
        let wavData = GeminiAudioSpeechEngine.pcmToWav(data: rawPCM, sampleRate: 24000, channels: 1, bitsPerSample: 16)

        #expect(wavData.count == rawPCM.count + 44)
        #expect(wavData.prefix(4) == Data([0x52, 0x49, 0x46, 0x46])) // "RIFF"
        #expect(wavData[8..<12] == Data([0x57, 0x41, 0x56, 0x45])) // "WAVE"
        #expect(wavData[12..<16] == Data([0x66, 0x6D, 0x74, 0x20])) // "fmt "
        #expect(wavData[36..<40] == Data([0x64, 0x61, 0x74, 0x61])) // "data"

        let player = try AVAudioPlayer(data: wavData)
        #expect(player.duration > 0.09)
        #expect(player.numberOfChannels == 1)
    }

    @Test("Verify pcmToWav leaves already-wrapped RIFF data untouched")
    func test_pcmToWav_idempotentOnRiff() {
        let alreadyWav = Data([0x52, 0x49, 0x46, 0x46, 0x01, 0x02, 0x03, 0x04])
        let result = GeminiAudioSpeechEngine.pcmToWav(data: alreadyWav)
        #expect(result == alreadyWav)
    }
}
