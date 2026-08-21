import Foundation

public protocol GenerateMixedReflexQueueUseCaseProtocol: Sendable {
    func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem]
    func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem
}

public final class GenerateMixedReflexQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol, Sendable {
    public init() {}

    public func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] {
        let allModes = ReflexBlitzMode.allCases
        return words.map { word in
            let randomMode = allModes.randomElement() ?? .multipleChoice
            return MixedReflexDrillItem(word: word, assignedMode: randomMode, isRetry: false)
        }
    }

    public func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem {
        let alternativeModes = ReflexBlitzMode.allCases.filter { $0 != item.assignedMode }
        let newMode = alternativeModes.randomElement() ?? .multipleChoice
        return MixedReflexDrillItem(word: item.word, assignedMode: newMode, isRetry: true)
    }
}
