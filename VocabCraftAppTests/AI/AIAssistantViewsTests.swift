import CraftUIKit
import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("AI Assistant Views Tests")
struct AIAssistantViewsTests {
    private func makeSampleScenario() -> RoleplayScenario {
        RoleplayScenario(
            id: "test-cafe",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome! What can I get started for you?",
            targetWordIds: ["latte", "croissant"],
            iconSymbol: "cup.and.saucer"
        )
    }

    @Test @MainActor
    func testAIAssistantHubViewInitialization() async {
        let container = AppContainer()
        let vm = container.makeAIAssistantHubViewModel()
        let view = AIAssistantHubView(viewModel: vm)
        _ = view.body

        await vm.loadScenarios()
        #expect(!vm.scenarios.isEmpty)
        #expect(vm.dailyScenario != nil)
    }

    @Test @MainActor
    func testRoleplayRoomViewInitializationAndSending() async {
        let scenario = makeSampleScenario()
        let executeTurnUseCase = ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider())
        let completeSessionUseCase = CompleteRoleplaySessionUseCase()
        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeTurnUseCase,
            completeSessionUseCase: completeSessionUseCase
        )

        var dismissed = false
        let view = RoleplayRoomView(viewModel: vm, onDismiss: { dismissed = true })
        _ = view.body
        #expect(!dismissed)
        #expect(vm.messages.count == 1)

        await vm.sendMessage("Can I have a latte, please?")
        #expect(vm.messages.count >= 2)
        #expect(vm.masteredWords.contains("latte"))

        await vm.finishSession()
        #expect(vm.sessionSummary != nil)
    }

    @Test @MainActor
    func testRoleplayRoomViewModelSpeechPlayback() async {
        let scenario = makeSampleScenario()
        let mockTTS = MockTextToSpeechService()
        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider()),
            completeSessionUseCase: CompleteRoleplaySessionUseCase(),
            ttsService: mockTTS
        )

        vm.playSpeech(for: "Welcome to the coffee shop!")
        #expect(mockTTS.isSpeaking == true)

        mockTTS.stop()
        await vm.sendMessage("Hello!")
        // Verify auto-play triggered for character reply
        #expect(mockTTS.isSpeaking == true)
    }

    @Test @MainActor
    func testRoleplaySummaryViewInitialization() {
        let summary = RoleplaySessionSummary(
            scenarioId: "test-cafe",
            totalTurns: 3,
            targetWordsAttempted: ["latte", "croissant"],
            targetWordsMastered: ["latte"],
            fluencyScore: 85,
            xpEarned: 35,
            refinements: [
                SentenceRefinementPair(
                    originalUserSentence: "I want latte",
                    refinedNativeSentence: "Could I please get a latte?"
                )
            ]
        )

        var dismissed = false
        let summaryView = RoleplaySummaryView(summary: summary) {
            dismissed = true
        }
        _ = summaryView.body
        #expect(summaryView.summary.fluencyScore == 85)
        #expect(summaryView.summary.targetWordsMastered.count == 1)
        #expect(summaryView.summary.refinements.count == 1)

        summaryView.onDismiss()
        #expect(dismissed)
    }

    @Test @MainActor
    func testRoleplaySummaryView_dualCTAsAndBreakdown() {
        let refinement = SentenceRefinementPair(
            originalUserSentence: "I want latte",
            refinedNativeSentence: "Could I please get a latte?"
        )
        let summary = RoleplaySessionSummary(
            scenarioId: "test-cafe",
            totalTurns: 3,
            targetWordsAttempted: ["latte", "croissant"],
            targetWordsMastered: ["latte"],
            fluencyScore: 85,
            xpEarned: 35,
            refinements: [refinement]
        )

        var reflexTriggered = false
        var dismissed = false
        var savedPair: SentenceRefinementPair?
        var removedPair: SentenceRefinementPair?

        let summaryView = RoleplaySummaryView(
            summary: summary,
            onStartReflex: { reflexTriggered = true },
            onSaveToVault: { savedPair = $0 },
            onRemoveFromVault: { removedPair = $0 },
            onDismiss: { dismissed = true }
        )

        _ = summaryView.body

        #expect(summaryView.masteredWords == ["latte"])
        #expect(summaryView.unmasteredWords == ["croissant"])

        summaryView.onStartReflex?()
        #expect(reflexTriggered)

        summaryView.onDismiss()
        #expect(dismissed)

        summaryView.onSaveToVault?(refinement)
        #expect(savedPair == refinement)

        summaryView.onRemoveFromVault?(refinement)
        #expect(removedPair == refinement)
    }

    @Test @MainActor
    func testRoleplaySummaryViewConfettiThreshold() {
        let highSummary = RoleplaySessionSummary(
            scenarioId: "test-cafe",
            totalTurns: 2,
            targetWordsAttempted: ["latte", "croissant"],
            targetWordsMastered: ["latte", "croissant"],
            fluencyScore: 90,
            xpEarned: 40,
            refinements: []
        )
        let highView = RoleplaySummaryView(summary: highSummary, onDismiss: {})
        _ = highView.body

        let emptySummary = RoleplaySessionSummary(
            scenarioId: "test-cafe",
            totalTurns: 0,
            targetWordsAttempted: [],
            targetWordsMastered: [],
            fluencyScore: 60,
            xpEarned: 10,
            refinements: []
        )
        let emptyView = RoleplaySummaryView(summary: emptySummary, onDismiss: {})
        _ = emptyView.body

        let lowSummary = RoleplaySessionSummary(
            scenarioId: "test-cafe",
            totalTurns: 2,
            targetWordsAttempted: ["latte", "croissant"],
            targetWordsMastered: ["latte"],
            fluencyScore: 50,
            xpEarned: 15,
            refinements: []
        )
        let lowView = RoleplaySummaryView(summary: lowSummary, onDismiss: {})
        _ = lowView.body
    }

    @Test @MainActor
    func testHomepageViewEmbedsAIAssistantHubView() {
        let container = AppContainer()
        let homeVM = container.makeHomepageViewModel()
        let homeView = HomepageView(viewModel: homeVM)
        _ = homeView.body
        #expect(container.userSettingsStore.hasCompletedOnboarding)
    }

    @Test @MainActor
    func testAIConfigSheetRendersAndSavesKey() {
        let defaults = UserDefaults(suiteName: "test_ai_config_sheet_\(UUID().uuidString)") ?? .standard
        let store = UserSettingsStore(defaults: defaults)
        var dismissed = false
        let sheet = AIConfigSheet(store: store) {
            dismissed = true
        }
        _ = sheet.body

        sheet.save("AIzaSyTestKey12345")
        #expect(store.geminiApiKey == "AIzaSyTestKey12345")

        sheet.onDismiss()
        #expect(dismissed)
    }

    @Test @MainActor
    func testSettingsAICardRendersAndUpdatesKey() {
        let defaults = UserDefaults(suiteName: "test_settings_ai_card_\(UUID().uuidString)") ?? .standard
        let store = UserSettingsStore(defaults: defaults)
        let card = SettingsAICard(store: store)
        _ = card.body
        #expect(store.geminiApiKey.isEmpty)

        store.geminiApiKey = "test-gemini-key"
        #expect(store.geminiApiKey == "test-gemini-key")
        _ = card.body
    }

    @Test @MainActor
    func testSettingsViewIncludesAICard() {
        let defaults = UserDefaults(suiteName: "test_settings_view_\(UUID().uuidString)") ?? .standard
        let store = UserSettingsStore(defaults: defaults)
        let vm = SettingsViewModel(
            store: store,
            ttsService: MockTextToSpeechService(),
            resetProgressUseCase: ResetUserProgressUseCase(srsRepository: MockSRSRepository())
        )
        let view = SettingsView(viewModel: vm)
        _ = view.body
    }

    @Test @MainActor
    func testAIAssistantHubViewWithStoreAndBanner() async {
        let defaults = UserDefaults(suiteName: "test_ai_hub_store_\(UUID().uuidString)") ?? .standard
        let store = UserSettingsStore(defaults: defaults)
        let container = AppContainer(userSettingsStore: store)
        let vm = container.makeAIAssistantHubViewModel()
        let view = AIAssistantHubView(viewModel: vm, store: store)
        _ = view.body

        await vm.loadScenarios()
        #expect(!vm.scenarios.isEmpty)
    }

    // MARK: - Task 2: EngineStatusPill & CompanionHeroCard Tests

    @Test @MainActor
    func test_engineStatusPill_renders_proper_badge_for_modes() {
        var onDeviceTapped = false
        let onDevicePill = EngineStatusPill(isCloudConfigured: false) {
            onDeviceTapped = true
        }
        #expect(!onDevicePill.isCloudConfigured)
        _ = onDevicePill.body
        onDevicePill.onTap()
        #expect(onDeviceTapped)

        var cloudTapped = false
        let cloudPill = EngineStatusPill(isCloudConfigured: true) {
            cloudTapped = true
        }
        #expect(cloudPill.isCloudConfigured)
        _ = cloudPill.body
        cloudPill.onTap()
        #expect(cloudTapped)
    }

    @Test @MainActor
    func test_companionHeroCard_renders_and_dispatches_actions() {
        let scenario = makeSampleScenario()
        var callStarted = false
        var chatStarted = false

        let heroCard = CompanionHeroCard(
            scenario: scenario,
            wordsLearnedCount: 3,
            onStartCall: { callStarted = true },
            onStartChat: { chatStarted = true }
        )

        #expect(heroCard.scenario == scenario)
        #expect(heroCard.wordsLearnedCount == 3)
        _ = heroCard.body

        heroCard.onStartCall()
        #expect(callStarted)

        heroCard.onStartChat()
        #expect(chatStarted)
    }

    @Test @MainActor
    func test_companionHeroCard_handles_zero_and_large_words_learned() {
        let scenario = makeSampleScenario()

        let zeroWordsCard = CompanionHeroCard(
            scenario: scenario,
            wordsLearnedCount: 0,
            onStartCall: {},
            onStartChat: {}
        )
        #expect(zeroWordsCard.wordsLearnedCount == 0)
        _ = zeroWordsCard.body

        let manyWordsCard = CompanionHeroCard(
            scenario: scenario,
            wordsLearnedCount: 42,
            onStartCall: {},
            onStartChat: {}
        )
        #expect(manyWordsCard.wordsLearnedCount == 42)
        _ = manyWordsCard.body
    }

    @Test @MainActor
    func test_companionHeroCard_greetingKeyFormatting() {
        let greetingKey = AppStrings.AIAssistant.companionGreetingKey(wordsCount: 5)
        #expect(String(reflecting: greetingKey).contains("app.ai.hub.companion.greeting_format"))
    }

    // MARK: - Task 3: ScenarioListCard Tests

    @Test @MainActor
    func test_scenarioListCard_renders_and_dispatches_actions() {
        let scenario = makeSampleScenario()
        var voiceStarted = false
        var textStarted = false

        let card = ScenarioListCard(
            scenario: scenario,
            onStartVoice: { voiceStarted = true },
            onStartText: { textStarted = true }
        )

        #expect(card.scenario == scenario)
        _ = card.body

        card.onStartVoice()
        #expect(voiceStarted)

        card.onStartText()
        #expect(textStarted)
    }

    @Test @MainActor
    func test_scenarioListCard_handles_various_target_words() {
        let emptyScenario = RoleplayScenario(
            id: "test-empty",
            titleKey: "app.ai_assistant.scenario.hotel.title",
            descriptionKey: "app.ai_assistant.scenario.hotel.desc",
            topic: .travel,
            difficulty: .intermediate,
            characterName: "Receptionist",
            characterRole: "Front Desk",
            userRole: "Guest",
            initialGreeting: "Welcome to Grand Hotel!",
            targetWordIds: [],
            iconSymbol: "building.2"
        )
        let emptyCard = ScenarioListCard(
            scenario: emptyScenario,
            onStartVoice: {},
            onStartText: {}
        )
        #expect(emptyCard.scenario.targetWordIds.isEmpty)
        _ = emptyCard.body

        let manyScenario = RoleplayScenario(
            id: "test-many",
            titleKey: "app.ai_assistant.scenario.interview.title",
            descriptionKey: "app.ai_assistant.scenario.interview.desc",
            topic: .interview,
            difficulty: .advanced,
            characterName: "Interviewer",
            characterRole: "Hiring Manager",
            userRole: "Candidate",
            initialGreeting: "Tell me about yourself.",
            targetWordIds: ["leadership", "collaboration", "initiative", "deadline", "strategy"],
            iconSymbol: "briefcase"
        )
        let manyCard = ScenarioListCard(
            scenario: manyScenario,
            onStartVoice: {},
            onStartText: {}
        )
        #expect(manyCard.scenario.targetWordIds.count == 5)
        _ = manyCard.body
    }

    // MARK: - Task 4: RoleplayVoiceCallView Tests

    @Test @MainActor
    func test_roleplayVoiceCallView_controlPropertiesAndMappings() {
        // Microphone symbol mapping (correcting .audio to .mic)
        #expect(RoleplayVoiceCallView.micSymbol(isMuted: false) == .mic)
        #expect(RoleplayVoiceCallView.micSymbol(isMuted: true) == .micSlash)

        // Microphone accessibility keys
        #expect(RoleplayVoiceCallView.micAccessibilityKey(isMuted: false) == AppStrings.AIAssistant.callMicMute)
        #expect(RoleplayVoiceCallView.micAccessibilityKey(isMuted: true) == AppStrings.AIAssistant.callMicUnmute)

        // Subtitles symbol mapping (using quoteBubble)
        #expect(RoleplayVoiceCallView.subtitlesSymbol() == .quoteBubble)

        // Live badge key
        #expect(RoleplayVoiceCallView.liveBadgeKey == AppStrings.AIAssistant.callLiveBadge)
    }

    @Test @MainActor
    func test_roleplayVoiceCallView_rendersActiveCallAndStates() async {
        let scenario = makeSampleScenario()
        let engine = MockVoiceConversationEngine(scenario: scenario)
        let vm = RoleplayVoiceCallViewModel(engine: engine)

        var dismissed = false
        let view = RoleplayVoiceCallView(viewModel: vm, onDismiss: { dismissed = true })
        _ = view.body

        // Verify startCall triggered
        await vm.startCall()
        #expect(engine.startCallInvoked)
        _ = view.body

        // Toggle mute and check state
        vm.toggleMute()
        #expect(vm.isMuted)
        _ = view.body

        // Toggle captions and check state
        vm.toggleSubtitles()
        #expect(!vm.isSubtitlesVisible)
        _ = view.body

        // Finish call
        await vm.endCall()
        #expect(vm.sessionSummary != nil)
        _ = view.body
        #expect(!dismissed)
    }

    // MARK: - Task 5: SentenceStarterChipsBar & InteractiveTargetWordsStrip Tests

    @Test @MainActor
    func test_sentenceStarterChipsBar_rendersAndSelectsPrompt() {
        var selectedPrompt: String?
        let prompts = [
            "Hi! I'd like to order a warm beverage, please.",
            "Could I get an iced coffee?"
        ]
        let bar = SentenceStarterChipsBar(prompts: prompts) { prompt in
            selectedPrompt = prompt
        }

        #expect(bar.prompts.count == 2)
        #expect(bar.prompts.first == "Hi! I'd like to order a warm beverage, please.")
        _ = bar.body

        bar.onSelectPrompt("Could I get an iced coffee?")
        #expect(selectedPrompt == "Could I get an iced coffee?")
    }

    @Test @MainActor
    func test_sentenceStarterChipsBar_handlesEmptyPrompts() {
        let bar = SentenceStarterChipsBar(prompts: []) { _ in }
        #expect(bar.prompts.isEmpty)
        _ = bar.body
    }

    @Test @MainActor
    func test_interactiveTargetWordsStrip_rendersAndDispatchesTap() {
        var tappedWord: String?
        let targetWords = ["beverage", "pastry", "complimentary"]
        let mastered: Set<String> = ["beverage"]

        let strip = InteractiveTargetWordsStrip(
            targetWords: targetWords,
            masteredWords: mastered
        ) { word in
            tappedWord = word
        }

        #expect(strip.targetWords.count == 3)
        #expect(strip.masteredWords.contains("beverage"))
        #expect(!strip.masteredWords.contains("pastry"))
        _ = strip.body

        strip.onWordTap("pastry")
        #expect(tappedWord == "pastry")
    }

    @Test @MainActor
    func test_interactiveTargetWordsStrip_handlesEmptyWords() {
        let strip = InteractiveTargetWordsStrip(targetWords: [], masteredWords: []) { _ in }
        #expect(strip.targetWords.isEmpty)
        _ = strip.body
    }

    @Test @MainActor
    func test_roleplayRoomView_withScaffoldingAndRefinements() async {
        let scenario = RoleplayScenario(
            id: "test-cafe",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome! What can I get started for you?",
            targetWordIds: ["latte", "croissant"],
            iconSymbol: "cup.and.saucer",
            starterSuggestions: ["I'd like a latte, please.", "Do you have croissants?"]
        )
        let executeTurnUseCase = ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider())
        let completeSessionUseCase = CompleteRoleplaySessionUseCase()
        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeTurnUseCase,
            completeSessionUseCase: completeSessionUseCase
        )

        var dismissed = false
        let view = RoleplayRoomView(viewModel: vm, onDismiss: { dismissed = true })
        _ = view.body

        // Simulate choosing a starter suggestion
        vm.inputText = scenario.starterSuggestions[0]
        #expect(vm.inputText == "I'd like a latte, please.")

        await vm.sendMessage(vm.inputText)
        #expect(vm.messages.count >= 2)

        // Expand refinement if message has one
        if let userMsg = vm.messages.first(where: { $0.isUser }) {
            vm.toggleRefinement(for: userMsg.id)
            #expect(vm.messages.first(where: { $0.id == userMsg.id })?.isRefinementExpanded == true)
        }
        _ = view.body
        #expect(!dismissed)
    }

    @Test @MainActor
    func test_roleplayRoomView_suggestedChipsBarRenderingAndSelection() async {
        let scenario = RoleplayScenario(
            id: "test-cafe",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome! What can I get started for you?",
            targetWordIds: ["latte"],
            iconSymbol: "cup.and.saucer",
            starterSuggestions: ["I'd like a latte, please.", "What coffee do you have?"]
        )
        let executeTurnUseCase = ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider())
        let completeSessionUseCase = CompleteRoleplaySessionUseCase()
        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeTurnUseCase,
            completeSessionUseCase: completeSessionUseCase
        )

        let view = RoleplayRoomView(viewModel: vm, onDismiss: {})
        _ = view.body

        #expect(vm.suggestedResponses == scenario.starterSuggestions)
        #expect(vm.isSuggestionsVisible)

        vm.selectSuggestion(scenario.starterSuggestions[0])
        #expect(vm.inputText == scenario.starterSuggestions[0])
        _ = view.body

        vm.toggleSuggestionsVisibility()
        #expect(!vm.isSuggestionsVisible)
        _ = view.body

        vm.toggleSuggestionsVisibility()
        #expect(vm.isSuggestionsVisible)
        _ = view.body
    }
}
