import Foundation

public enum QuickDrillStepType: String, Equatable, Sendable {
    case pronunciation // Step 1: Read example sentence using mic
    case fastMeaning   // Step 2: Pick correct VN definition under time limit
    case fillInBlank   // Step 3: Complete context sentence missing lemma
}

public struct QuickDrillStep: Identifiable, Equatable, Sendable {
    public let id: Int
    public let type: QuickDrillStepType
    public let promptText: String
    public let targetText: String
    public let options: [String]
    public let sentenceWithGap: String?

    public init(
        id: Int,
        type: QuickDrillStepType,
        promptText: String,
        targetText: String,
        options: [String] = [],
        sentenceWithGap: String? = nil
    ) {
        self.id = id
        self.type = type
        self.promptText = promptText
        self.targetText = targetText
        self.options = options
        self.sentenceWithGap = sentenceWithGap
    }
}
