import Foundation
import Observation

@MainActor
@Observable
public final class QuickReflexDrillViewModel {
    public let targetWord: WordItem
    public let allWords: [WordItem]
    public var steps: [QuickDrillStep] = []
    public var currentStepIndex: Int = 0
    public var elapsedTimeMs: Int = 0
    public var isCompleted: Bool = false
    public var isCorrect: Bool = false
    public var stepSuccessCount: Int = 0
    public var srsResult: SRSResult?
    public var triggerSparkle: Bool = false

    // Real-time Mic & Speech State
    public var isMicActive: Bool = false
    public var recordedSpokenText: String = ""
    public var errorMessage: String? = nil

    // Step Evaluation Feedback State
    public var isStepEvaluated: Bool = false
    public var isStepCorrect: Bool = false
    public var selectedOption: String? = nil
    public var stepFeedbackMessage: String = ""

    private let ttsService: TextToSpeechProtocol
    private let sttService: SpeechRecognitionProtocol
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol?
    private var startTime: Date?
    private var timerTask: Task<Void, Never>?
    private var autoAdvanceTask: Task<Void, Never>?

    public var isListening: Bool { isMicActive || sttService.isListening }
    public var recognizedText: String { recordedSpokenText }

    public init(
        targetWord: WordItem,
        allWords: [WordItem],
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol? = nil
    ) {
        self.targetWord = targetWord
        self.allWords = allWords
        self.ttsService = ttsService ?? TextToSpeechService()
        self.sttService = sttService ?? SpeechRecognitionService()
        self.evaluateSRSUseCase = evaluateSRSUseCase
        generateSteps()
        startTimer()
    }

    deinit {
        let stt = sttService
        Task { @MainActor in stt.stopListening() }
    }

    public func generateSteps() {
        let distractors = allWords.filter { $0.id != targetWord.id }
        
        // Step 1: Pronunciation
        let step1 = QuickDrillStep(
            id: 1,
            type: .pronunciation,
            promptText: "Đọc to câu ví dụ chứa từ '\(targetWord.lemma)'",
            targetText: targetWord.exampleSentenceEn
        )

        // Step 2: Fast Meaning Match
        var defOptions = distractors.shuffled().prefix(3).map { $0.definition }
        defOptions.append(targetWord.definition)
        defOptions.shuffle()

        let step2 = QuickDrillStep(
            id: 2,
            type: .fastMeaning,
            promptText: "Chọn nghĩa tiếng Việt đúng của từ '\(targetWord.lemma)'",
            targetText: targetWord.definition,
            options: Array(defOptions)
        )

        // Step 3: Fill in Blank
        let sentenceGap = targetWord.exampleSentenceEn.replacingOccurrences(
            of: targetWord.lemma,
            with: "_______",
            options: .caseInsensitive
        )
        var lemmaOptions = distractors.shuffled().prefix(3).map { $0.lemma }
        lemmaOptions.append(targetWord.lemma)
        lemmaOptions.shuffle()

        let step3 = QuickDrillStep(
            id: 3,
            type: .fillInBlank,
            promptText: "Hoàn thành câu bằng từ tiếng Anh chính xác",
            targetText: targetWord.lemma,
            options: Array(lemmaOptions),
            sentenceWithGap: sentenceGap
        )

        self.steps = [step1, step2, step3]
    }

    public func startTimer() {
        startTime = Date()
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self = self, let start = self.startTime else { break }
                self.elapsedTimeMs = Int(Date().timeIntervalSince(start) * 1000)
            }
        }
    }

    public func speakTargetSentence() {
        guard currentStepIndex < steps.count else { return }
        ttsService.speak(text: steps[currentStepIndex].targetText)
    }

    public func handleMicTap() {
        if isMicActive {
            stopVoiceRecognition()
            if !recordedSpokenText.isEmpty {
                submitAnswer(recordedSpokenText)
            }
        } else {
            startVoiceRecognition()
        }
    }

    public func startVoiceRecognition() {
        ttsService.stop()
        errorMessage = nil
        isMicActive = true
        recordedSpokenText = ""

        sttService.startListening(
            onResult: { [weak self] text in
                guard let self = self else { return }
                self.recordedSpokenText = text
                guard self.currentStepIndex < self.steps.count else { return }
                let target = self.steps[self.currentStepIndex].targetText
                if self.isAnswerMatching(userText: text, targetText: target) {
                    self.stopVoiceRecognition()
                    self.submitAnswer(text)
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.isMicActive = false
                let errDesc = error.localizedDescription
                self.errorMessage = "Không thể thu âm: \(errDesc). Vui lòng kiểm tra quyền Micro trong Cài đặt."
            }
        )
    }

    public func stopVoiceRecognition() {
        isMicActive = false
        sttService.stopListening()
    }

    public func submitAnswer(_ answer: String) {
        guard currentStepIndex < steps.count, !isStepEvaluated else { return }
        autoAdvanceTask?.cancel()
        stopVoiceRecognition()

        let currentStep = steps[currentStepIndex]
        let correct = isAnswerMatching(userText: answer, targetText: currentStep.targetText)

        self.selectedOption = answer
        self.isStepEvaluated = true
        self.isStepCorrect = correct

        if correct {
            stepSuccessCount += 1
            stepFeedbackMessage = "Chính xác!"
        } else {
            stepFeedbackMessage = "Chưa chính xác. Đáp án đúng: \"\(currentStep.targetText)\""
        }

        // Auto-advance after 1.4s delay so user clearly sees correct/wrong feedback
        autoAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1400))
            guard let self = self, !Task.isCancelled else { return }
            self.nextStep()
        }
    }

    public func nextStep() {
        autoAdvanceTask?.cancel()
        isStepEvaluated = false
        isStepCorrect = false
        selectedOption = nil
        recordedSpokenText = ""
        stepFeedbackMessage = ""
        errorMessage = nil

        if currentStepIndex + 1 < steps.count {
            currentStepIndex += 1
        } else {
            finishDrill()
        }
    }

    public func finishDrill() {
        timerTask?.cancel()
        stopVoiceRecognition()
        
        let allCorrect = stepSuccessCount == steps.count
        let avgTimeMs = steps.isEmpty ? 2000 : elapsedTimeMs / steps.count

        let result: SRSResult
        if let useCase = evaluateSRSUseCase {
            result = useCase.evaluateResponse(
                currentMastery: targetWord.masteryLevel,
                easeFactor: 2.5,
                isCorrect: allCorrect,
                responseTimeMs: avgTimeMs
            )
        } else {
            result = SRSEngine.calculateNextInterval(
                currentMastery: targetWord.masteryLevel,
                easeFactor: 2.5,
                isCorrect: allCorrect,
                responseTimeMs: avgTimeMs
            )
        }

        self.srsResult = result
        self.isCorrect = allCorrect
        self.triggerSparkle = allCorrect
        self.isCompleted = true
    }

    private func isAnswerMatching(userText: String, targetText: String) -> Bool {
        let u = userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let t = targetText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !u.isEmpty, !t.isEmpty else { return false }
        return u == t || u.contains(t) || t.contains(u)
    }
}
