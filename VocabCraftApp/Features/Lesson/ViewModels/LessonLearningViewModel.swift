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

    public private(set) var hintStage: Int = 0
    public private(set) var eliminatedOptionId: String?
    private var attemptCountPerWord: [Int64: Int] = [:]

    private let planGenerator: LessonPlanGeneratorProtocol
    private let completeLessonUseCase: CompleteLessonUseCaseProtocol
    private let ttsService: TextToSpeechProtocol
    private let soundEffectService: SoundEffectServiceProtocol
    private let speechEngine: ReflexSpeechEngineProtocol
    private let initialStepCount: Int

    public private(set) var completionTask: Task<LessonCompletionResult, Error>?
    public private(set) var persistenceError: (any Error)?

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

        setupSpeechEngineCallbacks()
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

    private var maxProgress: Double = 0.0

    public var progress: Double {
        guard !steps.isEmpty else { return 1.0 }
        if isCompleted || isSummaryStep { return 1.0 }
        let effectiveTotal = max(initialStepCount, steps.count)
        let current = min(1.0, Double(currentStepIndex) / Double(max(effectiveTotal, 1)))
        return max(maxProgress, current)
    }

    public func startSpeechSession() {
        let contextualPhrases = words.map(\.lemma)
        speechEngine.startSession(contextualPhrases: contextualPhrases)
    }

    public func stopSpeechSession() {
        ttsService.stop()
        stopListeningForSpeaking()
        speechEngine.stopSession()
    }

    public func advanceStep() {
        guard !isSummaryStep else { return }
        maxProgress = max(maxProgress, progress)
        ttsService.stop()
        stopListeningForSpeaking()
        isFeedbackPresented = false
        typingText = ""
        liveTranscript = ""
        speechState = .idle
        hintStage = 0
        eliminatedOptionId = nil
        currentStepIndex += 1
        if currentStepIndex >= steps.count {
            finishLesson()
        }
    }

    public func submitAnswer(isCorrect: Bool, for item: LessonExerciseItem) {
        guard !isFeedbackPresented else { return }
        guard currentExerciseItem?.id == item.id else { return }
        maxProgress = max(maxProgress, progress)
        stopListeningForSpeaking()
        totalAnswered += 1
        lastAttemptCorrect = isCorrect

        let currentWordAttempts = attemptCountPerWord[item.word.id, default: 0] + 1
        attemptCountPerWord[item.word.id] = currentWordAttempts

        if isCorrect {
            correctAnswers += 1
            soundEffectService.playSuccessChime()
            CraftHaptics.shared.success()
        } else {
            mistakeCount += 1
            weakWordIds.insert(item.word.id)
            soundEffectService.playIncorrectChime()
            CraftHaptics.shared.error()

            // Smart Requeue (Option A): Max 1 retry per word with mode downgrading
            if currentWordAttempts == 1 {
                let fallbackMode: ReflexBlitzMode = .multipleChoice
                let fallbackOptions = ReflexDistractorGenerator.generateOptions(
                    mode: .multipleChoice,
                    target: ReflexBlitzWordItem(from: item.word),
                    pool: words.map { ReflexBlitzWordItem(from: $0) }
                )

                let clozeStages = item.clozeStages ?? ReflexHintMaskGenerator.generateStages(
                    lemma: item.word.lemma,
                    sentenceEn: item.word.exampleEn,
                    pos: item.word.pos
                )

                let retryItem = LessonExerciseItem(
                    id: "\(fallbackMode.rawValue)-\(item.word.id)-retry-\(UUID().uuidString.prefix(4))",
                    word: item.word,
                    assignedMode: fallbackMode,
                    options: fallbackOptions,
                    clozeStages: clozeStages,
                    attemptCount: currentWordAttempts + 1,
                    isRequeued: true
                )
                steps.append(.exercise(item: retryItem))
            }
        }

        isFeedbackPresented = true
    }

    public func requestHint(for item: LessonExerciseItem) {
        guard !isFeedbackPresented else { return }
        guard currentExerciseItem?.id == item.id else { return }
        guard hintStage < 3 else { return }
        CraftHaptics.shared.selection()
        hintStage += 1

        if hintStage >= 2 && (item.assignedMode == .multipleChoice || item.assignedMode == .listening) {
            if eliminatedOptionId == nil {
                let wrongOptions = item.options.filter { !$0.isCorrect }
                eliminatedOptionId = wrongOptions.first?.id
            }
        }
    }

    public func skipExercise(for item: LessonExerciseItem) {
        submitAnswer(isCorrect: false, for: item)
    }

    public func playAudio(for text: String) {
        ttsService.speak(text: text)
    }

    public func stopAudio() {
        ttsService.stop()
    }

    public func startListeningForSpeaking(targetLemma: String, item: LessonExerciseItem) {
        speechState = .listening(audioLevels: [0.5, 0.6, 0.4])
        liveTranscript = ""

        speechEngine.onTranscriptUpdate = { [weak self] transcript in
            Task { @MainActor in
                guard let self, self.currentExerciseItem?.id == item.id else { return }
                self.liveTranscript = transcript
            }
        }

        speechEngine.onMatchDetected = { [weak self] _ in
            Task { @MainActor in
                guard let self, !self.isFeedbackPresented, self.currentExerciseItem?.id == item.id else { return }
                self.speechState = .evaluated(overallScore: 1.0)
                self.submitAnswer(isCorrect: true, for: item)
            }
        }

        if !speechEngine.isSessionActive {
            startSpeechSession()
        }
        speechEngine.beginWord(targetLemma: targetLemma, contextualPhrases: [targetLemma, item.word.exampleEn])
    }

    public func stopListeningForSpeaking() {
        speechEngine.endWord()
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
        guard completionTask == nil else { return }
        stopSpeechSession()

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

        self.completionTask = Task {
            do {
                let result = try await completeLessonUseCase.execute(
                    stageId: stageId,
                    deckId: deckId,
                    stars: stars,
                    weakWordIds: Array(weakWordIds),
                    progressFraction: 1.0
                )
                await MainActor.run {
                    self.isCompleted = true
                }
                return result
            } catch {
                await MainActor.run {
                    self.persistenceError = error
                }
                throw error
            }
        }
    }

    @discardableResult
    public func awaitCompletion() async throws -> LessonCompletionResult? {
        try await completionTask?.value
    }
}
