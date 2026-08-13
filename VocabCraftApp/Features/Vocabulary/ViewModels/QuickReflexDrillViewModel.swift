import Foundation
import Observation

public struct QuickReflexDrillState: Equatable, Sendable {
    public var steps: [QuickDrillStep] = []
    public var currentStepIndex: Int = 0
    public var elapsedTimeMs: Int = 0
    public var isCompleted: Bool = false
    public var isCorrect: Bool = false
    public var stepSuccessCount: Int = 0
    public var srsResult: SRSResult?
    public var triggerSparkle: Bool = false

    // Step Timer & Speed Bonus State
    public var stepRemainingSeconds: Double = 5.0
    public var stepMaxSeconds: Double = 5.0
    public var isSpeedBonus: Bool = false
    public var totalSpeedBonusCount: Int = 0

    // Real-time Mic & Speech State (Hold-to-Talk)
    public var isMicActive: Bool = false
    public var recordedSpokenText: String = ""
    public var errorMessage: String?

    // Step Evaluation Feedback State
    public var isStepEvaluated: Bool = false
    public var isStepCorrect: Bool = false
    public var selectedOption: String?

    public init() {}
}

@MainActor
@Observable
public final class QuickReflexDrillViewModel {
    public let targetWord: WordItem
    public let allWords: [WordItem]
    public var state = QuickReflexDrillState()

    // Internal Tracking State (Not UI bound)
    private var stepStartTime: Date?
    private var startTime: Date?
    private var timerTask: Task<Void, Never>?
    private var autoAdvanceTask: Task<Void, Never>?

    private let ttsService: TextToSpeechProtocol
    private let sttService: SpeechRecognitionProtocol
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol?

    public var isListening: Bool { state.isMicActive || sttService.isListening }
    public var recognizedText: String { state.recordedSpokenText }

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

        // Step 1: Fast Meaning Match (Recognition - Nhận biết nhanh)
        var defOptions = distractors.shuffled().prefix(3).map { $0.definition }
        defOptions.append(targetWord.definition)
        defOptions.shuffle()

        let step1 = QuickDrillStep(
            id: 1,
            type: .fastMeaning,
            promptText: "Chọn nghĩa tiếng Việt đúng của từ '\(targetWord.lemma)'",
            targetText: targetWord.definition,
            options: Array(defOptions)
        )

        // Step 2: Fill in Blank (Context - Ngữ cảnh ứng dụng)
        let sentenceGap = targetWord.exampleSentenceEn.replacingOccurrences(
            of: targetWord.lemma,
            with: "_______",
            options: .caseInsensitive
        )
        var lemmaOptions = distractors.shuffled().prefix(3).map { $0.lemma }
        lemmaOptions.append(targetWord.lemma)
        lemmaOptions.shuffle()

        let step2 = QuickDrillStep(
            id: 2,
            type: .fillInBlank,
            promptText: "Hoàn thành câu bằng từ tiếng Anh chính xác",
            targetText: targetWord.lemma,
            options: Array(lemmaOptions),
            sentenceWithGap: sentenceGap
        )

        // Step 3: Pronunciation Vocalization (Peak Reflex - Đọc & Phát âm câu mẫu)
        let step3 = QuickDrillStep(
            id: 3,
            type: .pronunciation,
            promptText: "Chạm micro và đọc câu ví dụ chứa từ '\(targetWord.lemma)'",
            targetText: targetWord.exampleSentenceEn
        )

        self.state.steps = [step1, step2, step3]
    }

    public func startTimer() {
        startTime = Date()
        stepStartTime = Date()
        state.stepRemainingSeconds = state.stepMaxSeconds
        timerTask?.cancel()

        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self = self, let start = self.startTime else { break }

                self.state.elapsedTimeMs = Int(Date().timeIntervalSince(start) * 1000)

                // Per-step countdown tick
                if !self.state.isStepEvaluated, let stepStart = self.stepStartTime {
                    let elapsedStep = Date().timeIntervalSince(stepStart)
                    let rem = max(0, self.state.stepMaxSeconds - elapsedStep)
                    self.state.stepRemainingSeconds = rem
                }
            }
        }
    }

    public func speakTargetSentence() {
        guard state.currentStepIndex < state.steps.count else { return }
        ttsService.speak(text: state.steps[state.currentStepIndex].targetText)
    }

    // MARK: - Tap-to-Talk Speech Recognition Methods

    public func startRecording() {
        guard !state.isMicActive && !state.isStepEvaluated else { return }
        ttsService.stop()
        state.errorMessage = nil
        state.isMicActive = true
        state.recordedSpokenText = ""

        sttService.startListening(
            onResult: { [weak self] text in
                guard let self = self else { return }
                self.state.recordedSpokenText = text
                if self.state.currentStepIndex < self.state.steps.count {
                    let target = self.state.steps[self.state.currentStepIndex].targetText
                    if self.isAnswerMatching(userText: text, targetText: target) {
                        self.stopRecordingAndEvaluate()
                    }
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                self.state.isMicActive = false
                let errDesc = error.localizedDescription
                self.state.errorMessage = "Không thể thu âm: \(errDesc). Vui lòng kiểm tra quyền Micro."
            }
        )
    }

    public func stopRecordingAndEvaluate() {
        guard state.isMicActive else { return }
        state.isMicActive = false
        sttService.stopListening()

        if !state.recordedSpokenText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            submitAnswer(state.recordedSpokenText)
        } else {
            state.errorMessage = "Chưa nghe thấy câu trả lời. Hãy chạm micro và đọc câu mẫu."
        }
    }

    public func handleMicTap() {
        if state.isMicActive {
            stopRecordingAndEvaluate()
        } else {
            startRecording()
        }
    }

    // MARK: - Answer Submission & Fast Auto-Advance

    public func submitAnswer(_ answer: String) {
        guard state.currentStepIndex < state.steps.count, !state.isStepEvaluated else { return }
        autoAdvanceTask?.cancel()

        let currentStep = state.steps[state.currentStepIndex]
        let correct = isAnswerMatching(userText: answer, targetText: currentStep.targetText)

        self.state.selectedOption = answer
        self.state.isStepEvaluated = true
        self.state.isStepCorrect = correct

        if correct {
            state.stepSuccessCount += 1
            // Check speed bonus (< 2.5s)
            if let stepStart = stepStartTime {
                let duration = Date().timeIntervalSince(stepStart)
                if duration <= 2.5 {
                    state.isSpeedBonus = true
                    state.totalSpeedBonusCount += 1
                }
            }
        }

        // Fast auto-advance after 800ms show of correct/wrong highlight
        autoAdvanceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(800))
            guard let self = self, !Task.isCancelled else { return }
            self.nextStep()
        }
    }

    public func nextStep() {
        autoAdvanceTask?.cancel()
        state.isStepEvaluated = false
        state.isStepCorrect = false
        state.isSpeedBonus = false
        state.selectedOption = nil
        state.recordedSpokenText = ""
        state.errorMessage = nil

        if state.currentStepIndex + 1 < state.steps.count {
            state.currentStepIndex += 1
            stepStartTime = Date()
            state.stepRemainingSeconds = state.stepMaxSeconds
        } else {
            finishDrill()
        }
    }

    public func finishDrill() {
        timerTask?.cancel()
        if state.isMicActive {
            sttService.stopListening()
            state.isMicActive = false
        }

        let allCorrect = state.stepSuccessCount == state.steps.count
        let avgTimeMs = state.steps.isEmpty ? 2000 : state.elapsedTimeMs / state.steps.count

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

        self.state.srsResult = result
        self.state.isCorrect = allCorrect
        self.state.triggerSparkle = allCorrect
        self.state.isCompleted = true
    }

    private func isAnswerMatching(userText: String, targetText: String) -> Bool {
        let u = userText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let t = targetText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard !u.isEmpty, !t.isEmpty else { return false }
        return u == t || u.contains(t) || t.contains(u)
    }
}
