import Foundation

public enum AIPackError: Error, Sendable, Equatable {
    case apiKeyRequired(providerName: String)
    case downloadRequired(packName: String, sizeDescription: String)
    case deviceNotSupported(reason: String)
    case noPackAvailable

    case llmFailed(packName: String, underlyingMessage: String)
    case ttsFailed(packName: String, underlyingMessage: String)
    case sttFailed(packName: String, underlyingMessage: String)
    case networkUnavailable

    public var localizedKey: String {
        switch self {
        case .apiKeyRequired: return "app.ai.error.api_key_required"
        case .downloadRequired: return "app.ai.error.download_required"
        case .deviceNotSupported: return "app.ai.error.device_not_supported"
        case .noPackAvailable: return "app.ai.error.no_pack_available"
        case .llmFailed: return "app.ai.error.llm_failed"
        case .ttsFailed: return "app.ai.error.tts_failed"
        case .sttFailed: return "app.ai.error.stt_failed"
        case .networkUnavailable: return "app.ai.error.network_unavailable"
        }
    }
}
