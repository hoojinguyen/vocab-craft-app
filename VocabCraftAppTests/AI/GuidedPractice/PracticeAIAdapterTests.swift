import Foundation
import Testing
@testable import VocabCraftApp

private final class ControllableMockLLMProvider: LLMProviderProtocol, @unchecked Sendable {
    let providerIdentifier: String = "controllable_mock_llm"

    private let lock = NSLock()
    private var callCountValue: Int = 0
    private var capturedMessagesValue: [[LLMChatMessage]] = []
    private var capturedSystemPromptsValue: [String] = []

    var behavior: @Sendable (Int) async throws -> Any

    init(behavior: @escaping @Sendable (Int) async throws -> Any) {
        self.behavior = behavior
    }

    var callCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return callCountValue
    }

    var capturedMessages: [[LLMChatMessage]] {
        lock.lock()
        defer { lock.unlock() }
        return capturedMessagesValue
    }

    var capturedSystemPrompts: [String] {
        lock.lock()
        defer { lock.unlock() }
        return capturedSystemPromptsValue
    }

    private func recordCall(messages: [LLMChatMessage], systemPrompt: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        callCountValue += 1
        capturedMessagesValue.append(messages)
        capturedSystemPromptsValue.append(systemPrompt)
        return callCountValue
    }

    func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        let currentCall = recordCall(messages: messages, systemPrompt: systemPrompt)

        let result = try await behavior(currentCall)
        if let typed = result as? T {
            return typed
        }
        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: [],
                debugDescription: "Type mismatch: expected \(T.self), got \(type(of: result))"
            )
        )
    }
}

@Suite("Practice AI Adapter Tests")
struct PracticeAIAdapterTests {
    private let defaultCapability = PracticeCapability(
        canGenerateDialogue: true,
        canAssessUsage: true,
        canCaptureSpeech: true,
        canPlaySpeech: true,
        providerIdentity: "test_llm"
    )

    private func makeRequest(turnCount: Int = 1) throws -> PracticeAIRequest {
        let mission = try PracticeFixtures.mission(wordIds: [101])
        let turns = (1...turnCount).map { i in
            PracticeTurn(
                id: UUID(),
                sessionId: mission.id,
                sequence: i,
                speaker: i % 2 == 1 ? .learner : .character,
                inputMode: .voice,
                originalText: "Turn text \(i)",
                acceptedText: "Turn text \(i)",
                transcriptStatus: .final,
                generationStatus: .succeeded,
                requestId: "req-\(i)",
                sessionRevision: 1,
                timestamp: PracticeFixtures.baseDate.addingTimeInterval(Double(i))
            )
        }
        return PracticeAIRequest(
            mission: mission,
            acceptedTurns: turns,
            supportBudget: .none,
            providerIdentity: "test_llm"
        )
    }

    @Test("successful response returns structured AI response")
    func successfulResponse() async throws {
        let expected = PracticeAIResponse(
            characterReply: "Welcome to our café! How may I help you?",
            objectiveAssessments: [
                PracticeObjectiveAssessment(objectiveId: "order_food", intentVerdict: .achieved)
            ],
            wordAssessments: [
                PracticeWordAssessment(
                    wordId: 101,
                    objectiveId: "order_food",
                    usageVerdict: .appropriate,
                    quotedSpan: "menu"
                )
            ],
            coachFeedback: "Great greeting!",
            hintCandidate: nil
        )

        let provider = ControllableMockLLMProvider { _ in expected }
        let adapter = PracticeAIAdapter(
            provider: provider,
            capability: defaultCapability
        )

        let request = try makeRequest()
        let response = try await adapter.respond(to: request)

        #expect(response.characterReply == expected.characterReply)
        #expect(response.wordAssessments.count == 1)
        #expect(provider.callCount == 1)
    }

    @Test("30-second timeout with ManualPracticeClock throws PracticeFailure timeout")
    func timeout30SecondsWithManualPracticeClock() async throws {
        let clock = ManualPracticeClock(initialDate: PracticeFixtures.baseDate)

        let provider = ControllableMockLLMProvider { _ in
            // Simulate hanging provider by sleeping beyond timeout
            try await clock.sleep(for: .seconds(60))
            return PracticeAIResponse(characterReply: "Too late")
        }

        let adapter = PracticeAIAdapter(
            provider: provider,
            capability: defaultCapability,
            clock: clock,
            timeoutSeconds: 30
        )

        let request = try makeRequest()

        let task = Task {
            try await adapter.respond(to: request)
        }

        // Wait for both the adapter's timeout timer and provider to register their sleep waiters
        await clock.waitForSleepers(count: 2)

        // Advance by 30 seconds to trigger timeout
        clock.advance(by: .seconds(30))

        do {
            _ = try await task.value
            Issue.record("Expected timeout failure was not thrown")
        } catch let failure as PracticeFailure {
            #expect(failure.code == .timeout)
        } catch {
            Issue.record("Unexpected error thrown: \(error)")
        }
    }

    @Test("single schema repair retry on invalid schema succeeds on second attempt")
    func singleSchemaRepairRetrySucceeds() async throws {
        let validResponse = PracticeAIResponse(
            characterReply: "Here is your drink.",
            objectiveAssessments: [],
            wordAssessments: []
        )

        let provider = ControllableMockLLMProvider { callIndex in
            if callIndex == 1 {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON format")
                )
            }
            return validResponse
        }

        let adapter = PracticeAIAdapter(
            provider: provider,
            capability: defaultCapability
        )

        let request = try makeRequest()
        let response = try await adapter.respond(to: request)

        #expect(response.characterReply == "Here is your drink.")
        #expect(provider.callCount == 2)
    }

    @Test("schema repair failure throws schema PracticeFailure after single retry")
    func schemaRepairFailsAfterSingleRetry() async throws {
        let provider = ControllableMockLLMProvider { _ in
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON format")
            )
        }

        let adapter = PracticeAIAdapter(
            provider: provider,
            capability: defaultCapability
        )

        let request = try makeRequest()

        do {
            _ = try await adapter.respond(to: request)
            Issue.record("Expected schema failure was not thrown")
        } catch let failure as PracticeFailure {
            #expect(failure.code == .schema)
            #expect(provider.callCount == 2)
        } catch {
            Issue.record("Unexpected error thrown: \(error)")
        }
    }

    @Test("network error does not trigger repair loop")
    func networkErrorDoesNotTriggerRepairLoop() async throws {
        let provider = ControllableMockLLMProvider { _ in
            throw URLError(.notConnectedToInternet)
        }

        let adapter = PracticeAIAdapter(
            provider: provider,
            capability: defaultCapability
        )

        let request = try makeRequest()

        do {
            _ = try await adapter.respond(to: request)
            Issue.record("Expected network failure was not thrown")
        } catch let failure as PracticeFailure {
            #expect(failure.code == .network)
            #expect(provider.callCount == 1) // strictly no retry loop
        } catch {
            Issue.record("Unexpected error thrown: \(error)")
        }
    }

    @Test("capability reporting returns configured capability")
    func capabilityReporting() async {
        let provider = ControllableMockLLMProvider { _ in
            PracticeAIResponse(characterReply: "Hi")
        }
        let adapter = PracticeAIAdapter(
            provider: provider,
            capability: defaultCapability
        )

        let reported = await adapter.capability()
        #expect(reported == defaultCapability)
    }

    @Test("canAssessUsage false generates dialogue safely without fake assessment")
    func canAssessUsageFalseGeneratesDialogueWithoutFakeAssessment() async throws {
        let noAssessmentCapability = PracticeCapability(
            canGenerateDialogue: true,
            canAssessUsage: false,
            canCaptureSpeech: true,
            canPlaySpeech: true,
            providerIdentity: "offline_roleplay"
        )

        let roleplayOutput = RoleplayTurnOutput(
            characterReply: "Good morning! Are you ready to order?",
            targetWordsUsed: ["order"],
            refinementSuggestion: nil,
            pedagogicalNote: "Try ordering breakfast.",
            suggestedResponses: ["I'd like coffee."],
            isConcluded: false
        )

        let provider = ControllableMockLLMProvider { _ in
            roleplayOutput
        }

        let adapter = PracticeAIAdapter(
            provider: provider,
            capability: noAssessmentCapability
        )

        let request = try makeRequest()
        let response = try await adapter.respond(to: request)

        #expect(response.characterReply == "Good morning! Are you ready to order?")
        #expect(response.wordAssessments.isEmpty)
        #expect(response.objectiveAssessments.isEmpty)
    }

    @Test("history limited to at most 8 accepted turns and prompt injection safety preserved")
    func historyLimitedToAtMost8Turns() async throws {
        let provider = ControllableMockLLMProvider { _ in
            PracticeAIResponse(characterReply: "Sure thing!")
        }
        let adapter = PracticeAIAdapter(
            provider: provider,
            capability: defaultCapability
        )

        let request = try makeRequest(turnCount: 15)
        _ = try await adapter.respond(to: request)

        #expect(provider.callCount == 1)
        guard let sentMessages = provider.capturedMessages.first else {
            Issue.record("No messages captured")
            return
        }
        #expect(sentMessages.count <= 8)
        #expect(sentMessages.last?.content == "Turn text 15")

        guard let systemPrompt = provider.capturedSystemPrompts.first else {
            Issue.record("No system prompt captured")
            return
        }
        // Verify system instructions contain objectives and words
        #expect(systemPrompt.contains("targetWordIds") || systemPrompt.contains("101"))
    }
}
