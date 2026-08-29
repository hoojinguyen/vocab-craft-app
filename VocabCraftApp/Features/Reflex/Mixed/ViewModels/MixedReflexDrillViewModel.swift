import Foundation
import Observation

@MainActor
@Observable
public final class MixedReflexDrillViewModel: Identifiable {
    public let id: UUID = UUID()
    public private(set) var queue: [MixedReflexDrillItem] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var comboStreak: Int = 0
    public private(set) var maxComboStreak: Int = 0
    public private(set) var attempts: [ReflexBlitzAttempt] = []
    public private(set) var isCompleted: Bool = false
    public private(set) var sessionSummary: ReflexBlitzSessionSummary?

    private let selectedWords: [VaultWordItem]
    private let queueUseCase: GenerateMixedReflexQueueUseCaseProtocol
    private let recordAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?

    public init(
        selectedWords: [VaultWordItem],
        queueUseCase: GenerateMixedReflexQueueUseCaseProtocol,
        recordAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil
    ) {
        self.selectedWords = selectedWords
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

    public func generateOptions(for item: MixedReflexDrillItem) -> [ReflexBlitzOption] {
        let mode = item.assignedMode
        guard mode == .multipleChoice || mode == .listening else { return [] }

        let isMultipleChoice = mode == .multipleChoice
        let correctText = isMultipleChoice ? item.word.lemma : item.word.definitionVi

        var distractors: [String] = []
        var seen: Set<String> = [correctText]

        for otherWord in selectedWords.shuffled() {
            let candidate = isMultipleChoice ? otherWord.lemma : otherWord.definitionVi
            if !candidate.isEmpty && !seen.contains(candidate) {
                seen.insert(candidate)
                distractors.append(candidate)
                if distractors.count == 3 { break }
            }
        }

        if distractors.count < 3 {
            for starter in ReflexBlitzWordItem.defaultStarterWords.shuffled() {
                let candidate = isMultipleChoice ? starter.lemma : starter.definitionVi
                if !candidate.isEmpty && !seen.contains(candidate) {
                    seen.insert(candidate)
                    distractors.append(candidate)
                    if distractors.count == 3 { break }
                }
            }
        }

        var options: [ReflexBlitzOption] = [
            ReflexBlitzOption(text: correctText, isCorrect: true)
        ]
        for distractor in distractors.prefix(3) {
            options.append(ReflexBlitzOption(text: distractor, isCorrect: false))
        }
        return options.shuffled()
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
    }

    /// Advances to the next item in the queue and triggers session completion if exhausted.
    /// Must be called from the view after the feedback sheet is dismissed,
    /// so the background card does not flip to the next word while the sheet is still visible.
    public func advanceToNextItem() {
        currentIndex += 1
        if currentIndex >= queue.count {
            finishSession()
        }
    }

    public func restartSession() {
        self.queue = queueUseCase.generate(from: selectedWords)
        self.currentIndex = 0
        self.comboStreak = 0
        self.maxComboStreak = 0
        self.attempts = []
        self.isCompleted = self.queue.isEmpty
        self.sessionSummary = nil
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

    public func playAudio(for text: String) {
        ttsService?.speak(text: text)
    }
}
