import AVFoundation
import Foundation
import os

private final class AudioPlayerTransferBox: @unchecked Sendable {
    let player: AVAudioPlayer

    init(_ player: AVAudioPlayer) {
        self.player = player
    }
}

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

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "GeminiAudio")

    /// Converts raw 24kHz 16-bit 1-channel PCM data to WAV container format if not already wrapped in RIFF.
    public nonisolated static func pcmToWav(data: Data, sampleRate: Int = 24000, channels: Int = 1, bitsPerSample: Int = 16) -> Data {
        if data.count >= 4 && data.prefix(4) == Data([0x52, 0x49, 0x46, 0x46]) {
            return data
        }
        var header = Data()
        let byteRate = sampleRate * channels * (bitsPerSample / 8)
        let blockAlign = channels * (bitsPerSample / 8)
        let totalChunkSize = 36 + data.count

        // RIFF header
        header.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        var chunkSize = UInt32(totalChunkSize).littleEndian
        withUnsafeBytes(of: &chunkSize) { header.append(contentsOf: $0) }
        header.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"

        // fmt chunk
        header.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        var subchunk1Size = UInt32(16).littleEndian
        withUnsafeBytes(of: &subchunk1Size) { header.append(contentsOf: $0) }
        var audioFormat = UInt16(1).littleEndian // PCM = 1
        withUnsafeBytes(of: &audioFormat) { header.append(contentsOf: $0) }
        var numChannels = UInt16(channels).littleEndian
        withUnsafeBytes(of: &numChannels) { header.append(contentsOf: $0) }
        var sRate = UInt32(sampleRate).littleEndian
        withUnsafeBytes(of: &sRate) { header.append(contentsOf: $0) }
        var bRate = UInt32(byteRate).littleEndian
        withUnsafeBytes(of: &bRate) { header.append(contentsOf: $0) }
        var bAlign = UInt16(blockAlign).littleEndian
        withUnsafeBytes(of: &bAlign) { header.append(contentsOf: $0) }
        var bPerSample = UInt16(bitsPerSample).littleEndian
        withUnsafeBytes(of: &bPerSample) { header.append(contentsOf: $0) }

        // data chunk
        header.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        var subchunk2Size = UInt32(data.count).littleEndian
        withUnsafeBytes(of: &subchunk2Size) { header.append(contentsOf: $0) }

        return header + data
    }

    public func buildRequest(text: String, persona: VoicePersona, apiKey: String) throws -> URLRequest {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            Self.logger.error("Gemini API key is empty when building TTS request")
            throw URLError(.userAuthenticationRequired)
        }

        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent")
        components?.queryItems = [URLQueryItem(name: "key", value: trimmedKey)]
        guard let url = components?.url else {
            Self.logger.error("Failed to build Gemini TTS URL")
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 8.0

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

            guard let httpResponse = response as? HTTPURLResponse else {
                Self.logger.error("Gemini TTS response is not HTTPURLResponse")
                throw URLError(.badServerResponse)
            }

            guard httpResponse.statusCode == 200 else {
                let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
                Self.logger.error("Gemini TTS HTTP error statusCode=\(httpResponse.statusCode) body=\(errorBody)")
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
                Self.logger.error("Gemini TTS failed to decode base64 inline audio data from JSON response")
                throw URLError(.cannotParseResponse)
            }

            let wavData = Self.pcmToWav(data: decoded)
            audioData = wavData
            storeInCache(key: key, data: wavData)
            Self.logger.notice("Gemini TTS synthesized successfully (\(wavData.count) bytes)")
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
            if !player.play() {
                self.activeContinuation = nil
                self.audioPlayer = nil
                self.isSpeaking = false
                continuation.resume(throwing: URLError(.cannotDecodeContentData))
            }
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

    func attachPlayerForTesting(_ player: AVAudioPlayer) {
        self.audioPlayer = player
        self.isSpeaking = true
    }

    // MARK: - AVAudioPlayerDelegate

    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let box = AudioPlayerTransferBox(player)
        Task { @MainActor [weak self] in
            guard let self, self.audioPlayer === box.player else { return }
            self.isSpeaking = false
            self.audioPlayer = nil
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume(returning: ())
            }
        }
    }

    public nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        let box = AudioPlayerTransferBox(player)
        Task { @MainActor [weak self] in
            guard let self, self.audioPlayer === box.player else { return }
            self.isSpeaking = false
            self.audioPlayer = nil
            if let continuation = self.activeContinuation {
                self.activeContinuation = nil
                continuation.resume(throwing: error ?? URLError(.cannotDecodeContentData))
            }
        }
    }
}
