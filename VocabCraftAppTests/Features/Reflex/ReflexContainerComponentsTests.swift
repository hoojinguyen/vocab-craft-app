import CraftUIKit
import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
@testable import VocabCraftApp

#if canImport(Testing)
@Suite("ReflexContainerComponents Tests")
struct ReflexContainerComponentsTests {
    @Test("Validates ReflexReviewedConsolidationView instantiation and properties")
    func testReviewedView() {
        let item = ReflexBlitzWordItem.defaultStarterWords[0]
        let result = ReflexCardResult(
            isCorrect: true,
            responseTimeMs: 1200,
            isTimeout: false,
            typedText: "habit",
            recognizedSpoken: "habit"
        )
        let view = ReflexReviewedConsolidationView(
            word: item,
            mode: .speaking,
            reviewResult: result,
            displayedSentence: item.exampleSentenceEn,
            onReplayAudio: nil
        )
        #expect(view.isResultCorrect == true)
        #expect(view.isResultTimeout == false)
        #expect(view.word.lemma == "habit")
        #expect(view.mode == .speaking)
    }

    @Test("Validates ReflexReviewedConsolidationView across all modalities")
    func testReviewedViewModalities() {
        let item = ReflexBlitzWordItem.defaultStarterWords[1]

        // Speaking mode
        let speakingResult = ReflexCardResult(
            isCorrect: true,
            responseTimeMs: 1500,
            isTimeout: false,
            recognizedSpoken: "improve"
        )
        let speakingView = ReflexReviewedConsolidationView(
            word: item,
            mode: .speaking,
            reviewResult: speakingResult,
            displayedSentence: item.completedSentenceWithTargetWord
        )
        #expect(speakingView.isResultCorrect == true)

        // Typing mode incorrect
        let typingResult = ReflexCardResult(
            isCorrect: false,
            responseTimeMs: 3200,
            isTimeout: false,
            typedText: "improv"
        )
        let typingView = ReflexReviewedConsolidationView(
            word: item,
            mode: .typing,
            reviewResult: typingResult,
            displayedSentence: item.completedSentenceWithTargetWord
        )
        #expect(typingView.isResultCorrect == false)
        #expect(typingView.isResultTimeout == false)

        // Listening mode timeout
        let listeningResult = ReflexCardResult(
            isCorrect: false,
            responseTimeMs: 5500,
            isTimeout: true,
            selectedOption: "Thói quen"
        )
        let listeningView = ReflexReviewedConsolidationView(
            word: item,
            mode: .listening,
            reviewResult: listeningResult,
            displayedSentence: item.completedSentenceWithTargetWord
        )
        #expect(listeningView.isResultCorrect == false)
        #expect(listeningView.isResultTimeout == true)
    }

    @Test("Validates ReflexCardContainerView instantiation and styling")
    func testCardContainerView() {
        let container = ReflexCardContainerView(
            isReviewed: false,
            isCorrect: false,
            isTimeout: false,
            timerStage: .steady
        ) {
            Text("Active Mode Content")
        }

        #expect(container.isReviewed == false)
        #expect(container.isCorrect == false)
        #expect(container.isTimeout == false)
        #expect(container.timerStage == .steady)

        let reviewedContainer = ReflexCardContainerView(
            isReviewed: true,
            isCorrect: true,
            isTimeout: false,
            timerStage: .steady
        ) {
            Text("Reviewed Mode Content")
        }

        #expect(reviewedContainer.isReviewed == true)
        #expect(reviewedContainer.isCorrect == true)
    }

    @Test("Validates ReflexHeaderBarView instantiation and callbacks")
    func testHeaderBarView() {
        var didClose = false
        var didSkip = false

        let header = ReflexHeaderBarView(
            currentIndex: 2,
            totalCount: 10,
            comboStreak: 4,
            fractionRemaining: 0.75,
            timerStage: .warning,
            showSkipInHeader: true,
            onClose: { didClose = true },
            onSkip: { didSkip = true }
        )

        #expect(header.currentIndex == 2)
        #expect(header.totalCount == 10)
        #expect(header.comboStreak == 4)
        #expect(header.fractionRemaining == 0.75)
        #expect(header.timerStage == .warning)
        #expect(header.showSkipInHeader == true)

        header.onClose()
        #expect(didClose == true)

        header.onSkip?()
        #expect(didSkip == true)
    }
}
#endif
