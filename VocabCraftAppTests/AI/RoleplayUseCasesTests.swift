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

    @Test("FetchRoleplayScenariosUseCase populates starterSuggestions for adaptive daily scenario")
    func test_adaptiveDailyScenario_hasPopulatedStarterSuggestions() async throws {
        let useCase = FetchRoleplayScenariosUseCase()
        let scenarios = try await useCase.execute(userWeakWords: ["collaborate", "innovative"])

        let daily = scenarios.first { $0.id == "daily-adaptive" }
        let unwrapped = try #require(daily)
        #expect(!unwrapped.starterSuggestions.isEmpty)
        #expect(unwrapped.starterSuggestions.count >= 2)
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

    @Test("ExecuteRoleplayTurnUseCase forwards suggested responses from provider")
    func testExecuteRoleplayTurnForwardsSuggestedResponses() async throws {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "Here is your drink.",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: nil,
            pedagogicalNote: nil,
            suggestedResponses: [
                "Could I also get a pastry?",
                "Is there a complimentary refill?"
            ]
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

        #expect(result.suggestedResponses.count == 2)
        #expect(result.suggestedResponses.contains("Could I also get a pastry?"))
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

    @Test("ExecuteRoleplayTurnUseCase cleans stage directions and asterisks from character reply")
    func testExecuteRoleplayTurnCleansAsterisksAndQuotes() async throws {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "*smiles warmly* \"Sure, here is your iced espresso!\" *hands you the cup*",
            targetWordsUsed: ["espresso"],
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
            targetWordIds: ["espresso"],
            iconSymbol: "cup.and.saucer"
        )

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "An espresso please",
            chatHistory: []
        )

        #expect(result.characterReply == "Sure, here is your iced espresso!")
        #expect(!result.characterReply.contains("*"))
    }

    @Test("ExecuteRoleplayTurnUseCase rethrows error when LLM provider throws")
    func testExecuteRoleplayTurnRethrowsOnError() async {
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

        await #expect(throws: Error.self) {
            _ = try await useCase.execute(
                scenario: scenario,
                userUtterance: "What is your best beverage?",
                chatHistory: []
            )
        }
    }

    @Test("ExecuteRoleplayTurnUseCase word-boundary regex prevents substring false positives")
    func testExecuteRoleplayTurnWordBoundaryRegex() async throws {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "Hello there!",
            targetWordsUsed: [],
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
            targetWordIds: ["age", "tea"],
            iconSymbol: "cup.and.saucer"
        )

        // "beverage" contains "age" as a substring, but NOT as a word boundary
        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "I like this beverage and steam.",
            chatHistory: []
        )

        #expect(!result.targetWordsUsed.contains("age"))
        #expect(!result.targetWordsUsed.contains("tea"))
    }

    @Test("ExecuteRoleplayTurnUseCase prompt formats 3-branch suggestions instructions")
    func testPromptSpecifiesThreeBranchSuggestions() async throws {
        let mockOutput = RoleplayTurnOutput(
            characterReply: "What kind of coffee do you enjoy?",
            targetWordsUsed: [],
            refinementSuggestion: nil,
            pedagogicalNote: nil,
            suggestedResponses: [
                "I'd like an espresso, please.",
                "What beans do you recommend?",
                "Just something warm, thanks!"
            ]
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
            targetWordIds: ["espresso"],
            iconSymbol: "cup.and.saucer"
        )

        let result = try await useCase.execute(
            scenario: scenario,
            userUtterance: "Good morning!",
            chatHistory: []
        )

        #expect(result.suggestedResponses.count == 3)
        #expect(result.refinementSuggestion == nil)
    }

    @Test("ExecuteRoleplayTurnUseCase system prompt contains 3-branch and refinement guidelines")
    func testSystemPromptContainsThreeBranchAndRefinementGuidelines() async throws {
        let spyProvider = RoleplayPromptRecordingLLMProvider()
        let useCase = ExecuteRoleplayTurnUseCase(llmProvider: spyProvider)

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
            targetWordIds: ["espresso", "cappuccino"],
            iconSymbol: "cup.and.saucer"
        )

        _ = try await useCase.execute(
            scenario: scenario,
            userUtterance: "Good morning!",
            chatHistory: []
        )

        let prompt = spyProvider.capturedSystemPrompt ?? ""
        #expect(prompt.contains("REFINEMENT RULES:"))
        #expect(prompt.contains("RETURN NULL. Never rephrase a correct sentence."))
        #expect(prompt.contains("SUGGESTED RESPONSES RULES:"))
        #expect(prompt.contains("1. Target Word: A response naturally using one of the target words: espresso, cappuccino."))
        #expect(prompt.contains("2. Inquiry/Question: A natural polite question or request continuing the conversation."))
        #expect(prompt.contains("3. Casual Reaction: A colloquial remark or response."))
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

    @Test("CompleteRoleplaySessionUseCase persists mastered words to UserProgressRepository")
    func testCompleteRoleplaySessionPersistsMasteredWords() async throws {
        let mockProgressRepo = MockUserProgressRepository()
        let mockVocabSource = MockVocabularyDataSource()
        let useCase = CompleteRoleplaySessionUseCase(
            userSettingsStore: nil,
            userProgressRepository: mockProgressRepo,
            vocabularyDataSource: mockVocabSource
        )

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
            targetWordIds: ["resilience", "spontaneous"],
            iconSymbol: "cup.and.saucer"
        )

        let messages = [
            RoleplayMessage(sender: .character(name: "Barista"), text: "Hi!"),
            RoleplayMessage(sender: .user, text: "I have great resilience.")
        ]

        let summary = await useCase.execute(
            scenario: scenario,
            messages: messages,
            masteredWords: ["Resilience"]
        )

        #expect(summary.targetWordsMastered == ["Resilience"])
        #expect(mockProgressRepo.recordChallengeCallCount == 1)
        let progress = try await mockProgressRepo.getProgress(wordId: 1)
        #expect(progress != nil)
        #expect(progress?.masteryLevel == 1)
        #expect(progress?.sourceDeckId == "cafe-order")
    }
}

// MARK: - Prompt Recording Helper

private final class RoleplayPromptRecordingLLMProvider: LLMProviderProtocol, @unchecked Sendable {
    let providerIdentifier: String = "prompt-recording-mock"
    var capturedSystemPrompt: String?

    func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        self.capturedSystemPrompt = systemPrompt
        let output = RoleplayTurnOutput(
            characterReply: "Welcome!",
            targetWordsUsed: [],
            refinementSuggestion: nil,
            pedagogicalNote: nil,
            suggestedResponses: ["I want coffee."]
        )
        if let typed = output as? T {
            return typed
        }
        fatalError("Unsupported schema")
    }
}
