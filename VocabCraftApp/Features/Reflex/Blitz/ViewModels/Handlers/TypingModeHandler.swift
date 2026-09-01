import Foundation

/// Strategy handler for Typing reflex drill modality.
@MainActor
public struct TypingModeHandler: ReflexModeHandlerProtocol {
    public let mode: ReflexBlitzMode = .typing
    public let timeLimitSeconds: Double = 7.5

    public let hintMilestones: [ReflexHintMilestone] = [
        ReflexHintMilestone(stage: 1, delayMs: 2500),
        ReflexHintMilestone(stage: 2, delayMs: 4500)
    ]

    public var shouldSpeakOnReviewFlip: Bool { true }
    public var reviewSpeechRate: Float { 0.5 }
    public var reviewSpeechDelayMs: Int { 250 }

    public init() {}

    // swiftlint:disable:next function_parameter_count
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
            return ModeWordPreparationResult(
                options: [],
                clozeStages: nil,
                eliminatedOptionId: nil,
                hintBadgeText: ""
            )
        }
    }

    public func hintStage(forElapsedTimeMs ms: Int) -> Int {
        if ms >= 4500 { return 2 }
        if ms >= 2500 { return 1 }
        return 0
    }
}
