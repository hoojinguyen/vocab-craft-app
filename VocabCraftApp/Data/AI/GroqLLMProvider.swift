import Foundation
import os

public enum GroqError: Error, LocalizedError, Sendable, Equatable {
    case missingApiKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Groq API key is not configured."
        case .invalidResponse:
            return "Invalid response received from Groq API."
        case .apiError(let code, let msg):
            return "Groq API error (\(code)): \(msg)"
        }
    }
}

public final class GroqLLMProvider: LLMProviderProtocol, Sendable {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "VocabCraftApp", category: "GroqAI")
    public let providerIdentifier: String = "groq-llama"
    private let apiKey: String
    private let session: URLSession
    private let models: [String]
    private let fallbackProvider: (any LLMProviderProtocol)?

    public static let defaultModels: [String] = [
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant"
    ]

    public init(
        apiKey: String,
        session: URLSession = .shared,
        models: [String] = defaultModels,
        fallbackProvider: (any LLMProviderProtocol)? = nil
    ) {
        self.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        self.session = session
        self.models = models.isEmpty ? Self.defaultModels : models
        self.fallbackProvider = fallbackProvider
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        guard !apiKey.isEmpty else {
            Self.logger.warning("Groq API key is empty, checking fallback")
            if let fallback = fallbackProvider {
                return try await fallback.sendStructuredMessage(
                    messages: messages,
                    systemPrompt: systemPrompt,
                    responseSchema: responseSchema
                )
            }
            throw GroqError.missingApiKey
        }

        var lastError: Error?
        for model in models {
            do {
                let jsonContent = try await executeRequest(for: model, messages: messages, systemPrompt: systemPrompt)
                let cleanedData = Data(jsonContent.utf8)
                return try JSONDecoder().decode(T.self, from: cleanedData)
            } catch {
                lastError = error
                Self.logger.warning("Groq model \(model) failed: \(error.localizedDescription), trying next")
            }
        }

        if let fallback = fallbackProvider {
            Self.logger.notice("All Groq models failed, falling back to backup provider")
            return try await fallback.sendStructuredMessage(
                messages: messages,
                systemPrompt: systemPrompt,
                responseSchema: responseSchema
            )
        }

        if let lastError = lastError as? GroqError {
            throw lastError
        } else if let lastError {
            throw lastError
        } else {
            throw GroqError.invalidResponse
        }
    }

    private func executeRequest(
        for model: String,
        messages: [LLMChatMessage],
        systemPrompt: String
    ) async throws -> String {
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else {
            throw GroqError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        var formattedMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt + "\nAlways output valid JSON conforming to the requested schema. Do not wrap in markdown quotes if possible."]
        ]
        for msg in messages {
            let roleStr = (msg.role == .user) ? "user" : "assistant"
            formattedMessages.append(["role": roleStr, "content": msg.content])
        }

        let body: [String: Any] = [
            "model": model,
            "messages": formattedMessages,
            "temperature": 0.7,
            "response_format": ["type": "json_object"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw GroqError.apiError(statusCode: httpResponse.statusCode, message: errMsg)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw GroqError.invalidResponse
        }

        return cleanJsonString(content)
    }

    private func cleanJsonString(_ text: String) -> String {
        var clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("```json") {
            clean = String(clean.dropFirst(7))
        } else if clean.hasPrefix("```") {
            clean = String(clean.dropFirst(3))
        }
        if clean.hasSuffix("```") {
            clean = String(clean.dropLast(3))
        }
        return clean.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
