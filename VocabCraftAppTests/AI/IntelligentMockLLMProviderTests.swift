import Testing
@testable import VocabCraftApp

@Suite("Intelligent Mock LLM Provider Tests")
struct IntelligentMockLLMProviderTests {
    @Test("Extracts target words and advances cafe dialogue")
    func cafeScenarioTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .system, content: "Scenario: scenario_cafe_order. Target words: espresso, croissant, recommendation, decaf."),
            LLMChatMessage(role: .model, content: "Hi! Welcome to The Daily Roast. What can I get started for you today?"),
            LLMChatMessage(role: .user, content: "Can I have a hot espresso and a fresh croissant?")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are Alex the barista.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("espresso"))
        #expect(output.targetWordsUsed.contains("croissant"))
        #expect(!output.characterReply.isEmpty)
        #expect(output.refinementSuggestion != nil)
    }

    @Test("Advances cafe dialogue to checkout on second turn")
    func cafeScenarioSecondTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .system, content: "Scenario: scenario_cafe_order. Target words: espresso, croissant, recommendation, decaf."),
            LLMChatMessage(role: .model, content: "Hi! Welcome to The Daily Roast. What can I get started for you today?"),
            LLMChatMessage(role: .user, content: "Can I have an espresso?"),
            LLMChatMessage(role: .model, content: "Sure, single or double?"),
            LLMChatMessage(role: .user, content: "Double espresso and that's all, thank you.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are Alex the barista.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("espresso"))
        #expect(output.characterReply.contains("$6.50") || output.characterReply.contains("reader"))
        #expect(output.refinementSuggestion != nil)
        #expect(output.pedagogicalNote != nil)
        #expect(!output.isConcluded)
    }

    @Test("Advances cafe dialogue to receipt and farewell on third turn")
    func cafeScenarioThirdTurnConcludes() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .system, content: "Scenario: scenario_cafe_order. Target words: beverage, pastry, complimentary."),
            LLMChatMessage(role: .model, content: "Hello! Welcome to Craft Cafe. What can I get for you today?"),
            LLMChatMessage(role: .user, content: "Hi! I'd like to order a warm beverage and a fresh pastry, please."),
            LLMChatMessage(role: .model, content: "Great choice! Would you like your beverage hot or iced?"),
            LLMChatMessage(role: .user, content: "Hot please, and do you offer complimentary snacks?"),
            LLMChatMessage(role: .model, content: "Coming right up! That will be $6.50. You can tap your card right on the reader."),
            LLMChatMessage(role: .user, content: "Here is my card to tap. Thanks for the recommendation!")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are Emma the barista.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.isConcluded)
        #expect(output.characterReply.contains("receipt") || output.characterReply.contains("All set"))
        #expect(output.suggestedResponses.contains(where: { $0.contains("goodbye") || $0.contains("day") }))
    }

    @Test("Handles job interview scenario turn")
    func interviewScenarioTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "In my previous experience, I led cross-functional team collaboration.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are the hiring manager.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("experience"))
        #expect(output.targetWordsUsed.contains("collaboration"))
        #expect(!output.characterReply.isEmpty)
        #expect(output.refinementSuggestion?.contains("STAR") == true)
    }

    @Test("Advances job interview scenario on second turn")
    func interviewScenarioSecondTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "In my previous experience, I led cross-functional team collaboration."),
            LLMChatMessage(role: .model, content: "Thank you for sharing that. Could you tell me about a time you handled a tight deadline or challenge?"),
            LLMChatMessage(role: .user, content: "Under tight deadline pressure, I demonstrated clear leadership.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are the hiring manager.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("deadline"))
        #expect(output.targetWordsUsed.contains("leadership"))
        #expect(output.characterReply.contains("questions for us"))
        #expect(output.refinementSuggestion != nil)
        #expect(!output.isConcluded)
    }

    @Test("Advances job interview scenario to conclusion on third turn")
    func interviewScenarioThirdTurnConcludes() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "In my previous experience, I led cross-functional team collaboration."),
            LLMChatMessage(role: .model, content: "Thank you for sharing that. Could you tell me about a time you handled a tight deadline or challenge?"),
            LLMChatMessage(role: .user, content: "Under tight deadline pressure, I demonstrated clear leadership."),
            LLMChatMessage(role: .model, content: "That demonstrates excellent leadership and problem-solving skills under pressure. Do you have any questions for us about the role or team?"),
            LLMChatMessage(role: .user, content: "What does success look like for this position in the first 90 days?")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are the hiring manager.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.isConcluded)
        #expect(output.characterReply.contains("insightful questions") || output.characterReply.contains("next steps"))
    }

    @Test("Handles hotel check-in scenario turn")
    func hotelScenarioTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Hello, I have a hotel reservation and here is my passport.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are the hotel concierge.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("reservation"))
        #expect(output.targetWordsUsed.contains("passport"))
        #expect(!output.characterReply.isEmpty)
        #expect(output.refinementSuggestion != nil)
    }

    @Test("Advances hotel check-in scenario on second turn")
    func hotelScenarioSecondTurn() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Hello, I have a hotel reservation and here is my passport."),
            LLMChatMessage(role: .model, content: "I found your reservation right here. May I have your passport or ID card, please?"),
            LLMChatMessage(role: .user, content: "What amenities and complimentary services are included?")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are the hotel concierge.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.targetWordsUsed.contains("amenities"))
        #expect(output.targetWordsUsed.contains("complimentary"))
        #expect(output.characterReply.contains("keycard"))
        #expect(output.refinementSuggestion != nil)
        #expect(!output.isConcluded)
    }

    @Test("Advances hotel check-in scenario to conclusion on third turn")
    func hotelScenarioThirdTurnConcludes() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Hello, I have a hotel reservation and here is my passport."),
            LLMChatMessage(role: .model, content: "I found your reservation right here. May I have your passport or ID card, please?"),
            LLMChatMessage(role: .user, content: "What amenities and complimentary services are included?"),
            LLMChatMessage(role: .model, content: "Thank you. Here is your keycard for room 402. Complimentary breakfast and amenities like the pool are on the 5th floor. Enjoy your stay!"),
            LLMChatMessage(role: .user, content: "Thank you so much! What time is breakfast served in the morning?")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are the hotel concierge.",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(output.isConcluded)
        #expect(output.characterReply.contains("set") || output.characterReply.contains("stay"))
    }

    @Test("Fallback response handles free-form speech outside script")
    func freeFormFallback() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Tell me about the weather outside.")
        ]

        let output = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "General conversation",
            responseSchema: RoleplayTurnOutput.self
        )

        #expect(!output.characterReply.isEmpty)
        #expect(output.pedagogicalNote != nil)
    }

    @Test("Verify provider identifier and unsupported schema handling")
    func providerIdentifierAndUnsupportedSchema() async throws {
        let provider = IntelligentMockLLMProvider()
        #expect(provider.providerIdentifier == "intelligent_mock")

        struct UnrelatedSchema: Codable, Sendable {
            let id: String
        }

        let messages = [
            LLMChatMessage(role: .user, content: "Hello")
        ]

        await #expect(throws: DecodingError.self) {
            _ = try await provider.sendStructuredMessage(
                messages: messages,
                systemPrompt: "test",
                responseSchema: UnrelatedSchema.self
            )
        }
    }

    @Test("Detects dynamic catalog target words for Cafe scenario")
    func detectsCatalogCafeWords() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Could I please order a hot beverage and a fresh pastry?")
        ]
        let systemPrompt = "You are Emma, a Barista. Target vocabulary for the user: beverage, pastry, complimentary."
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(output.targetWordsUsed.contains("beverage"))
        #expect(output.targetWordsUsed.contains("pastry"))
    }

    @Test("Detects dynamic catalog target words for Hotel scenario")
    func detectsCatalogHotelWords() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "We need to accommodate the reservation.")
        ]
        let systemPrompt = "You are David, Front Desk Concierge. Target vocabulary for the user: reservation, amenities, accommodate."
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(output.targetWordsUsed.contains("accommodate"))
        #expect(output.targetWordsUsed.contains("reservation"))
    }

    @Test("Detects dynamic catalog target words for Interview scenario")
    func detectsCatalogInterviewWords() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "I took the initiative to build an innovative solution and collaborate with peers.")
        ]
        let systemPrompt = "You are Ms. Jenkins, Lead Hiring Manager. Target vocabulary for the user: collaborate, innovative, initiative."
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: systemPrompt,
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(output.targetWordsUsed.contains("initiative"))
        #expect(output.targetWordsUsed.contains("innovative"))
        #expect(output.targetWordsUsed.contains("collaborate"))
    }

    @Test("Directly extracts target words with dynamic expected words")
    func extractTargetWordsWithExpectedWords() {
        let provider = IntelligentMockLLMProvider()
        let extracted = provider.extractTargetWords(
            from: "I want a beverage and some gelato",
            expectedWords: ["gelato", "pastry"]
        )
        #expect(extracted.contains("beverage"))
        #expect(extracted.contains("gelato"))
        #expect(!extracted.contains("pastry"))
    }

    @Test("Generates contextual suggested responses for user turn")
    func testIntelligentMockGeneratesSuggestedResponses() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .system, content: "Target vocabulary for the user: beverage, pastry, complimentary."),
            LLMChatMessage(role: .user, content: "Hello!")
        ]
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "Target vocabulary for the user: beverage, pastry, complimentary.",
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(!output.suggestedResponses.isEmpty, "Mock provider should generate at least one suggested response")
        #expect(output.suggestedResponses.count >= 2)
    }

    @Test("Generates suggested responses for Interview scenario turns")
    func testInterviewSuggestedResponses() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "In my previous experience, I led collaboration.")
        ]
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are Ms. Jenkins, Lead Hiring Manager. Target vocabulary for the user: collaborate, innovative, initiative.",
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(output.suggestedResponses.count >= 2)
        #expect(output.suggestedResponses.allSatisfy { !$0.isEmpty })
    }

    @Test("Generates suggested responses for Hotel scenario turns")
    func testHotelSuggestedResponses() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Hello, I have a reservation and here is my passport.")
        ]
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are David, Front Desk Concierge. Target vocabulary for the user: reservation, amenities, accommodate.",
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(output.suggestedResponses.count >= 2)
        #expect(output.suggestedResponses.allSatisfy { !$0.isEmpty })
    }

    @Test("Generates suggested responses for second turn in cafe")
    func testCafeSecondTurnSuggestedResponses() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "Can I have an espresso?"),
            LLMChatMessage(role: .model, content: "Sure, single or double?"),
            LLMChatMessage(role: .user, content: "Double please.")
        ]
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "You are Alex the barista.",
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(output.suggestedResponses.count >= 2)
        #expect(output.suggestedResponses.contains(where: { $0.localizedCaseInsensitiveContains("receipt") }))
    }

    @Test("Generates suggested responses for fallback general scenario")
    func testFallbackSuggestedResponses() async throws {
        let provider = IntelligentMockLLMProvider()
        let messages = [
            LLMChatMessage(role: .user, content: "How is the weather today?")
        ]
        let output: RoleplayTurnOutput = try await provider.sendStructuredMessage(
            messages: messages,
            systemPrompt: "General conversation topic",
            responseSchema: RoleplayTurnOutput.self
        )
        #expect(output.suggestedResponses.count >= 2)
        #expect(output.suggestedResponses.allSatisfy { !$0.isEmpty })
    }
}
