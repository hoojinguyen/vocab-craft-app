import CraftUIKit
import Foundation
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
public final class LessonLearningViewModel: Identifiable {
    public let id: UUID = UUID()
    public let stageId: String
    public let deckId: String
    public let words: [TopicWordDTO]
    public internal(set) var steps: [LessonStep] = []
    public internal(set) var currentStepIndex: Int = 0
    public internal(set) var mistakeCount: Int = 0
    public internal(set) var totalAnswered: Int = 0
    public internal(set) var correctAnswers: Int = 0
    public internal(set) var weakWordIds: Set<Int64> = []
    public internal(set) var isCompleted: Bool = false
    public internal(set) var summary: LessonSummaryModel?
    public var isFeedbackPresented: Bool = false
    public var lastAttemptCorrect: Bool = false
    public var typingText: String = ""
    public var liveTranscript: String = ""
    public var speechState: CraftSpeechState = .idle
    public internal(set) var isSpeakingDisabledForLesson: Bool = false
    public var permissionNotice: LessonPermissionNotice?
    public internal(set) var hasPresentedPermissionNotice: Bool = false
    public var isPermissionNoticePresented: Bool {
        get { permissionNotice != nil }
        set {
            if !newValue {
                permissionNotice = nil
            }
        }
    }
    var autoPronounceTask: Task<Void, Never>?
    var speechStartTask: Task<Void, Never>?
    var speakingRequestGeneration: UInt = 0

    public internal(set) var hintStage: Int = 0
    public internal(set) var eliminatedOptionId: String?
    var attemptCountPerWord: [Int64: Int] = [:]

    let planGenerator: LessonPlanGeneratorProtocol
    let completeLessonUseCase: CompleteLessonUseCaseProtocol
    let ttsService: TextToSpeechProtocol
    let soundEffectService: SoundEffectServiceProtocol
    public let speechEngine: ReflexSpeechEngineProtocol
    let initialStepCount: Int

    public internal(set) var completionTask: Task<LessonCompletionResult, Error>?
    public internal(set) var persistenceError: (any Error)?
    var maxProgress: Double = 0.0

    public init(
        stageId: String,
        deckId: String,
        words: [TopicWordDTO],
        planGenerator: LessonPlanGeneratorProtocol = LessonPlanGenerator(),
        completeLessonUseCase: CompleteLessonUseCaseProtocol,
        ttsService: TextToSpeechProtocol,
        soundEffectService: SoundEffectServiceProtocol,
        speechEngine: ReflexSpeechEngineProtocol
    ) {
        self.stageId = stageId
        self.deckId = deckId
        self.words = words
        self.planGenerator = planGenerator
        self.completeLessonUseCase = completeLessonUseCase
        self.ttsService = ttsService
        self.soundEffectService = soundEffectService
        self.speechEngine = speechEngine
        let generatedSteps = planGenerator.generatePlan(from: words, distractorPool: words)
        self.steps = generatedSteps
        self.initialStepCount = generatedSteps.count
        LessonPerformanceDiagnostics.event("LessonPlanReady", detail: "stepCount=\(generatedSteps.count)")
    }

    public var currentStep: LessonStep? {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    public var currentExerciseItem: LessonExerciseItem? {
        if case .exercise(let item) = currentStep {
            return item
        }
        return nil
    }

    public var isSummaryStep: Bool {
        if case .summary = currentStep {
            return true
        }
        return false
    }

    public var progress: Double {
        guard !steps.isEmpty else { return 1.0 }
        if isCompleted || isSummaryStep { return 1.0 }
        let effectiveTotal = max(initialStepCount, steps.count)
        let current = min(1.0, Double(currentStepIndex) / Double(max(effectiveTotal, 1)))
        return max(maxProgress, current)
    }

    deinit {
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                cleanup()
            }
        } else {
            Task { @MainActor [speechEngine] in
                speechEngine.pauseListening()
                speechEngine.stopSession()
            }
        }
    }
}
