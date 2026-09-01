import Foundation

/// Strategy handler for Listening reflex drill modality.
@MainActor
public struct ListeningModeHandler: ReflexModeHandlerProtocol {
    public let mode: ReflexBlitzMode = .listening
    public let timeLimitSeconds: Double = 5.5

    public let hintMilestones: [ReflexHintMilestone] = [
        ReflexHintMilestone(stage: 1, delayMs: 1800),
        ReflexHintMilestone(stage: 2, delayMs: 3000)
    ]

    public var shouldSpeakOnReviewFlip: Bool { false }
    public var reviewSpeechRate: Float { 1.0 }
    public var reviewSpeechDelayMs: Int { 0 }

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
        ttsService.speak(text: word.lemma, rate: 1.0, locale: "en-US")

        if let planItem {
            return ModeWordPreparationResult(
                options: planItem.options,
                clozeStages: planItem.clozeStages,
                eliminatedOptionId: planItem.eliminatedOptionId,
                hintBadgeText: planItem.hintBadgeText
            )
        } else {
            let options = word.generateOptions(mode: .listening, allPool: allWords)
            return ModeWordPreparationResult(
                options: options,
                clozeStages: nil,
                eliminatedOptionId: nil,
                hintBadgeText: ""
            )
        }
    }

    public func onHintStageReached(
        stage: Int,
        word: ReflexBlitzWordItem,
        ttsService: TextToSpeechProtocol
    ) {
        if stage == 1 || stage == 2 {
            ttsService.speak(text: word.lemma, rate: 1.0, locale: "en-US")
        }
    }

    public func hintStage(forElapsedTimeMs ms: Int) -> Int {
        if ms >= 3000 { return 2 }
        if ms >= 1800 { return 1 }
        return 0
    }
}
