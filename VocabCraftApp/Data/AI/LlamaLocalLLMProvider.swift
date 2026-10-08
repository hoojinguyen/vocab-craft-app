import Foundation

/// On-device LLM provider backed by local Llama-3.2-1B neural model weights.
/// Guarantees zero silent fallback and fail-fast typed errors when models are missing.
public final class LlamaLocalLLMProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "llama-3.2-1b-local"

    private let worker: LlamaInferenceWorker
    private let isReadyProvider: (@Sendable () -> Bool)?

    public var isReady: Bool {
        if let provider = isReadyProvider {
            return provider()
        }
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                OnDemandAIModelManager.shared.isModelReady(.llama)
            }
        } else {
            return DispatchQueue.main.sync {
                OnDemandAIModelManager.shared.isModelReady(.llama)
            }
        }
    }

    public init(
        worker: LlamaInferenceWorker? = nil,
        isReadyProvider: (@Sendable () -> Bool)? = nil
    ) {
        self.worker = worker ?? LlamaInferenceWorker()
        self.isReadyProvider = isReadyProvider
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        // Zero Silent Fallback: Fail fast if model is not ready
        guard isReady else {
            throw AIPackError.downloadRequired(packName: "Llama 3.2 1B", sizeDescription: "~740MB")
        }

        do {
            let jsonString = try await worker.generateStructuredResponse(
                messages: messages,
                systemPrompt: systemPrompt
            )
            guard let data = jsonString.data(using: .utf8) else {
                throw AIPackError.llmFailed(
                    packName: "Offline AI Pack",
                    underlyingMessage: "Failed to convert model response to UTF-8 data"
                )
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch is CancellationError {
            throw CancellationError()
        } catch let packError as AIPackError {
            throw packError
        } catch {
            throw AIPackError.llmFailed(
                packName: "Offline AI Pack",
                underlyingMessage: error.localizedDescription
            )
        }
    }
}
