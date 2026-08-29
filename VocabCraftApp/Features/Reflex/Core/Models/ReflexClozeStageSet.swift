import Foundation

/// Immutable pre-computed stages for progressive cloze hint revelation in Reflex drills.
public struct ReflexClozeStageSet: Equatable, Sendable {
    public let initialParts: ClozeSentenceParts
    public let lengthMaskedParts: ClozeSentenceParts
    public let patternRevealedParts: ClozeSentenceParts
    public let maskedWordString: String
    public let strategy: ReflexHintMaskStrategy

    public init(
        initialParts: ClozeSentenceParts,
        lengthMaskedParts: ClozeSentenceParts,
        patternRevealedParts: ClozeSentenceParts,
        maskedWordString: String,
        strategy: ReflexHintMaskStrategy
    ) {
        self.initialParts = initialParts
        self.lengthMaskedParts = lengthMaskedParts
        self.patternRevealedParts = patternRevealedParts
        self.maskedWordString = maskedWordString
        self.strategy = strategy
    }
}
