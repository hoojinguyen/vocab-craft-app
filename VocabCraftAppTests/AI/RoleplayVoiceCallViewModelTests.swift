import Foundation
import Testing
@testable import VocabCraftApp

@Suite("RoleplayVoiceCallViewModel Tests", .serialized)
struct RoleplayVoiceCallViewModelTests {
    private func makeTestScenario() -> RoleplayScenario {
        RoleplayScenario(
            id: "scenario_cafe",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome to The Daily Roast! What can I get for you today?",
            targetWordIds: ["espresso", "croissant", "cappuccino"],
            iconSymbol: "cup.and.saucer.fill"
        )
    }

    private func makeMockSummary(scenarioId: String) -> RoleplaySessionSummary {
        RoleplaySessionSummary(
            scenarioId: scenarioId,
            totalTurns: 4,
            targetWordsAttempted: ["espresso", "croissant"],
            targetWordsMastered: ["espresso", "croissant"],
            fluencyScore: 92,
            xpEarned: 50,
            refinements: [
                SentenceRefinementPair(
                    originalUserSentence: "I want coffee",
                    refinedNativeSentence: "I'd like an espresso, please."
                )
            ]
        )
    }

    @MainActor
    private func makeTestVoiceCallViewModel(
        callStartTime: Date = Date().addingTimeInterval(-10),
        mockSummary: RoleplaySessionSummary? = nil
    ) -> RoleplayVoiceCallViewModel {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario, mockSummary: mockSummary)
        return RoleplayVoiceCallViewModel(engine: engine, callStartTime: callStartTime)
    }

    @Test("ViewModel initializes with engine properties forwarded and no summary")
    @MainActor
    func initialProperties() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        #expect(vm.state == .idle)
        #expect(vm.scenario.id == "scenario_cafe")
        #expect(vm.scenario.characterName == "Alex")
        #expect(vm.scenario.characterRole == "Barista")
        #expect(vm.isMuted == false)
        #expect(vm.isSubtitlesVisible == true)
        #expect(vm.masteredTargetWords.isEmpty)
        #expect(vm.sessionSummary == nil)
    }

    @Test("startCall delegates to engine")
    @MainActor
    func startCallDelegates() async {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        #expect(engine.startCallInvoked == false)
        await vm.startCall()
        #expect(engine.startCallInvoked == true)
        #expect(vm.state == .speaking(characterText: scenario.initialGreeting))
    }

    @Test("finishSpeaking delegates to engine finishUserTurnManually")
    @MainActor
    func finishSpeakingDelegates() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        #expect(engine.finishUserTurnManuallyInvoked == false)
        vm.finishSpeaking()
        #expect(engine.finishUserTurnManuallyInvoked == true)
    }

    @Test("toggleMute delegates to engine and flips state")
    @MainActor
    func toggleMuteDelegates() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        #expect(vm.isMuted == false)
        vm.toggleMute()
        #expect(engine.toggleMuteInvoked == true)
        #expect(vm.isMuted == true)

        vm.toggleMute()
        #expect(vm.isMuted == false)
    }

    @Test("toggleSubtitles delegates to engine and flips state")
    @MainActor
    func toggleSubtitlesDelegates() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        #expect(vm.isSubtitlesVisible == true)
        vm.toggleSubtitles()
        #expect(engine.toggleSubtitlesInvoked == true)
        #expect(vm.isSubtitlesVisible == false)

        vm.toggleSubtitles()
        #expect(vm.isSubtitlesVisible == true)
    }

    @Test("endCall delegates to engine and sets sessionSummary")
    @MainActor
    func endCallSetsSummary() async {
        let scenario = makeTestScenario()
        let mockSummary = makeMockSummary(scenarioId: scenario.id)
        let engine = MockVoiceConversationEngine(scenario: scenario, mockSummary: mockSummary)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        #expect(vm.sessionSummary == nil)
        await vm.endCall()

        #expect(engine.endCallInvoked == true)
        #expect(vm.state == .ended)
        #expect(vm.sessionSummary?.id == mockSummary.id)
        #expect(vm.sessionSummary?.fluencyScore == 92)
    }

    @Test("checkForNewTargetWordMastered detects new words and does not re-trigger")
    @MainActor
    func checkForNewTargetWordMastered() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        // Initial check: no mastered words, count is 0, nothing triggers
        vm.checkForNewTargetWordMastered()

        // Engine gains 1 word
        engine.masteredTargetWords = ["espresso"]
        #expect(vm.masteredTargetWords.contains("espresso"))

        // Checking triggers haptic logic and updates previous count
        vm.checkForNewTargetWordMastered()

        // Checking again without changes does not re-trigger
        vm.checkForNewTargetWordMastered()

        // Engine gains another word
        engine.masteredTargetWords = ["espresso", "croissant"]
        vm.checkForNewTargetWordMastered()
        #expect(vm.masteredTargetWords.count == 2)
    }

    @Test("ViewModel initialized with pre-existing mastered words respects count baseline")
    @MainActor
    func preExistingMasteredWordsBaseline() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        engine.masteredTargetWords = ["espresso"]

        let vm = RoleplayVoiceCallViewModel(engine: engine)
        #expect(vm.masteredTargetWords.count == 1)

        // First check should not trigger since previousMasteredCount is already 1
        vm.checkForNewTargetWordMastered()

        // Adding second word triggers
        engine.masteredTargetWords = ["espresso", "croissant"]
        vm.checkForNewTargetWordMastered()
        #expect(vm.masteredTargetWords.count == 2)
    }

    @Test("endCall treats call lasting < 3.0s with 0 turns as accidental call")
    @MainActor
    func endCallAccidentalDismissalGuard() async {
        let scenario = makeTestScenario()
        let zeroTurnSummary = RoleplaySessionSummary(
            scenarioId: scenario.id,
            totalTurns: 0,
            targetWordsAttempted: scenario.targetWordIds,
            targetWordsMastered: [],
            fluencyScore: 60,
            xpEarned: 10,
            refinements: []
        )
        let engine = MockVoiceConversationEngine(scenario: scenario, mockSummary: zeroTurnSummary)
        let vm = RoleplayVoiceCallViewModel(engine: engine, callStartTime: Date())

        #expect(vm.isCallCancelled == false)
        #expect(vm.sessionSummary == nil)

        await vm.endCall()

        #expect(engine.endCallInvoked == true)
        #expect(vm.isCallCancelled == true)
        #expect(vm.sessionSummary == nil)
    }

    @Test("endCall preserves summary if call lasted > 3s even with 0 turns")
    @MainActor
    func endCallPreservesSummaryWhenDurationExceedsThreshold() async {
        let scenario = makeTestScenario()
        let zeroTurnSummary = RoleplaySessionSummary(
            scenarioId: scenario.id,
            totalTurns: 0,
            targetWordsAttempted: scenario.targetWordIds,
            targetWordsMastered: [],
            fluencyScore: 60,
            xpEarned: 10,
            refinements: []
        )
        let engine = MockVoiceConversationEngine(scenario: scenario, mockSummary: zeroTurnSummary)
        let vm = RoleplayVoiceCallViewModel(engine: engine, callStartTime: Date().addingTimeInterval(-4.0))

        await vm.endCall()

        #expect(engine.endCallInvoked == true)
        #expect(vm.isCallCancelled == false)
        #expect(vm.sessionSummary != nil)
        #expect(vm.sessionSummary?.totalTurns == 0)
    }

    @Test("endCall preserves summary if call lasted < 3s but turns > 0")
    @MainActor
    func endCallPreservesSummaryWhenTurnsGreaterThanZero() async {
        let scenario = makeTestScenario()
        let turnSummary = RoleplaySessionSummary(
            scenarioId: scenario.id,
            totalTurns: 1,
            targetWordsAttempted: scenario.targetWordIds,
            targetWordsMastered: ["espresso"],
            fluencyScore: 70,
            xpEarned: 25,
            refinements: []
        )
        let engine = MockVoiceConversationEngine(scenario: scenario, mockSummary: turnSummary)
        let vm = RoleplayVoiceCallViewModel(engine: engine, callStartTime: Date())

        await vm.endCall()

        #expect(engine.endCallInvoked == true)
        #expect(vm.isCallCancelled == false)
        #expect(vm.sessionSummary != nil)
        #expect(vm.sessionSummary?.totalTurns == 1)
    }

    @Test("ViewModel exposes suggestedResponses and audioLevel from engine")
    @MainActor
    func suggestedResponsesAndAudioLevelForwarding() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        engine.suggestedResponses = ["I'd like an espresso, please.", "A croissant as well."]
        engine.audioLevel = 0.42

        let vm = RoleplayVoiceCallViewModel(engine: engine)
        #expect(vm.suggestedResponses == ["I'd like an espresso, please.", "A croissant as well."])
        #expect(vm.audioLevel == 0.42)
    }

    @Test("ViewModel hints expanded state toggles correctly")
    @MainActor
    func hintsToggle() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        #expect(vm.isHintsExpanded == false)
        vm.toggleHints()
        #expect(vm.isHintsExpanded == true)
        vm.toggleHints()
        #expect(vm.isHintsExpanded == false)
    }

    @Test("ViewModel plays sample pronunciation via ttsService")
    @MainActor
    func playSamplePronunciationInvokesTTS() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        engine.suggestedResponses = ["I'd like an espresso, please."]
        let tts = MockTTS()
        let vm = RoleplayVoiceCallViewModel(engine: engine, ttsService: tts)

        #expect(!vm.suggestedResponses.isEmpty)
        let sample = vm.suggestedResponses[0]
        vm.playSamplePronunciation(sample)
        #expect(tts.lastSpokenText == "I'd like an espresso, please.")
    }

    @Test("Close button triggers discard alert when call is active")
    @MainActor
    func testCloseButtonTriggersDiscardAlertWhenCallInProgress() async {
        let viewModel = makeTestVoiceCallViewModel()
        viewModel.handleCloseButton()
        #expect(viewModel.showDiscardAlert == true)
        viewModel.cancelCall()
        #expect(viewModel.isCallCancelled == true)
        #expect(viewModel.sessionSummary == nil)
    }

    @Test("Quick exit within 3s without turns cancels immediately without alert")
    @MainActor
    func quickExitWithin3sWithoutTurnsCancelsImmediately() async {
        let viewModel = makeTestVoiceCallViewModel(callStartTime: Date())
        viewModel.handleCloseButton()
        #expect(viewModel.showDiscardAlert == false)
        #expect(viewModel.isCallCancelled == true)
        #expect(viewModel.sessionSummary == nil)
    }

    @Test("Close button within 3s but with turns triggers discard alert")
    @MainActor
    func closeButtonWithin3sWithTurnsTriggersDiscardAlert() async {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        engine.messages = [
            RoleplayMessage(sender: .character(name: "Alex"), text: "Hi!"),
            RoleplayMessage(sender: .user, text: "I want an espresso")
        ]
        let viewModel = RoleplayVoiceCallViewModel(engine: engine, callStartTime: Date())

        viewModel.handleCloseButton()
        #expect(viewModel.showDiscardAlert == true)
        #expect(viewModel.isCallCancelled == false)
    }

    @Test("Cancel call cancels engine and clears summary")
    @MainActor
    func cancelCallCancelsEngineAndClearsSummary() async {
        let scenario = makeTestScenario()
        let mockSummary = makeMockSummary(scenarioId: scenario.id)
        let engine = MockVoiceConversationEngine(scenario: scenario, mockSummary: mockSummary)
        let viewModel = RoleplayVoiceCallViewModel(engine: engine)

        viewModel.sessionSummary = mockSummary
        #expect(viewModel.sessionSummary != nil)

        viewModel.cancelCall()

        #expect(engine.cancelCallInvoked == true)
        #expect(viewModel.sessionSummary == nil)
        #expect(viewModel.isCallCancelled == true)
    }

    @Test("Hang-up button endCall produces summary for inline rendering")
    @MainActor
    func hangUpButtonEndCallProducesSummary() async {
        let scenario = makeTestScenario()
        let mockSummary = makeMockSummary(scenarioId: scenario.id)
        let engine = MockVoiceConversationEngine(scenario: scenario, mockSummary: mockSummary)
        let viewModel = RoleplayVoiceCallViewModel(engine: engine, callStartTime: Date().addingTimeInterval(-10.0))

        #expect(viewModel.sessionSummary == nil)
        await viewModel.endCall()

        #expect(engine.endCallInvoked == true)
        #expect(viewModel.sessionSummary != nil)
        #expect(viewModel.isCallCancelled == false)
    }

    @Test("finishSpeaking forwards to engine and automatically collapses scaffolding drawer")
    @MainActor
    func finishSpeakingCollapsesDrawerAndForwardsToEngine() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        vm.isHintsExpanded = true
        #expect(vm.isHintsExpanded == true)
        #expect(engine.finishUserTurnManuallyInvoked == false)

        vm.finishSpeaking()

        #expect(engine.finishUserTurnManuallyInvoked == true)
        #expect(vm.isHintsExpanded == false)
    }

    @Test("cancelCall collapses scaffolding drawer and cleans session")
    @MainActor
    func cancelCallCollapsesDrawerAndCleansSession() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        vm.isHintsExpanded = true
        vm.cancelCall()

        #expect(vm.isHintsExpanded == false)
        #expect(vm.isCallCancelled == true)
        #expect(engine.cancelCallInvoked == true)
    }

    @Test("Discard alert flow properly manages alert visibility and cancellation")
    @MainActor
    func discardAlertFlowManagement() {
        let scenario = makeTestScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        engine.messages = [
            RoleplayMessage(sender: .character(name: "Alex"), text: "Welcome!"),
            RoleplayMessage(sender: .user, text: "I'd like an espresso.")
        ]
        let vm = RoleplayVoiceCallViewModel(engine: engine, callStartTime: Date())

        #expect(vm.showDiscardAlert == false)
        #expect(vm.isCallCancelled == false)

        // User taps close button
        vm.handleCloseButton()
        #expect(vm.showDiscardAlert == true)
        #expect(vm.isCallCancelled == false)

        // User cancels discard alert dialog
        vm.showDiscardAlert = false
        #expect(vm.showDiscardAlert == false)
        #expect(vm.isCallCancelled == false)

        // User taps close again and confirms discard
        vm.handleCloseButton()
        #expect(vm.showDiscardAlert == true)
        vm.cancelCall()
        #expect(vm.isCallCancelled == true)
        #expect(vm.sessionSummary == nil)
        #expect(engine.cancelCallInvoked == true)
    }
}

// MARK: - Test Mock

@MainActor
private final class MockVoiceConversationEngine: VoiceConversationEngineProtocol {
    var state: VoiceCallState = .idle
    var isMuted: Bool = false
    var isSubtitlesVisible: Bool = true
    var scenario: RoleplayScenario
    var messages: [RoleplayMessage] = []
    var masteredTargetWords: Set<String> = []
    var audioLevel: Float = 0.0
    var suggestedResponses: [String] = []

    var startCallInvoked = false
    var finishUserTurnManuallyInvoked = false
    var toggleMuteInvoked = false
    var toggleSubtitlesInvoked = false
    var endCallInvoked = false
    var cancelCallInvoked = false
    var mockSummaryToReturn: RoleplaySessionSummary

    init(
        scenario: RoleplayScenario,
        mockSummary: RoleplaySessionSummary? = nil
    ) {
        self.scenario = scenario
        self.mockSummaryToReturn = mockSummary ?? RoleplaySessionSummary(
            scenarioId: scenario.id,
            totalTurns: 3,
            targetWordsAttempted: scenario.targetWordIds,
            targetWordsMastered: scenario.targetWordIds,
            fluencyScore: 90,
            xpEarned: 40,
            refinements: []
        )
    }

    func startCall() async {
        startCallInvoked = true
        state = .speaking(characterText: scenario.initialGreeting)
    }

    func finishUserTurnManually() {
        finishUserTurnManuallyInvoked = true
    }

    func toggleMute() {
        toggleMuteInvoked = true
        isMuted.toggle()
    }

    func toggleSubtitles() {
        toggleSubtitlesInvoked = true
        isSubtitlesVisible.toggle()
    }

    func cancelCall() {
        cancelCallInvoked = true
        state = .ended
    }

    func endCall() async -> RoleplaySessionSummary {
        endCallInvoked = true
        state = .ended
        return mockSummaryToReturn
    }
}

@MainActor
private final class MockTTS: TextToSpeechProtocol {
    var lastSpokenText: String?
    var isSpeaking: Bool = false

    func speak(text: String, rate: Float, locale: String) {
        lastSpokenText = text
    }

    func stop() {}
}
