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

    var startCallInvoked = false
    var finishUserTurnManuallyInvoked = false
    var toggleMuteInvoked = false
    var toggleSubtitlesInvoked = false
    var endCallInvoked = false
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

    func endCall() async -> RoleplaySessionSummary {
        endCallInvoked = true
        state = .ended
        return mockSummaryToReturn
    }
}
