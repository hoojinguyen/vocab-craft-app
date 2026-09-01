import CraftUIKit
import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("MixedReflexDrillViews Tests")
struct MixedReflexDrillViewsTests {
    @Test("DynamicReflexModeBadge hiển thị đúng cho cả 4 chế độ")
    @MainActor
    func testDynamicReflexModeBadgeRendering() {
        for mode in ReflexBlitzMode.allCases {
            let badge = DynamicReflexModeBadge(mode: mode)
            let compactBadge = DynamicReflexModeBadge(mode: mode, isCompact: true)
            #expect(badge.mode == mode)
            #expect(compactBadge.isCompact == true)
        }
    }

    @Test("DynamicReflexModeBadge a11y label và localized format hoạt động chính xác")
    func testDynamicReflexModeBadgeA11yLocalization() {
        let label = AppStrings.Reflex.modeA11yLabel(mode: "Trắc nghiệm", duration: "4.5s")
        #expect(!label.isEmpty)
        #expect(label.contains("Trắc nghiệm"))
        #expect(label.contains("4.5s"))

        let aliasLabel = AppStrings.Reflex.modeAccessibilityLabel(mode: "Luyện nói", duration: "6.0s")
        #expect(!aliasLabel.isEmpty)
        #expect(aliasLabel.contains("Luyện nói"))
        #expect(aliasLabel.contains("6.0s"))
    }

    @Test("DynamicPulseTimerBar phân loại đúng 3 cấp độ thời gian (Steady, Warning, Urgent)")
    @MainActor
    func testDynamicPulseTimerBarStages() {
        // Steady (> 0.45)
        let steadyBar = DynamicPulseTimerBar(fractionRemaining: 0.8)
        #expect(steadyBar.isUrgent == false)
        #expect(steadyBar.isWarning == false)

        // Warning (0.18 < fraction <= 0.45)
        let warningBar = DynamicPulseTimerBar(fractionRemaining: 0.3)
        #expect(warningBar.isUrgent == false)
        #expect(warningBar.isWarning == true)

        // Urgent (<= 0.18)
        let urgentBar = DynamicPulseTimerBar(fractionRemaining: 0.1)
        #expect(urgentBar.isUrgent == true)
        #expect(urgentBar.isWarning == false)
    }

    @Test("MixedReflexSummaryView hiển thị đầy đủ thông tin tổng kết và hỗ trợ trạng thái Perfect Score")
    @MainActor
    func testMixedReflexSummaryView() {
        let attempts = [
            ReflexBlitzAttempt(
                wordId: 1,
                lemma: "habit",
                pos: "n.",
                definitionVi: "Thói quen",
                responseTimeMs: 1200,
                usedHint: false,
                isCorrect: true
            ),
            ReflexBlitzAttempt(
                wordId: 2,
                lemma: "focus",
                pos: "v.",
                definitionVi: "Tập trung",
                responseTimeMs: 1800,
                usedHint: false,
                isCorrect: true
            )
        ]
        let summary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: 2)
        let practicedWords = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen", isMastered: true),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung", isMastered: false)
        ]

        var retryCalled = false
        var doneCalled = false

        let summaryView = MixedReflexSummaryView(
            summary: summary,
            practicedWords: practicedWords,
            onSpeakWord: { _ in },
            onReDrillWeak: { retryCalled = true },
            onFinish: { doneCalled = true }
        )

        #expect(summaryView.summary.totalWords == 2)
        #expect(summaryView.summary.correctWords == 2)
        #expect(summaryView.summary.weakWordAttempts.isEmpty)
        _ = summaryView.body
        _ = summaryView.stickyBottomActionDock

        summaryView.onRetry()
        #expect(retryCalled == true)

        summaryView.onDone()
        #expect(doneCalled == true)
    }

    @Test("MixedReflexSummaryView hiển thị mục từ yếu khi có câu sai")
    @MainActor
    func testMixedReflexSummaryViewWithWeakWords() {
        let attempts = [
            ReflexBlitzAttempt(
                wordId: 1,
                lemma: "eloquent",
                pos: "adj.",
                definitionVi: "Hùng biện",
                responseTimeMs: 2500,
                usedHint: false,
                isCorrect: false
            )
        ]
        let summary = ReflexBlitzSessionSummary.create(from: attempts, maxCombo: 0)

        var redrillCalled = false
        var finishCalled = false
        var spokenLemma: String?

        let summaryView = MixedReflexSummaryView(
            summary: summary,
            onSpeakWord: { spokenLemma = $0 },
            onReDrillWeak: { redrillCalled = true },
            onFinish: { finishCalled = true }
        )

        #expect(summaryView.summary.weakWordAttempts.count == 1)
        _ = summaryView.body
        _ = summaryView.bottomActionDock

        summaryView.onReDrillWeak()
        #expect(redrillCalled == true)

        summaryView.onFinish()
        #expect(finishCalled == true)

        summaryView.onSpeakWord?("eloquent")
        #expect(spokenLemma == "eloquent")
    }

    @Test("MixedReflexDrillViewModel reDrillWeakWords khởi tạo lại phiên luyện tập với các từ sai")
    @MainActor
    func testMixedReflexDrillViewModelReDrillWeakWords() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen", exampleSentenceEn: "Reading books daily is a great habit."),
            VaultWordItem(id: 2, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", exampleSentenceEn: "She gave an eloquent speech.")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        // Nộp câu 1 đúng, câu 2 sai -> câu 2 được requeue vào cuối hàng đợi
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1200)
        vm.advanceToNextItem()
        await vm.submitAnswer(isCorrect: false, responseTimeMs: 4000)
        vm.advanceToNextItem()
        // Nộp câu 3 (retry của câu 2)
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1000)
        vm.advanceToNextItem()

        #expect(vm.isCompleted == true)
        #expect(vm.sessionSummary?.weakWordAttempts.count == 1)
        #expect(vm.sessionSummary?.weakWordAttempts.first?.wordId == 2)

        // Gọi reDrillWeakWords
        vm.reDrillWeakWords()

        #expect(vm.isCompleted == false)
        #expect(vm.selectedWords.count == 1)
        #expect(vm.selectedWords.first?.id == 2)
        #expect(vm.queue.count == 1)
        #expect(vm.queue.first?.word.id == 2)
        #expect(vm.currentIndex == 0)
        #expect(vm.comboStreak == 0)
    }

    @Test("MixedReflexDrillView khởi tạo và kết nối với MixedReflexDrillViewModel")
    @MainActor
    func testMixedReflexDrillViewInitialization() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen", exampleSentenceEn: "Reading books daily is a great habit."),
            VaultWordItem(id: 2, lemma: "focus", pos: "v.", definitionVi: "Tập trung", exampleSentenceEn: "Focus on your goals.")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        var finished = false
        let drillView = MixedReflexDrillView(viewModel: vm, onFinish: {
            finished = true
        })

        #expect(drillView.viewModel.queue.count == 2)
        #expect(drillView.viewModel.currentItem != nil)

        // Hoàn thành lần lượt cả 2 câu
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1200)
        vm.advanceToNextItem()
        #expect(vm.currentIndex == 1)

        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1400)
        vm.advanceToNextItem()
        #expect(vm.isCompleted == true)
        #expect(vm.sessionSummary != nil)

        drillView.onFinish()
        #expect(finished == true)
    }

    @Test("MixedReflexDrillView khởi tạo và hiển thị card Listening cho item chế độ listening")
    @MainActor
    func testMixedReflexDrillViewListeningModeChallengeCard() async {
        let words = [
            VaultWordItem(id: 1, lemma: "ephemeral", pos: "adj.", definitionVi: "Phù du", exampleSentenceEn: "Her fame is ephemeral.")
        ]
        final class MockListeningQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol {
            let item: MixedReflexDrillItem
            init(item: MixedReflexDrillItem) { self.item = item }
            func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] { [item] }
            func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem { item }
        }

        let item = MixedReflexDrillItem(word: words[0], assignedMode: .listening, isRetry: false)
        let queueUseCase = MockListeningQueueUseCase(item: item)
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        let drillView = MixedReflexDrillView(viewModel: vm, onFinish: {})
        #expect(drillView.viewModel.queue.count == 1)
        #expect(drillView.viewModel.currentItem?.assignedMode == .listening)
        #expect(drillView.isReviewed == false)
        #expect(drillView.isResultCorrect == false)
        #expect(drillView.isResultTimeout == false)
    }

    @Test("MixedReflexDrillView tiến triển mượt mà qua các từ với view identity rõ ràng")
    @MainActor
    func testMixedReflexDrillViewProgressionWithIdentity() async {
        let words = [
            VaultWordItem(id: 1, lemma: "ephemeral", pos: "adj.", definitionVi: "Phù du", exampleSentenceEn: "Her fame is ephemeral."),
            VaultWordItem(id: 2, lemma: "serendipity", pos: "n.", definitionVi: "May mắn", exampleSentenceEn: "Pure serendipity.")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        let drillView = MixedReflexDrillView(viewModel: vm, onFinish: {})
        #expect(drillView.viewModel.queue.count == 2)
        #expect(drillView.viewModel.currentIndex == 0)
        #expect(drillView.viewModel.currentItem?.word.id == words[0].id)

        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1000)
        vm.advanceToNextItem()

        #expect(drillView.viewModel.currentIndex == 1)
        #expect(drillView.viewModel.currentItem?.word.id == words[1].id)
    }

    @Test("MixedReflexDrillView khởi tạo và hiển thị card Typing cho item chế độ typing")
    @MainActor
    func testMixedReflexDrillViewTypingModeChallengeCard() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen", exampleSentenceEn: "Reading books daily is a great habit.")
        ]
        final class MockTypingQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol {
            let item: MixedReflexDrillItem
            init(item: MixedReflexDrillItem) { self.item = item }
            func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] { [item] }
            func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem { item }
        }

        let item = MixedReflexDrillItem(word: words[0], assignedMode: .typing, isRetry: false)
        let queueUseCase = MockTypingQueueUseCase(item: item)
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        let drillView = MixedReflexDrillView(viewModel: vm, onFinish: {})
        #expect(drillView.viewModel.queue.count == 1)
        #expect(drillView.viewModel.currentItem?.assignedMode == .typing)
        #expect(drillView.isReviewed == false)
        #expect(drillView.isResultCorrect == false)
        #expect(drillView.isResultTimeout == false)
    }

    @Test("MixedReflexDrillView khởi tạo và hiển thị card Speaking cho item chế độ speaking")
    @MainActor
    func testMixedReflexDrillViewSpeakingModeChallengeCard() async {
        let words = [
            VaultWordItem(id: 1, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", exampleSentenceEn: "She gave an eloquent speech.")
        ]
        final class MockSpeakingQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol {
            let item: MixedReflexDrillItem
            init(item: MixedReflexDrillItem) { self.item = item }
            func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] { [item] }
            func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem { item }
        }

        let item = MixedReflexDrillItem(word: words[0], assignedMode: .speaking, isRetry: false)
        let queueUseCase = MockSpeakingQueueUseCase(item: item)
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        let drillView = MixedReflexDrillView(viewModel: vm, onFinish: {})
        #expect(drillView.viewModel.queue.count == 1)
        #expect(drillView.viewModel.currentItem?.assignedMode == .speaking)
        #expect(drillView.isReviewed == false)
        #expect(drillView.isResultCorrect == false)
        #expect(drillView.isResultTimeout == false)
        _ = drillView.body
    }

    @Test("Mixed Reflex Drill handles incorrect typing submission without silent drop")
    @MainActor
    func testMixedReflexIncorrectTypingSubmission() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen", exampleSentenceEn: "Reading books daily is a great habit.")
        ]
        final class MockTypingQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol {
            let item: MixedReflexDrillItem
            init(item: MixedReflexDrillItem) { self.item = item }
            func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] { [item] }
            func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem {
                MixedReflexDrillItem(word: item.word, assignedMode: .typing, isRetry: true)
            }
        }

        let item = MixedReflexDrillItem(word: words[0], assignedMode: .typing, isRetry: false)
        let queueUseCase = MockTypingQueueUseCase(item: item)
        let viewModel = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: queueUseCase
        )

        let drillView = MixedReflexDrillView(viewModel: viewModel, onFinish: {})
        #expect(drillView.viewModel.queue.count == 1)
        #expect(drillView.viewModel.currentItem?.assignedMode == .typing)
        #expect(viewModel.attempts.isEmpty)

        await viewModel.submitAnswer(isCorrect: false, responseTimeMs: 1200)

        #expect(viewModel.attempts.count == 1)
        #expect(viewModel.attempts[0].isCorrect == false)
        #expect(viewModel.queue.count == 2)
        #expect(viewModel.queue.last?.isRetry == true)
    }

    @Test("ReflexCountdownOverlayView khởi tạo đúng với count, mode và callback onFinish")
    @MainActor
    func testReflexCountdownOverlayViewConfiguration() {
        var finishCalled = false
        let overlay = ReflexCountdownOverlayView(count: 3, mode: .speaking) {
            finishCalled = true
        }

        #expect(overlay.count == 3)
        #expect(overlay.mode == .speaking)
        #expect(overlay.title == ReflexBlitzMode.speaking.title)
        _ = overlay.body

        overlay.onFinish()
        #expect(finishCalled == true)
    }

    @Test("ReflexCountdownOverlayView hỗ trợ mixed drill countdown với custom title, subtitle, icon và tint")
    @MainActor
    func testReflexCountdownOverlayViewMixedConfiguration() {
        var finishCalled = false
        let theme = CraftDefaultTheme()
        let overlay = ReflexCountdownOverlayView(
            count: 3,
            title: AppStrings.Practice.mixedDrillTitleText,
            subtitle: AppStrings.Practice.mixedDrillSubtitleText,
            iconName: "bolt.fill",
            tintColor: theme.colors.brandPrimary,
            onFinish: { finishCalled = true }
        )

        #expect(overlay.count == 3)
        #expect(overlay.title == AppStrings.Practice.mixedDrillTitleText)
        #expect(overlay.subtitle == AppStrings.Practice.mixedDrillSubtitleText)
        #expect(overlay.iconName == "bolt.fill")
        #expect(overlay.tintColor == theme.colors.brandPrimary)
        #expect(overlay.mode == nil)
        _ = overlay.body

        overlay.onFinish()
        #expect(finishCalled == true)
    }

    @Test("MixedReflexDrillView hỗ trợ cờ startWithCountdown để hiển thị overlay trước bài tập")
    @MainActor
    func testMixedReflexDrillViewCountdownOverlayPresentation() {
        let words = [
            VaultWordItem(id: 1, lemma: "voice", pos: "n.", definitionVi: "tiếng nói", exampleSentenceEn: "Her voice is clear.")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vmWithSkip = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: queueUseCase,
            allowSpeakingSkip: true
        )
        let vmWithoutSkip = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: queueUseCase,
            allowSpeakingSkip: false
        )

        var finished = false
        let drillViewWithCountdown = MixedReflexDrillView(
            viewModel: vmWithSkip,
            startWithCountdown: true,
            onFinish: { finished = true }
        )
        #expect(drillViewWithCountdown.startWithCountdown == true)
        #expect(drillViewWithCountdown.viewModel.allowSpeakingSkip == true)
        _ = drillViewWithCountdown.body

        let drillViewWithoutCountdown = MixedReflexDrillView(
            viewModel: vmWithoutSkip,
            startWithCountdown: false,
            onFinish: { finished = true }
        )
        #expect(drillViewWithoutCountdown.startWithCountdown == false)
        #expect(drillViewWithoutCountdown.viewModel.allowSpeakingSkip == false)
        _ = drillViewWithoutCountdown.body
        #expect(finished == false)
    }

    @Test("MixedReflexDrillView nút Không thể nói lúc này bỏ qua từ nói mà không phạt streak")
    @MainActor
    func testMixedReflexDrillViewSkipSpeakingButtonAction() {
        let words = [
            VaultWordItem(id: 1, lemma: "speak", pos: "v.", definitionVi: "nói", exampleSentenceEn: "Speak clearly.")
        ]
        final class MockSpeakingQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol {
            let item: MixedReflexDrillItem
            init(item: MixedReflexDrillItem) { self.item = item }
            func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] { [item] }
            func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem { item }
        }

        let item = MixedReflexDrillItem(word: words[0], assignedMode: .speaking, isRetry: false)
        let queueUseCase = MockSpeakingQueueUseCase(item: item)
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: queueUseCase,
            allowSpeakingSkip: true
        )

        #expect(vm.allowSpeakingSkip == true)
        #expect(vm.currentItem?.assignedMode == .speaking)
        #expect(vm.comboStreak == 0)

        // Thực hiện hành động bỏ qua nói
        vm.skipSpeakingCurrentWord()

        // Hàng đợi tăng thêm 1 từ thay thế ở chế độ khác
        #expect(vm.queue.count == 2)
        #expect(vm.queue.last?.assignedMode != .speaking)
        #expect(vm.attempts.isEmpty)
        #expect(vm.comboStreak == 0)

        // Phím CTA text kiểm tra giá trị localized chuẩn
        #expect(!AppStrings.Practice.cantSpeakNowCTA.isEmpty)
        #expect(AppStrings.Practice.cantSpeakNowCTA == "Không thể nói lúc này" || AppStrings.Practice.cantSpeakNowCTA == "Can't speak now")
    }

    @Test("MixedReflexDrillView tích hợp chính xác với ReflexSpeechEngineProtocol và nhận diện phát âm")
    @MainActor
    func testMixedReflexDrillViewSpeechEngineIntegration() async {
        let words = [
            VaultWordItem(id: 1, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", exampleSentenceEn: "He is eloquent.")
        ]
        final class MockSpeakingQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol {
            let item: MixedReflexDrillItem
            init(item: MixedReflexDrillItem) { self.item = item }
            func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] { [item] }
            func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem { item }
        }

        let item = MixedReflexDrillItem(word: words[0], assignedMode: .speaking, isRetry: false)
        let queueUseCase = MockSpeakingQueueUseCase(item: item)
        let vm = MixedReflexDrillViewModel(
            selectedWords: words,
            queueUseCase: queueUseCase
        )
        let mockSpeechEngine = MockResilientReflexSpeechEngine()

        var finished = false
        let drillView = MixedReflexDrillView(
            viewModel: vm,
            speechEngine: mockSpeechEngine,
            startWithCountdown: false,
            onFinish: { finished = true }
        )

        #expect(drillView.speechEngine != nil)
        _ = drillView.body

        // Simulate match detected callback directly on speech engine
        mockSpeechEngine.beginWord(targetLemma: words[0].lemma, contextualPhrases: [])
        mockSpeechEngine.simulateMatch(words[0].lemma)

        #expect(mockSpeechEngine.isWordActive == true)
        #expect(drillView.viewModel.currentItem?.word.lemma == "eloquent")
    }
}
#endif
