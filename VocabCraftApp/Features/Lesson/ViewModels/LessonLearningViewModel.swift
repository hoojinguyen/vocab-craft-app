import CraftUIKit
import Foundation
import Observation

@MainActor
@Observable
public final class LessonLearningViewModel: Identifiable {
    public let id: UUID = UUID()
    public let stageId: String
    public let deckId: String
    public let words: [TopicWordDTO]
    public private(set) var steps: [LessonStep] = []
    public private(set) var currentStepIndex: Int = 0
    public private(set) var mistakeCount: Int = 0
    public private(set) var totalAnswered: Int = 0
    public private(set) var correctAnswers: Int = 0
    public private(set) var weakWordIds: Set<Int64> = []
    public private(set) var isCompleted: Bool = false
    public private(set) var summary: LessonSummaryModel?
    public var isFeedbackPresented: Bool = false
    public var lastAttemptCorrect: Bool = false
    public var typingText: String = ""
    public var liveTranscript: String = ""
    public var speechState: CraftSpeechState = .idle

    private let planGenerator: LessonPlanGeneratorProtocol
    private let completeLessonUseCase: CompleteLessonUseCaseProtocol
    private let ttsService: TextToSpeechProtocol
    private let soundEffectService: SoundEffectServiceProtocol
    private let speechEngine: ReflexSpeechEngineProtocol

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
        self.steps = planGenerator.generatePlan(from: words, distractorPool: words)

        setupSpeechEngineCallbacks()
    }

    public var currentStep: LessonStep? {
        guard currentStepIndex >= 0 && currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }

    public var progress: Double {
        guard !steps.isEmpty else { return 1.0 }
        return Double(currentStepIndex) / Double(steps.count)
    }

    public func advanceStep() {
        stopListeningForSpeaking()
        isFeedbackPresented = false
        typingText = ""
        liveTranscript = ""
        speechState = .idle
        currentStepIndex += 1
        if currentStepIndex >= steps.count {
            finishLesson()
        }
    }

    public func submitAnswer(isCorrect: Bool, for item: LessonExerciseItem) {
        guard !isFeedbackPresented else { return }
        stopListeningForSpeaking()
        totalAnswered += 1
        lastAttemptCorrect = isCorrect

        if isCorrect {
            correctAnswers += 1
            soundEffectService.playSuccessChime()
            CraftHaptics.shared.success()
        } else {
            mistakeCount += 1
            weakWordIds.insert(item.word.id)
            soundEffectService.playIncorrectChime()
            CraftHaptics.shared.error()

            let retryItem = LessonExerciseItem(
                id: "\(item.assignedMode.rawValue)-\(item.word.id)-retry-\(UUID().uuidString.prefix(4))",
                word: item.word,
                assignedMode: item.assignedMode,
                options: item.options,
                isRequeued: true
            )
            steps.append(.exercise(item: retryItem))
        }

        isFeedbackPresented = true
    }

    public func skipSpeaking(for item: LessonExerciseItem) {
        stopListeningForSpeaking()
        let fallbackMode: ReflexBlitzMode = .typing
        let retryItem = LessonExerciseItem(
            id: "\(fallbackMode.rawValue)-\(item.word.id)-skip-\(UUID().uuidString.prefix(4))",
            word: item.word,
            assignedMode: fallbackMode,
            options: item.options,
            isRequeued: true
        )
        steps.append(.exercise(item: retryItem))
        advanceStep()
    }

    public func playAudio(for text: String) {
        ttsService.speak(text: text)
    }

    public func startListeningForSpeaking(targetLemma: String, item: LessonExerciseItem) {
        speechState = .listening(audioLevels: [0.5, 0.6, 0.4])
        liveTranscript = ""

        speechEngine.onTranscriptUpdate = { [weak self] transcript in
            Task { @MainActor in
                self?.liveTranscript = transcript
            }
        }

        speechEngine.onMatchDetected = { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isFeedbackPresented else { return }
                self.speechState = .evaluated(overallScore: 1.0)
                self.submitAnswer(isCorrect: true, for: item)
            }
        }

        speechEngine.startSession(contextualPhrases: [targetLemma])
        speechEngine.beginWord(targetLemma: targetLemma, contextualPhrases: [targetLemma])
    }

    public func stopListeningForSpeaking() {
        speechEngine.endWord()
        speechEngine.stopSession()
        speechEngine.onMatchDetected = nil
        speechEngine.onTranscriptUpdate = nil
    }

    private func setupSpeechEngineCallbacks() {
        speechEngine.onError = { [weak self] _ in
            Task { @MainActor in
                self?.speechState = .idle
            }
        }
    }

    private func finishLesson() {
        let stars = mistakeCount == 0 ? 3 : (mistakeCount <= 2 ? 2 : 1)
        let isCheckpoint = stageId.hasPrefix("checkpoint_")
        let xpEarned = isCheckpoint ? 80 : 25
        let accuracy = totalAnswered > 0 ? Double(correctAnswers) / Double(totalAnswered) : 1.0

        let summaryModel = LessonSummaryModel(
            stageId: stageId,
            deckId: deckId,
            stars: stars,
            xpEarned: xpEarned,
            accuracyFraction: accuracy,
            learnedWords: words,
            weakWordIds: Array(weakWordIds)
        )

        self.summary = summaryModel
        self.steps.append(.summary(summary: summaryModel))
        self.isCompleted = true

        Task {
            _ = try? await completeLessonUseCase.execute(
                stageId: stageId,
                deckId: deckId,
                stars: stars,
                weakWordIds: Array(weakWordIds),
                progressFraction: 1.0
            )
        }
    }
}
