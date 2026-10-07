import Foundation

public enum AIPackStatus: Sendable, Equatable {
    case ready
    case needsDownload(sizeDescription: String)
    case needsApiKey(providerName: String)
    case partiallyReady(ready: [String], notReady: [String])
    case unavailable(reason: String)
}
