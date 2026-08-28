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

final class ReflexBlitzModeSelectionViewTests: XCTestCase {
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
        assertColorsEqual(speaking.accentColor, colors.brandPrimary)

        let typing = ReflexBlitzModeSelectionView.modeItem(for: .typing, colors: colors)
        XCTAssertEqual(typing.title, AppStrings.ReflexBlitz.typingTitleText)
        XCTAssertEqual(typing.badgeText, "7.5s")
        XCTAssertEqual(typing.iconName, "keyboard")
        assertColorsEqual(typing.accentColor, colors.streakLegendary)

        let multipleChoice = ReflexBlitzModeSelectionView.modeItem(for: .multipleChoice, colors: colors)
        XCTAssertEqual(multipleChoice.title, AppStrings.ReflexBlitz.mcTitleText)
        XCTAssertEqual(multipleChoice.badgeText, "4.5s")
        XCTAssertEqual(multipleChoice.iconName, "square.grid.2x2.fill")
        assertColorsEqual(multipleChoice.accentColor, colors.statusSuccess)

        let listening = ReflexBlitzModeSelectionView.modeItem(for: .listening, colors: colors)
        XCTAssertEqual(listening.title, AppStrings.ReflexBlitz.listeningTitleText)
        XCTAssertEqual(listening.badgeText, "5.5s")
        XCTAssertEqual(listening.iconName, "headphones")
        assertColorsEqual(listening.accentColor, colors.statusInfo)
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
}

// MARK: - Swift Testing Suite

@Suite("Reflex Blitz Mode Selection View Tests")
struct ReflexBlitzModeSelectionViewTestsSuite {
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
