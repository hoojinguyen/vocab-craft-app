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

extension AIPackError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .apiKeyRequired(let providerName):
            return "API key required for \(providerName)"
        case .downloadRequired(let packName, let sizeDescription):
            return "Download required for \(packName) (\(sizeDescription))"
        case .deviceNotSupported(let reason):
            return reason
        case .noPackAvailable:
            return "No AI pack available"
        case .llmFailed(_, let underlyingMessage):
            return underlyingMessage
        case .ttsFailed(_, let underlyingMessage):
            return underlyingMessage
        case .sttFailed(_, let underlyingMessage):
            return underlyingMessage
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}
