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
    @Test("DynamicReflexModeBadge renders correctly across all 4 modes")
    @MainActor
    func testDynamicReflexModeBadgeRendering() {
        for mode in ReflexBlitzMode.allCases {
            let badge = DynamicReflexModeBadge(mode: mode)
            let compactBadge = DynamicReflexModeBadge(mode: mode, isCompact: true)
            #expect(badge.mode == mode)
            #expect(compactBadge.isCompact == true)
        }
    }

    @Test("DynamicReflexModeBadge a11y label and localized format operate accurately")
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

    @Test("DynamicPulseTimerBar classifies 3 latency stages correctly (Steady, Warning, Urgent)")
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

    @Test("MixedReflexSummaryView renders summary data and supports Perfect Score state")
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

    @Test("MixedReflexSummaryView displays weak words section when attempts contain mistakes")
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

    @Test("MixedReflexDrillViewModel reDrillWeakWords initializes a new drill session with incorrect words")
    @MainActor
    func testMixedReflexDrillViewModelReDrillWeakWords() async {
        let words = [
            VaultWordItem(id: 1, lemma: "habit", pos: "n.", definitionVi: "Thói quen", exampleSentenceEn: "Reading books daily is a great habit."),
            VaultWordItem(id: 2, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", exampleSentenceEn: "She gave an eloquent speech.")
        ]
        let queueUseCase = GenerateMixedReflexQueueUseCase()
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: queueUseCase)

        // Submit item 1 correct, item 2 incorrect -> item 2 requeued at end of queue
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1200)
        vm.advanceToNextItem()
        await vm.submitAnswer(isCorrect: false, responseTimeMs: 4000)
        vm.advanceToNextItem()
        // Submit item 3 (retry of item 2)
        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1000)
        vm.advanceToNextItem()

        #expect(vm.isCompleted == true)
        #expect(vm.sessionSummary?.weakWordAttempts.count == 1)
        #expect(vm.sessionSummary?.weakWordAttempts.first?.wordId == 2)

        // Call reDrillWeakWords
        vm.reDrillWeakWords()

        #expect(vm.isCompleted == false)
        #expect(vm.selectedWords.count == 1)
        #expect(vm.selectedWords.first?.id == 2)
        #expect(vm.queue.count == 1)
        #expect(vm.queue.first?.word.id == 2)
        #expect(vm.currentIndex == 0)
        #expect(vm.comboStreak == 0)
    }

    @Test("MixedReflexDrillView initializes and binds with MixedReflexDrillViewModel")
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

        // Complete both items sequentially
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

    @Test("MixedReflexDrillView initializes and displays Listening challenge card for listening mode item")
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

    @Test("MixedReflexDrillView progresses smoothly across words with distinct view identity")
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

    @Test("MixedReflexDrillView initializes and displays Typing challenge card for typing mode item")
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

    @Test("MixedReflexDrillView initializes and displays Speaking challenge card for speaking mode item")
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

    @Test("ReflexCountdownOverlayView initializes correctly with count, mode, and onFinish callback")
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

    @Test("ReflexCountdownOverlayView supports mixed drill countdown with custom title, subtitle, icon, and tint")
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

    @Test("MixedReflexDrillView supports startWithCountdown flag to present countdown overlay")
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

    @Test("MixedReflexDrillView skip speaking button bypasses speaking prompt without streak penalty")
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

        // Perform skip speaking action
        vm.skipSpeakingCurrentWord()

        // Queue increases by 1 item with replacement mode
        #expect(vm.queue.count == 2)
        #expect(vm.queue.last?.assignedMode != .speaking)
        #expect(vm.attempts.isEmpty)
        #expect(vm.comboStreak == 0)

        // CTA button text validates standard localized value
        #expect(!AppStrings.Practice.cantSpeakNowCTA.isEmpty)
        #expect(AppStrings.Practice.cantSpeakNowCTA == "Không thể nói lúc này" || AppStrings.Practice.cantSpeakNowCTA == "Can't speak now")
    }

    @Test("MixedReflexDrillView integrates properly with ReflexSpeechEngineProtocol and speech recognition")
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

        // Explicitly setup speech engine callbacks & start item
        drillView.setupSpeechEngineCallbacks()
        drillView.startDrillItem(item)
        await Task.yield()

        #expect(mockSpeechEngine.onMatchDetected != nil)
        #expect(mockSpeechEngine.isWordActive == true)

        // Simulate match detected callback directly on speech engine
        mockSpeechEngine.simulateMatch(words[0].lemma)

        // Give the async Task time to execute
        try? await Task.sleep(for: .milliseconds(50))

        #expect(mockSpeechEngine.isWordActive == false)
        #expect(drillView.viewModel.attempts.count == 1)
        #expect(drillView.viewModel.attempts.first?.isCorrect == true)

        drillView.advanceToNextItem()
        #expect(drillView.viewModel.isCompleted == true)
        #expect(!finished)
    }

    @Test("Mixed timer waits for speech readiness before starting timer")
    @MainActor
    func mixedTimerWaitsForSpeechReadiness() async {
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
        let mockSpeechEngine = MockResilientReflexSpeechEngine()
        mockSpeechEngine.shouldSuspendStartListening = true

        let drillView = MixedReflexDrillView(
            viewModel: vm,
            speechEngine: mockSpeechEngine,
            startWithCountdown: false,
            onFinish: {}
        )
        drillView.setupSpeechEngineCallbacks()
        drillView.startDrillItem(item)
        await Task.yield()

        // While startListening is suspended:
        #expect(mockSpeechEngine.startListeningCallCount == 1)
        #expect(drillView.speechState == .preparing)
        #expect(drillView.elapsedTimeMs == 0)

        // Sleep 40ms to verify timer has NOT started
        try? await Task.sleep(for: .milliseconds(40))
        #expect(drillView.elapsedTimeMs == 0)

        // Now complete startListening
        mockSpeechEngine.startListeningContinuation?.resume()
        mockSpeechEngine.startListeningContinuation = nil
        mockSpeechEngine.shouldSuspendStartListening = false

        // Sleep to allow timer loop to tick
        for _ in 0..<10 {
            if drillView.elapsedTimeMs > 0 { break }
            try? await Task.sleep(for: .milliseconds(30))
        }
        #expect(drillView.speechState.isListening)
        #expect(drillView.elapsedTimeMs > 0)
    }

    @Test("Mixed permission denial uses typing for remaining speaking items")
    @MainActor
    func mixedPermissionDenialUsesTypingForRemainingSpeakingItems() async {
        let words = [
            VaultWordItem(id: 1, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", exampleSentenceEn: "She gave an eloquent speech."),
            VaultWordItem(id: 2, lemma: "resilient", pos: "adj.", definitionVi: "Kiên cường", exampleSentenceEn: "He is resilient."),
            VaultWordItem(id: 3, lemma: "habit", pos: "n.", definitionVi: "Thói quen", exampleSentenceEn: "Habit is powerful.")
        ]
        final class MockCustomQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol {
            let items: [MixedReflexDrillItem]
            init(items: [MixedReflexDrillItem]) { self.items = items }
            func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] { items }
            func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem { item }
        }
        let items = [
            MixedReflexDrillItem(word: words[0], assignedMode: .speaking, isRetry: false),
            MixedReflexDrillItem(word: words[1], assignedMode: .multipleChoice, isRetry: false),
            MixedReflexDrillItem(word: words[2], assignedMode: .speaking, isRetry: false)
        ]
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: MockCustomQueueUseCase(items: items))
        let mockSpeechEngine = MockResilientReflexSpeechEngine()
        mockSpeechEngine.simulatedStartListeningError = SpeechCaptureError.microphoneDenied

        let drillView = MixedReflexDrillView(
            viewModel: vm,
            speechEngine: mockSpeechEngine,
            startWithCountdown: false,
            onFinish: {}
        )
        drillView.setupSpeechEngineCallbacks()
        drillView.startDrillItem(items[0])
        await Task.yield()

        try? await Task.sleep(for: .milliseconds(40))

        #expect(vm.queue[0].assignedMode == .typing)
        #expect(vm.queue[1].assignedMode == .multipleChoice)
        #expect(vm.queue[2].assignedMode == .typing)
        #expect(drillView.speechState == .unavailable)
        #expect(drillView.isPermissionDenied == true)
        #expect(drillView.showPermissionAlert == true)
        #expect(drillView.elapsedTimeMs == 0)

        // Dismiss the alert and verify timer begins
        drillView.dismissPermissionAlert()
        #expect(drillView.showPermissionAlert == false)
        for _ in 0..<10 {
            if drillView.elapsedTimeMs > 0 { break }
            try? await Task.sleep(for: .milliseconds(30))
        }
        #expect(drillView.elapsedTimeMs > 0)
    }

    @Test("Mixed cancellation before permission denial ignores error")
    @MainActor
    func mixedCancellationBeforePermissionDenialIgnoresError() async {
        let words = [
            VaultWordItem(id: 1, lemma: "eloquent", pos: "adj.", definitionVi: "Hùng biện", exampleSentenceEn: "She gave an eloquent speech."),
            VaultWordItem(id: 2, lemma: "resilient", pos: "adj.", definitionVi: "Kiên cường", exampleSentenceEn: "He is resilient.")
        ]
        final class MockCustomQueueUseCase: GenerateMixedReflexQueueUseCaseProtocol {
            let items: [MixedReflexDrillItem]
            init(items: [MixedReflexDrillItem]) { self.items = items }
            func generate(from words: [VaultWordItem]) -> [MixedReflexDrillItem] { items }
            func requeueFailedItem(_ item: MixedReflexDrillItem) -> MixedReflexDrillItem { item }
        }
        let items = [
            MixedReflexDrillItem(word: words[0], assignedMode: .speaking, isRetry: false),
            MixedReflexDrillItem(word: words[1], assignedMode: .multipleChoice, isRetry: false)
        ]
        let vm = MixedReflexDrillViewModel(selectedWords: words, queueUseCase: MockCustomQueueUseCase(items: items))
        let mockSpeechEngine = MockResilientReflexSpeechEngine()
        mockSpeechEngine.shouldSuspendStartListening = true

        let drillView = MixedReflexDrillView(
            viewModel: vm,
            speechEngine: mockSpeechEngine,
            startWithCountdown: false,
            onFinish: {}
        )
        drillView.setupSpeechEngineCallbacks()
        drillView.startDrillItem(items[0])
        await Task.yield()

        // Advance to next item before startListening resumes
        vm.advanceToNextItem()
        drillView.startDrillItem(items[1])

        // Resume item 0 start listening with permission error
        mockSpeechEngine.startListeningContinuation?.resume(throwing: SpeechCaptureError.microphoneDenied)
        try? await Task.sleep(for: .milliseconds(30))

        #expect(drillView.isPermissionDenied == false)
        #expect(drillView.showPermissionAlert == false)
    }

    @Test("Mixed countdown ticks do not acquire capture and capture begins only on completion")
    @MainActor
    func testMixedCountdownTicksDoNotAcquireCaptureAndBeginsOnCompletion() async {
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
        let mockSpeechEngine = MockResilientReflexSpeechEngine()

        let drillView = MixedReflexDrillView(
            viewModel: vm,
            speechEngine: mockSpeechEngine,
            startWithCountdown: true,
            onFinish: {}
        )
        drillView.setupSpeechEngineCallbacks()

        #expect(drillView.startWithCountdown == true)
        #expect(mockSpeechEngine.startListeningCallCount == 0)
        #expect(mockSpeechEngine.isWordActive == false)

        let haptics = CountdownHapticSpy()
        let clock = ImmediateCountdownClock()
        let sequence = CountdownSequence(
            startNumber: 3,
            clock: clock,
            haptics: haptics,
            onFinish: {
                drillView.startDrillItem(item)
            }
        )

        sequence.onTick = { _ in
            #expect(mockSpeechEngine.startListeningCallCount == 0)
            #expect(mockSpeechEngine.isWordActive == false)
        }

        await sequence.run()
        await Task.yield()

        #expect(haptics.events == [.prepare, .tick, .tick, .tick, .completion])
        #expect(mockSpeechEngine.startListeningCallCount == 1)
        #expect(mockSpeechEngine.isWordActive == true)
    }
}
#endif
