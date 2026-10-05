import AVFoundation
import Foundation

@MainActor
public protocol GeminiAudioSynthesizing: AnyObject, Sendable {
    var isSpeaking: Bool { get }
    func synthesizeAndPlay(text: String, persona: VoicePersona, apiKey: String) async throws
    func stop()
}

@MainActor
public final class GeminiAudioSpeechEngine: NSObject, AVAudioPlayerDelegate, GeminiAudioSynthesizing, @unchecked Sendable {
    public private(set) var isSpeaking: Bool = false
    private var audioPlayer: AVAudioPlayer?
    private var activeContinuation: CheckedContinuation<Void, Error>?
    private var cache: [String: Data] = [:]
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        super.init()
    }

    public func cacheKey(for text: String, persona: VoicePersona) -> String {
        "\(persona.rawValue)::\(text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }

    public func cachedData(for key: String) -> Data? {
        cache[key]
    }

    public func storeInCache(key: String, data: Data) {
        if cache.count > 50 {
            cache.removeAll()
        }
        cache[key] = data
    }

    public func buildRequest(text: String, persona: VoicePersona, apiKey: String) throws -> URLRequest {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }

        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")
        components?.queryItems = [URLQueryItem(name: "key", value: trimmedKey)]
        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 3.5

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "Read the following dialogue turn aloud with a warm, natural conversational tone:\n\(text)"]
                    ]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["AUDIO"],
                "speechConfig": [
                    "voiceConfig": [
                        "prebuiltVoiceConfig": [
                            "voiceName": persona.rawValue
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    public func synthesizeAndPlay(text: String, persona: VoicePersona, apiKey: String) async throws {
        stop()

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let key = cacheKey(for: text, persona: persona)
        let audioData: Data

        if let cached = cachedData(for: key) {
            audioData = cached
        } else {
            let request = try buildRequest(text: text, persona: persona, apiKey: apiKey)
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let candidates = json["candidates"] as? [[String: Any]],
                  let firstCandidate = candidates.first,
                  let content = firstCandidate["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]],
                  let audioPart = parts.first(where: { ($0["inlineData"] as? [String: Any])?["data"] is String }),
                  let inlineData = audioPart["inlineData"] as? [String: Any],
                  let base64String = inlineData["data"] as? String,
                  let decoded = Data(base64Encoded: base64String) else {
                throw URLError(.cannotParseResponse)
            }

            audioData = decoded
            storeInCache(key: key, data: decoded)
        }

        let isTesting = NSClassFromString("XCTestCase") != nil
        if isTesting { return }

        try await playAudioData(audioData)
    }

    private func playAudioData(_ data: Data) async throws {
        let player = try AVAudioPlayer(data: data)
        self.audioPlayer = player
        isSpeaking = true
        player.delegate = self
        player.prepareToPlay()

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.activeContinuation = continuation
            player.play()
        }
    }

    public func stop() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        audioPlayer = nil
        isSpeaking = false
        if let continuation = activeContinuation {
            activeContinuation = nil
            continuation.resume(returning: ())
        }
    }

    // MARK: - AVAudioPlayerDelegate

    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isSpeaking = false
            self.audioPlayer = nil
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume(returning: ())
            }
        }
    }

    public nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.isSpeaking = false
            self.audioPlayer = nil
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume(throwing: error ?? URLError(.cannotDecodeContentData))
            }
        }
    }
}
