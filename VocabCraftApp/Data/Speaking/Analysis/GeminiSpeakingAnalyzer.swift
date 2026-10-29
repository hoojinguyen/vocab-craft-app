import Foundation

public struct GeminiSpeakingAnalyzer: SpeakingAnalyzing {
    private let apiKey: @Sendable () async -> String
    private let urlSession: URLSession

    public init(apiKey: @escaping @Sendable () async -> String, session: URLSession = .shared) {
        self.apiKey = apiKey
        urlSession = session
    }

    public func analyze(_ session: SpeakingSessionSnapshot, audioURL: URL) async throws -> SpeakingAnalysis {
        let key = await apiKey().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw SpeakingAnalysisError.missingKey }

        let audio: Data
        do {
            audio = try Data(contentsOf: audioURL)
        } catch {
            throw SpeakingAnalysisError.audioUnavailable
        }
        let request = try SpeakingAnalysisRequestBuilder.makeRequest(apiKey: key, session: session, audio: audio)

        let responseData: Data
        let response: URLResponse
        do {
            (responseData, response) = try await urlSession.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw SpeakingAnalysisError.network
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpeakingAnalysisError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200..<300:
            break
        case 401, 403:
            throw SpeakingAnalysisError.unauthorized
        case 429:
            throw SpeakingAnalysisError.quotaExceeded
        default:
            throw SpeakingAnalysisError.invalidResponse
        }

        do {
            let envelope = try JSONDecoder().decode(GenerateContentResponse.self, from: responseData)
            guard let text = envelope.candidates.first?.content.parts.first?.text,
                  let data = text.data(using: .utf8) else {
                throw SpeakingAnalysisError.invalidResponse
            }
            let raw = try JSONDecoder().decode(SpeakingAnalysis.self, from: data)
            return try SpeakingAnalysisValidator.validate(raw, plan: session.plan)
        } catch let error as SpeakingAnalysisError {
            throw error
        } catch {
            throw SpeakingAnalysisError.invalidResponse
        }
    }
}

private struct GenerateContentResponse: Decodable {
    let candidates: [GenerateContentCandidate]
}

private struct GenerateContentCandidate: Decodable {
    let content: GenerateContentContent
}

private struct GenerateContentContent: Decodable {
    let parts: [GenerateContentPart]
}

private struct GenerateContentPart: Decodable {
    let text: String?
}
