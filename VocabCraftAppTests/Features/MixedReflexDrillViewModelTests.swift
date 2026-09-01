import Foundation
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("MixedReflexDrillViewModel Tests")
struct MixedReflexDrillViewModelTests {
    @Test("Loop-back pushes incorrect word to end of queue and marks isRetry")
    @MainActor
    func testLoopBackOnWrongAnswer() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        #expect(vm.queue.count == 2)
        #expect(vm.currentIndex == 0)
        #expect(vm.isCompleted == false)
        let firstWordId = vm.currentItem?.word.id

        // Submit incorrect answer for item 1
        await vm.submitAnswer(isCorrect: false, responseTimeMs: 1500)

        // Queue grows to 3 items, item 1 requeued at end with isRetry flag true
        #expect(vm.queue.count == 3)
        #expect(vm.queue.last?.word.id == firstWordId)
        #expect(vm.queue.last?.isRetry == true)
        vm.advanceToNextItem()
        #expect(vm.currentIndex == 1)
        #expect(vm.currentItem?.word.id == 2)
        #expect(vm.comboStreak == 0)
    }

    @Test("Combo streak increases on correct answer and resets to 0 on incorrect answer")
    @MainActor
    func testComboStreakTracking() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung"),
            VaultWordItem(id: 3, lemma: "create", pos: "v.", definitionVi: "Tạo ra")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        // Item 1: correct
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1000)
        vm.advanceToNextItem()
        #expect(vm.comboStreak == 1)
        #expect(vm.maxComboStreak == 1)

        // Item 2: correct
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1200)
        vm.advanceToNextItem()
        #expect(vm.comboStreak == 2)
        #expect(vm.maxComboStreak == 2)

        // Item 3: incorrect -> comboStreak resets, maxCombo preserved
        await vm.submitAnswer(isCorrect: false, responseTimeMs: 3000)
        vm.advanceToNextItem()
        #expect(vm.comboStreak == 0)
        #expect(vm.maxComboStreak == 2)

        // Item 4 (retry of item 3): correct
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 900)
        vm.advanceToNextItem()
        #expect(vm.comboStreak == 1)
        #expect(vm.maxComboStreak == 2)
    }

    @Test("Progress tracking and session completion with sessionSummary")
    @MainActor
    func testSessionCompletionAndSummary() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        #expect(vm.progress == 0.0)
        #expect(vm.isCompleted == false)
        #expect(vm.sessionSummary == nil)

        // Complete item 1
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1500)
        vm.advanceToNextItem()
        #expect(vm.progress == 0.5)
        #expect(vm.isCompleted == false)

        // Complete item 2
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1800)
        vm.advanceToNextItem()
        #expect(vm.progress == 1.0)
        #expect(vm.isCompleted == true)
        #expect(vm.currentItem == nil)
        #expect(vm.sessionSummary != nil)
        #expect(vm.sessionSummary?.totalWords == 2)
        #expect(vm.sessionSummary?.correctWords == 2)
        #expect(vm.sessionSummary?.maxComboStreak == 2)
    }

    @Test("RecordAttemptUseCase called when answer is submitted")
    @MainActor
    func testRecordAttemptUseCaseCalled() async {
        let words = [
            VaultWordItem(id: 42, lemma: "clarity", pos: "n.", definitionVi: "Sự rõ ràng")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let mockRecordUseCase = MockRecordMixedDrillAttemptUseCase()
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: queueUseCase,
            recordAttemptUseCase: mockRecordUseCase
        )

        let mode = vm.currentItem?.assignedMode ?? .multipleChoice
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1200)

        #expect(mockRecordUseCase.executedWordId == 42)
        #expect(mockRecordUseCase.executedMode == mode)
        #expect(mockRecordUseCase.executedIsCorrect == true)
    }

    @Test("Pronounce current word via TextToSpeech")
    @MainActor
    func testPlayAudioForCurrentWord() async {
        let words = [
            VaultWordItem(id: 1, lemma: "serendipity", pos: "n.", definitionVi: "Sự may mắn bất ngờ")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let mockTTS = MockTTS()
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: queueUseCase,
            ttsService: mockTTS
        )

        vm.playAudioForCurrentWord()
        #expect(mockTTS.lastSpokenText == "serendipity")
    }

    @Test("MixedReflexDrillViewModel initializes sessionPlan and plan items")
    @MainActor
    func testMixedSessionPlanInitialization() {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        #expect(vm.sessionPlan != nil)
        #expect(vm.sessionPlan?.items.count == 2)
        #expect(vm.currentPlanItem != nil)
        #expect(vm.currentClozeStages != nil)
    }
}

@Suite("MixedReflexDrillViewModel Skip Speaking Tests")
struct MixedReflexDrillSkipSpeakingTests {
    @Test("Skip speaking requeues word to end with non-speaking mode without penalty")
    @MainActor
    func testSkipSpeakingRequeue() {
        let words = [
            VaultWordItem(id: 1, lemma: "voice", pos: "n", definitionVi: "tiếng nói")
        ]
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: GenerateMixedReflexQueueUseCase(),
            allowSpeakingSkip: true
        )
        #expect(vm.allowSpeakingSkip)
        vm.skipSpeakingCurrentWord()
        #expect(vm.comboStreak == 0)
        #expect(vm.attempts.isEmpty)
        #expect(vm.queue.count == 2)
        #expect(vm.queue.last?.assignedMode != .speaking)
    }

    @Test("Skip speaking does nothing when allowSpeakingSkip is false")
    @MainActor
    func testSkipSpeakingDisabled() {
        let words = [
            VaultWordItem(id: 1, lemma: "voice", pos: "n", definitionVi: "tiếng nói")
        ]
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: GenerateMixedReflexQueueUseCase(),
            allowSpeakingSkip: false
        )
        #expect(!vm.allowSpeakingSkip)
        vm.skipSpeakingCurrentWord()
        #expect(vm.queue.count == 1)
        #expect(vm.currentIndex == 0)
    }

    @Test("Skip speaking preserves existing combo streak without adding attempt")
    @MainActor
    func testSkipSpeakingPreservesComboStreak() async {
        let words = [
            VaultWordItem(id: 1, lemma: "voice", pos: "n", definitionVi: "tiếng nói"),
            VaultWordItem(id: 2, lemma: "sound", pos: "n", definitionVi: "âm thanh")
        ]
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: GenerateMixedReflexQueueUseCase(),
            allowSpeakingSkip: true
        )
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1000)
        vm.advanceToNextItem()
        #expect(vm.comboStreak == 1)
        #expect(vm.attempts.count == 1)

        vm.skipSpeakingCurrentWord()
        #expect(vm.comboStreak == 1)
        #expect(vm.attempts.count == 1)
        #expect(vm.queue.count == 3)
        #expect(vm.queue.last?.assignedMode != .speaking)
    }

    @Test("MixedReflexDrillViewModel integrates with PracticeDrillPlanGenerator")
    @MainActor
    func testPlanGeneratorIntegration() {
        let words = [
            VaultWordItem(
                id: 1,
                lemma: "typingWord",
                pos: "n",
                definitionVi: "từ gõ",
                modeStats: ModeSuccessStats(speaking: 10, typing: 0, multipleChoice: 10, listening: 10)
            )
        ]
        let generator = PracticeDrillPlanGenerator()
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            planGenerator: generator
        )

        #expect(vm.queue.count == 1)
        #expect(vm.currentItem?.assignedMode == .typing)
        #expect(vm.sessionPlan != nil)
        #expect(vm.sessionPlan?.items.first?.assignedMode == .typing)
        #expect(!vm.generateOptions(for: vm.queue[0]).isEmpty || vm.queue[0].assignedMode == .typing)
    }

    @Test("MixedReflexDrillViewModel retrieves precomputed options and elimination hint from plan")
    @MainActor
    func testPlanGeneratorPrecomputedOptions() {
        let words = [
            VaultWordItem(
                id: 1,
                lemma: "apple",
                pos: "n",
                definitionVi: "quả táo",
                modeStats: ModeSuccessStats(speaking: 10, typing: 10, multipleChoice: 0, listening: 10)
            ),
            VaultWordItem(
                id: 2,
                lemma: "banana",
                pos: "n",
                definitionVi: "quả chuối",
                modeStats: ModeSuccessStats(speaking: 10, typing: 10, multipleChoice: 10, listening: 10)
            )
        ]
        let generator = PracticeDrillPlanGenerator()
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            planGenerator: generator
        )

        guard let firstItem = vm.currentItem else {
            Issue.record("Expected currentItem to exist")
            return
        }

        let options = vm.generateOptions(for: firstItem)
        if firstItem.assignedMode == .multipleChoice || firstItem.assignedMode == .listening {
            #expect(!options.isEmpty)
            #expect(options.count == 4 || options.count == words.count)
            #expect(vm.currentEliminatedOptionId != nil)
        }
    }
}

@Suite("RecordMixedDrillAttemptUseCase ModeSuccessStats Tests")
struct RecordMixedDrillModeSuccessStatsTests {
    @Test("Recording correct drill attempt increments modeSuccessStats for that mode")
    func testRecordAttemptIncrementsModeStats() async throws {
        let mockRepo = MockUserProgressRepository()
        let mockDataSource = SampleVocabularyDataSource()
        let useCase = RecordMixedDrillAttemptUseCase(progressRepo: mockRepo, dataSource: mockDataSource)

        let result = try await useCase.execute(wordId: 1, mode: .speaking, isCorrect: true)
        #expect(result?.modeStats.speaking == 1)
        #expect(result?.modeStats.typing == 0)

        let result2 = try await useCase.execute(wordId: 1, mode: .typing, isCorrect: true)
        #expect(result2?.modeStats.speaking == 1)
        #expect(result2?.modeStats.typing == 1)
    }

    @Test("Recording incorrect drill attempt does not increment modeSuccessStats")
    func testRecordAttemptIncorrectDoesNotIncrementModeStats() async throws {
        let mockRepo = MockUserProgressRepository()
        let mockDataSource = SampleVocabularyDataSource()
        let useCase = RecordMixedDrillAttemptUseCase(progressRepo: mockRepo, dataSource: mockDataSource)

        let result = try await useCase.execute(wordId: 1, mode: .speaking, isCorrect: false)
        #expect(result?.modeStats.speaking == 0)
    }
}

// MARK: - Test Mocks

@MainActor
private final class MockTTS: TextToSpeechProtocol {
    var lastSpokenText: String?
    var isSpeaking: Bool = false

    func speak(text: String, rate: Float, locale: String) {
        lastSpokenText = text
    }

    func stop() {}
}

private final class MockRecordMixedDrillAttemptUseCase: RecordMixedDrillAttemptUseCaseProtocol, @unchecked Sendable {
    var executedWordId: Int64?
    var executedMode: ReflexBlitzMode?
    var executedIsCorrect: Bool?

    func execute(wordId: Int64, mode: ReflexBlitzMode, isCorrect: Bool) async throws -> VaultWordItem? {
        self.executedWordId = wordId
        self.executedMode = mode
        self.executedIsCorrect = isCorrect
        return nil
    }
}
#endif
