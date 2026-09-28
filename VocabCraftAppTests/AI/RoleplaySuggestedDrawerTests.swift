import CraftUIKit
import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("RoleplaySuggestedDrawer Tests")
struct RoleplaySuggestedDrawerTests {
    private func makeSampleScenario(targetWords: [String] = ["espresso", "croissant"]) -> RoleplayScenario {
        RoleplayScenario(
            id: "test-cafe",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome to The Daily Roast!",
            targetWordIds: targetWords,
            iconSymbol: "cup.and.saucer"
        )
    }

    @Test("When suggestedResponses is empty, view renders empty / does not display")
    @MainActor
    func testEmptySuggestedResponsesRendersEmpty() {
        let scenario = makeSampleScenario()
        let engine = MockDrawerVoiceEngine(scenario: scenario, suggestedResponses: [])
        let vm = RoleplayVoiceCallViewModel(engine: engine)
        let drawer = RoleplaySuggestedDrawer(viewModel: vm)

        #expect(drawer.isVisible == false)
        #expect(drawer.itemCount == 0)
        _ = drawer.body
    }

    @Test("When collapsed, capsule button shows item count")
    @MainActor
    func testCollapsedCapsuleShowsItemCount() {
        let scenario = makeSampleScenario()
        let suggestions = [
            "Could I please order an espresso?",
            "Do you have a fresh croissant?"
        ]
        let engine = MockDrawerVoiceEngine(scenario: scenario, suggestedResponses: suggestions)
        let vm = RoleplayVoiceCallViewModel(engine: engine)
        let drawer = RoleplaySuggestedDrawer(viewModel: vm)

        #expect(drawer.isVisible == true)
        #expect(drawer.isExpanded == false)
        #expect(drawer.itemCount == 2)
        #expect(drawer.toggleTitleText.contains("2"))

        _ = drawer.body
        _ = drawer.collapsedCapsule
    }

    @Test("Attributed text highlights target words with bold font and brandPrimary")
    @MainActor
    func testAttributedTextHighlightsTargetWords() {
        let sentence = "I would love a hot espresso and a croissant, please."
        let targetWords = ["espresso", "croissant"]
        let primaryColor = Color.blue
        let highlightFont = Font.body.bold()

        let attributed = RoleplaySuggestedDrawer.highlightedText(
            for: sentence,
            targetWords: targetWords,
            primaryColor: primaryColor,
            highlightFont: highlightFont
        )

        let plainString = String(attributed.characters)
        #expect(plainString == sentence)

        // Verify that target word ranges have foregroundColor and font applied
        for target in targetWords {
            let range = attributed.range(of: target, options: .caseInsensitive)
            #expect(range != nil)
            if let range {
                let color = attributed[range].foregroundColor
                #expect(color == primaryColor)
                let font = attributed[range].font
                #expect(font == highlightFont)
            }
        }

        // Verify non-target words do not have highlight primary color
        if let nonTargetRange = attributed.range(of: "would love") {
            let color = attributed[nonTargetRange].foregroundColor
            #expect(color == nil)
        }

        // Verify case-insensitive matching
        let capitalizedSentence = "Espresso is my favorite morning drink."
        let capitalizedAttributed = RoleplaySuggestedDrawer.highlightedText(
            for: capitalizedSentence,
            targetWords: ["espresso"],
            primaryColor: primaryColor,
            highlightFont: highlightFont
        )
        if let matchRange = capitalizedAttributed.range(of: "Espresso") {
            #expect(capitalizedAttributed[matchRange].foregroundColor == primaryColor)
        }
    }

    @Test("Word boundaries prevent sub-words from being falsely highlighted")
    @MainActor
    func testWordBoundariesPreventSubwordHighlighting() {
        let sentence = "The bear has a tiny ear."
        let targetWords = ["ear"]
        let primaryColor = Color.blue
        let highlightFont = Font.body.bold()

        let attributed = RoleplaySuggestedDrawer.highlightedText(
            for: sentence,
            targetWords: targetWords,
            primaryColor: primaryColor,
            highlightFont: highlightFont
        )

        if let bearRange = attributed.range(of: "bear") {
            #expect(attributed[bearRange].foregroundColor == nil)
        }

        let highlightedRuns = attributed.runs.filter { $0.foregroundColor == primaryColor }
        #expect(highlightedRuns.count == 1)
        if let firstRun = highlightedRuns.first {
            #expect(String(attributed[firstRun.range].characters) == "ear")
            #expect(firstRun.font == highlightFont)
        }
    }

    @Test("Audio preview button calls viewModel.playSamplePronunciation")
    @MainActor
    func testAudioPreviewCallsTTS() {
        let scenario = makeSampleScenario()
        let suggestions = ["I would like an espresso, please."]
        let engine = MockDrawerVoiceEngine(scenario: scenario, suggestedResponses: suggestions)
        let mockTTS = MockTextToSpeechService()
        let vm = RoleplayVoiceCallViewModel(engine: engine, ttsService: mockTTS)
        let drawer = RoleplaySuggestedDrawer(viewModel: vm)

        let sentence = suggestions[0]
        drawer.playSamplePronunciation(sentence)

        #expect(mockTTS.speakCallCount == 1)
        #expect(mockTTS.lastSpokenText == sentence)
    }

    @Test("Auto-collapses drawer when call state changes to speaking or thinking")
    @MainActor
    func testAutoCollapseOnSpeakingOrThinking() {
        let scenario = makeSampleScenario()
        let suggestions = ["Can I get an espresso?"]
        let engine = MockDrawerVoiceEngine(scenario: scenario, suggestedResponses: suggestions)
        let vm = RoleplayVoiceCallViewModel(engine: engine)
        let drawer = RoleplaySuggestedDrawer(viewModel: vm)

        // Expand hints drawer
        vm.isHintsExpanded = true
        #expect(drawer.isExpanded == true)

        // State changes to .speaking -> should collapse
        drawer.handleStateChange(.speaking(characterText: "Coming right up!"))
        #expect(vm.isHintsExpanded == false)
        #expect(drawer.isExpanded == false)

        // Re-expand
        vm.isHintsExpanded = true
        #expect(drawer.isExpanded == true)

        // State changes to .thinking -> should collapse
        drawer.handleStateChange(.thinking)
        #expect(vm.isHintsExpanded == false)
        #expect(drawer.isExpanded == false)

        // Re-expand
        vm.isHintsExpanded = true
        #expect(drawer.isExpanded == true)

        // State changes to .listening -> should NOT collapse
        drawer.handleStateChange(.listening(liveTranscript: "Yes please"))
        #expect(vm.isHintsExpanded == true)
        #expect(drawer.isExpanded == true)
    }
}

// MARK: - Test Mock Engine

@MainActor
private final class MockDrawerVoiceEngine: VoiceConversationEngineProtocol {
    var state: VoiceCallState = .idle
    var isMuted: Bool = false
    var isSubtitlesVisible: Bool = true
    var suggestedResponses: [String] = []
    var scenario: RoleplayScenario
    var messages: [RoleplayMessage] = []
    var masteredTargetWords: Set<String> = []

    init(scenario: RoleplayScenario, suggestedResponses: [String] = []) {
        self.scenario = scenario
        self.suggestedResponses = suggestedResponses
    }

    func startCall() async {}
    func finishUserTurnManually() {}
    func toggleMute() { isMuted.toggle() }
    func toggleSubtitles() { isSubtitlesVisible.toggle() }
    func endCall() async -> RoleplaySessionSummary {
        RoleplaySessionSummary(
            scenarioId: scenario.id,
            totalTurns: 0,
            targetWordsAttempted: [],
            targetWordsMastered: [],
            fluencyScore: 100,
            xpEarned: 0,
            refinements: []
        )
    }
}
