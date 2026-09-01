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
    public let allowSpeakingSkip: Bool
    public private(set) var selectedWords: [VaultWordItem]
    private let queueUseCase: GenerateMixedReflexQueueUseCaseProtocol
    private let planGenerator: PracticeDrillPlanGeneratorProtocol?
    private let recordAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol?
    private let ttsService: TextToSpeechProtocol?

    public init(
        selectedWords: [VaultWordItem],
        queueUseCase: GenerateMixedReflexQueueUseCaseProtocol = GenerateMixedReflexQueueUseCase(),
        planGenerator: PracticeDrillPlanGeneratorProtocol? = nil,
        recordAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol? = nil,
        ttsService: TextToSpeechProtocol? = nil,
        allowSpeakingSkip: Bool = false
    ) {
        self.selectedWords = selectedWords
        self.queueUseCase = queueUseCase
        self.planGenerator = planGenerator
        self.recordAttemptUseCase = recordAttemptUseCase
        self.ttsService = ttsService
        self.allowSpeakingSkip = allowSpeakingSkip

        if let planGenerator {
            let precomputedPlan = planGenerator.generatePlan(from: selectedWords)
            self.sessionPlan = precomputedPlan
            self.queue = precomputedPlan.items.compactMap { item in
                guard let vaultItem = item.word as? VaultWordItem else { return nil }
                return MixedReflexDrillItem(word: vaultItem, assignedMode: item.assignedMode, isRetry: false)
            }
        } else {
            self.queue = queueUseCase.generate(from: selectedWords)
        }

        if self.queue.isEmpty {
            self.isCompleted = true
        } else {
            if self.sessionPlan == nil {
                buildSessionPlan()
            } else {
                loadPlanItem(at: 0)
            }
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
        if let planItem = currentPlanItem,
           planItem.assignedMode == item.assignedMode,
           planItem.word.lemma == item.word.lemma,
           !planItem.options.isEmpty {
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

        if current.assignedMode != .listening {
            playAudioForCurrentWord()
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

    /// Skips the current speaking question without penalty and requeues it to the end of the queue
    /// with a non-speaking mode (Typing, Multiple Choice, or Listening).
    public func skipSpeakingCurrentWord() {
        guard allowSpeakingSkip, let current = currentItem else { return }

        let nonSpeakingModes = ReflexBlitzMode.allCases.filter { $0 != .speaking }
        let newMode = nonSpeakingModes.randomElement() ?? .multipleChoice
        let retryItem = MixedReflexDrillItem(word: current.word, assignedMode: newMode, isRetry: true)
        queue.append(retryItem)

        let retryPlanItem = createPlanItem(for: retryItem)
        var items = sessionPlan?.items ?? []
        items.append(retryPlanItem)
        self.sessionPlan = ReflexDrillSessionPlan(mode: .multipleChoice, items: items)

        advanceToNextItem()
    }

    public func reDrillWeakWords() {
        guard let summary = sessionSummary, !summary.weakWordAttempts.isEmpty else { return }
        let weakWordIds = Set(summary.weakWordAttempts.map { Int64($0.wordId) })
        let weakVaultWords = selectedWords.filter { weakWordIds.contains($0.id) }
        guard !weakVaultWords.isEmpty else { return }
        self.selectedWords = weakVaultWords
        restartSession()
    }

    public func restartSession() {
        if let planGenerator {
            let precomputedPlan = planGenerator.generatePlan(from: selectedWords)
            self.sessionPlan = precomputedPlan
            self.queue = precomputedPlan.items.compactMap { item in
                guard let vaultItem = item.word as? VaultWordItem else { return nil }
                return MixedReflexDrillItem(word: vaultItem, assignedMode: item.assignedMode, isRetry: false)
            }
        } else {
            self.queue = queueUseCase.generate(from: selectedWords)
        }
        self.currentIndex = 0
        self.comboStreak = 0
        self.maxComboStreak = 0
        self.attempts = []
        self.isCompleted = self.queue.isEmpty
        self.sessionSummary = nil
        if !self.queue.isEmpty {
            if self.sessionPlan == nil || planGenerator == nil {
                buildSessionPlan()
            } else {
                loadPlanItem(at: 0)
            }
        } else {
            self.sessionPlan = nil
            self.currentPlanItem = nil
            self.currentClozeStages = nil
            self.currentEliminatedOptionId = nil
            self.currentHintBadgeText = ""
        }
    }

    private func createPlanItem(for item: MixedReflexDrillItem) -> ReflexDrillPlanItem {
        ReflexDrillPlanItemBuilder.buildItem(
            id: "\(item.assignedMode.rawValue)-mixed-\(item.id.uuidString)",
            word: item,
            assignedMode: item.assignedMode,
            distractorPool: selectedWords
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
