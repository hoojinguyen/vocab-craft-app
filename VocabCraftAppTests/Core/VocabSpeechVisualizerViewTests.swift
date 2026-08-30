import Foundation
import CraftUIKit
import SpeechKit
import SwiftUI
@testable import VocabCraftApp
#if canImport(XCTest)
import XCTest
#endif

@MainActor
final class VocabSpeechVisualizerViewTests: XCTestCase {
    // MARK: - VocabSpeechVisualizerView Integration Tests

    func testVocabSpeechVisualizerView_backwardCompatibleInit() {
        let view = VocabSpeechVisualizerView(
            isListening: true,
            recognizedText: "Test speech"
        )

        XCTAssertTrue(view.isListening)
        XCTAssertEqual(view.recognizedText, "Test speech")
        XCTAssertEqual(view.placeholderText, AppStrings.Reflex.quickVisualizerPlaceholderText)
        XCTAssertNil(view.evaluationResult)
        XCTAssertTrue(view.tokens.isEmpty)
    }

    func testVocabSpeechVisualizerView_initWithEvaluationResult() {
        let tokens = [
            WordTokenResult(id: 0, targetWord: "Algorithm", spokenWord: "algorithm", status: .exactMatch, similarityScore: 1.0)
        ]
        let evalResult = SpeechEvaluationResult(
            targetSentence: "Algorithm",
            spokenText: "algorithm",
            tokens: tokens,
            overallScore: 1.0,
            isPassed: true,
            durationMs: 800
        )

        let view = VocabSpeechVisualizerView(
            isListening: false,
            recognizedText: "algorithm",
            evaluationResult: evalResult
        )

        XCTAssertFalse(view.isListening)
        XCTAssertEqual(view.recognizedText, "algorithm")
        XCTAssertEqual(view.evaluationResult, evalResult)
        XCTAssertEqual(view.tokens.count, 1)
        XCTAssertEqual(view.tokens[0].targetWord, "Algorithm")
        XCTAssertEqual(view.tokens[0].spokenWord, "algorithm")
    }

    func testVocabSpeechVisualizerView_initWithExplicitTokens() {
        let tokens = [
            WordTokenResult(id: 0, targetWord: "Neural", spokenWord: "neural", status: .exactMatch, similarityScore: 1.0),
            WordTokenResult(id: 1, targetWord: "Network", spokenWord: nil, status: .missing, similarityScore: 0.0)
        ]

        let view = VocabSpeechVisualizerView(
            isListening: true,
            recognizedText: "neural",
            tokens: tokens
        )

        XCTAssertTrue(view.isListening)
        XCTAssertEqual(view.tokens.count, 2)
        XCTAssertNil(view.evaluationResult)
    }

    func testVocabSpeechVisualizerViewIsolation() {
        let visualizer = VocabSpeechVisualizerView(
            isListening: true,
            recognizedText: "hello",
            placeholderText: "Listening..."
        )
        XCTAssertNotNil(visualizer.body)
    }
}
