#if canImport(XCTest)
import XCTest
#endif
import SwiftUI
@testable import CraftUIKit

final class CraftSpeechUIComponentTests: XCTestCase {
    func testTokenViewVisualPropertiesForStatuses() {
        let pending = CraftSpeechWordToken(targetWord: "hello", status: .pending)
        let matched = CraftSpeechWordToken(targetWord: "world", status: .matched)
        let fuzzy = CraftSpeechWordToken(targetWord: "good", status: .fuzzy)
        let mismatched = CraftSpeechWordToken(targetWord: "job", status: .mismatched)
        
        XCTAssertEqual(pending.status, .pending)
        XCTAssertEqual(matched.status, .matched)
        XCTAssertEqual(fuzzy.status, .fuzzy)
        XCTAssertEqual(mismatched.status, .mismatched)

        let pendingView = CraftSpeechWordTokenView(token: pending)
        let matchedView = CraftSpeechWordTokenView(token: matched)
        let fuzzyView = CraftSpeechWordTokenView(token: fuzzy)
        let mismatchedView = CraftSpeechWordTokenView(token: mismatched)

        XCTAssertEqual(pendingView.token.targetWord, "hello")
        XCTAssertEqual(matchedView.token.targetWord, "world")
        XCTAssertEqual(fuzzyView.token.targetWord, "good")
        XCTAssertEqual(mismatchedView.token.targetWord, "job")

        XCTAssertNotNil(pendingView.body)
        XCTAssertNotNil(matchedView.body)
        XCTAssertNotNil(fuzzyView.body)
        XCTAssertNotNil(mismatchedView.body)
    }

    func testFlowLayoutDefaultInitialization() {
        let layout = CraftSpeechWordFlowLayout()
        XCTAssertEqual(layout.spacing, 8)
        XCTAssertEqual(layout.lineSpacing, 8)
        XCTAssertEqual(layout.alignment, .center)
    }

    func testFlowLayoutCustomInitialization() {
        let leadingLayout = CraftSpeechWordFlowLayout(spacing: 12, lineSpacing: 16, alignment: .leading)
        XCTAssertEqual(leadingLayout.spacing, 12)
        XCTAssertEqual(leadingLayout.lineSpacing, 16)
        XCTAssertEqual(leadingLayout.alignment, .leading)

        let trailingLayout = CraftSpeechWordFlowLayout(spacing: 6, lineSpacing: 10, alignment: .trailing)
        XCTAssertEqual(trailingLayout.spacing, 6)
        XCTAssertEqual(trailingLayout.lineSpacing, 10)
        XCTAssertEqual(trailingLayout.alignment, .trailing)

        let centerLayout = CraftSpeechWordFlowLayout(spacing: 4, lineSpacing: 4, alignment: .center)
        XCTAssertEqual(centerLayout.spacing, 4)
        XCTAssertEqual(centerLayout.lineSpacing, 4)
        XCTAssertEqual(centerLayout.alignment, .center)
    }

    func testFlowLayoutWithTokenViewsHierarchy() {
        let tokens = [
            CraftSpeechWordToken(targetWord: "The", status: .matched),
            CraftSpeechWordToken(targetWord: "quick", status: .matched),
            CraftSpeechWordToken(targetWord: "brown", status: .fuzzy),
            CraftSpeechWordToken(targetWord: "fox", status: .mismatched),
            CraftSpeechWordToken(targetWord: "jumps", status: .pending)
        ]

        let container = CraftSpeechWordFlowLayout(spacing: 8, lineSpacing: 8, alignment: .center) {
            ForEach(tokens) { token in
                CraftSpeechWordTokenView(token: token)
            }
        }

        XCTAssertNotNil(container)
    }

    func testTactileMicHubInitializationAndStates() {
        var tapped = false
        let idleView = CraftTactileMicHubView(speechState: .idle) {
            tapped = true
        }
        XCTAssertEqual(idleView.speechState, .idle)
        idleView.onTapMic()
        XCTAssertTrue(tapped)
        XCTAssertNotNil(idleView.body)

        let listeningView = CraftTactileMicHubView(speechState: .listening(audioLevels: [0.1, 0.5, 0.8]), onTapMic: {})
        XCTAssertEqual(listeningView.speechState, .listening(audioLevels: [0.1, 0.5, 0.8]))
        XCTAssertNotNil(listeningView.body)

        let processingView = CraftTactileMicHubView(speechState: .processing, onTapMic: {})
        XCTAssertEqual(processingView.speechState, .processing)
        XCTAssertNotNil(processingView.body)

        let evaluatedView = CraftTactileMicHubView(speechState: .evaluated(overallScore: 92), onTapMic: {})
        XCTAssertEqual(evaluatedView.speechState, .evaluated(overallScore: 92))
        XCTAssertNil(evaluatedView.customSubtitle)
        XCTAssertNotNil(evaluatedView.body)

        let customSubtitleView = CraftTactileMicHubView(speechState: .evaluated(overallScore: 92), customSubtitle: "", onTapMic: {})
        XCTAssertEqual(customSubtitleView.customSubtitle, "")
        XCTAssertNotNil(customSubtitleView.body)
    }

    func testCraftVoiceMatchCardInitializesCleanly() {
        let card = CraftVoiceMatchCard(
            originText: "It was a good job.",
            actualText: "It was",
            subtitle: "Đó là một công việc tốt.",
            speechState: .idle,
            onTapMic: {}
        )
        XCTAssertNotNil(card)
        XCTAssertNotNil(card.body)
    }

    func testCraftVoiceMatchCardWithExplicitTokens() {
        let tokens = [
            CraftSpeechWordToken(targetWord: "It", status: .matched),
            CraftSpeechWordToken(targetWord: "was", status: .matched),
            CraftSpeechWordToken(targetWord: "a", status: .pending),
            CraftSpeechWordToken(targetWord: "good", status: .pending),
            CraftSpeechWordToken(targetWord: "job", status: .pending)
        ]
        let card = CraftVoiceMatchCard(
            originText: "It was a good job.",
            explicitTokens: tokens,
            subtitle: "Đó là một công việc tốt.",
            speechState: .listening(audioLevels: [0.3, 0.6]),
            customInstruction: "Speak clearly into the microphone",
            onTapMic: {},
            onReset: {}
        )
        XCTAssertNotNil(card)
        XCTAssertNotNil(card.body)
        XCTAssertEqual(card.originText, "It was a good job.")
        XCTAssertEqual(card.explicitTokens?.count, 5)
        XCTAssertEqual(card.customInstruction, "Speak clearly into the microphone")
    }

    func testCraftVoiceMatchCardEvaluatedScore() {
        let card = CraftVoiceMatchCard(
            originText: "Great job",
            actualText: "Great job",
            speechState: .evaluated(overallScore: 95),
            onTapMic: {}
        )
        XCTAssertNotNil(card)
        XCTAssertNotNil(card.body)
    }
}

