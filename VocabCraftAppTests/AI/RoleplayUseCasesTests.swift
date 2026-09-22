import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Roleplay Use Cases Tests", .serialized)
struct RoleplayUseCasesTests {
    // MARK: - FetchRoleplayScenariosUseCase Tests

    @Test("FetchRoleplayScenariosUseCase loads catalog items and prepends adaptive scenario")
    func testFetchScenariosLoadsCatalogWithAdaptive() async throws {
        let useCase = FetchRoleplayScenariosUseCase()
        let scenarios = try await useCase.execute(userWeakWords: ["complimentary", "beverage", "pastry", "extraWord"])

        #expect(!scenarios.isEmpty)
        #expect(scenarios.contains(where: { $0.id == "cafe-order" }))
        #expect(scenarios.first?.id == "daily-adaptive")
        #expect(scenarios.first?.targetWordIds == ["complimentary", "beverage", "pastry"])
    }

    @Test("FetchRoleplayScenariosUseCase returns only standard scenarios when weak words empty")
    func testFetchScenariosWithoutWeakWords() async throws {
        let useCase = FetchRoleplayScenariosUseCase()
        let scenarios = try await useCase.execute(userWeakWords: [])

        #expect(scenarios.count == RoleplayScenarioCatalog.standardScenarios.count)
        #expect(!scenarios.contains(where: { $0.id == "daily-adaptive" }))
        #expect(scenarios.contains(where: { $0.id == "cafe-order" }))
        #expect(scenarios.contains(where: { $0.id == "hotel-checkin" }))
        #expect(scenarios.contains(where: { $0.id == "job-interview" }))
    }

    // MARK: - ExecuteRoleplayTurnUseCase Tests

    @Test("ExecuteRoleplayTurnUseCase matches target words and parses output")
    func testExecuteRoleplayTurnMatchesTargetWords() async throws {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "I recommend our signature beverage!",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: nil,
            pedagogicalNote: nil
        )
        let mockProvider = MockLLMProvider(mockTurnOutput: mockOutput)
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: mockProvider)

        let scenario = RoleplayScenario(
            id: "cafe-order",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi!",
            targetWordIds: ["beverage", "pastry"],
            iconSymbol: "cup.and.saucer"
        )

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "What is your best beverage?",
            chatHistory: []
        )

        #expect(result.characterReply == "I recommend our signature beverage!")
        #expect(result.targetWordsUsed.contains("beverage"))
    }

    @Test("ExecuteRoleplayTurnUseCase unions local detected words with LLM output")
    func testExecuteRoleplayTurnUnionsLocalAndLLMWords() async throws {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "Here is your fresh pastry and drink.",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: "You could say: May I have a beverage and pastry?",
            pedagogicalNote: "Great vocabulary usage!"
        )
        let mockProvider = MockLLMProvider(mockTurnOutput: mockOutput)
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: mockProvider)

        let scenario = RoleplayScenario(
            id: "cafe-order",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi!",
            targetWordIds: ["beverage", "pastry"],
            iconSymbol: "cup.and.saucer"
        )

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "I'd like a pastry please.",
            chatHistory: []
        )

        #expect(result.targetWordsUsed.contains("pastry"))
        #expect(result.targetWordsUsed.contains("beverage"))
        #expect(result.refinementSuggestion?.contains("May I have") == true)
        #expect(result.pedagogicalNote == "Great vocabulary usage!")
    }

    @Test("ExecuteRoleplayTurnUseCase falls back gracefully when LLM throws")
    func testExecuteRoleplayTurnFallbackOnError() async throws {
        let mockProvider = MockLLMProvider()
        mockProvider.shouldThrowError = true
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: mockProvider)

        let scenario = RoleplayScenario(
            id: "cafe-order",
            titleKey: "title",
            descriptionKey: "desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Barista",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi!",
            targetWordIds: ["beverage", "pastry"],
            iconSymbol: "cup.and.saucer"
        )

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "What is your best beverage?",
            chatHistory: []
        )

        #expect(result.characterReply == "I hear you! That makes total sense in this situation.")
        #expect(result.targetWordsUsed.contains("beverage"))
        #expect(result.refinementSuggestion == nil)
        #expect(result.pedagogicalNote == nil)
    }

    // MARK: - CompleteRoleplaySessionUseCase Tests

    @Test("CompleteRoleplaySessionUseCase calculates fluency and mastery")
    func testCompleteRoleplaySessionCalculatesMetrics() async {
        let useCase = CompleteRoleplaySessionUseCase()
        let refinements = [
            SentenceRefinementPair(
                originalUserSentence: "I want drink.",
                refinedNativeSentence: "Could I please get a beverage?"
            )
        ]
        let summary = await useCase.execute(
            scenarioId: "cafe-order",
            totalTurns: 4,
            targetWordsAttempted: ["beverage", "pastry"],
            targetWordsMastered: ["beverage"],
            refinements: refinements
        )

        #expect(summary.scenarioId == "cafe-order")
        #expect(summary.totalTurns == 4)
        #expect(summary.targetWordsMastered == ["beverage"])
        #expect(summary.fluencyScore > 0)
        #expect(summary.fluencyScore <= 100)
        #expect(summary.xpEarned > 0)
        #expect(summary.refinements.count == 1)
        #expect(summary.refinements.first?.originalUserSentence == "I want drink.")
    }

    @Test("CompleteRoleplaySessionUseCase handles empty attempted target words")
    func testCompleteRoleplaySessionEmptyAttempted() async {
        let useCase = CompleteRoleplaySessionUseCase()
        let summary = await useCase.execute(
            scenarioId: "cafe-order",
            totalTurns: 0,
            targetWordsAttempted: [],
            targetWordsMastered: [],
            refinements: []
        )

        #expect(summary.fluencyScore == 60)
        #expect(summary.xpEarned == 10)
    }
}
