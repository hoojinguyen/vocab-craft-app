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
    public var cefrLevel: String = "B1"
    public var triggerSparkle: Bool = false

    public init(cefrLevel: String = "B1") {
        self.cefrLevel = cefrLevel
    }
}

@MainActor
@Observable
public final class ReflexDrillViewModel {
    public var state: ReflexDrillState
    
    private let fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol?
    private let evaluateSRSUseCase: EvaluateSRSUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol
    private let sttService: SpeechRecognitionProtocol
    
    private var timerTask: Task<Void, Never>?

    public var isListening: Bool { sttService.isListening }
    public var recognizedText: String { sttService.recognizedText }
    public var isSpeaking: Bool { ttsService.isSpeaking }

    public init(
        fetchVocabularyUseCase: FetchVocabularyUseCaseProtocol? = nil,
        evaluateSRSUseCase: EvaluateSRSUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        sttService: SpeechRecognitionProtocol? = nil,
        cefrLevel: String = "B1"
    ) {
        self.state = ReflexDrillState(cefrLevel: cefrLevel)
        self.fetchVocabularyUseCase = fetchVocabularyUseCase
        self.evaluateSRSUseCase = evaluateSRSUseCase
        self.ttsService = ttsService ?? TextToSpeechService()
        self.sttService = sttService ?? SpeechRecognitionService()
    }

    public func loadDrills() {
        Task {
            do {
                if let useCase = fetchVocabularyUseCase {
                    let drills = try await useCase.executeFetchDrills(cefrLevel: state.cefrLevel)
                    self.state.drillsList = drills
                    self.state.currentDrillIndex = 0
                    self.state.drill = drills.first
                }
            } catch {
                // Fallback or error state
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
        state.feedbackText = ""
        state.srsResult = nil
        
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                if let start = state.startTime {
                    state.elapsedTimeMs = Int(Date().timeIntervalSince(start) * 1000)
                }
            }
        }
    }

    public func speakCorrectAnswer() {
        guard let drill = state.drill else { return }
        ttsService.speak(text: drill.correctAnswer)
    }

    public func startVoiceRecognition() {
        sttService.startListening(
            onResult: { [weak self] recognizedText in
                self?.evaluateAnswer(recognizedText)
            },
            onError: { [weak self] _ in
                self?.state.feedbackText = "Không thể ghi âm. Vui lòng thử lại!"
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
        
        let cleanedAnswer = answer.trimmingCharacters(in: .punctuationCharacters).lowercased()
        let cleanedCorrect = drill.correctAnswer.trimmingCharacters(in: .punctuationCharacters).lowercased()
        let isCorrect = cleanedAnswer == cleanedCorrect || cleanedAnswer.contains(cleanedCorrect)

        let result: SRSResult
        if let useCase = evaluateSRSUseCase {
            result = useCase.evaluateResponse(
                currentMastery: state.currentMastery,
                easeFactor: state.easeFactor,
                isCorrect: isCorrect,
                responseTimeMs: state.elapsedTimeMs
            )
        } else {
            result = SRSEngine.calculateNextInterval(
                currentMastery: state.currentMastery,
                easeFactor: state.easeFactor,
                isCorrect: isCorrect,
                responseTimeMs: state.elapsedTimeMs
            )
        }

        state.currentMastery = result.nextMastery
        state.easeFactor = result.easeFactor
        state.srsResult = result
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
}
