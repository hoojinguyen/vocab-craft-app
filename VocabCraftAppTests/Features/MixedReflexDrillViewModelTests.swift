import Testing
import Foundation
@testable import VocabCraftApp

@Suite("MixedReflexDrillViewModel Tests")
struct MixedReflexDrillViewModelTests {

    @Test("Loop-back đẩy từ sai về cuối hàng đợi và đánh dấu isRetry")
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

        // Trả lời sai câu 1
        await vm.submitAnswer(isCorrect: false, responseTimeMs: 1500)

        // Hàng đợi tăng lên 3 phần tử, câu 1 được đẩy về cuối với cờ isRetry == true
        #expect(vm.queue.count == 3)
        #expect(vm.queue.last?.word.id == firstWordId)
        #expect(vm.queue.last?.isRetry == true)
        #expect(vm.currentIndex == 1)
        #expect(vm.currentItem?.word.id == 2)
        #expect(vm.comboStreak == 0)
    }

    @Test("Combo streak tăng khi trả lời đúng và reset về 0 khi trả lời sai")
    @MainActor
    func testComboStreakTracking() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen"),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung"),
            VaultWordItem(id: 3, lemma: "create", pos: "v.", definitionVi: "Tạo ra")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        // Câu 1: đúng
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1000)
        #expect(vm.comboStreak == 1)
        #expect(vm.maxComboStreak == 1)

        // Câu 2: đúng
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1200)
        #expect(vm.comboStreak == 2)
        #expect(vm.maxComboStreak == 2)

        // Câu 3: sai -> comboStreak reset, maxCombo giữ nguyên 2
        await vm.submitAnswer(isCorrect: false, responseTimeMs: 3000)
        #expect(vm.comboStreak == 0)
        #expect(vm.maxComboStreak == 2)

        // Câu 4 (retry của câu 3): đúng
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 900)
        #expect(vm.comboStreak == 1)
        #expect(vm.maxComboStreak == 2)
    }

    @Test("Tiến độ (progress) và hoàn thành phiên luyện tập với sessionSummary")
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

        // Hoàn thành câu 1
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1500)
        #expect(vm.progress == 0.5)
        #expect(vm.isCompleted == false)

        // Hoàn thành câu 2
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1800)
        #expect(vm.progress == 1.0)
        #expect(vm.isCompleted == true)
        #expect(vm.currentItem == nil)
        #expect(vm.sessionSummary != nil)
        #expect(vm.sessionSummary?.totalWords == 2)
        #expect(vm.sessionSummary?.correctWords == 2)
        #expect(vm.sessionSummary?.maxComboStreak == 2)
    }

    @Test("RecordAttemptUseCase được gọi chính xác khi nộp kết quả câu trả lời")
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

    @Test("Phát âm từ vựng hiện tại qua TextToSpeech")
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
