import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AppContainer AI Assistant Integration Tests")
struct AppContainerAITests {
    @Test @MainActor
    func testAppContainerCreatesAIAssistantViewModels() {
        let container = AppContainer()
        let hubVM = container.makeAIAssistantHubViewModel()
        #expect(hubVM.scenarios.isEmpty)
    }

    @Test @MainActor
    func testAppContainerCreatesRoleplayRoomViewModel() {
        let container = AppContainer()
        let scenario = RoleplayScenario(
            id: "test",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hello",
            targetWordIds: ["espresso"],
            iconSymbol: "cup.and.saucer"
        )
        let roomVM = container.makeRoleplayRoomViewModel(for: scenario)
        #expect(roomVM.scenario.id == "test")
        #expect(roomVM.messages.count == 1)
    }

    @Test @MainActor
    func testAppContainerCreatesRoleplayVoiceCallViewModelWithResilientEngine() {
        let container = AppContainer()
        let scenario = RoleplayScenario(
            id: "voice-test",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Alex",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hello",
            targetWordIds: ["espresso"],
            iconSymbol: "cup.and.saucer"
        )
        let voiceCallVM = container.makeRoleplayVoiceCallViewModel(for: scenario)
        #expect(voiceCallVM.engine is ResilientConversationSpeechEngine)
    }

    @Test @MainActor
    func testDynamicLLMProviderSwitchingWithApiKey() {
        let defaults = UserDefaults(suiteName: "test_dynamic_llm_\(UUID().uuidString)") ?? .standard
        let store = UserSettingsStore(defaults: defaults)
        let container = AppContainer(userSettingsStore: store)

        // Initially empty key -> fallback mock provider (IntelligentMockLLMProvider or MockLLMProvider)
        #expect(container.llmProvider is IntelligentMockLLMProvider || container.llmProvider is MockLLMProvider)

        // Set API Key -> GeminiLLMProvider
        store.geminiApiKey = "AIzaSyFakeTestKey12345"
        #expect(container.llmProvider is GeminiLLMProvider)

        // Clear API Key -> fallback mock provider
        store.geminiApiKey = ""
        #expect(container.llmProvider is IntelligentMockLLMProvider || container.llmProvider is MockLLMProvider)
    }

    @Test @MainActor
    func testDynamicLLMProviderWhitespaceAndPersistence() {
        let suiteName = "test_persistence_llm_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let store1 = UserSettingsStore(defaults: defaults)
        let container = AppContainer(userSettingsStore: store1)

        // Whitespace only treated as empty -> fallback mock provider
        store1.geminiApiKey = "   \n  \t  "
        #expect(container.llmProvider is IntelligentMockLLMProvider || container.llmProvider is MockLLMProvider)

        // Save valid key
        store1.geminiApiKey = "AIzaSySavedKey789"
        #expect(container.llmProvider is GeminiLLMProvider)

        // Reload store from same defaults -> key persists
        let store2 = UserSettingsStore(defaults: defaults)
        let container2 = AppContainer(userSettingsStore: store2)
        #expect(store2.geminiApiKey == "AIzaSySavedKey789")
        #expect(container2.llmProvider is GeminiLLMProvider)
    }

    @Test @MainActor
    func testIsGeminiApiKeyConfigured() {
        let defaults = UserDefaults(suiteName: "test_key_configured_\(UUID().uuidString)") ?? .standard
        let store = UserSettingsStore(defaults: defaults)

        #expect(!store.isGeminiApiKeyConfigured)

        store.geminiApiKey = "   \n  \t  "
        #expect(!store.isGeminiApiKeyConfigured)

        store.geminiApiKey = "AIzaSyValidKey123"
        #expect(store.isGeminiApiKeyConfigured)

        store.geminiApiKey = ""
        #expect(!store.isGeminiApiKeyConfigured)
    }
}
