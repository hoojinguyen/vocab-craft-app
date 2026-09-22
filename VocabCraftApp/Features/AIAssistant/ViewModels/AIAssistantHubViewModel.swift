import Foundation
import Observation

@Observable
@MainActor
public final class AIAssistantHubViewModel {
    public var scenarios: [RoleplayScenario] = []
    public var dailyScenario: RoleplayScenario?
    public var selectedTopic: ScenarioTopic?
    public var isLoading: Bool = false
    public var errorMessage: String?

    private let fetchScenariosUseCase: FetchRoleplayScenariosUseCase

    public init(fetchScenariosUseCase: FetchRoleplayScenariosUseCase) {
        self.fetchScenariosUseCase = fetchScenariosUseCase
    }

    public func loadScenarios(weakWords: [String] = []) async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await fetchScenariosUseCase.execute(userWeakWords: weakWords)
            self.scenarios = loaded
            self.dailyScenario = loaded.first
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    public var filteredScenarios: [RoleplayScenario] {
        guard let topic = selectedTopic else { return scenarios }
        return scenarios.filter { $0.topic == topic }
    }
}
