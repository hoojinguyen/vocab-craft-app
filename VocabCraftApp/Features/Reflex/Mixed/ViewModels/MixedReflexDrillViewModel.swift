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
    public private(set) var sessionPlan: ReflexDrillSessionPlan?
    public private(set) var currentPlanItem: ReflexDrillPlanItem?
    public private(set) var currentClozeStages: ReflexClozeStageSet?
    public private(set) var currentEliminatedOptionId: String?
    public private(set) var currentHintBadgeText: String = ""

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
        } else {
            buildSessionPlan()
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
        if let planItem = currentPlanItem, planItem.id.contains(item.id.uuidString) {
            return planItem.options
        }
        let mode = item.assignedMode
        guard mode == .multipleChoice || mode == .listening else { return [] }
        return ReflexDistractorGenerator.generateOptions(
            mode: mode,
            target: item,
            pool: selectedWords
        )
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
            let retryPlanItem = createPlanItem(for: retryItem)
            var items = sessionPlan?.items ?? []
            items.append(retryPlanItem)
            self.sessionPlan = ReflexDrillSessionPlan(mode: .multipleChoice, items: items)
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
        } else {
            loadPlanItem(at: currentIndex)
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
        if !self.queue.isEmpty {
            buildSessionPlan()
        } else {
            self.sessionPlan = nil
            self.currentPlanItem = nil
            self.currentClozeStages = nil
            self.currentEliminatedOptionId = nil
            self.currentHintBadgeText = ""
        }
    }

    private func createPlanItem(for item: MixedReflexDrillItem) -> ReflexDrillPlanItem {
        let mode = item.assignedMode
        let options: [ReflexBlitzOption]
        if mode == .multipleChoice || mode == .listening {
            options = ReflexDistractorGenerator.generateOptions(
                mode: mode,
                target: item,
                pool: selectedWords
            )
        } else {
            options = []
        }

        let correctIndex = options.firstIndex(where: { $0.isCorrect }) ?? 0
        let incorrectOptions = options.filter { !$0.isCorrect }
        let eliminatedId = incorrectOptions.randomElement()?.id

        let clozeStages = ReflexHintMaskGenerator.generateStages(
            lemma: item.word.lemma,
            sentenceEn: item.word.exampleSentenceEn,
            pos: item.cleanPos
        )

        let hintBadgeText: String
        switch clozeStages.strategy {
        case .middleCluster(let cluster, _):
            hintBadgeText = "...\(cluster)... • \(item.cleanPos)"
        case .prefix(let count):
            let prefixStr = String(item.word.lemma.prefix(count))
            hintBadgeText = "\(prefixStr)... • \(item.cleanPos)"
        case .suffix(let count):
            let suffixStr = String(item.word.lemma.suffix(count))
            hintBadgeText = "...\(suffixStr) • \(item.cleanPos)"
        case .consonantScaffold, .shortWordPrefix, .shortWordSuffix:
            hintBadgeText = "\(item.cleanInitialLetterHint)"
        }

        return ReflexDrillPlanItem(
            id: "\(mode.rawValue)-mixed-\(item.id.uuidString)",
            word: item,
            assignedMode: mode,
            options: options,
            correctOptionIndex: correctIndex,
            eliminatedOptionId: eliminatedId,
            clozeStages: clozeStages,
            hintBadgeText: hintBadgeText
        )
    }

    private func buildSessionPlan() {
        let planItems = queue.map { createPlanItem(for: $0) }
        self.sessionPlan = ReflexDrillSessionPlan(mode: .multipleChoice, items: planItems)
        loadPlanItem(at: currentIndex)
    }

    private func loadPlanItem(at index: Int) {
        guard let plan = sessionPlan, index >= 0 && index < plan.items.count else {
            currentPlanItem = nil
            currentClozeStages = nil
            currentEliminatedOptionId = nil
            currentHintBadgeText = ""
            return
        }
        let item = plan.items[index]
        currentPlanItem = item
        currentClozeStages = item.clozeStages
        currentEliminatedOptionId = item.eliminatedOptionId
        currentHintBadgeText = item.hintBadgeText
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
