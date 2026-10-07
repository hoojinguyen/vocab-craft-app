import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AppContainer AI Tests")
struct AppContainerAITests {
    @Test("AppContainer exposes configured aiPackRegistry")
    @MainActor
    func testAppContainerRegistryExposure() {
        let container = AppContainer()
        #expect(container.aiPackRegistry.packCatalog.count >= 2)
    }

    @Test("AppContainer builds voice call view model using active pack")
    @MainActor
    func testVoiceCallViewModelCreation() {
        let container = AppContainer()
        let vm = container.makeRoleplayVoiceCallViewModel(for: RoleplayScenario.cafeMock)
        #expect(vm.engine is TurnBasedVoiceConversationEngine)
    }

    @Test("AppContainer creates AI assistant hub view model")
    @MainActor
    func testAppContainerCreatesAIAssistantViewModels() {
        let container = AppContainer()
        let hubVM = container.makeAIAssistantHubViewModel()
        #expect(hubVM.scenarios.isEmpty)
    }

    @Test("AppContainer creates roleplay room view model")
    @MainActor
    func testAppContainerCreatesRoleplayRoomViewModel() {
        let container = AppContainer()
        let roomVM = container.makeRoleplayRoomViewModel(for: RoleplayScenario.cafeMock)
        #expect(roomVM.scenario.id == RoleplayScenario.cafeMock.id)
        #expect(roomVM.messages.count == 1)
    }

    @Test("AppContainer creates execute roleplay turn use case")
    @MainActor
    func testAppContainerCreatesExecuteRoleplayTurnUseCase() {
        let container = AppContainer()
        let useCase = container.makeExecuteRoleplayTurnUseCase()
        #expect(useCase != nil)
    }

    @Test("UserSettingsStore gemini api key configuration detection")
    @MainActor
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
