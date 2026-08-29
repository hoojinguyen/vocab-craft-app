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

extension MixedReflexDrillItem: ReflexDrillable {
    public var lemma: String { word.lemma }
    public var pos: String { word.pos }
    public var ipa: String { word.ipa }
    public var definitionVi: String { word.definitionVi }
    public var exampleSentenceEn: String { word.exampleSentenceEn }
    public var exampleSentenceVi: String { word.exampleSentenceVi }
    public var clozeSentenceEn: String { word.clozeSentenceEn }
    public var cefrLevel: String { word.cefrLevel }
    public var audioResourceUrl: String? { word.audioResourceUrl }
}
