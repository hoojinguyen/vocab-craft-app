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
}
