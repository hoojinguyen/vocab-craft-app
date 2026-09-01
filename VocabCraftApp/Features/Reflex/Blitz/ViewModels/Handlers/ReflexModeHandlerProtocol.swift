import Foundation
import SpeechKit

/// Result of preparing a word item for a specific reflex drill mode.
public struct ModeWordPreparationResult: Equatable, Sendable {
    public let options: [ReflexBlitzOption]
    public let clozeStages: ReflexClozeStageSet?
    public let eliminatedOptionId: String?
    public let hintBadgeText: String

    public init(
        options: [ReflexBlitzOption] = [],
        clozeStages: ReflexClozeStageSet? = nil,
        eliminatedOptionId: String? = nil,
        hintBadgeText: String = ""
    ) {
        self.options = options
        self.clozeStages = clozeStages
        self.eliminatedOptionId = eliminatedOptionId
        self.hintBadgeText = hintBadgeText
    }
}

/// Evaluation result for typing answer submissions.
public enum TypingValidationResult: Equatable, Sendable {
    case empty
    case evaluated(isCorrect: Bool, cleanInput: String)
}

/// Milestone definition for progressive hint reveals.
public struct ReflexHintMilestone: Equatable, Sendable {
    public let stage: Int
    public let delayMs: Int

    public init(stage: Int, delayMs: Int) {
        self.stage = stage
        self.delayMs = delayMs
    }
}

/// Strategy protocol defining mode-specific validation, hint scheduling, lifecycle, and audio behavior.
@MainActor
public protocol ReflexModeHandlerProtocol: Sendable {
    var mode: ReflexBlitzMode { get }
    var timeLimitSeconds: Double { get }
    var hintMilestones: [ReflexHintMilestone] { get }
    var shouldSpeakOnReviewFlip: Bool { get }
    var reviewSpeechRate: Float { get }
    var reviewSpeechDelayMs: Int { get }

    func prepareWord(
        word: ReflexBlitzWordItem,
        allWords: [ReflexBlitzWordItem],
        planItem: ReflexDrillPlanItem?,
        ttsService: TextToSpeechProtocol,
        speechEngine: ReflexSpeechEngineProtocol,
        isKeyboardFallback: Bool
    ) -> ModeWordPreparationResult

    func onHintStageReached(
        stage: Int,
        word: ReflexBlitzWordItem,
        ttsService: TextToSpeechProtocol
    )

    func hintStage(forElapsedTimeMs ms: Int) -> Int

    func validateOption(_ option: ReflexBlitzOption) -> Bool
    func validateTyping(input: String, targetLemma: String) -> TypingValidationResult
    func validateSpokenMatch(spokenText: String, targetLemma: String) -> Bool

    func onWordCompleted(speechEngine: ReflexSpeechEngineProtocol)
    func onTimeout(speechEngine: ReflexSpeechEngineProtocol)
}

// MARK: - Default Protocol Implementations

extension ReflexModeHandlerProtocol {
    public var shouldSpeakOnReviewFlip: Bool { true }
    public var reviewSpeechRate: Float { 0.5 }
    public var reviewSpeechDelayMs: Int { 250 }

    public func onHintStageReached(
        stage: Int,
        word: ReflexBlitzWordItem,
        ttsService: TextToSpeechProtocol
    ) {
        // Default: no audio action on hint
    }

    public func validateOption(_ option: ReflexBlitzOption) -> Bool {
        option.isCorrect
    }

    public func validateTyping(input: String, targetLemma: String) -> TypingValidationResult {
        let cleanInput = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanInput.isEmpty else { return .empty }
        let cleanTarget = targetLemma.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCorrect = cleanInput.lowercased() == cleanTarget.lowercased()
        return .evaluated(isCorrect: isCorrect, cleanInput: cleanInput)
    }

    public func validateSpokenMatch(spokenText: String, targetLemma: String) -> Bool {
        let cleanMatched = spokenText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanLemma = targetLemma.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanMatched.isEmpty, !cleanLemma.isEmpty else { return false }
        if cleanMatched == cleanLemma || cleanMatched.contains(cleanLemma) {
            return true
        }
        return ReflexSpeechMatcher.isReflexMatch(spokenText: spokenText, targetLemma: targetLemma)
    }

    public func onWordCompleted(speechEngine: ReflexSpeechEngineProtocol) {
        // Default: no speech engine action
    }

    public func onTimeout(speechEngine: ReflexSpeechEngineProtocol) {
        // Default: no speech engine action
    }
}

// MARK: - Mode Handler Factory

@MainActor
public enum ReflexModeHandlerFactory {
    public static func handler(for mode: ReflexBlitzMode) -> ReflexModeHandlerProtocol {
        switch mode {
        case .multipleChoice:
            return MultipleChoiceModeHandler()
        case .typing:
            return TypingModeHandler()
        case .speaking:
            return SpeakingModeHandler()
        case .listening:
            return ListeningModeHandler()
        }
    }
}
