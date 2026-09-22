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
}
