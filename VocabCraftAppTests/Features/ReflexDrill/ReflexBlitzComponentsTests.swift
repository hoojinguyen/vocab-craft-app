import CraftUIKit
import SwiftUI
import Testing
#if canImport(UIKit)
import UIKit
#endif
@testable import VocabCraftApp
import XCTest

#if canImport(AppKit)
import AppKit
#endif

final class ReflexBlitzComponentsTests: XCTestCase {
    private func assertColorsEqual(_ color1: Color, _ color2: Color, file: StaticString = #filePath, line: UInt = #line) {
        #if canImport(UIKit)
        let ui1 = UIColor(color1), ui2 = UIColor(color2)
        let lightTrait = UITraitCollection(userInterfaceStyle: .light)
        let darkTrait = UITraitCollection(userInterfaceStyle: .dark)
        XCTAssertEqual(ui1.resolvedColor(with: lightTrait), ui2.resolvedColor(with: lightTrait), "Light mode mismatch", file: file, line: line)
        XCTAssertEqual(ui1.resolvedColor(with: darkTrait), ui2.resolvedColor(with: darkTrait), "Dark mode mismatch", file: file, line: line)
        #elseif canImport(AppKit)
        var srgb1 = "", srgb2 = ""
        NSAppearance(named: .aqua)?.performAsCurrentDrawingAppearance {
            let ns1 = NSColor(color1).usingColorSpace(.sRGB) ?? NSColor(color1)
            let ns2 = NSColor(color2).usingColorSpace(.sRGB) ?? NSColor(color2)
            srgb1 = "\(ns1.redComponent),\(ns1.greenComponent),\(ns1.blueComponent),\(ns1.alphaComponent)"
            srgb2 = "\(ns2.redComponent),\(ns2.greenComponent),\(ns2.blueComponent),\(ns2.alphaComponent)"
        }
        XCTAssertEqual(srgb1, srgb2, "Light mode mismatch", file: file, line: line)
        #else
        XCTAssertEqual(color1, color2, file: file, line: line)
        #endif
    }
    @MainActor
    func testHeaderViewInstantiation() {
        var didClose = false, didSkip = false
        let theme = CraftDefaultTheme()
        let header = ReflexBlitzHeaderView(
            currentIndex: 2, totalCount: 8, comboStreak: 3, fractionRemaining: 0.75,
            timerStage: .warning, onClose: { didClose = true }, onSkip: { didSkip = true }
        )
        XCTAssertNotNil(header)
        XCTAssertEqual(header.currentIndex, 2)
        XCTAssertEqual(header.totalCount, 8)
        XCTAssertEqual(header.comboStreak, 3)
        XCTAssertEqual(header.fractionRemaining, 0.75)
        XCTAssertEqual(header.timerStage, .warning)
        assertColorsEqual(header.timerBarColor, theme.colors.statusWarning)
        header.onClose()
        header.onSkip()
        XCTAssertTrue(didClose)
        XCTAssertTrue(didSkip)
    }

    @MainActor
    func testHeaderViewTimerStagesColor() {
        let theme = CraftDefaultTheme()
        let steadyHeader = ReflexBlitzHeaderView(currentIndex: 0, totalCount: 5, comboStreak: 0, fractionRemaining: 1.0, timerStage: .steady, onClose: {})
        assertColorsEqual(steadyHeader.timerBarColor, theme.colors.brandPrimary)

        let warningHeader = ReflexBlitzHeaderView(currentIndex: 1, totalCount: 5, comboStreak: 0, fractionRemaining: 0.4, timerStage: .warning, onClose: {})
        assertColorsEqual(warningHeader.timerBarColor, theme.colors.statusWarning)

        let urgentHeader = ReflexBlitzHeaderView(currentIndex: 2, totalCount: 5, comboStreak: 0, fractionRemaining: 0.1, timerStage: .urgent, onClose: {})
        assertColorsEqual(urgentHeader.timerBarColor, theme.colors.statusDanger)
    }

    @MainActor
    func testHeaderViewSegmentColorsWithAttemptsHistory() {
        let theme = CraftDefaultTheme()
        let attempts = [
            ReflexBlitzAttempt(wordId: 1, lemma: "a", pos: "", ipa: "", definitionVi: "", responseTimeMs: 1000, usedHint: false, isCorrect: true),
            ReflexBlitzAttempt(wordId: 2, lemma: "b", pos: "", ipa: "", definitionVi: "", responseTimeMs: 2000, usedHint: false, isCorrect: false)
        ]
        let header = ReflexBlitzHeaderView(currentIndex: 2, totalCount: 5, comboStreak: 0, attempts: attempts, onClose: {})
        assertColorsEqual(header.segmentColor(for: 0), theme.colors.statusSuccess)
        assertColorsEqual(header.segmentColor(for: 1), theme.colors.statusDanger)
        assertColorsEqual(header.segmentColor(for: 2), theme.colors.brandPrimary)
        XCTAssertNotNil(header.segmentColor(for: 3))
    }

    @MainActor
    func testHeaderViewBodyRendersAcrossComboThresholds() {
        let noCombo = ReflexBlitzHeaderView(currentIndex: 0, totalCount: 5, comboStreak: 1, fractionRemaining: 0.9, timerStage: .steady, onClose: {}, onSkip: {})
        XCTAssertNotNil(noCombo.body)

        let combo = ReflexBlitzHeaderView(currentIndex: 4, totalCount: 5, comboStreak: 4, fractionRemaining: 0.2, timerStage: .urgent, onClose: {}, onSkip: {})
        XCTAssertNotNil(combo.body)
    }

    @MainActor
    func testHeaderViewWithModeProperty() {
        let header = ReflexBlitzHeaderView(
            currentIndex: 1, totalCount: 10, comboStreak: 2, fractionRemaining: 0.5,
            timerStage: .steady, mode: .listening, onClose: {}, onSkip: {}, showSkipInHeader: true
        )
        XCTAssertEqual(header.mode, .listening)
        XCTAssertNotNil(header.body)
    }

    @MainActor
    func testHeaderViewDynamicTimerBar() {
        let now = Date()
        let active = ReflexBlitzHeaderView(
            currentIndex: 0, totalCount: 5, comboStreak: 0, fractionRemaining: 1.0,
            timerStage: .steady, mode: .speaking, wordStartTime: now, timeLimitSeconds: 6.0, isTimerActive: true, onClose: {}
        )
        XCTAssertEqual(active.wordStartTime, now)
        XCTAssertEqual(active.timeLimitSeconds, 6.0)
        XCTAssertTrue(active.isTimerActive)
        XCTAssertNotNil(active.body)
    }

    @MainActor
    func testCountdownOverlayInstantiationAndBody() {
        let overlay3 = ReflexCountdownOverlayView(count: 3)
        XCTAssertNotNil(overlay3)
        XCTAssertEqual(overlay3.count, 3)
        XCTAssertNotNil(overlay3.body)

        let overlay0 = ReflexCountdownOverlayView(count: 0)
        XCTAssertNotNil(overlay0)
        XCTAssertEqual(overlay0.count, 0)
        XCTAssertNotNil(overlay0.body)
    }

    @MainActor
    func testCardViewInstantiationAndStates() {
        let word = ReflexBlitzWordItem(
            id: 1, lemma: "ephemeral", pos: "adj.", ipa: "/ɪˈfem.ər.əl/",
            definitionVi: "Phù du, chóng tàn", exampleSentenceEn: "Her fame is ephemeral in nature.",
            exampleSentenceVi: "Danh tiếng của cô ấy phù du."
        )

        var submitted = false
        var textInput = "test"
        let binding = Binding<String>(get: { textInput }, set: { textInput = $0 })

        let defaultCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.85, timerStage: .steady, showHint: false,
            isCorrect: false, isTimeout: false, liveTranscript: "ephem", elapsedTimeMs: 900,
            isKeyboardFallbackActive: false, keyboardInputText: binding, onSubmitKeyboard: { submitted = true }
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
        assertColorsEqual(defaultCard.timerStrokeColor, CraftDefaultColorTokens().brandPrimary)
        assertColorsEqual(defaultCard.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
        XCTAssertNotNil(defaultCard.body)

        defaultCard.onSubmitKeyboard?()
        XCTAssertTrue(submitted)

        let warningCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.35, timerStage: .warning, showHint: true,
            isCorrect: false, isTimeout: false, liveTranscript: "", elapsedTimeMs: 4000,
            isKeyboardFallbackActive: false, keyboardInputText: .constant(""), onSubmitKeyboard: {}
        )
        XCTAssertEqual(warningCard.timerStage, .warning)
        XCTAssertTrue(warningCard.showHint)
        assertColorsEqual(warningCard.timerStrokeColor, CraftDefaultColorTokens().statusWarning)
        XCTAssertNotNil(warningCard.body)

        let urgentCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.1, timerStage: .urgent, showHint: true,
            isCorrect: false, isTimeout: false, liveTranscript: "", elapsedTimeMs: 5500,
            isKeyboardFallbackActive: false, keyboardInputText: .constant(""), onSubmitKeyboard: {}
        )
        XCTAssertEqual(urgentCard.timerStage, .urgent)
        assertColorsEqual(urgentCard.timerStrokeColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertNotNil(urgentCard.body)

        let correctCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.6, timerStage: .steady, showHint: false,
            isCorrect: true, isTimeout: false, liveTranscript: "ephemeral", elapsedTimeMs: 2400,
            isKeyboardFallbackActive: false, keyboardInputText: .constant(""), onSubmitKeyboard: {}
        )
        XCTAssertNotNil(correctCard)
        XCTAssertTrue(correctCard.isCorrect)
        assertColorsEqual(correctCard.timerStrokeColor, CraftDefaultColorTokens().statusSuccess)
        assertColorsEqual(correctCard.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
        XCTAssertNotNil(correctCard.body)

        let timeoutCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.0, timerStage: .urgent, showHint: true,
            isCorrect: false, isTimeout: true, liveTranscript: "", elapsedTimeMs: 6000,
            isKeyboardFallbackActive: false, keyboardInputText: .constant(""), onSubmitKeyboard: {}
        )
        XCTAssertNotNil(timeoutCard)
        XCTAssertTrue(timeoutCard.isTimeout)
        assertColorsEqual(timeoutCard.timerStrokeColor, CraftDefaultColorTokens().statusDanger)
        assertColorsEqual(timeoutCard.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
        XCTAssertNotNil(timeoutCard.body)

        let keyboardCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.5, timerStage: .steady, showHint: false,
            isCorrect: false, isTimeout: false, liveTranscript: "", elapsedTimeMs: 3000,
            isKeyboardFallbackActive: true, keyboardInputText: .constant("ephem"), onSubmitKeyboard: {}
        )
        XCTAssertTrue(keyboardCard.isKeyboardFallbackActive)
        XCTAssertNotNil(keyboardCard.body)
    }

    @MainActor
    func testCardViewTargetWordMorphingAndIPA() {
        let word = ReflexBlitzWordItem(
            id: 2, lemma: "fluent", pos: "adj.", ipa: "/ˈfluː.ənt/",
            definitionVi: "Trôi chảy, lưu loát",
            exampleSentenceEn: "She is fluent in English and French.",
            exampleSentenceVi: "Cô ấy nói trôi chảy tiếng Anh và tiếng Pháp."
        )

        let correctCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.7, timerStage: .steady, showHint: false,
            isCorrect: true, isTimeout: false, liveTranscript: "fluent", elapsedTimeMs: 1800,
            isKeyboardFallbackActive: false, keyboardInputText: .constant(""), onSubmitKeyboard: {}
        )

        let sentence = correctCard.displayedSentence
        XCTAssertTrue(sentence.contains("fluent"))
        XCTAssertEqual(sentence, word.completedSentenceWithTargetWord)
        XCTAssertEqual(correctCard.word.ipa, "/ˈfluː.ənt/")
    }

    @MainActor
    func testCardHidesIPAUntilAnswered() {
        let word = ReflexBlitzWordItem(
            id: 10, lemma: "meticulous", pos: "adj.", ipa: "/məˈtɪk.jə.ləs/",
            definitionVi: "Tỉ mỉ, cẩn thận",
            exampleSentenceEn: "She is meticulous about her work quality.",
            exampleSentenceVi: "Cô ấy rất tỉ mỉ về chất lượng công việc của mình."
        )

        // 1. Active drilling without hint: IPA must be hidden from view body
        let activeDrillingCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.8, timerStage: .steady,
            showHint: false, isCorrect: false, isTimeout: false, liveTranscript: ""
        )
        XCTAssertNotNil(activeDrillingCard.body)
        XCTAssertFalse(activeDrillingCard.isCorrect)
        XCTAssertFalse(activeDrillingCard.isTimeout)
        XCTAssertFalse(activeDrillingCard.showHint)
        XCTAssertEqual(activeDrillingCard.displayedSentence, word.clozeSentenceEn)

        // 2. Active drilling with hint: hint initial letter revealed, IPA still hidden
        let hintedDrillingCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.4, timerStage: .warning,
            showHint: true, isCorrect: false, isTimeout: false, liveTranscript: ""
        )
        XCTAssertNotNil(hintedDrillingCard.body)
        XCTAssertTrue(hintedDrillingCard.showHint)
        XCTAssertFalse(hintedDrillingCard.isCorrect)
        XCTAssertFalse(hintedDrillingCard.isTimeout)
        XCTAssertTrue(word.initialLetterHint.hasPrefix("m..."))

        // 3. Correct match: IPA and full target word revealed
        let correctCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.5, timerStage: .steady,
            showHint: false, isCorrect: true, isTimeout: false, liveTranscript: "meticulous"
        )
        XCTAssertNotNil(correctCard.body)
        XCTAssertTrue(correctCard.isCorrect)
        XCTAssertEqual(correctCard.displayedSentence, word.completedSentenceWithTargetWord)
        XCTAssertEqual(correctCard.word.ipa, "/məˈtɪk.jə.ləs/")

        // 4. Timeout reveal: IPA and full example sentence revealed
        let timeoutCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.0, timerStage: .urgent,
            showHint: true, isCorrect: false, isTimeout: true, liveTranscript: ""
        )
        XCTAssertNotNil(timeoutCard.body)
        XCTAssertTrue(timeoutCard.isTimeout)
        XCTAssertEqual(timeoutCard.displayedSentence, word.exampleSentenceEn)
        XCTAssertEqual(timeoutCard.word.ipa, "/məˈtɪk.jə.ləs/")
    }

    @MainActor
    func testClozeSentenceRevealPartsOnCorrectAndTimeout() {
        let word = ReflexBlitzWordItem(
            id: 3, lemma: "fluent", pos: "adj.", ipa: "/ˈfluː.ənt/",
            definitionVi: "Trôi chảy, lưu loát",
            exampleSentenceEn: "She is fluent in English and French.",
            exampleSentenceVi: "Cô ấy nói trôi chảy tiếng Anh và tiếng Pháp.",
            clozeSentenceEn: "She is [ _________ ] in English and French."
        )

        // 1. Drilling state: cloze slot has placeholder dots
        let drillingCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.9, timerStage: .steady,
            showHint: false, isCorrect: false, isTimeout: false
        )
        let drillingParts = drillingCard.clozeParts
        XCTAssertNotNil(drillingParts)
        XCTAssertEqual(drillingParts?.prefix, "She is ")
        XCTAssertEqual(drillingParts?.suffix, " in English and French.")
        XCTAssertTrue(drillingParts?.slot.contains("•") == true)

        // 2. Hinted state: cloze slot contains initial letter hint
        let hintedCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.4, timerStage: .warning,
            showHint: true, isCorrect: false, isTimeout: false
        )
        let hintedParts = hintedCard.clozeParts
        XCTAssertNotNil(hintedParts)
        XCTAssertEqual(hintedParts?.prefix, "She is ")
        XCTAssertEqual(hintedParts?.suffix, " in English and French.")
        XCTAssertTrue(hintedParts?.slot.contains("f") == true)

        // 3. Correct match state: cloze slot reveals the target lemma
        let correctCard = ReflexBlitzCardView(
            word: word, fractionRemaining: 0.6, timerStage: .steady,
            showHint: false, isCorrect: true, isTimeout: false
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
    func testCompactClozeSlotRepresentationDoesNotExceedMaxDots() {
        let longWord = ReflexBlitzWordItem(
            id: 99,
            lemma: "comprehension",
            pos: "n.",
            ipa: "/ˌkɒm.prɪˈhen.ʃən/",
            definitionVi: "Sự thấu hiểu",
            exampleSentenceEn: "Reading aids comprehension of language.",
            exampleSentenceVi: "Đọc sách giúp thấu hiểu ngôn ngữ.",
            clozeSentenceEn: "Reading aids [ _____________ ] of language."
        )

        let card = ReflexBlitzCardView(
            word: longWord,
            showHint: false,
            isCorrect: false
        )
        let slot = card.slotRepresentation
        XCTAssertEqual(slot, "[ • • • ]")

        let hintedCard = ReflexBlitzCardView(
            word: longWord,
            showHint: true,
            isCorrect: false
        )
        let hintedSlot = hintedCard.slotRepresentation
        XCTAssertTrue(hintedSlot.hasPrefix("[ c"))
        XCTAssertEqual(hintedSlot, "[ c • • ]")
        XCTAssertTrue(hintedSlot.count <= 10)
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
    func testMultipleChoiceCardUsesVerticalOptionsStackWithoutPrefix() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = word.generateOptions(mode: .multipleChoice, allPool: ReflexBlitzWordItem.defaultStarterWords)
        var selectedOption: ReflexBlitzOption?
        let card = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .activeCountdown,
            options: options,
            onSelectOption: { opt in selectedOption = opt }
        )
        XCTAssertNotNil(card.body)
        XCTAssertEqual(card.options.count, 4)
        assertColorsEqual(card.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
        card.onSelectOption?(options[1])
        XCTAssertEqual(selectedOption?.id, options[1].id)
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
        assertColorsEqual(cardView.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
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
        assertColorsEqual(wrongCardView.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
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
        assertColorsEqual(timeoutCardView.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
        XCTAssertNotNil(timeoutCardView.body)
    }

    @MainActor
    func testCardViewChoiceStatesDerivationInReviewedMode() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let optionHabit = ReflexBlitzOption(id: "1", text: "habit", isCorrect: true)
        let optionFocus = ReflexBlitzOption(id: "2", text: "focus", isCorrect: false)
        let optionCreate = ReflexBlitzOption(id: "3", text: "create", isCorrect: false)
        let optionRelax = ReflexBlitzOption(id: "4", text: "relax", isCorrect: false)
        let options = [optionHabit, optionFocus, optionCreate, optionRelax]

        // 1. Active countdown mode (not reviewed) -> all .idle and no status indicator
        let activeCard = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .activeCountdown,
            options: options
        )
        XCTAssertFalse(activeCard.isReviewed)
        XCTAssertEqual(activeCard.choiceState(for: optionHabit), .idle)
        XCTAssertEqual(activeCard.choiceState(for: optionFocus), .idle)
        XCTAssertEqual(activeCard.choiceState(for: optionCreate), .idle)
        XCTAssertEqual(activeCard.choiceState(for: optionRelax), .idle)
        XCTAssertFalse(activeCard.showsStatusIndicator(for: optionHabit))
        XCTAssertFalse(activeCard.showsStatusIndicator(for: optionFocus))
        XCTAssertFalse(activeCard.showsStatusIndicator(for: optionCreate))
        XCTAssertFalse(activeCard.showsStatusIndicator(for: optionRelax))
        XCTAssertNotNil(activeCard.body)

        // 2. Reviewed mode with wrong selection ("focus")
        let wrongCard = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: 2000,
                isTimeout: false,
                selectedOption: "focus"
            )),
            options: options
        )
        XCTAssertTrue(wrongCard.isReviewed)
        XCTAssertEqual(wrongCard.selectedOptionText, "focus")
        XCTAssertEqual(wrongCard.choiceState(for: optionHabit), .correct)
        XCTAssertEqual(wrongCard.choiceState(for: optionFocus), .wrong)
        XCTAssertEqual(wrongCard.choiceState(for: optionCreate), .disabled)
        XCTAssertEqual(wrongCard.choiceState(for: optionRelax), .disabled)
        XCTAssertTrue(wrongCard.showsStatusIndicator(for: optionHabit))
        XCTAssertTrue(wrongCard.showsStatusIndicator(for: optionFocus))
        XCTAssertFalse(wrongCard.showsStatusIndicator(for: optionCreate))
        XCTAssertFalse(wrongCard.showsStatusIndicator(for: optionRelax))
        XCTAssertNotNil(wrongCard.body)

        // 3. Reviewed mode with correct selection ("habit")
        let correctCard = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .reviewed(result: ReflexCardResult(
                isCorrect: true,
                responseTimeMs: 1200,
                isTimeout: false,
                selectedOption: "habit"
            )),
            options: options
        )
        XCTAssertTrue(correctCard.isReviewed)
        XCTAssertEqual(correctCard.selectedOptionText, "habit")
        XCTAssertEqual(correctCard.choiceState(for: optionHabit), .correct)
        XCTAssertEqual(correctCard.choiceState(for: optionFocus), .disabled)
        XCTAssertEqual(correctCard.choiceState(for: optionCreate), .disabled)
        XCTAssertEqual(correctCard.choiceState(for: optionRelax), .disabled)
        XCTAssertTrue(correctCard.showsStatusIndicator(for: optionHabit))
        XCTAssertFalse(correctCard.showsStatusIndicator(for: optionFocus))
        XCTAssertFalse(correctCard.showsStatusIndicator(for: optionCreate))
        XCTAssertFalse(correctCard.showsStatusIndicator(for: optionRelax))
        XCTAssertNotNil(correctCard.body)

        // 4. Reviewed mode with timeout (no selection)
        let timeoutCard = ReflexBlitzCardView(
            word: word,
            mode: .multipleChoice,
            cardPhase: .reviewed(result: ReflexCardResult(
                isCorrect: false,
                responseTimeMs: 4000,
                isTimeout: true,
                selectedOption: nil
            )),
            options: options
        )
        XCTAssertTrue(timeoutCard.isReviewed)
        XCTAssertNil(timeoutCard.selectedOptionText)
        XCTAssertEqual(timeoutCard.choiceState(for: optionHabit), .correct)
        XCTAssertEqual(timeoutCard.choiceState(for: optionFocus), .disabled)
        XCTAssertEqual(timeoutCard.choiceState(for: optionCreate), .disabled)
        XCTAssertEqual(timeoutCard.choiceState(for: optionRelax), .disabled)
        XCTAssertTrue(timeoutCard.showsStatusIndicator(for: optionHabit))
        XCTAssertFalse(timeoutCard.showsStatusIndicator(for: optionFocus))
        XCTAssertFalse(timeoutCard.showsStatusIndicator(for: optionCreate))
        XCTAssertFalse(timeoutCard.showsStatusIndicator(for: optionRelax))
        XCTAssertNotNil(timeoutCard.body)
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

    @MainActor
    func testReflexBlitzCardReviewedViewCleanConsolidationLayout() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(id: "1", text: "habit", isCorrect: true),
            ReflexBlitzOption(id: "2", text: "focus", isCorrect: false),
            ReflexBlitzOption(id: "3", text: "create", isCorrect: false),
            ReflexBlitzOption(id: "4", text: "relax", isCorrect: false)
        ]
        var didReplay = false
        let reviewedCard = ReflexBlitzCardReviewedView(
            word: word,
            mode: .multipleChoice,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            options: options,
            reviewResult: ReflexCardResult(isCorrect: true, responseTimeMs: 1200, isTimeout: false, selectedOption: "habit"),
            selectedOptionText: "habit",
            clozeParts: nil,
            displayedSentence: word.completedSentenceWithTargetWord,
            onReplayAudio: { didReplay = true }
        )
        XCTAssertNotNil(reviewedCard.body)
        XCTAssertEqual(reviewedCard.options.count, 4)
        XCTAssertEqual(reviewedCard.selectedOptionText, "habit")
        XCTAssertTrue(reviewedCard.isResultCorrect)
        XCTAssertFalse(reviewedCard.isResultTimeout)
        XCTAssertEqual(reviewedCard.displayedSentence, word.completedSentenceWithTargetWord)
        reviewedCard.onReplayAudio?()
        XCTAssertTrue(didReplay)
    }

    @MainActor
    func testReflexBlitzCardReviewedViewIncorrectAndTimeoutModes() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = [
            ReflexBlitzOption(id: "1", text: "habit", isCorrect: true),
            ReflexBlitzOption(id: "2", text: "focus", isCorrect: false),
            ReflexBlitzOption(id: "3", text: "create", isCorrect: false),
            ReflexBlitzOption(id: "4", text: "relax", isCorrect: false)
        ]

        // 1. Multiple Choice Incorrect Selection
        let wrongCard = ReflexBlitzCardReviewedView(
            word: word,
            mode: .multipleChoice,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: false,
            options: options,
            reviewResult: ReflexCardResult(isCorrect: false, responseTimeMs: 2300, isTimeout: false, selectedOption: "focus"),
            selectedOptionText: "focus",
            clozeParts: nil,
            displayedSentence: word.completedSentenceWithTargetWord,
            onReplayAudio: nil
        )
        XCTAssertNotNil(wrongCard.body)
        XCTAssertEqual(wrongCard.selectedOptionText, "focus")
        XCTAssertFalse(wrongCard.isResultCorrect)
        XCTAssertFalse(wrongCard.isResultTimeout)

        // 2. Multiple Choice Timeout
        let timeoutCard = ReflexBlitzCardReviewedView(
            word: word,
            mode: .multipleChoice,
            isReviewed: true,
            isResultCorrect: false,
            isResultTimeout: true,
            options: options,
            reviewResult: ReflexCardResult(isCorrect: false, responseTimeMs: 4500, isTimeout: true, selectedOption: nil),
            selectedOptionText: nil,
            clozeParts: nil,
            displayedSentence: word.completedSentenceWithTargetWord,
            onReplayAudio: nil
        )
        XCTAssertNotNil(timeoutCard.body)
        XCTAssertNil(timeoutCard.selectedOptionText)
        XCTAssertFalse(timeoutCard.isResultCorrect)
        XCTAssertTrue(timeoutCard.isResultTimeout)

        // 3. Speaking mode reviewed chip
        let speakingCard = ReflexBlitzCardReviewedView(
            word: word,
            mode: .speaking,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            options: [],
            reviewResult: ReflexCardResult(isCorrect: true, responseTimeMs: 1200, isTimeout: false, recognizedSpoken: "habit"),
            selectedOptionText: nil,
            clozeParts: nil,
            displayedSentence: word.completedSentenceWithTargetWord,
            onReplayAudio: nil
        )
        XCTAssertNotNil(speakingCard.body)

        // 4. Typing mode reviewed chip
        let typingCard = ReflexBlitzCardReviewedView(
            word: word,
            mode: .typing,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            options: [],
            reviewResult: ReflexCardResult(isCorrect: true, responseTimeMs: 1800, isTimeout: false, typedText: "habit"),
            selectedOptionText: nil,
            clozeParts: nil,
            displayedSentence: word.completedSentenceWithTargetWord,
            onReplayAudio: nil
        )
        XCTAssertNotNil(typingCard.body)
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
        assertColorsEqual(cardView.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
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
        assertColorsEqual(cardView.cardBorderColor, CraftDefaultColorTokens().hairline.opacity(0.4))
        assertColorsEqual(cardView.timerStrokeColor, CraftDefaultColorTokens().statusDanger)
        XCTAssertNotNil(cardView.body)
    }
}
