import Foundation

/// Errors that may arise when communicating with the Gemini API.
public enum GeminiError: Error, LocalizedError, Sendable, Equatable {
    case missingApiKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Gemini API key is not configured."
        case .invalidResponse:
            return "Invalid response received from Gemini API."
        case .apiError(let code, let msg):
            return "Gemini API error (\(code)): \(msg)"
        }
    }
}

/// Production LLM provider implementing Google Gemini 1.5 Flash client with JSON structured output.
public final class GeminiLLMProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "gemini-flash"
    private let apiKey: String
    private let session: URLSession

    /// Initializes a Gemini LLM provider with API key and optional URLSession.
    ///
    /// - Parameters:
    ///   - apiKey: Google Gemini API key string.
    ///   - session: URLSession instance for networking (defaults to .shared).
    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingApiKey
        }

        guard let endpoint = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)"
        ) else {
            throw GeminiError.invalidResponse
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let contents = messages.map { msg -> [String: Any] in
            let role = msg.role == .user ? "user" : "model"
            return [
                "role": role,
                "parts": [["text": msg.content]]
            ]
        }

        let payload: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": contents,
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.7
            ]
        ]

        let httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.httpBody = httpBody

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown"
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorText)
        }

        // Parse candidates[0].content.parts[0].text
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.invalidResponse
        }

        let rawData = Data(text.utf8)
        return try JSONDecoder().decode(T.self, from: rawData)
    }
}
