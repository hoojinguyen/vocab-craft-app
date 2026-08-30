import CraftUIKit
import Foundation
import SwiftUI
#if canImport(Testing)
import Testing
#endif
#if canImport(UIKit)
import UIKit
#endif
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

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
        header.onSkip?()
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
    func testHeaderViewWithSkipProperty() {
        let header = ReflexBlitzHeaderView(
            currentIndex: 1, totalCount: 10, comboStreak: 2, fractionRemaining: 0.5,
            timerStage: .steady, showSkipInHeader: true, onClose: {}, onSkip: {}
        )
        XCTAssertTrue(header.showSkipInHeader)
        XCTAssertNotNil(header.body)
    }

    @MainActor
    func testHeaderViewDynamicTimerBar() {
        let now = Date()
        let active = ReflexBlitzHeaderView(
            currentIndex: 0, totalCount: 5, comboStreak: 0, fractionRemaining: 1.0,
            timerStage: .steady, wordStartTime: now, timeLimitSeconds: 6.0, isTimerActive: true, onClose: {}
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
    func testReflexBlitzMultipleChoiceCardViewUsesDeclarativeFlipCard() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = word.generateOptions(mode: .multipleChoice, allPool: ReflexBlitzWordItem.defaultStarterWords)

        // Active Prompt State: front card has no CEFR badge
        let activeCard = ReflexMultipleChoiceModeView(
            word: word,
            options: options,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: false,
            selectedOptionText: nil as String?,
            clozeParts: nil as ClozeSentenceParts?,
            displayedSentence: word.clozeSentenceEn,
            cardBorderColor: Color.clear,
            onSelectOption: nil,
            onReplayAudio: nil
        )
        XCTAssertNotNil(activeCard.body)

        // Reviewed State: back card has CEFR badge and audio replay
        let reviewedCard = ReflexMultipleChoiceModeView(
            word: word,
            options: options,
            isReviewed: true,
            isResultCorrect: true,
            isResultTimeout: false,
            showHint: false,
            selectedOptionText: "habit",
            clozeParts: nil as ClozeSentenceParts?,
            displayedSentence: word.completedSentenceWithTargetWord,
            cardBorderColor: Color.clear,
            onSelectOption: nil,
            onReplayAudio: {}
        )
        XCTAssertNotNil(reviewedCard.body)
    }

    @MainActor
    func testReflexBlitzMultipleChoiceCardViewProgressiveHintStages() {
        let word = ReflexBlitzWordItem.defaultStarterWords[0]
        let options = word.generateOptions(mode: .multipleChoice, allPool: ReflexBlitzWordItem.defaultStarterWords)
        let wrongOption = options.first(where: { !$0.isCorrect })!
        let correctOption = options.first(where: { $0.isCorrect })!

        // Stage 0: all options idle
        let stage0Card = ReflexMultipleChoiceModeView(
            word: word,
            options: options,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: false,
            hintStage: 0,
            selectedOptionText: nil as String?,
            clozeParts: nil as ClozeSentenceParts?,
            displayedSentence: word.clozeSentenceEn,
            cardBorderColor: Color.clear,
            eliminatedOptionId: nil,
            onSelectOption: nil,
            onReplayAudio: nil
        )
        XCTAssertEqual(stage0Card.choiceState(for: wrongOption), CraftChoiceState.idle)
        XCTAssertEqual(stage0Card.choiceState(for: correctOption), CraftChoiceState.idle)
        XCTAssertNotNil(stage0Card.body)

        // Stage 3: eliminated option is disabled, correct option is idle
        let stage3Card = ReflexMultipleChoiceModeView(
            word: word,
            options: options,
            isReviewed: false,
            isResultCorrect: false,
            isResultTimeout: false,
            showHint: true,
            hintStage: 3,
            selectedOptionText: nil as String?,
            clozeParts: nil as ClozeSentenceParts?,
            displayedSentence: word.clozeSentenceEn,
            cardBorderColor: Color.clear,
            eliminatedOptionId: wrongOption.id,
            onSelectOption: nil,
            onReplayAudio: nil
        )
        XCTAssertEqual(stage3Card.choiceState(for: wrongOption), CraftChoiceState.disabled)
        XCTAssertEqual(stage3Card.choiceState(for: correctOption), CraftChoiceState.idle)
        XCTAssertNotNil(stage3Card.body)
    }
}
