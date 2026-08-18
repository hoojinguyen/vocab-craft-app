import SwiftUI
import XCTest
@testable import VocabCraftApp

final class ReflexBlitzComponentsTests: XCTestCase {
    @MainActor
    func testHeaderViewInstantiation() {
        var didClose = false
        var didSkip = false

        let header = ReflexBlitzHeaderView(
            currentIndex: 2,
            totalCount: 8,
            comboStreak: 3,
            onClose: { didClose = true },
            onSkip: { didSkip = true }
        )
        XCTAssertNotNil(header)
        XCTAssertEqual(header.currentIndex, 2)
        XCTAssertEqual(header.totalCount, 8)
        XCTAssertEqual(header.comboStreak, 3)

        header.onClose()
        header.onSkip()
        XCTAssertTrue(didClose)
        XCTAssertTrue(didSkip)
    }

    @MainActor
    func testHeaderViewBodyRendersAcrossComboThresholds() {
        let noComboHeader = ReflexBlitzHeaderView(
            currentIndex: 0,
            totalCount: 5,
            comboStreak: 1,
            onClose: {},
            onSkip: {}
        )
        XCTAssertNotNil(noComboHeader.body)

        let comboHeader = ReflexBlitzHeaderView(
            currentIndex: 4,
            totalCount: 5,
            comboStreak: 4,
            onClose: {},
            onSkip: {}
        )
        XCTAssertNotNil(comboHeader.body)
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
        XCTAssertEqual(defaultCard.timerStrokeColor, .vocabHeroAccent)
        XCTAssertNotNil(defaultCard.body)

        defaultCard.onSubmitKeyboard()
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
        XCTAssertEqual(warningCard.timerStrokeColor, .vocabPeach)
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
        XCTAssertEqual(urgentCard.timerStrokeColor, .vocabCoral)
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
        XCTAssertEqual(correctCard.timerStrokeColor, .vocabMint)
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
        XCTAssertEqual(timeoutCard.timerStrokeColor, .vocabCoral)
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
}
