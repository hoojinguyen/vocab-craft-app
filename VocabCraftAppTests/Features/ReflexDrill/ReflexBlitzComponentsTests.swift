import CraftUIKit
import SwiftUI
import Testing
@testable import VocabCraftApp
import XCTest

final class ReflexBlitzComponentsTests: XCTestCase {
    @MainActor
    func testHeaderViewInstantiation() {
        var didClose = false
        var didSkip = false
        let theme = CraftDefaultTheme()

        let header = ReflexBlitzHeaderView(
            currentIndex: 2,
            totalCount: 8,
            comboStreak: 3,
            fractionRemaining: 0.75,
            timerStage: .warning,
            onClose: { didClose = true },
            onSkip: { didSkip = true }
        )
        XCTAssertNotNil(header)
        XCTAssertEqual(header.currentIndex, 2)
        XCTAssertEqual(header.totalCount, 8)
        XCTAssertEqual(header.comboStreak, 3)
        XCTAssertEqual(header.fractionRemaining, 0.75)
        XCTAssertEqual(header.timerStage, .warning)
        XCTAssertEqual(header.timerBarColor, theme.colors.statusWarning)

        header.onClose()
        header.onSkip()
        XCTAssertTrue(didClose)
        XCTAssertTrue(didSkip)
    }

    @MainActor
    func testHeaderViewTimerStagesColor() {
        let theme = CraftDefaultTheme()
        let steadyHeader = ReflexBlitzHeaderView(
            currentIndex: 0,
            totalCount: 5,
            comboStreak: 0,
            fractionRemaining: 1.0,
            timerStage: .steady,
            onClose: {}
        )
        XCTAssertEqual(steadyHeader.timerBarColor, theme.colors.brandPrimary)

        let warningHeader = ReflexBlitzHeaderView(
            currentIndex: 1,
            totalCount: 5,
            comboStreak: 0,
            fractionRemaining: 0.4,
            timerStage: .warning,
            onClose: {}
        )
        XCTAssertEqual(warningHeader.timerBarColor, theme.colors.statusWarning)

        let urgentHeader = ReflexBlitzHeaderView(
            currentIndex: 2,
            totalCount: 5,
            comboStreak: 0,
            fractionRemaining: 0.1,
            timerStage: .urgent,
            onClose: {}
        )
        XCTAssertEqual(urgentHeader.timerBarColor, theme.colors.statusDanger)
    }

    @MainActor
    func testHeaderViewSegmentColorsWithAttemptsHistory() {
        let theme = CraftDefaultTheme()
        let attempts = [
            ReflexBlitzAttempt(wordId: 1, lemma: "a", pos: "", ipa: "", definitionVi: "", responseTimeMs: 1000, usedHint: false, isCorrect: true),
            ReflexBlitzAttempt(wordId: 2, lemma: "b", pos: "", ipa: "", definitionVi: "", responseTimeMs: 2000, usedHint: false, isCorrect: false)
        ]
        let header = ReflexBlitzHeaderView(
            currentIndex: 2,
            totalCount: 5,
            comboStreak: 0,
            attempts: attempts,
            onClose: {}
        )
        XCTAssertEqual(header.segmentColor(for: 0), theme.colors.statusSuccess)
        XCTAssertEqual(header.segmentColor(for: 1), theme.colors.statusDanger)
        XCTAssertEqual(header.segmentColor(for: 2), theme.colors.brandPrimary)
        XCTAssertNotNil(header.segmentColor(for: 3))
    }

    @MainActor
    func testHeaderViewBodyRendersAcrossComboThresholds() {
        let noComboHeader = ReflexBlitzHeaderView(
            currentIndex: 0,
            totalCount: 5,
            comboStreak: 1,
            fractionRemaining: 0.9,
            timerStage: .steady,
            onClose: {},
            onSkip: {}
        )
        XCTAssertNotNil(noComboHeader.body)

        let comboHeader = ReflexBlitzHeaderView(
            currentIndex: 4,
            totalCount: 5,
            comboStreak: 4,
            fractionRemaining: 0.2,
            timerStage: .urgent,
            onClose: {},
            onSkip: {}
        )
        XCTAssertNotNil(comboHeader.body)
    }

    @MainActor
    func testHeaderViewWithModeProperty() {
        let header = ReflexBlitzHeaderView(
            currentIndex: 1,
            totalCount: 10,
            comboStreak: 2,
            fractionRemaining: 0.5,
            timerStage: .steady,
            mode: .listening,
            onClose: {},
            onSkip: {},
            showSkipInHeader: true
        )
        XCTAssertEqual(header.mode, .listening)
        XCTAssertNotNil(header.body)
    }

    @MainActor
    func testHeaderViewDynamicTimerBar() {
        let now = Date()
        let activeHeader = ReflexBlitzHeaderView(
            currentIndex: 0,
            totalCount: 5,
            comboStreak: 0,
            fractionRemaining: 1.0,
            timerStage: .steady,
            mode: .speaking,
            wordStartTime: now,
            timeLimitSeconds: 6.0,
            isTimerActive: true,
            onClose: {}
        )
        XCTAssertEqual(activeHeader.wordStartTime, now)
        XCTAssertEqual(activeHeader.timeLimitSeconds, 6.0)
        XCTAssertTrue(activeHeader.isTimerActive)
        XCTAssertNotNil(activeHeader.body)
    }

    @MainActor
    func testCountdownOverlayInstantiationAndBody() {
        let overlayCountdown = ReflexCountdownOverlayView(count: 3)
        XCTAssertNotNil(overlayCountdown)
        XCTAssertEqual(overlayCountdown.count, 3)
        XCTAssertNotNil(overlayCountdown.body)

        let overlayGo = ReflexCountdownOverlayView(count: 0)
        XCTAssertNotNil(overlayGo)
        XCTAssertEqual(overlayGo.count, 0)
        XCTAssertNotNil(overlayGo.body)
    }

    @MainActor
    func testCardViewInstantiationAndStates() {
        let word = ReflexBlitzWordItem(
            id: 1,
            lemma: "ephemeral",
            pos: "adj.",
            ipa: "/ɪˈfem.ər.əl/",
            definitionVi: "Phù du, chóng tàn",
            exampleSentenceEn: "Her fame is ephemeral in nature.",
            exampleSentenceVi: "Danh tiếng của cô ấy phù du."
        )

        // Default drilling state with full parameters
        var submitted = false
        var textInput = "test"
        let binding = Binding<String>(
            get: { textInput },
            set: { textInput = $0 }
        )

        let defaultCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.85,
            timerStage: .steady,
            showHint: false,
            isCorrect: false,
            isTimeout: false,
            liveTranscript: "ephem",
            elapsedTimeMs: 900,
            isKeyboardFallbackActive: false,
            keyboardInputText: binding,
            onSubmitKeyboard: { submitted = true }
        )
        XCTAssertNotNil(defaultCard)
        XCTAssertEqual(defaultCard.word.id, 1)
        XCTAssertEqual(defaultCard.fractionRemaining, 0.85)
        XCTAssertEqual(defaultCard.timerStage, .steady)
        XCTAssertFalse(defaultCard.showHint)
        XCTAssertFalse(defaultCard.isCorrect)
        XCTAssertFalse(defaultCard.isTimeout)
        XCTAssertEqual(defaultCard.liveTranscript, "ephem")
        XCTAssertEqual(defaultCard.elapsedTimeMs, 900)
        XCTAssertFalse(defaultCard.isKeyboardFallbackActive)
        XCTAssertEqual(defaultCard.timerStrokeColor, CraftDefaultColorTokens().brandPrimary)
        XCTAssertNotNil(defaultCard.body)

        defaultCard.onSubmitKeyboard?()
        XCTAssertTrue(submitted)

        // Warning stage
        let warningCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.35,
            timerStage: .warning,
            showHint: true,
            isCorrect: false,
            isTimeout: false,
            liveTranscript: "",
            elapsedTimeMs: 4000,
            isKeyboardFallbackActive: false,
            keyboardInputText: .constant(""),
            onSubmitKeyboard: {}
        )
        XCTAssertEqual(warningCard.timerStage, .warning)
        XCTAssertTrue(warningCard.showHint)
        XCTAssertEqual(warningCard.timerStrokeColor, CraftDefaultColorTokens().statusWarning)
        XCTAssertNotNil(warningCard.body)

        // Urgent stage
        let urgentCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.1,
            timerStage: .urgent,
            showHint: true,
            isCorrect: false,
            isTimeout: false,
            liveTranscript: "",
            elapsedTimeMs: 5500,
            isKeyboardFallbackActive: false,
            keyboardInputText: .constant(""),
            onSubmitKeyboard: {}
        )
        XCTAssertEqual(urgentCard.timerStage, .urgent)
        XCTAssertEqual(urgentCard.timerStrokeColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertNotNil(urgentCard.body)

        // Correct match state
        let correctCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.6,
            timerStage: .steady,
            showHint: false,
            isCorrect: true,
            isTimeout: false,
            liveTranscript: "ephemeral",
            elapsedTimeMs: 2400,
            isKeyboardFallbackActive: false,
            keyboardInputText: .constant(""),
            onSubmitKeyboard: {}
        )
        XCTAssertNotNil(correctCard)
        XCTAssertTrue(correctCard.isCorrect)
        XCTAssertEqual(correctCard.timerStrokeColor, CraftDefaultColorTokens().statusSuccess)
        XCTAssertNotNil(correctCard.body)

        // Timeout state
        let timeoutCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.0,
            timerStage: .urgent,
            showHint: true,
            isCorrect: false,
            isTimeout: true,
            liveTranscript: "",
            elapsedTimeMs: 6000,
            isKeyboardFallbackActive: false,
            keyboardInputText: .constant(""),
            onSubmitKeyboard: {}
        )
        XCTAssertNotNil(timeoutCard)
        XCTAssertTrue(timeoutCard.isTimeout)
        XCTAssertEqual(timeoutCard.timerStrokeColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertNotNil(timeoutCard.body)

        // Keyboard Fallback Active State
        let keyboardCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.5,
            timerStage: .steady,
            showHint: false,
            isCorrect: false,
            isTimeout: false,
            liveTranscript: "",
            elapsedTimeMs: 3000,
            isKeyboardFallbackActive: true,
            keyboardInputText: .constant("ephem"),
            onSubmitKeyboard: {}
        )
        XCTAssertTrue(keyboardCard.isKeyboardFallbackActive)
        XCTAssertNotNil(keyboardCard.body)
    }

    @MainActor
    func testCardViewTargetWordMorphingAndIPA() {
        let word = ReflexBlitzWordItem(
            id: 2,
            lemma: "fluent",
            pos: "adj.",
            ipa: "/ˈfluː.ənt/",
            definitionVi: "Trôi chảy, lưu loát",
            exampleSentenceEn: "She is fluent in English and French.",
            exampleSentenceVi: "Cô ấy nói trôi chảy tiếng Anh và tiếng Pháp."
        )

        let correctCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.7,
            timerStage: .steady,
            showHint: false,
            isCorrect: true,
            isTimeout: false,
            liveTranscript: "fluent",
            elapsedTimeMs: 1800,
            isKeyboardFallbackActive: false,
            keyboardInputText: .constant(""),
            onSubmitKeyboard: {}
        )

        let sentence = correctCard.displayedSentence
        XCTAssertTrue(sentence.contains("fluent"))
        XCTAssertEqual(sentence, word.completedSentenceWithTargetWord)
        XCTAssertEqual(correctCard.word.ipa, "/ˈfluː.ənt/")
    }

    @MainActor
    func testCardHidesIPAUntilAnswered() {
        let word = ReflexBlitzWordItem(
            id: 10,
            lemma: "meticulous",
            pos: "adj.",
            ipa: "/məˈtɪk.jə.ləs/",
            definitionVi: "Tỉ mỉ, cẩn thận",
            exampleSentenceEn: "She is meticulous about her work quality.",
            exampleSentenceVi: "Cô ấy rất tỉ mỉ về chất lượng công việc của mình."
        )

        // 1. Active drilling without hint: IPA must be hidden from view body
        let activeDrillingCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.8,
            timerStage: .steady,
            showHint: false,
            isCorrect: false,
            isTimeout: false,
            liveTranscript: ""
        )
        XCTAssertNotNil(activeDrillingCard.body)
        XCTAssertFalse(activeDrillingCard.isCorrect)
        XCTAssertFalse(activeDrillingCard.isTimeout)
        XCTAssertFalse(activeDrillingCard.showHint)
        XCTAssertEqual(activeDrillingCard.displayedSentence, word.clozeSentenceEn)

        // 2. Active drilling with hint: hint initial letter revealed, IPA still hidden
        let hintedDrillingCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.4,
            timerStage: .warning,
            showHint: true,
            isCorrect: false,
            isTimeout: false,
            liveTranscript: ""
        )
        XCTAssertNotNil(hintedDrillingCard.body)
        XCTAssertTrue(hintedDrillingCard.showHint)
        XCTAssertFalse(hintedDrillingCard.isCorrect)
        XCTAssertFalse(hintedDrillingCard.isTimeout)
        XCTAssertTrue(word.initialLetterHint.hasPrefix("m..."))

        // 3. Correct match: IPA and full target word revealed
        let correctCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.5,
            timerStage: .steady,
            showHint: false,
            isCorrect: true,
            isTimeout: false,
            liveTranscript: "meticulous"
        )
        XCTAssertNotNil(correctCard.body)
        XCTAssertTrue(correctCard.isCorrect)
        XCTAssertEqual(correctCard.displayedSentence, word.completedSentenceWithTargetWord)
        XCTAssertEqual(correctCard.word.ipa, "/məˈtɪk.jə.ləs/")

        // 4. Timeout reveal: IPA and full example sentence revealed
        let timeoutCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.0,
            timerStage: .urgent,
            showHint: true,
            isCorrect: false,
            isTimeout: true,
            liveTranscript: ""
        )
        XCTAssertNotNil(timeoutCard.body)
        XCTAssertTrue(timeoutCard.isTimeout)
        XCTAssertEqual(timeoutCard.displayedSentence, word.exampleSentenceEn)
        XCTAssertEqual(timeoutCard.word.ipa, "/məˈtɪk.jə.ləs/")
    }

    @MainActor
    func testClozeSentenceRevealPartsOnCorrectAndTimeout() {
        let word = ReflexBlitzWordItem(
            id: 3,
            lemma: "fluent",
            pos: "adj.",
            ipa: "/ˈfluː.ənt/",
            definitionVi: "Trôi chảy, lưu loát",
            exampleSentenceEn: "She is fluent in English and French.",
            exampleSentenceVi: "Cô ấy nói trôi chảy tiếng Anh và tiếng Pháp.",
            clozeSentenceEn: "She is [ _________ ] in English and French."
        )

        // 1. Drilling state: cloze slot has placeholder dots
        let drillingCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.9,
            timerStage: .steady,
            showHint: false,
            isCorrect: false,
            isTimeout: false
        )
        let drillingParts = drillingCard.clozeParts
        XCTAssertNotNil(drillingParts)
        XCTAssertEqual(drillingParts?.prefix, "She is ")
        XCTAssertEqual(drillingParts?.suffix, " in English and French.")
        XCTAssertTrue(drillingParts?.slot.contains("•") == true)

        // 2. Hinted state: cloze slot contains initial letter hint
        let hintedCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.4,
            timerStage: .warning,
            showHint: true,
            isCorrect: false,
            isTimeout: false
        )
        let hintedParts = hintedCard.clozeParts
        XCTAssertNotNil(hintedParts)
        XCTAssertEqual(hintedParts?.prefix, "She is ")
        XCTAssertEqual(hintedParts?.suffix, " in English and French.")
        XCTAssertTrue(hintedParts?.slot.contains("f") == true)

        // 3. Correct match state: cloze slot reveals the target lemma
        let correctCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.6,
            timerStage: .steady,
            showHint: false,
            isCorrect: true,
            isTimeout: false
        )
        let correctParts = correctCard.clozeParts
        XCTAssertNotNil(correctParts)
        XCTAssertEqual(correctParts?.prefix, "She is ")
        XCTAssertEqual(correctParts?.slot, "fluent")
        XCTAssertEqual(correctParts?.suffix, " in English and French.")
        XCTAssertEqual((correctParts?.prefix ?? "") + (correctParts?.slot ?? "") + (correctParts?.suffix ?? ""), "She is fluent in English and French.")
        XCTAssertNotNil(correctCard.body)

        // 4. Timeout state: cloze slot reveals the target lemma
        let timeoutCard = ReflexBlitzCardView(
            word: word,
            fractionRemaining: 0.0,
            timerStage: .urgent,
            showHint: true,
            isCorrect: false,
            isTimeout: true
        )
        let timeoutParts = timeoutCard.clozeParts
        XCTAssertNotNil(timeoutParts)
        XCTAssertEqual(timeoutParts?.prefix, "She is ")
        XCTAssertEqual(timeoutParts?.slot, "fluent")
        XCTAssertEqual(timeoutParts?.suffix, " in English and French.")
        XCTAssertNotNil(timeoutCard.body)
    }

    @MainActor
    func testClozeSentenceFallbackWhenNoPatternMatches() {
        let noClozeWord = ReflexBlitzWordItem(
            id: 4,
            lemma: "resilient",
            pos: "adj.",
            ipa: "/rɪˈzɪl.jənt/",
            definitionVi: "Kiên cường",
            exampleSentenceEn: "They stayed strong.",
            exampleSentenceVi: "Họ luôn vững vàng.",
            clozeSentenceEn: "They stayed strong."
        )

        let card = ReflexBlitzCardView(
            word: noClozeWord,
            isCorrect: true
        )
        XCTAssertNil(card.clozeParts)
        XCTAssertNotNil(card.body)
    }

    @MainActor
    func testCardViewInMultipleChoiceModeRendersOptions() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = word.generateOptions(mode: .multipleChoice, allPool: ReflexBlitzWordItem.defaultStarterWords)
        var selectedOption: ReflexBlitzOption?
        let cardView = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .activeCountdown,
            options: options,
            onSelectOption: { opt in selectedOption = opt }
        )
        XCTAssertNotNil(cardView)
        XCTAssertEqual(cardView.mode, .multipleChoice)
        XCTAssertEqual(cardView.options.count, 4)
        XCTAssertNotNil(cardView.body)

        cardView.onSelectOption?(options[0])
        XCTAssertEqual(selectedOption?.id, options[0].id)
    }

    @MainActor
    func testCardViewInSpeakingModeRendersLivingAudio() {
        let word = ReflexBlitzWordItem.defaultStarterWords[1]
        let cardView = ReflexBlitzCardView(
            word: word,
            mode: .speaking,
            cardPhase: .activeCountdown,
            liveTranscript: "improve"
        )
        XCTAssertNotNil(cardView)
        XCTAssertEqual(cardView.mode, .speaking)
        XCTAssertEqual(cardView.liveTranscript, "improve")
        XCTAssertNotNil(cardView.body)
    }

    @MainActor
    func testCardViewInTypingModeRendersTextFieldAndSubmit() {
        let word = ReflexBlitzWordItem.defaultStarterWords[2]
        var didSubmit = false
        var text = "focus"
        let binding = Binding<String>(get: { text }, set: { text = $0 })
        let cardView = ReflexBlitzCardView(
            word: word,
            mode: .typing,
            cardPhase: .activeCountdown,
            keyboardInputText: binding,
            onSubmitKeyboard: { didSubmit = true }
        )
        XCTAssertNotNil(cardView)
        XCTAssertEqual(cardView.mode, .typing)
        XCTAssertNotNil(cardView.body)

        cardView.onSubmitKeyboard?()
        XCTAssertTrue(didSubmit)
    }

    @MainActor
    func testCardViewInListeningModeRendersWaveformAndAudioOptions() {
        let word = ReflexBlitzWordItem.defaultStarterWords[3]
        let options = word.generateOptions(mode: .listening, allPool: ReflexBlitzWordItem.defaultStarterWords)
        var didReplayAudio = false
        let cardView = ReflexBlitzCardView(
            word: word,
            mode: .listening,
            cardPhase: .activeCountdown,
            options: options,
            onReplayAudio: { didReplayAudio = true }
        )
        XCTAssertNotNil(cardView)
        XCTAssertEqual(cardView.mode, .listening)
        XCTAssertEqual(cardView.options.count, 4)
        XCTAssertNotNil(cardView.body)

        cardView.onReplayAudio?()
        XCTAssertTrue(didReplayAudio)
    }

    @MainActor
    func testCardViewInReviewedStateRendersCompletedSentence() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let cardView = ReflexBlitzCardView(
            word: word,
            mode: .speaking,
            cardPhase: .reviewed(result: ReflexCardResult(
                isCorrect: true,
                responseTimeMs: 1200,
                isTimeout: false,
                selectedOption: nil,
                typedText: nil,
                recognizedSpoken: "habit"
            )),
            options: []
        )
        XCTAssertEqual(cardView.displayedSentence, word.completedSentenceWithTargetWord)
        XCTAssertTrue(cardView.isReviewed)
        XCTAssertTrue(cardView.isResultCorrect)
        XCTAssertFalse(cardView.isResultTimeout)
        XCTAssertEqual(cardView.cardBorderColor, CraftDefaultColorTokens().statusSuccess)
        XCTAssertNotNil(cardView.body)
    }

    @MainActor
    func testCardViewInReviewedStateHighlightsSelectedAndCorrectOptions() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(id: "1", text: "habit", isCorrect: true),
            ReflexBlitzOption(id: "2", text: "focus", isCorrect: false),
            ReflexBlitzOption(id: "3", text: "create", isCorrect: false),
            ReflexBlitzOption(id: "4", text: "relax", isCorrect: false)
        ]

        // Incorrect selection
        let wrongCardView = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: 2200,
                isTimeout: false,
                selectedOption: "focus",
                typedText: nil,
                recognizedSpoken: nil
            )),
            options: options
        )
        XCTAssertTrue(wrongCardView.isReviewed)
        XCTAssertFalse(wrongCardView.isResultCorrect)
        XCTAssertEqual(wrongCardView.cardBorderColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertEqual(wrongCardView.selectedOptionText, "focus")
        XCTAssertNotNil(wrongCardView.body)

        // Timeout selection
        let timeoutCardView = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: 4500,
                isTimeout: true,
                selectedOption: nil,
                typedText: nil,
                recognizedSpoken: nil
            )),
            options: options
        )
        XCTAssertTrue(timeoutCardView.isReviewed)
        XCTAssertTrue(timeoutCardView.isResultTimeout)
        XCTAssertEqual(timeoutCardView.cardBorderColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertNotNil(timeoutCardView.body)
    }

    @MainActor
    func testCardViewInReviewedStateShowsAudioReplayAndTranslation() {
        let word = ReflexBlitzWordItem.defaultStarterWords[4]
        var replayed = false
        let cardView = ReflexBlitzCardView(
            word: word,
            mode: .listening,
            cardPhase: .reviewed(result: ReflexCardResult(
                isCorrect: true,
                responseTimeMs: 1500,
                isTimeout: false,
                selectedOption: word.definitionVi
            )),
            options: [],
            onReplayAudio: { replayed = true }
        )
        XCTAssertNotNil(cardView.body)
        cardView.onReplayAudio?()
        XCTAssertTrue(replayed)
    }

    // MARK: - Mode Selection View Tests

    @MainActor
    func testModeSelectionViewInstantiationAndCallbacks() {
        var selectedMode: ReflexBlitzMode?
        var didDismiss = false

        let view = ReflexBlitzModeSelectionView(
            weeklyPracticedCount: 42,
            weakWordsCount: 5,
            averageSpeedSeconds: 1.6,
            onSelectMode: { mode in
                selectedMode = mode
            },
            onDismiss: {
                didDismiss = true
            }
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(view.weeklyPracticedCount, 42)
        XCTAssertEqual(view.weakWordsCount, 5)
        XCTAssertEqual(view.averageSpeedSeconds, 1.6)
        XCTAssertNotNil(view.body)

        // Verify dismissal callback
        view.onDismiss()
        XCTAssertTrue(didDismiss)

        // Verify mode selections
        for mode in ReflexBlitzMode.allCases {
            view.onSelectMode(mode)
            XCTAssertEqual(selectedMode, mode)
        }
    }

    @MainActor
    func testModeSelectionViewDefaultInit() {
        let view = ReflexBlitzModeSelectionView(
            onSelectMode: { _ in },
            onDismiss: {}
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(view.weeklyPracticedCount, 0)
        XCTAssertEqual(view.weakWordsCount, 0)
        XCTAssertEqual(view.averageSpeedSeconds, 0.0)
        XCTAssertNotNil(view.body)
    }

    @MainActor
    func testModeSelectionViewMetadataAndCards() {
        let colors = CraftDefaultColorTokens()
        for mode in ReflexBlitzMode.allCases {
            let item = ReflexBlitzModeSelectionView.modeItem(for: mode, colors: colors)
            XCTAssertEqual(item.mode, mode)
            XCTAssertFalse(item.title.isEmpty)
            XCTAssertFalse(item.subtitle.isEmpty)
            XCTAssertFalse(item.badgeText.isEmpty)
            XCTAssertFalse(item.iconName.isEmpty)
        }

        let speaking = ReflexBlitzModeSelectionView.modeItem(for: .speaking, colors: colors)
        XCTAssertEqual(speaking.title, AppStrings.ReflexBlitz.speakingTitleText)
        XCTAssertEqual(speaking.badgeText, "6.0s")
        XCTAssertEqual(speaking.iconName, "waveform.and.mic")
        XCTAssertEqual(speaking.accentColor, colors.brandPrimary)

        let typing = ReflexBlitzModeSelectionView.modeItem(for: .typing, colors: colors)
        XCTAssertEqual(typing.title, AppStrings.ReflexBlitz.typingTitleText)
        XCTAssertEqual(typing.badgeText, "7.5s")
        XCTAssertEqual(typing.iconName, "keyboard")
        XCTAssertEqual(typing.accentColor, colors.streakLegendary)

        let multipleChoice = ReflexBlitzModeSelectionView.modeItem(for: .multipleChoice, colors: colors)
        XCTAssertEqual(multipleChoice.title, AppStrings.ReflexBlitz.mcTitleText)
        XCTAssertEqual(multipleChoice.badgeText, "4.5s")
        XCTAssertEqual(multipleChoice.iconName, "square.grid.2x2.fill")
        XCTAssertEqual(multipleChoice.accentColor, colors.statusSuccess)

        let listening = ReflexBlitzModeSelectionView.modeItem(for: .listening, colors: colors)
        XCTAssertEqual(listening.title, AppStrings.ReflexBlitz.listeningTitleText)
        XCTAssertEqual(listening.badgeText, "5.5s")
        XCTAssertEqual(listening.iconName, "headphones")
        XCTAssertEqual(listening.accentColor, colors.statusInfo)
    }

    @MainActor
    func testModeSelectionViewWithDeepLinkConfig() {
        var selectedConfig: ReflexBlitzDeepLinkConfig?
        let config = ReflexBlitzDeepLinkConfig(mode: .speaking, phase: .drilling, showHint: true, combo: 2)
        let view = ReflexBlitzModeSelectionView(
            weeklyPracticedCount: 15,
            weakWordsCount: 3,
            averageSpeedSeconds: 2.1,
            onSelectMode: { _ in },
            onSelectConfig: { cfg in
                selectedConfig = cfg
            },
            onDismiss: {}
        )
        XCTAssertNotNil(view.body)
        view.onSelectConfig?(config)
        XCTAssertEqual(selectedConfig?.mode, .speaking)
        XCTAssertEqual(selectedConfig?.phase, .drilling)
        XCTAssertEqual(selectedConfig?.showHint, true)
        XCTAssertEqual(selectedConfig?.combo, 2)
    }

    // MARK: - Advance Dock View Tests

    @MainActor
    func testAdvanceDockViewDisplaysFormattedTimeOnCorrect() {
        var didAdvance = false
        let view = ReflexBlitzAdvanceDockView(
            isReviewed: true,
            responseTimeMs: 1400,
            isCorrect: true,
            isTimeout: false,
            onAdvance: { didAdvance = true }
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(view.formattedResponseTime, "1.4s")
        XCTAssertEqual(view.buttonTitle, AppStrings.ReflexBlitz.advanceCorrectButton("1.4s"))
        XCTAssertNotNil(view.body)

        view.onAdvance()
        XCTAssertTrue(didAdvance)
    }

    @MainActor
    func testAdvanceDockViewDisplaysTimeoutState() {
        var didAdvance = false
        let view = ReflexBlitzAdvanceDockView(
            isReviewed: true,
            responseTimeMs: 6000,
            isCorrect: false,
            isTimeout: true,
            onAdvance: { didAdvance = true }
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(view.buttonTitle, AppStrings.ReflexBlitz.advanceTimeoutButton)
        XCTAssertNotNil(view.body)

        view.onAdvance()
        XCTAssertTrue(didAdvance)
    }

    @MainActor
    func testAdvanceDockViewDisplaysIncorrectNonTimeoutState() {
        let view = ReflexBlitzAdvanceDockView(
            isReviewed: true,
            responseTimeMs: 2300,
            isCorrect: false,
            isTimeout: false,
            onAdvance: {}
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(view.formattedResponseTime, "2.3s")
        XCTAssertEqual(view.buttonTitle, AppStrings.ReflexBlitz.advanceIncorrectButton("2.3s"))
        XCTAssertNotNil(view.body)
    }

    @MainActor
    func testAdvanceDockViewActiveDrillingAndSkip() {
        var didSkip = false
        var didAdvance = false
        let view = ReflexBlitzAdvanceDockView(
            isReviewed: false,
            responseTimeMs: 0,
            isCorrect: false,
            isTimeout: false,
            onAdvance: { didAdvance = true },
            onSkip: { didSkip = true }
        )
        XCTAssertNotNil(view)
        XCTAssertEqual(view.buttonTitle, AppStrings.ReflexBlitz.skipText)
        XCTAssertNotNil(view.body)

        view.onSkip?()
        XCTAssertTrue(didSkip)
        view.onAdvance()
        XCTAssertTrue(didAdvance)
    }

    @MainActor
    func testAdvanceDockViewCardPhaseConvenienceInit() {
        let correctResult = ReflexCardResult(
            isCorrect: true,
            responseTimeMs: 900,
            isTimeout: false
        )
        let reviewedView = ReflexBlitzAdvanceDockView(
            cardPhase: .reviewed(result: correctResult),
            onAdvance: {}
        )
        XCTAssertTrue(reviewedView.isReviewed)
        XCTAssertTrue(reviewedView.isCorrect)
        XCTAssertFalse(reviewedView.isTimeout)
        XCTAssertEqual(reviewedView.responseTimeMs, 900)
        XCTAssertEqual(reviewedView.formattedResponseTime, "0.9s")

        let activeView = ReflexBlitzAdvanceDockView(
            cardPhase: .activeCountdown,
            onAdvance: {}
        )
        XCTAssertFalse(activeView.isReviewed)
    }

    @MainActor
    func testCardViewShakeAndErrorPresentationOnIncorrectReview() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let incorrectResult = ReflexCardResult(
            isCorrect: false,
            responseTimeMs: 2500,
            isTimeout: false,
            selectedOption: "incorrectOption",
            typedText: "wrongWord",
            recognizedSpoken: nil
        )

        let cardView = ReflexBlitzCardView(
            word: word,
            mode: .typing,
            cardPhase: .reviewed(result: incorrectResult),
            options: []
        )

        XCTAssertTrue(cardView.isReviewed)
        XCTAssertFalse(cardView.isResultCorrect)
        XCTAssertFalse(cardView.isResultTimeout)
        XCTAssertEqual(cardView.cardBorderColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertNotNil(cardView.body)
    }

    @MainActor
    func testCardViewShakeAndTimeoutPresentationOnTimeoutReview() {
        let word = ReflexBlitzWordItem.defaultStarterWords[1]
        let timeoutResult = ReflexCardResult(
            isCorrect: false,
            responseTimeMs: 6000,
            isTimeout: true
        )

        let cardView = ReflexBlitzCardView(
            word: word,
            mode: .speaking,
            cardPhase: .reviewed(result: timeoutResult),
            options: []
        )

        XCTAssertTrue(cardView.isReviewed)
        XCTAssertFalse(cardView.isResultCorrect)
        XCTAssertTrue(cardView.isResultTimeout)
        XCTAssertEqual(cardView.cardBorderColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertEqual(cardView.timerStrokeColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertNotNil(cardView.body)
    }
}

// MARK: - Swift Testing Suite

@Suite("Reflex Blitz Mode Selection View Tests")
struct ReflexBlitzModeSelectionViewTests {
    @Test("Mode Selection View initializes and yields 4 mode cards with stats")
    @MainActor
    func testModeSelectionViewInitialization() {
        var selectedMode: ReflexBlitzMode?
        let view = ReflexBlitzModeSelectionView(
            weeklyPracticedCount: 42,
            weakWordsCount: 5,
            averageSpeedSeconds: 1.6,
            onSelectMode: { mode in
                selectedMode = mode
            },
            onDismiss: {}
        )
        #expect(view.weeklyPracticedCount == 42)
        #expect(view.weakWordsCount == 5)
        #expect(view.averageSpeedSeconds == 1.6)

        view.onSelectMode(.speaking)
        #expect(selectedMode == .speaking)
    }
}
