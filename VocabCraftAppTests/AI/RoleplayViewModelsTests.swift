import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AI Assistant ViewModels Tests", .serialized)
struct RoleplayViewModelsTests {
    // MARK: - AIAssistantHubViewModel Tests

    @Test @MainActor
    func testHubViewModelLoadsScenarios() async {
        let fetchUseCase = FetchRoleplayScenariosUseCase()
        let vm = AIAssistantHubViewModel(fetchScenariosUseCase: fetchUseCase)

        #expect(vm.scenarios.isEmpty)
        #expect(vm.dailyScenario == nil)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)

        await vm.loadScenarios()

        #expect(!vm.scenarios.isEmpty)
        #expect(vm.dailyScenario != nil)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test @MainActor
    func testHubViewModelFiltersByTopic() async {
        let fetchUseCase = FetchRoleplayScenariosUseCase()
        let vm = AIAssistantHubViewModel(fetchScenariosUseCase: fetchUseCase)

        await vm.loadScenarios()
        #expect(vm.filteredScenarios.count == vm.scenarios.count)

        vm.selectedTopic = .dining
        #expect(!vm.filteredScenarios.isEmpty)
        #expect(vm.filteredScenarios.allSatisfy { $0.topic == .dining })

        vm.selectedTopic = nil
        #expect(vm.filteredScenarios.count == vm.scenarios.count)
    }

    @Test @MainActor
    func testHubViewModelLoadsWithWeakWords() async {
        let fetchUseCase = FetchRoleplayScenariosUseCase()
        let vm = AIAssistantHubViewModel(fetchScenariosUseCase: fetchUseCase)

        await vm.loadScenarios(weakWords: ["complimentary", "beverage", "pastry"])
        #expect(!vm.scenarios.isEmpty)
        #expect(vm.dailyScenario?.id == "daily-adaptive")
        #expect(vm.dailyScenario?.targetWordIds == ["complimentary", "beverage", "pastry"])
    }

    // MARK: - RoleplayRoomViewModel Tests

    @Test @MainActor
    func testRoleplayRoomViewModelInitialGreeting() {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "Here is your drink!",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: "Good phrasing",
            pedagogicalNote: nil
        )
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider(mockTurnOutput: mockOutput))
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let scenario = RoleplayScenario(
            id: "cafe",
            titleKey: "Cafe",
            descriptionKey: "Desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome to Craft Cafe!",
            targetWordIds: ["beverage"],
            iconSymbol: "cup.fill"
        )

        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        #expect(vm.messages.count == 1)
        #expect(vm.messages.first?.isUser == false)
        #expect(vm.messages.first?.text == "Welcome to Craft Cafe!")
        #expect(vm.messages.first?.characterName == "Barista")
        #expect(vm.masteredWords.isEmpty)
        #expect(vm.isSending == false)
        #expect(vm.sessionSummary == nil)
    }

    @Test @MainActor
    func testRoleplayRoomViewModelAppendsTurnsAndDetectsWords() async {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "Here is your drink!",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: "Could I have a beverage please?",
            pedagogicalNote: "Polite phrasing"
        )
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider(mockTurnOutput: mockOutput))
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let scenario = RoleplayScenario(
            id: "cafe",
            titleKey: "Cafe",
            descriptionKey: "Desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome!",
            targetWordIds: ["beverage", "pastry"],
            iconSymbol: "cup.fill"
        )

        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        #expect(vm.messages.count == 1)
        await vm.sendMessage("I want a beverage please")

        #expect(vm.messages.count == 3) // Greeting + User + AI
        let userMsg = vm.messages[1]
        let aiMsg = vm.messages[2]

        #expect(userMsg.isUser == true)
        #expect(userMsg.text == "I want a beverage please")
        #expect(userMsg.refinementSuggestion == "Could I have a beverage please?")

        #expect(aiMsg.isUser == false)
        #expect(aiMsg.text == "Here is your drink!")
        #expect(aiMsg.characterName == "Barista")

        #expect(vm.masteredWords.contains("beverage"))
        #expect(!vm.isSending)
    }

    @Test @MainActor
    func testRoleplayRoomViewModelIgnoresEmptyOrWhitespaceMessage() async {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "Here is your drink!",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: nil,
            pedagogicalNote: nil
        )
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider(mockTurnOutput: mockOutput))
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let scenario = RoleplayScenario(
            id: "cafe",
            titleKey: "Cafe",
            descriptionKey: "Desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome!",
            targetWordIds: ["beverage"],
            iconSymbol: "cup.fill"
        )

        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        await vm.sendMessage("")
        #expect(vm.messages.count == 1)

        await vm.sendMessage("   \n\t  ")
        #expect(vm.messages.count == 1)
    }

    @Test @MainActor
    func testRoleplayRoomViewModelToggleRefinement() async {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "Sure thing!",
            targetWordsUsed: [],
            refinementSuggestion: "May I have some water?",
            pedagogicalNote: nil
        )
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider(mockTurnOutput: mockOutput))
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let scenario = RoleplayScenario(
            id: "cafe",
            titleKey: "Cafe",
            descriptionKey: "Desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome!",
            targetWordIds: ["beverage"],
            iconSymbol: "cup.fill"
        )

        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        await vm.sendMessage("Water please")
        #expect(vm.messages.count == 3)

        let userMsg = vm.messages[1]
        #expect(userMsg.isRefinementExpanded == false)

        vm.toggleRefinement(for: userMsg.id)
        #expect(vm.messages[1].isRefinementExpanded == true)

        vm.toggleRefinement(for: userMsg.id)
        #expect(vm.messages[1].isRefinementExpanded == false)

        // Toggling non-existent ID does nothing
        vm.toggleRefinement(for: UUID())
        #expect(vm.messages[1].isRefinementExpanded == false)
    }

    @Test @MainActor
    func testRoleplayRoomViewModelFinishSession() async {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "Here you go!",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: "Could I have a beverage?",
            pedagogicalNote: nil
        )
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: MockLLMProvider(mockTurnOutput: mockOutput))
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let scenario = RoleplayScenario(
            id: "cafe",
            titleKey: "Cafe",
            descriptionKey: "Desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome!",
            targetWordIds: ["beverage", "pastry"],
            iconSymbol: "cup.fill"
        )

        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        await vm.sendMessage("I want a beverage")
        #expect(vm.sessionSummary == nil)

        await vm.finishSession()

        #expect(vm.sessionSummary != nil)
        #expect(vm.sessionSummary?.scenarioId == "cafe")
        #expect(vm.sessionSummary?.totalTurns == 1)
        #expect(vm.sessionSummary?.targetWordsMastered == ["beverage"])
        #expect(vm.sessionSummary?.refinements.count == 1)
        #expect(vm.sessionSummary?.refinements.first?.originalUserSentence == "I want a beverage")
        #expect(vm.sessionSummary?.refinements.first?.refinedNativeSentence == "Could I have a beverage?")
    }

    @Test @MainActor
    func testRoleplayRoomViewModelFallbackOnUseCaseError() async {
        let mockProvider = MockLLMProvider()
        mockProvider.shouldThrowError = true
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockProvider)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let scenario = RoleplayScenario(
            id: "cafe",
            titleKey: "Cafe",
            descriptionKey: "Desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Welcome!",
            targetWordIds: ["beverage"],
            iconSymbol: "cup.fill"
        )

        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        await vm.sendMessage("Hello barista")
        #expect(vm.messages.count == 3) // Greeting + User + Fallback
        let fallbackMsg = vm.messages[2]
        #expect(fallbackMsg.isUser == false)
        #expect(fallbackMsg.text == AppStrings.AIAssistant.fallbackReplyText)
        #expect(fallbackMsg.characterName == "Barista")
        #expect(!vm.isSending)
    }

    @Test("RoleplayRoomViewModel initializes with starter suggestions and updates on turn completion")
    @MainActor
    func testSuggestedResponsesLifecycle() async throws {
        let scenario = RoleplayScenario(
            id: "cafe",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi!",
            targetWordIds: ["latte"],
            iconSymbol: "cup",
            starterSuggestions: ["I'd like a latte, please.", "What coffee do you have?"]
        )

        let mockOutput = RoleplayTurnOutput(
            characterReply: "Sure, whole or oat milk?",
            targetWordsUsed: ["latte"],
            refinementSuggestion: nil,
            pedagogicalNote: nil,
            suggestedResponses: ["Whole milk please.", "Oat milk, thanks!"]
        )
        let mockLLM = MockLLMProvider(mockTurnOutput: mockOutput)
        let executeUseCase = ExecuteRoleplayTurnUseCase(llmProvider: mockLLM)
        let completeUseCase = CompleteRoleplaySessionUseCase()

        let viewModel = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        #expect(viewModel.suggestedResponses == scenario.starterSuggestions)
        #expect(viewModel.isSuggestionsVisible)

        await viewModel.sendMessage("I want a latte")

        #expect(viewModel.suggestedResponses == ["Whole milk please.", "Oat milk, thanks!"])

        viewModel.selectSuggestion("Whole milk please.")
        #expect(viewModel.inputText == "Whole milk please.")

        viewModel.toggleSuggestionsVisibility()
        #expect(!viewModel.isSuggestionsVisible)
    }
}
