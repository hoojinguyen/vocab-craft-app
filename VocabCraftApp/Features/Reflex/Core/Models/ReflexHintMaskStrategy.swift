import Foundation

/// Strategy used to generate progressive cloze hint masking for Reflex drill items.
public enum ReflexHintMaskStrategy: Equatable, Sendable {
    case shortWordPrefix
    case shortWordSuffix
    case prefix(count: Int)
    case suffix(count: Int)
    case middleCluster(text: String, range: Range<Int>)
    case consonantScaffold
}
