import SwiftUI
import Testing
@testable import VocabCraftApp

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

    @Test("MixedReflexSummaryView hiển thị đầy đủ thông tin tổng kết và danh sách từ")
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
            onRetry: { retryCalled = true },
            onDone: { doneCalled = true }
        )

        #expect(summaryView.summary.totalWords == 2)
        #expect(summaryView.summary.correctWords == 2)
        #expect(summaryView.practicedWords.count == 2)

        summaryView.onRetry()
        #expect(retryCalled == true)

        summaryView.onDone()
        #expect(doneCalled == true)
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
        #expect(vm.currentIndex == 1)

        await vm.submitAnswer(isCorrect: true, responseTimeMs: 1400)
        #expect(vm.isCompleted == true)
        #expect(vm.sessionSummary != nil)

        drillView.onFinish()
        #expect(finished == true)
    }

    @Test("MixedDrillReviewedSection renders correctly across states")
    @MainActor
    func testMixedDrillReviewedSection() {
        let word = VaultWordItem(
            id: 1,
            lemma: "habit",
            pos: "noun",
            phonetic: "/ˈhæb.ɪt/",
            definitionVi: "Thói quen",
            exampleSentenceEn: "Reading books daily is a great habit.",
            exampleSentenceVi: "Đọc sách hàng ngày là thói quen tốt."
        )
        let item = MixedReflexDrillItem(word: word, assignedMode: .multipleChoice)
        let options = [
            ReflexBlitzOption(id: "1", text: "Thói quen", isCorrect: true),
            ReflexBlitzOption(id: "2", text: "Tập trung", isCorrect: false)
        ]

        var audioPlayed = false
        let correctResult = ReflexCardResult(
            isCorrect: true,
            responseTimeMs: 1200,
            isTimeout: false,
            selectedOption: "Thói quen"
        )

        let correctSection = MixedDrillReviewedSection(
            item: item,
            result: correctResult,
            options: options,
            onPlayAudio: { audioPlayed = true }
        )

        #expect(correctSection.item.word.lemma == "habit")
        #expect(correctSection.options.count == 2)
        _ = correctSection.body

        correctSection.onPlayAudio()
        #expect(audioPlayed == true)

        let timeoutResult = ReflexCardResult(
            isCorrect: false,
            responseTimeMs: 4500,
            isTimeout: true
        )
        let timeoutSection = MixedDrillReviewedSection(
            item: item,
            result: timeoutResult,
            options: options,
            onPlayAudio: {}
        )
        _ = timeoutSection.body
    }

    @Test("MixedDrillClozeSentence displays active and reviewed states correctly")
    @MainActor
    func testMixedDrillClozeSentence() {
        let word = VaultWordItem(
            id: 1,
            lemma: "habit",
            pos: "noun",
            phonetic: "/ˈhæb.ɪt/",
            definitionVi: "Thói quen",
            exampleSentenceEn: "Reading books daily is a great habit.",
            exampleSentenceVi: "Đọc sách hàng ngày là thói quen tốt."
        )

        let activeCloze = MixedDrillClozeSentence(word: word, isReviewed: false)
        #expect(activeCloze.isReviewed == false)
        _ = activeCloze.body

        let reviewedCloze = MixedDrillClozeSentence(word: word, isReviewed: true, isResultCorrect: true)
        #expect(reviewedCloze.isReviewed == true)
        #expect(reviewedCloze.isResultCorrect == true)
        _ = reviewedCloze.body
    }

    @Test("MixedDrill interactive sections initialize and trigger callbacks")
    @MainActor
    func testMixedDrillInteractiveSections() {
        let word = VaultWordItem(
            id: 1,
            lemma: "fluent",
            pos: "adj",
            definitionVi: "Lưu loát",
            exampleSentenceEn: "She is fluent in English."
        )

        // Multiple Choice
        var selectedOption: ReflexBlitzOption?
        let option = ReflexBlitzOption(id: "1", text: "Lưu loát", isCorrect: true)
        let mcSection = MixedDrillMultipleChoiceSection(
            word: word,
            options: [option],
            onSelectOption: { opt in selectedOption = opt }
        )
        _ = mcSection.body
        mcSection.onSelectOption(option)
        #expect(selectedOption?.id == "1")

        // Speaking
        var switchedToKeyboard = false
        let speakingSection = MixedDrillSpeakingSection(
            word: word,
            liveTranscript: "fluent",
            elapsedTimeMs: 1200,
            onSwitchToKeyboard: { switchedToKeyboard = true }
        )
        _ = speakingSection.body
        speakingSection.onSwitchToKeyboard()
        #expect(switchedToKeyboard == true)

        // Typing
        var submittedTyping = false
        var text = "fluent"
        let binding = Binding<String>(get: { text }, set: { text = $0 })
        let typingSection = MixedDrillTypingSection(
            word: word,
            typingText: binding,
            onSubmit: { submittedTyping = true }
        )
        _ = typingSection.body
        typingSection.onSubmit()
        #expect(submittedTyping == true)

        // Listening
        var audioReplayed = false
        let listeningSection = MixedDrillListeningSection(
            options: [option],
            elapsedTimeMs: 800,
            onPlayAudio: { audioReplayed = true },
            onSelectOption: { _ in }
        )
        _ = listeningSection.body
        listeningSection.onPlayAudio()
        #expect(audioReplayed == true)
    }
}
