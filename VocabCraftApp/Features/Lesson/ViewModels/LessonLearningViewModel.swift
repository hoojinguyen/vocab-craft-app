// swiftlint:disable file_length
import CraftUIKit
import Foundation
import Observation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
@Observable
// swiftlint:disable:next type_body_length
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
    public private(set) var isSpeakingDisabledForLesson: Bool = false
    public var permissionNotice: LessonPermissionNotice?
    public private(set) var hasPresentedPermissionNotice: Bool = false
    public var isPermissionNoticePresented: Bool {
        get { permissionNotice != nil }
        set {
            if !newValue {
                permissionNotice = nil
            }
        }
    }
    private(set) var autoPronounceTask: Task<Void, Never>?
    private var speechStartTask: Task<Void, Never>?
    private var speakingRequestGeneration: UInt = 0

    public private(set) var hintStage: Int = 0
    public private(set) var eliminatedOptionId: String?
    private var attemptCountPerWord: [Int64: Int] = [:]

    private let planGenerator: LessonPlanGeneratorProtocol
    private let completeLessonUseCase: CompleteLessonUseCaseProtocol
    private let recordSenseAttemptUseCase: (any RecordSenseAttemptUseCaseProtocol)?
    private let ttsService: TextToSpeechProtocol
    private let soundEffectService: SoundEffectServiceProtocol
    public let speechEngine: ReflexSpeechEngineProtocol
    private let initialStepCount: Int

    public let contentVersion: Int
    public let lessonRevision: Int
    public let profileID: ProfileID
    public let deviceID: DeviceID
    public let lessonID: LessonID?

    public private(set) var isSubmittingAnswer: Bool = false
    public private(set) var pendingAttemptID: AttemptID?
    public private(set) var pendingAttempt: AttemptSubmission?
    public var attemptPersistenceError: (any Error)?
    public var showAttemptPersistenceError: Bool = false
    public private(set) var completionEventID: EventID?
    private var stepStartTime: Date = Date()
    public private(set) var submissionTask: Task<AppendResult?, Error>?

    public private(set) var completionTask: Task<LessonCompletionResult, Error>?
    public private(set) var persistenceError: (any Error)?

    public init(
        stageId: String,
        deckId: String,
        words: [TopicWordDTO],
        planGenerator: LessonPlanGeneratorProtocol = LessonPlanGenerator(),
        completeLessonUseCase: CompleteLessonUseCaseProtocol,
        recordSenseAttemptUseCase: (any RecordSenseAttemptUseCaseProtocol)? = nil,
        contentVersion: Int = 1,
        lessonRevision: Int = 1,
        profileID: ProfileID = LearningJournal.defaultGuestProfileID,
        deviceID: DeviceID = LearningJournal.defaultDeviceID(),
        ttsService: TextToSpeechProtocol,
        soundEffectService: SoundEffectServiceProtocol,
        speechEngine: ReflexSpeechEngineProtocol
    ) {
        self.stageId = stageId
        self.deckId = deckId
        self.words = words
        self.planGenerator = planGenerator
        self.completeLessonUseCase = completeLessonUseCase
        self.recordSenseAttemptUseCase = recordSenseAttemptUseCase
        self.contentVersion = contentVersion
        self.lessonRevision = lessonRevision
        self.profileID = profileID
        self.deviceID = deviceID
        self.lessonID = LessonID(uuidString: stageId)
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

    private var maxProgress: Double = 0.0

    public var progress: Double {
        guard !steps.isEmpty else { return 1.0 }
        if isCompleted || isSummaryStep { return 1.0 }
        let effectiveTotal = max(initialStepCount, steps.count)
        let current = min(1.0, Double(currentStepIndex) / Double(max(effectiveTotal, 1)))
        return max(maxProgress, current)
    }

    public func startSpeechSession() {
        guard !isSpeakingDisabledForLesson else { return }
        let contextualPhrases = words.map(\.lemma)
        speechEngine.startSession(contextualPhrases: contextualPhrases, lazy: true)
    }

    public func stopSpeechSession() {
        ttsService.stop()
        cleanup()
    }

    public func advanceStep() {
        guard !isSummaryStep else { return }
        LessonPerformanceDiagnostics.event(
            "LessonStepAdvance",
            detail: "fromIndex=\(currentStepIndex) stepCount=\(steps.count)"
        )
        maxProgress = max(maxProgress, progress)
        autoPronounceTask?.cancel()
        autoPronounceTask = nil
        ttsService.stop()
        if speechEngine.isWordActive || speechState != .idle {
            stopListeningForSpeaking()
        }
        stepStartTime = Date()
        attemptPersistenceError = nil
        showAttemptPersistenceError = false
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isFeedbackPresented = false
            typingText = ""
            liveTranscript = ""
            speechState = .idle
            hintStage = 0
            eliminatedOptionId = nil
            if steps.isEmpty || currentStepIndex + 1 >= steps.count {
                finishLesson()
                currentStepIndex = max(0, steps.count - 1)
            } else {
                currentStepIndex += 1
            }
        }
    }

    public func submitAnswer(isCorrect: Bool, for item: LessonExerciseItem) {
        if recordSenseAttemptUseCase == nil {
            guard !isFeedbackPresented, !isSubmittingAnswer else { return }
            guard currentExerciseItem?.id == item.id else { return }
            applySuccessfulSubmission(isCorrect: isCorrect, for: item)
        } else {
            submissionTask = Task { @MainActor in
                try await self.submitAnswerAsync(isCorrect: isCorrect, for: item)
            }
        }
    }

    @discardableResult
    public func submitAnswerAsync(isCorrect: Bool, for item: LessonExerciseItem) async throws -> AppendResult? {
        guard !isFeedbackPresented, !isSubmittingAnswer else { return nil }
        guard currentExerciseItem?.id == item.id else { return nil }
        isSubmittingAnswer = true

        guard let recordSenseAttemptUseCase else {
            isSubmittingAnswer = false
            applySuccessfulSubmission(isCorrect: isCorrect, for: item)
            return nil
        }

        let attemptID = AttemptID(rawValue: UUID())
        let submission = makeAttemptSubmission(attemptID: attemptID, isCorrect: isCorrect, for: item)
        self.pendingAttempt = submission
        self.pendingAttemptID = attemptID

        do {
            let result = try await recordSenseAttemptUseCase.execute(attempt: submission)
            self.pendingAttempt = nil
            self.pendingAttemptID = nil
            self.attemptPersistenceError = nil
            self.showAttemptPersistenceError = false
            self.isSubmittingAnswer = false
            self.applySuccessfulSubmission(isCorrect: isCorrect, for: item)
            return result
        } catch {
            self.attemptPersistenceError = error
            self.showAttemptPersistenceError = true
            self.isSubmittingAnswer = false
            throw error
        }
    }

    @discardableResult
    public func retryPendingAttempt() async throws -> AppendResult? {
        guard let pending = pendingAttempt else { return nil }
        guard let recordSenseAttemptUseCase else { return nil }
        guard !isSubmittingAnswer else { return nil }
        isSubmittingAnswer = true

        do {
            let result = try await recordSenseAttemptUseCase.execute(attempt: pending)
            self.pendingAttempt = nil
            self.pendingAttemptID = nil
            self.attemptPersistenceError = nil
            self.showAttemptPersistenceError = false
            self.isSubmittingAnswer = false

            if let currentItem = currentExerciseItem {
                let isCorrect = (pending.outcome == .correct)
                self.applySuccessfulSubmission(isCorrect: isCorrect, for: currentItem)
            }
            return result
        } catch {
            self.attemptPersistenceError = error
            self.showAttemptPersistenceError = true
            self.isSubmittingAnswer = false
            throw error
        }
    }

    @discardableResult
    public func retryAttempt() async throws -> AppendResult? {
        try await retryPendingAttempt()
    }

    @discardableResult
    public func awaitSubmission() async throws -> AppendResult? {
        if let submissionTask {
            return try await submissionTask.value
        }
        return nil
    }

    private func applySuccessfulSubmission(isCorrect: Bool, for item: LessonExerciseItem) {
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

                let clozeStages = item.clozeStages

                let retryItem = LessonExerciseItem(
                    id: "\(fallbackMode.rawValue)-\(item.word.id)-retry-\(UUID().uuidString.prefix(4))",
                    word: item.word,
                    senseDetail: item.senseDetail,
                    assignedMode: fallbackMode,
                    options: fallbackOptions,
                    clozeStages: clozeStages,
                    attemptCount: currentWordAttempts + 1,
                    isRequeued: true
                )
                steps.append(.exercise(item: retryItem))
            }
        }

        // Auto-pronounce vocabulary word for non-listening modes after feedback sound
        autoPronounceTask?.cancel()
        if item.assignedMode != .listening {
            autoPronounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                self.ttsService.speak(text: item.word.lemma)
            }
        }

        isFeedbackPresented = true
    }

    public func requestHint(for item: LessonExerciseItem) {
        guard !isFeedbackPresented else { return }
        guard currentExerciseItem?.id == item.id else { return }
        let maxHintStage = (item.assignedMode == .speaking) ? 3 : 2
        guard hintStage < maxHintStage else { return }
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
        guard !isSpeakingDisabledForLesson else { return }
        guard !isFeedbackPresented && speechState == .idle else { return }
        LessonPerformanceDiagnostics.event(
            "LessonSpeakingStart",
            detail: "engineSessionActive=\(speechEngine.isSessionActive)"
        )
        speechState = .preparing
        liveTranscript = ""

        speechEngine.onTranscriptUpdate = { [weak self] transcript in
            guard let self, self.currentExerciseItem?.id == item.id else { return }
            self.liveTranscript = transcript
        }

        speechEngine.onMatchDetected = { [weak self] _ in
            guard let self, !self.isFeedbackPresented, self.currentExerciseItem?.id == item.id else { return }
            self.speechState = .evaluated(overallScore: 1.0)
            self.submitAnswer(isCorrect: true, for: item)
        }

        speechEngine.onError = { [weak self] error in
            guard let self, self.currentExerciseItem?.id == item.id else { return }
            LessonPerformanceDiagnostics.error("lesson.speaking", error: error)
            self.speechState = .idle
        }

        if !speechEngine.isSessionActive {
            startSpeechSession()
        }

        speakingRequestGeneration &+= 1
        let requestGeneration = speakingRequestGeneration

        speechStartTask?.cancel()
        speechStartTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.speechEngine.startListening(
                    targetLemma: targetLemma,
                    contextualPhrases: [targetLemma, item.word.exampleEn]
                )
                try Task.checkCancellation()
                guard self.currentExerciseItem?.id == item.id,
                      !self.isFeedbackPresented,
                      requestGeneration == self.speakingRequestGeneration else {
                    if self.speechState == .preparing && requestGeneration == self.speakingRequestGeneration {
                        self.speechState = .idle
                    }
                    return
                }
                self.speechState = .listening()
            } catch is CancellationError {
                if self.speechState == .preparing && requestGeneration == self.speakingRequestGeneration && self.currentExerciseItem?.id == item.id {
                    self.speechState = .idle
                }
                return
            } catch let error as SpeechCaptureError where error == .speechRecognitionDenied || error == .microphoneDenied {
                LessonPerformanceDiagnostics.error("lesson.speaking.permission", error: error)
                guard requestGeneration == self.speakingRequestGeneration else { return }
                self.handlePermissionDenied(for: item)
            } catch {
                LessonPerformanceDiagnostics.error("lesson.speaking.start", error: error)
                if requestGeneration == self.speakingRequestGeneration {
                    self.speechState = .idle
                }
            }
        }
    }

    public func stopListeningForSpeaking() {
        speakingRequestGeneration &+= 1
        speechStartTask?.cancel()
        speechStartTask = nil
        speechEngine.pauseListening()
        speechEngine.onMatchDetected = nil
        speechEngine.onTranscriptUpdate = nil
        speechEngine.onError = nil
        if speechState != .unavailable {
            speechState = .idle
        }
    }

    public func handleCantSpeakNow(for item: LessonExerciseItem) {
        guard currentExerciseItem?.id == item.id, !isFeedbackPresented else { return }
        stopListeningForSpeaking()
        speechEngine.stopSession()
        isSpeakingDisabledForLesson = true
        hintStage = 0
        eliminatedOptionId = nil

        // Convert current exercise item to multiple choice
        let fallbackOptions = ReflexDistractorGenerator.generateOptions(
            mode: .multipleChoice,
            target: ReflexBlitzWordItem(from: item.word),
            pool: words.map { ReflexBlitzWordItem(from: $0) }
        )
        let convertedCurrentItem = LessonExerciseItem(
            id: "mc-\(item.word.id)-fallback-\(UUID().uuidString.prefix(4))",
            word: item.word,
            assignedMode: .multipleChoice,
            options: fallbackOptions,
            clozeStages: item.clozeStages,
            attemptCount: item.attemptCount,
            isRequeued: item.isRequeued
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            steps[currentStepIndex] = .exercise(item: convertedCurrentItem)
        }

        // Convert any remaining speaking exercises in subsequent steps to multiple choice
        for index in (currentStepIndex + 1)..<steps.count {
            if case .exercise(let stepItem) = steps[index], stepItem.assignedMode == .speaking {
                let options = ReflexDistractorGenerator.generateOptions(
                    mode: .multipleChoice,
                    target: ReflexBlitzWordItem(from: stepItem.word),
                    pool: words.map { ReflexBlitzWordItem(from: $0) }
                )
                let convertedItem = LessonExerciseItem(
                    id: "mc-\(stepItem.word.id)-fallback-\(UUID().uuidString.prefix(4))",
                    word: stepItem.word,
                    assignedMode: .multipleChoice,
                    options: options,
                    clozeStages: stepItem.clozeStages,
                    attemptCount: stepItem.attemptCount,
                    isRequeued: stepItem.isRequeued
                )
                steps[index] = .exercise(item: convertedItem)
            }
        }
    }

    public func handlePermissionDenied(for item: LessonExerciseItem) {
        guard !isFeedbackPresented else { return }
        stopListeningForSpeaking()
        speechEngine.stopSession()
        isSpeakingDisabledForLesson = true
        speechState = .unavailable
        hintStage = 0
        eliminatedOptionId = nil

        // Convert current exercise item to typing fallback
        if currentExerciseItem?.id == item.id {
            let convertedCurrentItem = convertToTypingFallback(item: item)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                steps[currentStepIndex] = .exercise(item: convertedCurrentItem)
            }
        }

        // Convert any remaining speaking exercises in subsequent steps to typing fallback
        for index in (currentStepIndex + 1)..<steps.count {
            if case .exercise(let stepItem) = steps[index], stepItem.assignedMode == .speaking {
                steps[index] = .exercise(item: convertToTypingFallback(item: stepItem))
            }
        }

        if !hasPresentedPermissionNotice {
            hasPresentedPermissionNotice = true
            permissionNotice = LessonPermissionNotice()
        }
    }

    private func convertToTypingFallback(item: LessonExerciseItem) -> LessonExerciseItem {
        LessonExerciseItem(
            id: "typing-\(item.word.id)-fallback-\(UUID().uuidString.prefix(4))",
            word: item.word,
            assignedMode: .typing,
            options: [],
            clozeStages: item.clozeStages,
            attemptCount: item.attemptCount,
            isRequeued: item.isRequeued
        )
    }

    public func openSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    public func cleanup() {
        speechStartTask?.cancel()
        speechStartTask = nil
        autoPronounceTask?.cancel()
        autoPronounceTask = nil
        stopListeningForSpeaking()
        speechEngine.stopSession()
    }

    public func retrySpeaking(for item: LessonExerciseItem) {
        guard currentExerciseItem?.id == item.id, !isFeedbackPresented else { return }
        stopListeningForSpeaking()
        startListeningForSpeaking(targetLemma: item.word.lemma, item: item)
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

// MARK: - Lesson Completion & Persistence

extension LessonLearningViewModel {
    func finishLesson() {
        guard completionTask == nil, !isCompleted, !isSummaryStep else { return }
        ttsService.stop()
        cleanup()

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

        let stableEventID = self.completionEventID ?? EventID(rawValue: UUID())
        self.completionEventID = stableEventID
        let completion = makeLessonCompletion(eventID: stableEventID)

        self.completionTask = Task {
            do {
                let result = try await completeLessonUseCase.execute(
                    stageId: stageId,
                    deckId: deckId,
                    stars: stars,
                    weakWordIds: Array(weakWordIds),
                    progressFraction: 1.0,
                    completion: completion
                )
                await MainActor.run {
                    self.isCompleted = true
                }
                return result
            } catch {
                await MainActor.run {
                    self.persistenceError = error
                    self.completionTask = nil
                }
                throw error
            }
        }
    }

    @discardableResult
    public func retryCompletion() async throws -> LessonCompletionResult? {
        if isCompleted {
            return nil
        }
        if let completionTask {
            return try await completionTask.value
        }
        guard let summary else { return nil }
        persistenceError = nil

        let stableEventID = self.completionEventID ?? EventID(rawValue: UUID())
        self.completionEventID = stableEventID
        let completion = makeLessonCompletion(eventID: stableEventID)

        let task = Task {
            do {
                let result = try await completeLessonUseCase.execute(
                    stageId: stageId,
                    deckId: deckId,
                    stars: summary.stars,
                    weakWordIds: Array(weakWordIds),
                    progressFraction: 1.0,
                    completion: completion
                )
                await MainActor.run {
                    self.isCompleted = true
                }
                return result
            } catch {
                await MainActor.run {
                    self.persistenceError = error
                    self.completionTask = nil
                }
                throw error
            }
        }
        self.completionTask = task
        return try await task.value
    }

    @discardableResult
    public func awaitCompletion() async throws -> LessonCompletionResult? {
        if let completionTask {
            return try await completionTask.value
        }
        if !isCompleted && summary != nil {
            return try await retryCompletion()
        }
        return nil
    }

    private func makeLessonCompletion(eventID: EventID) -> LessonCompletion {
        let lessonIdentifier = lessonID ?? LessonID(uuidString: stageId) ?? LessonID(rawValue: UUID())
        return LessonCompletion(
            eventID: eventID,
            originProfileID: profileID,
            deviceID: deviceID,
            deviceSequence: 1,
            eventSchemaVersion: 1,
            lessonID: lessonIdentifier,
            lessonRevision: lessonRevision,
            contentVersion: contentVersion,
            completedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func resolveSenseID(for item: LessonExerciseItem) -> SenseID {
        if let senseID = item.senseID {
            return senseID
        }
        if let senseID = item.senseDetail?.id {
            return senseID
        }
        let formatted = String(format: "00000000-0000-4000-8000-%012llx", abs(item.word.id))
        return SenseID(uuidString: formatted) ?? SenseID(rawValue: UUID())
    }

    private func makeAttemptSubmission(
        attemptID: AttemptID,
        isCorrect: Bool,
        for item: LessonExerciseItem
    ) -> AttemptSubmission {
        let senseID = resolveSenseID(for: item)
        let elapsedMs = max(500, Int(Date().timeIntervalSince(stepStartTime) * 1000))

        let kind: ExerciseKind
        let capability: Capability?
        let inputModes: [InputMode]
        let responseMode: ResponseMode
        let outcome: ExerciseOutcome = isCorrect ? .correct : .incorrect
        let scoreMilli: Int? = isCorrect ? 1000 : 0
        let evaluatorVersion: String
        let pronunciationScore: Int?

        switch item.assignedMode {
        case .speaking:
            kind = .pronunciation
            capability = nil
            inputModes = [.audio]
            responseMode = .speech
            evaluatorVersion = "speech_v1"
            pronunciationScore = isCorrect ? 1000 : 0
        case .typing:
            kind = .recallText
            capability = .recall
            inputModes = [.text]
            responseMode = .text
            evaluatorVersion = "exact_match_v1"
            pronunciationScore = nil
        case .multipleChoice:
            kind = .recognitionChoice
            capability = .recognition
            inputModes = [.text]
            responseMode = .choice
            evaluatorVersion = "exact_match_v1"
            pronunciationScore = nil
        case .listening:
            kind = .recognitionChoice
            capability = .recognition
            inputModes = [.audio]
            responseMode = .choice
            evaluatorVersion = "exact_match_v1"
            pronunciationScore = nil
        }

        return AttemptSubmission(
            attemptID: attemptID,
            eventSchemaVersion: 1,
            senseID: senseID,
            senseRevision: item.senseDetail?.revision ?? 1,
            contentVersion: contentVersion,
            lessonID: lessonID ?? LessonID(uuidString: stageId),
            lessonRevision: lessonRevision,
            exerciseKind: kind,
            capability: capability,
            inputModes: inputModes,
            responseMode: responseMode,
            outcome: outcome,
            scoreMilli: scoreMilli,
            hintCount: hintStage,
            retryCount: max(0, item.attemptCount - 1),
            responseTimeMs: elapsedMs,
            occurredAt: ISO8601DateFormatter().string(from: Date()),
            elapsedSincePreviousMs: nil,
            clientSRSAlgorithmVersion: "none",
            evaluatorVersion: evaluatorVersion,
            pronunciationScoreMilli: pronunciationScore
        )
    }
}
