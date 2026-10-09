import Foundation
import os

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

/// Production LLM provider implementing Google Gemini Flash client with JSON structured output.
public final class GeminiLLMProvider: LLMProviderProtocol, Sendable {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "GeminiAI")
    public let providerIdentifier: String = "gemini-flash"
    private let apiKey: String
    private let session: URLSession
    private let models: [String]

    public static let defaultModels: [String] = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.0-flash"
    ]

    /// Initializes a Gemini LLM provider with API key, optional URLSession, and candidate models.
    ///
    /// - Parameters:
    ///   - apiKey: Google Gemini API key string.
    ///   - session: URLSession instance for networking (defaults to .shared).
    ///   - models: List of candidate model IDs in preference order.
    public init(
        apiKey: String,
        session: URLSession = .shared,
        models: [String] = defaultModels
    ) {
        self.apiKey = apiKey
        self.session = session
        self.models = models.isEmpty ? Self.defaultModels : models
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        guard !apiKey.isEmpty else {
            Self.logger.error("Gemini API key is missing or empty")
            throw GeminiError.missingApiKey
        }

        var lastError: Error?
        for modelName in models {
            do {
                let cleanedText = try await executeRequest(for: modelName, messages: messages, systemPrompt: systemPrompt)
                let rawData = Data(cleanedText.utf8)
                return try JSONDecoder().decode(T.self, from: rawData)
            } catch {
                lastError = error
                Self.logger.warning("Gemini model \(modelName) failed: \(error.localizedDescription), trying next model if available")
            }
        }

        if let lastError = lastError as? GeminiError {
            throw lastError
        } else if let lastError {
            throw lastError
        } else {
            throw GeminiError.invalidResponse
        }
    }

    private func executeRequest(for modelName: String, messages: [LLMChatMessage], systemPrompt: String) async throws -> String {
        guard let endpoint = URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
        ) else {
            throw GeminiError.invalidResponse
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 10.0

        let contents = messages.map { msg -> [String: Any] in
            let role = msg.role == .user ? "user" : "model"
            return [
                "role": role,
                "parts": [["text": msg.content]]
            ]
        }

        let payload: [String: Any] = [
            "systemInstruction": ["parts": [["text": systemPrompt]]],
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
            Self.logger.error("Gemini response is not HTTPURLResponse for \(modelName)")
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown"
            Self.logger.error("Gemini API error for \(modelName) statusCode=\(httpResponse.statusCode) message=\(errorText)")
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorText)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let textPart = parts.first(where: { ($0["text"] as? String)?.isEmpty == false }),
              let rawText = textPart["text"] as? String else {
            Self.logger.error("Failed to parse candidates text from Gemini JSON for \(modelName)")
            throw GeminiError.invalidResponse
        }

        Self.logger.notice("Gemini LLM response received successfully using \(modelName)")
        return Self.cleanJSONText(rawText)
    }

    private static func cleanJSONText(_ rawText: String) -> String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```json") && trimmed.hasSuffix("```") {
            return String(trimmed.dropFirst(7).dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if trimmed.hasPrefix("```") && trimmed.hasSuffix("```") {
            return String(trimmed.dropFirst(3).dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return trimmed
        }
    }
}
