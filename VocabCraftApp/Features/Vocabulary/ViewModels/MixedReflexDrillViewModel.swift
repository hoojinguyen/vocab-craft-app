import Foundation
import Observation

@MainActor
@Observable
public final class MixedReflexDrillViewModel {
    public private(set) var queue: [MixedReflexDrillItem] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var comboStreak: Int = 0
    public private(set) var maxComboStreak: Int = 0
    public private(set) var attempts: [ReflexBlitzAttempt] = []
    public private(set) var isCompleted: Bool = false
    public private(set) var sessionSummary: ReflexBlitzSessionSummary?

    private let queueUseCase: GenerateMixedReflexQueueUseCaseProtocol
    private let recordAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?

    public init(
        selectedWords: [VaultWordItem],
        queueUseCase: GenerateMixedReflexQueueUseCaseProtocol,
        recordAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.queueUseCase = queueUseCase
        self.recordAttemptUseCase = recordAttemptUseCase
        self.ttsService = ttsService
        self.queue = queueUseCase.generate(from: selectedWords)
        if self.queue.isEmpty {
            self.isCompleted = true
        }
    }

    public var currentItem: MixedReflexDrillItem? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }

    public var progress: Double {
        guard !queue.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(queue.count)
    }

    public func submitAnswer(isCorrect: Bool, responseTimeMs: Int = 2000) async {
        guard let current = currentItem else { return }

        let attempt = ReflexBlitzAttempt(
            wordId: Int(current.word.id),
            lemma: current.word.lemma,
            pos: current.word.pos,
            ipa: current.word.phonetic,
            definitionVi: current.word.definitionVi,
            responseTimeMs: responseTimeMs,
            usedHint: false,
            isCorrect: isCorrect
        )
        attempts.append(attempt)

        if isCorrect {
            comboStreak += 1
            maxComboStreak = max(maxComboStreak, comboStreak)
        } else {
            comboStreak = 0
            let retryItem = queueUseCase.requeueFailedItem(current)
            queue.append(retryItem)
        }

        _ = try? await recordAttemptUseCase?.execute(
            wordId: current.word.id,
            mode: current.assignedMode,
            isCorrect: isCorrect
        )

        currentIndex += 1
        if currentIndex >= queue.count {
            finishSession()
        }
    }

    private func finishSession() {
        isCompleted = true
        sessionSummary = ReflexBlitzSessionSummary.create(
            from: attempts,
            maxCombo: maxComboStreak
        )
    }

    public func playAudioForCurrentWord() {
        guard let current = currentItem else { return }
        ttsService?.speak(text: current.word.lemma)
    }
}
