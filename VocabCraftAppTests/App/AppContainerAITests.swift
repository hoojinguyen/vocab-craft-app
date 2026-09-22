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
    func testDynamicLLMProviderSwitchingWithApiKey() {
        let defaults = UserDefaults(suiteName: "test_dynamic_llm_\(UUID().uuidString)") ?? .standard
        let store = UserSettingsStore(defaults: defaults)
        let container = AppContainer(userSettingsStore: store)

        // Initially empty key -> MockLLMProvider
        #expect(container.llmProvider is MockLLMProvider)

        // Set API Key -> GeminiLLMProvider
        store.geminiApiKey = "AIzaSyFakeTestKey12345"
        #expect(container.llmProvider is GeminiLLMProvider)

        // Clear API Key -> MockLLMProvider
        store.geminiApiKey = ""
        #expect(container.llmProvider is MockLLMProvider)
    }

    @Test @MainActor
    func testDynamicLLMProviderWhitespaceAndPersistence() {
        let suiteName = "test_persistence_llm_\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        let store1 = UserSettingsStore(defaults: defaults)
        let container = AppContainer(userSettingsStore: store1)

        // Whitespace only treated as empty -> MockLLMProvider
        store1.geminiApiKey = "   \n  \t  "
        #expect(container.llmProvider is MockLLMProvider)

        // Save valid key
        store1.geminiApiKey = "AIzaSySavedKey789"
        #expect(container.llmProvider is GeminiLLMProvider)

        // Reload store from same defaults -> key persists
        let store2 = UserSettingsStore(defaults: defaults)
        let container2 = AppContainer(userSettingsStore: store2)
        #expect(store2.geminiApiKey == "AIzaSySavedKey789")
        #expect(container2.llmProvider is GeminiLLMProvider)
    }
}
