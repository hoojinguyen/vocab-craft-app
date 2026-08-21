import Foundation

public struct MixedReflexDrillItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let word: VaultWordItem
    public let assignedMode: ReflexBlitzMode
    public let isRetry: Bool

    public init(
        id: UUID = UUID(),
        word: VaultWordItem,
        assignedMode: ReflexBlitzMode,
        isRetry: Bool = false
    ) {
        self.id = id
        self.word = word
        self.assignedMode = assignedMode
        self.isRetry = isRetry
    }
}
