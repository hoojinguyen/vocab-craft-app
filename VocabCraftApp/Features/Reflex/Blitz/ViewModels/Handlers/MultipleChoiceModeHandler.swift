import Foundation

/// Strategy handler for Multiple Choice reflex drill modality.
@MainActor
public struct MultipleChoiceModeHandler: ReflexModeHandlerProtocol {
    public let mode: ReflexBlitzMode = .multipleChoice
    public let timeLimitSeconds: Double = 4.5

    public let hintMilestones: [ReflexHintMilestone] = [
        ReflexHintMilestone(stage: 1, delayMs: 1600),
        ReflexHintMilestone(stage: 2, delayMs: 2500),
        ReflexHintMilestone(stage: 3, delayMs: 3400)
    ]

    public var shouldSpeakOnReviewFlip: Bool { true }
    public var reviewSpeechRate: Float { 1.0 }
    public var reviewSpeechDelayMs: Int { 0 }

    public init() {}

    public func prepareWord(
        word: ReflexBlitzWordItem,
        allWords: [ReflexBlitzWordItem],
        planItem: ReflexDrillPlanItem?,
        ttsService: TextToSpeechProtocol,
        speechEngine: ReflexSpeechEngineProtocol,
        isKeyboardFallback: Bool
    ) -> ModeWordPreparationResult {
        if let planItem {
            return ModeWordPreparationResult(
                options: planItem.options,
                clozeStages: planItem.clozeStages,
                eliminatedOptionId: planItem.eliminatedOptionId,
                hintBadgeText: planItem.hintBadgeText
            )
        } else {
            let options = word.generateOptions(mode: .multipleChoice, allPool: allWords)
            return ModeWordPreparationResult(
                options: options,
                clozeStages: nil,
                eliminatedOptionId: nil,
                hintBadgeText: ""
            )
        }
    }

    public func hintStage(forElapsedTimeMs ms: Int) -> Int {
        if ms >= 3400 { return 3 }
        if ms >= 2500 { return 2 }
        if ms >= 1600 { return 1 }
        return 0
    }
}
