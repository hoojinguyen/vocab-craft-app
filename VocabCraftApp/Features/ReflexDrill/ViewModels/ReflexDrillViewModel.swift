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

    private let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol
    private let ttsService: TextToSpeechProtocol
    private let sttService: SpeechRecognitionProtocol

    private var timerTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?

    public var isListening: Bool { sttService.isListening }
    public var recognizedText: String { sttService.recognizedText }
    public var isSpeaking: Bool { ttsService.isSpeaking }

    public init(
        fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol,
        ttsService: TextToSpeechProtocol,
        sttService: SpeechRecognitionProtocol,
        cefrLevel: String = "B1"
    ) {
        self.state = ReflexDrillState(cefrLevel: cefrLevel)
        self.fetchVocabularyUseCase = fetchVocabularyUseCase
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.ttsService = ttsService
        self.sttService = sttService
    }

    deinit {
        let stt = sttService
        Task { @MainActor in
            stt.stopListening()
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
                self.state.errorMessage = "Không thể tải danh sách bài tập: \(error.localizedDescription)"
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

    public func handleMicTap() {
        if isListening {
            stopVoiceRecognition()
            evaluateAnswer(recognizedText)
        } else {
            startVoiceRecognition()
        }
    }

    public func startVoiceRecognition() {
        ttsService.stop()
        sttService.startListening(
            onResult: { [weak self] recognizedText in
                guard let self = self, let target = self.state.drill?.correctAnswer else { return }
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
                self?.state.feedbackText = "Không thể ghi âm: \(desc)"
                self?.state.errorMessage = desc
                self?.state.showErrorAlert = true
            }
        )
    }

    public func stopVoiceRecognition() {
        sttService.stopListening()
    }

    public func evaluateAnswer(_ answer: String) {
        timerTask?.cancel()
        sttService.stopListening()

        guard let drill = state.drill else { return }
        let isCorrect = isCorrectAnswer(userText: answer, targetText: drill.correctAnswer)

        let result = evaluateSRSUseCase.evaluateResponse(
            currentMastery: state.currentMastery,
            easeFactor: state.easeFactor,
            isCorrect: isCorrect,
            responseTimeMs: state.elapsedTimeMs
        )

        state.currentMastery = result.nextMastery
        state.easeFactor = result.easeFactor
        state.srsResult = result
        state.isCorrect = isCorrect
        state.isEvaluated = true

        if isCorrect {
            state.feedbackText = "Chính xác! Phản xạ xuất sắc (\(state.elapsedTimeMs)ms)"
            state.triggerSparkle = true
        } else {
            state.feedbackText = "Chưa chính xác. Đáp án đúng: \"\(drill.correctAnswer)\""
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
