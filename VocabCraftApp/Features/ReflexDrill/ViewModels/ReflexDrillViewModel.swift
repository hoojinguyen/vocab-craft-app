import Foundation
import Observation

public struct ReflexDrillState: Equatable {
    public var drill: ReflexDrillRecord?
    public var drillsList: [ReflexDrillRecord] = []
    public var currentDrillIndex: Int = 0
    public var startTime: Date?
    public var elapsedTimeMs: Int = 0
    public var feedbackText: String = ""
    public var currentMastery: Int = 0
    public var easeFactor: Double = 2.5
    public var srsResult: SRSResult?
    public var isEvaluated: Bool = false
    public var isCorrect: Bool = false
    public var cefrLevel: String = "B1"
    public var triggerSparkle: Bool = false
    public var errorMessage: String = ""
    public var showErrorAlert: Bool = false

    public init(cefrLevel: String = "B1") {
        self.cefrLevel = cefrLevel
    }
}

@MainActor
@Observable
public final class ReflexDrillViewModel {
    public var state: ReflexDrillState
    public var speechEvaluationResult: SpeechEvaluationResult?

    private var internalRecognizedText: String = ""

    private let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    private let ttsService: TextToSpeechProtocol
    private let sttService: SpeechRecognitionProtocol
    private let speechAssessmentService: SpeechAssessmentProtocol?

    private var timerTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?

    public var isListening: Bool {
        if let assessment = speechAssessmentService {
            return assessment.isListening
        }
        return (sttService as? SpeechRecognitionService)?.isListening ?? sttService.isListening
    }

    public var recognizedText: String {
        if let eval = speechEvaluationResult, !eval.spokenText.isEmpty {
            return eval.spokenText
        }
        if !internalRecognizedText.isEmpty {
            return internalRecognizedText
        }
        return (sttService as? SpeechRecognitionService)?.recognizedText ?? sttService.recognizedText
    }

    public var isSpeaking: Bool { ttsService.isSpeaking }

    public init(
        fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol,
        ttsService: TextToSpeechProtocol,
        sttService: SpeechRecognitionProtocol,
        speechAssessmentService: SpeechAssessmentProtocol? = nil,
        cefrLevel: String = "B1"
    ) {
        self.state = ReflexDrillState(cefrLevel: cefrLevel)
        self.fetchVocabularyUseCase = fetchVocabularyUseCase
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.ttsService = ttsService
        self.sttService = sttService
        self.speechAssessmentService = speechAssessmentService
    }

    deinit {
        let stt = sttService
        let assessment = speechAssessmentService
        Task { @MainActor in
            stt.stopListening()
            assessment?.stopAssessing()
        }
    }

    public func loadDrills() {
        loadTask?.cancel()
        loadTask = Task {
            do {
                let drills = try await fetchVocabularyUseCase.executeFetchDrills(cefrLevel: state.cefrLevel)
                guard !Task.isCancelled else { return }
                self.state.drillsList = drills
                self.state.currentDrillIndex = 0
                self.state.drill = drills.first
            } catch is CancellationError {
                return
            } catch {
                print("[ReflexDrillViewModel] Failed to load drills: \(error.localizedDescription)")
                self.state.errorMessage = String(localized: "reflex.errorLoadingDrills \(error.localizedDescription)")
                self.state.showErrorAlert = true
            }
            if self.state.drill == nil {
                self.setupSampleDrill()
            }
            self.startDrillTimer()
        }
    }

    public func setupSampleDrill() {
        let sample = ReflexDrillRecord(
            id: 101,
            drillType: "speak_phrase",
            promptText: "Một chú chó đen nhảy qua rào",
            correctAnswer: "A black dog jumps over the fence",
            distractors: ["A white cat runs away", "A green bird sings"],
            targetTimeMs: 2500,
            sentenceTextEn: "A black dog jumps over the fence"
        )
        state.drill = sample
    }

    public func startDrillTimer() {
        state.startTime = Date()
        state.elapsedTimeMs = 0
        state.isEvaluated = false
        state.isCorrect = false
        state.feedbackText = ""
        state.srsResult = nil
        speechEvaluationResult = nil
        internalRecognizedText = ""

        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self = self else { break }
                if let start = self.state.startTime {
                    self.state.elapsedTimeMs = Int(Date().timeIntervalSince(start) * 1000)
                }
            }
        }
    }

    public func speakCorrectAnswer() {
        guard let drill = state.drill else { return }
        ttsService.speak(text: drill.correctAnswer)
    }

    public func toggleListening() {
        handleMicTap()
    }

    public func startListening() {
        startVoiceRecognition()
    }

    public func stopListening() {
        stopVoiceRecognition()
    }

    public func handleMicTap() {
        if isListening {
            stopVoiceRecognition()
            let answerToEvaluate = speechEvaluationResult?.spokenText ?? recognizedText
            evaluateAnswer(answerToEvaluate)
        } else {
            startVoiceRecognition()
        }
    }

    public func startVoiceRecognition() {
        ttsService.stop()
        guard let drill = state.drill else { return }

        let targetSentence = drill.correctAnswer
        var contextualPhrases: [String] = []
        if let sentenceEn = drill.sentenceTextEn, !sentenceEn.isEmpty {
            contextualPhrases.append(sentenceEn)
        }
        if !targetSentence.isEmpty && !contextualPhrases.contains(targetSentence) {
            contextualPhrases.append(targetSentence)
        }
        for distractor in drill.distractors where !contextualPhrases.contains(distractor) {
            contextualPhrases.append(distractor)
        }

        if let assessment = speechAssessmentService {
            assessment.startAssessing(
                targetSentence: targetSentence,
                toleranceThreshold: 0.75,
                contextualPhrases: contextualPhrases,
                onProgress: { [weak self] evaluation in
                    guard let self = self else { return }
                    self.speechEvaluationResult = evaluation
                    self.internalRecognizedText = evaluation.spokenText
                },
                onCompletion: { [weak self] evaluation in
                    guard let self = self else { return }
                    self.speechEvaluationResult = evaluation
                    self.internalRecognizedText = evaluation.spokenText
                    self.evaluateAnswer(evaluation.spokenText)
                },
                onError: { [weak self] error in
                    guard let self = self else { return }
                    let desc: String
                    if let err = error as? SpeechKitError, let msg = err.errorDescription {
                        desc = msg
                    } else if let err = error as? SpeechRecognitionError, let msg = err.errorDescription {
                        desc = msg
                    } else {
                        desc = error.localizedDescription
                    }
                    self.state.feedbackText = String(localized: "reflex.errorRecording \(desc)")
                    self.state.errorMessage = desc
                    self.state.showErrorAlert = true
                }
            )
        } else {
            sttService.startListening(
                onResult: { [weak self] recognizedText in
                    guard let self = self, let target = self.state.drill?.correctAnswer else { return }
                    self.internalRecognizedText = recognizedText
                    // Only auto-evaluate when user speech matches target answer.
                    if self.isCorrectAnswer(userText: recognizedText, targetText: target) {
                        self.evaluateAnswer(recognizedText)
                    }
                },
                onError: { [weak self] error in
                    let desc: String
                    if let err = error as? SpeechRecognitionError, let msg = err.errorDescription {
                        desc = msg
                    } else {
                        desc = error.localizedDescription
                    }
                    self?.state.feedbackText = String(localized: "reflex.errorRecording \(desc)")
                    self?.state.errorMessage = desc
                    self?.state.showErrorAlert = true
                }
            )
        }
    }

    public func stopVoiceRecognition() {
        speechAssessmentService?.stopAssessing()
        sttService.stopListening()
    }

    public func evaluateAnswer(_ answer: String) {
        timerTask?.cancel()
        sttService.stopListening()
        speechAssessmentService?.stopAssessing()

        guard let drill = state.drill else { return }
        let isCorrect: Bool
        if let eval = speechEvaluationResult, !eval.spokenText.isEmpty {
            isCorrect = eval.isPassed || isCorrectAnswer(userText: eval.spokenText, targetText: drill.correctAnswer)
        } else {
            isCorrect = isCorrectAnswer(userText: answer, targetText: drill.correctAnswer)
        }

        let responseTime = (speechEvaluationResult?.durationMs ?? 0) > 0
            ? speechEvaluationResult!.durationMs
            : state.elapsedTimeMs

        let result = evaluateSRSUseCase.evaluateResponse(
            currentMastery: state.currentMastery,
            easeFactor: state.easeFactor,
            isCorrect: isCorrect,
            responseTimeMs: responseTime
        )

        state.currentMastery = result.nextMastery
        state.easeFactor = result.easeFactor
        state.srsResult = result
        state.isCorrect = isCorrect
        state.isEvaluated = true

        if isCorrect {
            state.feedbackText = String(localized: "reflex.correctFeedbackMs \(state.elapsedTimeMs)")
            state.triggerSparkle = true
        } else {
            state.feedbackText = String(localized: "reflex.incorrectFeedback \(drill.correctAnswer)")
            state.triggerSparkle = false
        }
    }

    public func nextDrill() {
        if !state.drillsList.isEmpty && state.currentDrillIndex + 1 < state.drillsList.count {
            state.currentDrillIndex += 1
            state.drill = state.drillsList[state.currentDrillIndex]
        } else {
            setupSampleDrill()
        }
        startDrillTimer()
    }

    // MARK: - Helper Methods

    private func normalizeText(_ text: String) -> String {
        text.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
    }

    private func isCorrectAnswer(userText: String, targetText: String) -> Bool {
        let userClean = normalizeText(userText)
        let targetClean = normalizeText(targetText)
        guard !userClean.isEmpty, !targetClean.isEmpty else { return false }
        return userClean == targetClean || userClean.contains(targetClean)
    }
}
