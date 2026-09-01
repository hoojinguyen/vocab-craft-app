import Foundation

/// Strategy handler for Speaking reflex drill modality.
@MainActor
public struct SpeakingModeHandler: ReflexModeHandlerProtocol {
    public let mode: ReflexBlitzMode = .speaking
    public let timeLimitSeconds: Double = 6.0

    public let hintMilestones: [ReflexHintMilestone] = [
        ReflexHintMilestone(stage: 1, delayMs: 2500),
        ReflexHintMilestone(stage: 2, delayMs: 4000),
        ReflexHintMilestone(stage: 3, delayMs: 5000)
    ]

    public var shouldSpeakOnReviewFlip: Bool { true }
    public var reviewSpeechRate: Float { 0.5 }
    public var reviewSpeechDelayMs: Int { 250 }

    public init() {}

    public func prepareWord(
        word: ReflexBlitzWordItem,
        allWords: [ReflexBlitzWordItem],
        planItem: ReflexDrillPlanItem?,
        ttsService: TextToSpeechProtocol,
        speechEngine: ReflexSpeechEngineProtocol,
        isKeyboardFallback: Bool
    ) -> ModeWordPreparationResult {
        if !isKeyboardFallback {
            speechEngine.beginWord(
                targetLemma: word.lemma,
                contextualPhrases: [word.lemma]
            )
        }

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

    public func onWordCompleted(speechEngine: ReflexSpeechEngineProtocol) {
        speechEngine.endWord()
    }

    public func onTimeout(speechEngine: ReflexSpeechEngineProtocol) {
        speechEngine.endWord()
    }

    public func hintStage(forElapsedTimeMs ms: Int) -> Int {
        if ms >= 5000 { return 3 }
        if ms >= 4000 { return 2 }
        if ms >= 2500 { return 1 }
        return 0
    }
}
