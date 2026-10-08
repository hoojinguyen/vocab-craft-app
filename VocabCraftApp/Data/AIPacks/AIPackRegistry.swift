import Foundation
import Observation

public struct AIPackEntry: Sendable, Identifiable, Equatable {
    public var id: AIPackIdentifier { identifier }
    public let identifier: AIPackIdentifier
    public let displayName: String
    public let description: String
    public let status: AIPackStatus
    public let isActive: Bool

    public init(
        identifier: AIPackIdentifier,
        displayName: String,
        description: String,
        status: AIPackStatus,
        isActive: Bool
    ) {
        self.identifier = identifier
        self.displayName = displayName
        self.description = description
        self.status = status
        self.isActive = isActive
    }
}

@MainActor
@Observable
public final class AIPackRegistry {
    private let packs: [AIPackIdentifier: any AIPackProtocol]
    private let settingsStore: UserSettingsStore
    public private(set) var activePackId: AIPackIdentifier
    public private(set) var activePackIssue: AIPackError?

    public init(packs: [any AIPackProtocol], settingsStore: UserSettingsStore) {
        var packMap: [AIPackIdentifier: any AIPackProtocol] = [:]
        for pack in packs {
            packMap[pack.identifier] = pack
        }
        self.packs = packMap
        self.settingsStore = settingsStore

        let saved = AIPackIdentifier(rawValue: settingsStore.selectedAIPackId) ?? .geminiCloud
        self.activePackId = saved
        self.revalidateActivePack()
    }

    public var activePack: (any AIPackProtocol)? {
        pack(for: activePackId)
    }

    public var packCatalog: [AIPackEntry] {
        packs.values.map { pack in
            AIPackEntry(
                identifier: pack.identifier,
                displayName: pack.displayName,
                description: pack.packDescription,
                status: pack.status,
                isActive: pack.identifier == activePackId
            )
        }.sorted { $0.identifier.rawValue < $1.identifier.rawValue }
    }

    public func selectPack(_ id: AIPackIdentifier) throws(AIPackError) {
        guard let pack = packs[id] else {
            throw .noPackAvailable
        }

        switch pack.status {
        case .ready:
            self.activePackId = id
            self.settingsStore.selectedAIPackId = id.rawValue
            self.activePackIssue = nil
        case .needsApiKey(let provider):
            throw .apiKeyRequired(providerName: provider)
        case .needsDownload(let size):
            throw .downloadRequired(packName: pack.displayName, sizeDescription: size)
        case .unavailable(let reason):
            throw .deviceNotSupported(reason: reason)
        case .partiallyReady:
            throw .downloadRequired(packName: pack.displayName, sizeDescription: "Incomplete models")
        }
    }

    public func resolveActivePack() throws(AIPackError) -> any AIPackProtocol {
        guard let pack = packs[activePackId] else {
            throw .noPackAvailable
        }
        guard pack.status == .ready else {
            switch pack.status {
            case .needsApiKey(let provider):
                throw .apiKeyRequired(providerName: provider)
            case .needsDownload(let size):
                throw .downloadRequired(packName: pack.displayName, sizeDescription: size)
            case .unavailable(let reason):
                throw .deviceNotSupported(reason: reason)
            case .partiallyReady:
                throw .downloadRequired(packName: pack.displayName, sizeDescription: "Incomplete models")
            case .ready:
                throw .noPackAvailable
            }
        }
        return pack
    }

    public func resolveActiveLLM() throws(AIPackError) -> any LLMProviderProtocol {
        try resolveActivePack().makeLLMProvider()
    }

    public func resolveActiveTTS() throws(AIPackError) -> any TTSEngineProtocol {
        try resolveActivePack().makeTTSEngine()
    }

    public func resolveActiveSTT() throws(AIPackError) -> any STTEngineProtocol {
        try resolveActivePack().makeSTTEngine()
    }

    public func revalidateActivePack() {
        guard let pack = packs[activePackId] else {
            activePackIssue = .noPackAvailable
            return
        }
        switch pack.status {
        case .ready:
            activePackIssue = nil
        case .needsApiKey(let provider):
            activePackIssue = .apiKeyRequired(providerName: provider)
        case .needsDownload(let size):
            activePackIssue = .downloadRequired(packName: pack.displayName, sizeDescription: size)
        case .unavailable(let reason):
            activePackIssue = .deviceNotSupported(reason: reason)
        case .partiallyReady:
            activePackIssue = .downloadRequired(packName: pack.displayName, sizeDescription: "Incomplete models")
        }
    }

    public func pack(for id: AIPackIdentifier) -> (any AIPackProtocol)? {
        packs[id]
    }
}
