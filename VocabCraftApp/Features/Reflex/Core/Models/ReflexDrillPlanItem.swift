import Foundation

/// Immutable pre-generated blueprint for a single Reflex drill step.
public struct ReflexDrillPlanItem: Identifiable, Equatable, Sendable {
    public let id: String
    public let word: any ReflexDrillable
    public let assignedMode: ReflexMode
    public let options: [ReflexBlitzOption]
    public let correctOptionIndex: Int
    public let eliminatedOptionId: String?
    public let clozeStages: ReflexClozeStageSet
    public let hintBadgeText: String

    public init(
        id: String,
        word: any ReflexDrillable,
        assignedMode: ReflexMode,
        options: [ReflexBlitzOption],
        correctOptionIndex: Int,
        eliminatedOptionId: String?,
        clozeStages: ReflexClozeStageSet,
        hintBadgeText: String
    ) {
        self.id = id
        self.word = word
        self.assignedMode = assignedMode
        self.options = options
        self.correctOptionIndex = correctOptionIndex
        self.eliminatedOptionId = eliminatedOptionId
        self.clozeStages = clozeStages
        self.hintBadgeText = hintBadgeText
    }

    public static func == (lhs: ReflexDrillPlanItem, rhs: ReflexDrillPlanItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.word.lemma == rhs.word.lemma &&
        lhs.assignedMode == rhs.assignedMode &&
        lhs.options == rhs.options &&
        lhs.correctOptionIndex == rhs.correctOptionIndex &&
        lhs.eliminatedOptionId == rhs.eliminatedOptionId &&
        lhs.clozeStages == rhs.clozeStages &&
        lhs.hintBadgeText == rhs.hintBadgeText
    }
}
