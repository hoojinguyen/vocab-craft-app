import SwiftUI
@testable import VocabCraftApp
import XCTest

final class SpeechWordHighlightViewTests: XCTestCase {
    
    // MARK: - SpeechWordHighlightView Initialization Tests
    
    func testSpeechWordHighlightView_initializationWithTokens() {
        let tokens = [
            WordTokenResult(id: 0, targetWord: "The", spokenWord: "the", status: .exactMatch, similarityScore: 1.0),
            WordTokenResult(id: 1, targetWord: "quick", spokenWord: "quik", status: .fuzzyMatch, similarityScore: 0.8),
            WordTokenResult(id: 2, targetWord: "brown", spokenWord: nil, status: .missing, similarityScore: 0.0),
            WordTokenResult(id: 3, targetWord: "fox", spokenWord: "fox", status: .exactMatch, similarityScore: 1.0)
        ]
        
        let view = SpeechWordHighlightView(tokens: tokens, targetSentence: "The quick brown fox")
        XCTAssertEqual(view.tokens.count, 4)
        XCTAssertEqual(view.targetSentence, "The quick brown fox")
        XCTAssertEqual(view.tokens[0].status, .exactMatch)
        XCTAssertEqual(view.tokens[1].status, .fuzzyMatch)
        XCTAssertEqual(view.tokens[2].status, .missing)
        XCTAssertEqual(view.tokens[3].status, .exactMatch)
    }
    
    func testSpeechWordHighlightView_initializationWithEvaluationResult() {
        let tokens = [
            WordTokenResult(id: 0, targetWord: "Hello", spokenWord: "hello", status: .exactMatch, similarityScore: 1.0),
            WordTokenResult(id: 1, targetWord: "World", spokenWord: "world", status: .exactMatch, similarityScore: 1.0)
        ]
        let evalResult = SpeechEvaluationResult(
            targetSentence: "Hello World",
            spokenText: "hello world",
            tokens: tokens,
            overallScore: 1.0,
            isPassed: true,
            durationMs: 1200
        )
        
        let view = SpeechWordHighlightView(evaluation: evalResult)
        XCTAssertEqual(view.tokens.count, 2)
        XCTAssertEqual(view.targetSentence, "Hello World")
        XCTAssertEqual(view.evaluationResult, evalResult)
    }
    
    func testSpeechWordHighlightView_emptyInitialization() {
        let view = SpeechWordHighlightView(tokens: [])
        XCTAssertTrue(view.tokens.isEmpty)
        XCTAssertEqual(view.targetSentence, "")
        XCTAssertNil(view.evaluationResult)
    }
    
    // MARK: - Color Palette Mapping Tests
    
    func testSpeechWordHighlightView_colorMappingExactMatch() {
        let bg = SpeechWordHighlightView.backgroundColor(for: .exactMatch)
        let fg = SpeechWordHighlightView.foregroundColor(for: .exactMatch)
        let border = SpeechWordHighlightView.borderColor(for: .exactMatch)
        let iconName = SpeechWordHighlightView.iconName(for: .exactMatch)
        
        XCTAssertNotNil(bg)
        XCTAssertNotNil(fg)
        XCTAssertNotNil(border)
        XCTAssertEqual(iconName, "checkmark")
    }
    
    func testSpeechWordHighlightView_colorMappingFuzzyMatch() {
        let bg = SpeechWordHighlightView.backgroundColor(for: .fuzzyMatch)
        let fg = SpeechWordHighlightView.foregroundColor(for: .fuzzyMatch)
        let border = SpeechWordHighlightView.borderColor(for: .fuzzyMatch)
        let iconName = SpeechWordHighlightView.iconName(for: .fuzzyMatch)
        
        XCTAssertNotNil(bg)
        XCTAssertNotNil(fg)
        XCTAssertNotNil(border)
        XCTAssertNil(iconName)
    }
    
    func testSpeechWordHighlightView_colorMappingMissing() {
        let bg = SpeechWordHighlightView.backgroundColor(for: .missing)
        let fg = SpeechWordHighlightView.foregroundColor(for: .missing)
        let border = SpeechWordHighlightView.borderColor(for: .missing)
        let iconName = SpeechWordHighlightView.iconName(for: .missing)
        
        XCTAssertNotNil(bg)
        XCTAssertNotNil(fg)
        XCTAssertNotNil(border)
        XCTAssertNil(iconName)
    }
    
    // MARK: - FlowLayout Tests
    
    func testSpeechFlowLayout_initialization() {
        let layout = SpeechFlowLayout(spacing: 6, lineSpacing: 6)
        XCTAssertEqual(layout.spacing, 6)
        XCTAssertEqual(layout.lineSpacing, 6)
    }
    
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
}
