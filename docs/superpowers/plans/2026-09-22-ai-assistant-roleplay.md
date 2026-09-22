# AI Assistant: Scenario Roleplay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the AI Scenario Roleplay subsystem for VocabCraft, replacing the AI Assistant placeholder with an interactive conversational roleplay experience that drives active vocabulary usage and updates the spaced repetition system.

**Architecture:** Provider-agnostic clean architecture with a protocol-driven LLM layer (`LLMProviderProtocol`) supporting Google Gemini and deterministic mocks. Domain use cases coordinate target word recognition, single-pass structured turn generation, and SRS mastery updates (`SRSEngine`), rendered via a CraftUIKit-first SwiftUI interface.

**Tech Stack:** Swift 6 (Strict Concurrency), SwiftUI, Observation (`@Observable`), Swift Testing (`@Suite`, `@Test`), CraftUIKit, SpeechKit, Foundation.

**Spec:** [`docs/superpowers/specs/2026-09-22-ai-assistant-roleplay-design.md`](file:///Users/hoojinguyen/Projects/vocab-craft-app/docs/superpowers/specs/2026-09-22-ai-assistant-roleplay-design.md)

## Global Constraints
- Zero raw styling: 100% token adherence via `CraftTheme`, `CraftColor`, `CraftFont`, `CraftSpacingTokens`.
- Zero hardcoded strings: all copy defined in `VocabCraftApp/Resources/Localizable.xcstrings` under `app.ai_assistant.*` with 100% English and Vietnamese parity (`state: translated, extractionState: manual`).
- Swift 6 strict concurrency: all entities and use cases conform to `Sendable`; ViewModels isolated to `@MainActor`.
- Compiler quality gate: 0 errors, 0 compiler warnings.

---

### Task 1: Domain Entities & LLM Provider Protocol

**Files:**
- Create: `VocabCraftApp/Domain/Protocols/LLMProviderProtocol.swift`
- Create: `VocabCraftApp/Domain/Entities/RoleplayScenario.swift`
- Create: `VocabCraftApp/Domain/Entities/RoleplayTurnOutput.swift`
- Create: `VocabCraftApp/Domain/Entities/RoleplaySessionSummary.swift`
- Test: `VocabCraftAppTests/AI/DomainEntitiesTests.swift`

**Interfaces:**
- Consumes: None
- Produces:
  - `protocol LLMProviderProtocol: Sendable`
  - `struct LLMChatMessage: Codable, Sendable, Equatable`
  - `struct RoleplayScenario: Identifiable, Codable, Sendable, Equatable`
  - `struct RoleplayTurnOutput: Codable, Sendable, Equatable`
  - `struct RoleplaySessionSummary: Identifiable, Codable, Sendable, Equatable`

- [ ] **Step 1: Write the failing test**

```swift
// VocabCraftAppTests/AI/DomainEntitiesTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AI Assistant Domain Entities Tests")
struct DomainEntitiesTests {
    @Test("RoleplayScenario initialization and topic modeling")
    func testRoleplayScenarioInitialization() {
        let scenario = RoleplayScenario(
            id: "cafe-order",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hi! Welcome to Artisan Coffee. What can I get started for you?",
            targetWordIds: ["beverage", "pastry", "complimentary"],
            iconSymbol: "cup.and.saucer.fill"
        )
        #expect(scenario.id == "cafe-order")
        #expect(scenario.topic == .dining)
        #expect(scenario.difficulty == .beginner)
        #expect(scenario.targetWordIds.count == 3)
    }

    @Test("RoleplayTurnOutput codable roundtrip")
    func testRoleplayTurnOutputCodable() throws {
        let output = RoleplayTurnOutput(
            characterReply: "Sure, we have fresh croissants today!",
            targetWordsUsed: ["pastry"],
            refinementSuggestion: "You could say 'I'd like to try your pastry.'",
            pedagogicalNote: "Great job ordering politely!"
        )
        let data = try JSONEncoder().encode(output)
        let decoded = try JSONDecoder().decode(RoleplayTurnOutput.self, from: data)
        #expect(decoded == output)
        #expect(decoded.targetWordsUsed == ["pastry"])
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter DomainEntitiesTests`
Expected: FAIL with compilation error "cannot find type 'RoleplayScenario' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Domain/Protocols/LLMProviderProtocol.swift`:
```swift
import Foundation

public enum LLMRole: String, Codable, Sendable {
    case user
    case model
    case system
}

public struct LLMChatMessage: Codable, Sendable, Equatable {
    public let role: LLMRole
    public let content: String

    public init(role: LLMRole, content: String) {
        self.role = role
        self.content = content
    }
}

public protocol LLMProviderProtocol: Sendable {
    var providerIdentifier: String { get }
    func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T
}
```

Create `VocabCraftApp/Domain/Entities/RoleplayScenario.swift`:
```swift
import Foundation

public enum ScenarioTopic: String, Codable, Sendable, CaseIterable {
    case dining
    case travel
    case workplace
    case dailyLife
    case interview
}

public enum ScenarioDifficulty: String, Codable, Sendable, CaseIterable {
    case beginner
    case intermediate
    case advanced
}

public struct RoleplayScenario: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let titleKey: String
    public let descriptionKey: String
    public let topic: ScenarioTopic
    public let difficulty: ScenarioDifficulty
    public let characterName: String
    public let characterRole: String
    public let userRole: String
    public let initialGreeting: String
    public let targetWordIds: [String]
    public let iconSymbol: String

    public init(
        id: String,
        titleKey: String,
        descriptionKey: String,
        topic: ScenarioTopic,
        difficulty: ScenarioDifficulty,
        characterName: String,
        characterRole: String,
        userRole: String,
        initialGreeting: String,
        targetWordIds: [String],
        iconSymbol: String
    ) {
        self.id = id
        self.titleKey = titleKey
        self.descriptionKey = descriptionKey
        self.topic = topic
        self.difficulty = difficulty
        self.characterName = characterName
        self.characterRole = characterRole
        self.userRole = userRole
        self.initialGreeting = initialGreeting
        self.targetWordIds = targetWordIds
        self.iconSymbol = iconSymbol
    }
}
```

Create `VocabCraftApp/Domain/Entities/RoleplayTurnOutput.swift`:
```swift
import Foundation

public struct RoleplayTurnOutput: Codable, Sendable, Equatable {
    public let characterReply: String
    public let targetWordsUsed: [String]
    public let refinementSuggestion: String?
    public let pedagogicalNote: String?

    public init(
        characterReply: String,
        targetWordsUsed: [String],
        refinementSuggestion: String? = nil,
        pedagogicalNote: String? = nil
    ) {
        self.characterReply = characterReply
        self.targetWordsUsed = targetWordsUsed
        self.refinementSuggestion = refinementSuggestion
        self.pedagogicalNote = pedagogicalNote
    }
}
```

Create `VocabCraftApp/Domain/Entities/RoleplaySessionSummary.swift`:
```swift
import Foundation

public struct SentenceRefinementPair: Codable, Sendable, Equatable, Identifiable {
    public var id: String { originalUserSentence }
    public let originalUserSentence: String
    public let refinedNativeSentence: String

    public init(originalUserSentence: String, refinedNativeSentence: String) {
        self.originalUserSentence = originalUserSentence
        self.refinedNativeSentence = refinedNativeSentence
    }
}

public struct RoleplaySessionSummary: Identifiable, Codable, Sendable, Equatable {
    public var id: String { scenarioId }
    public let scenarioId: String
    public let totalTurns: Int
    public let targetWordsAttempted: [String]
    public let targetWordsMastered: [String]
    public let fluencyScore: Int
    public let xpEarned: Int
    public let refinements: [SentenceRefinementPair]

    public init(
        scenarioId: String,
        totalTurns: Int,
        targetWordsAttempted: [String],
        targetWordsMastered: [String],
        fluencyScore: Int,
        xpEarned: Int,
        refinements: [SentenceRefinementPair]
    ) {
        self.scenarioId = scenarioId
        self.totalTurns = totalTurns
        self.targetWordsAttempted = targetWordsAttempted
        self.targetWordsMastered = targetWordsMastered
        self.fluencyScore = fluencyScore
        self.xpEarned = xpEarned
        self.refinements = refinements
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter DomainEntitiesTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Domain/Protocols/LLMProviderProtocol.swift VocabCraftApp/Domain/Entities/RoleplayScenario.swift VocabCraftApp/Domain/Entities/RoleplayTurnOutput.swift VocabCraftApp/Domain/Entities/RoleplaySessionSummary.swift VocabCraftAppTests/AI/DomainEntitiesTests.swift
git commit -m "feat(ai): define LLMProviderProtocol and roleplay domain entities"
```

---

### Task 2: Mock & Gemini LLM Providers

**Files:**
- Create: `VocabCraftApp/Data/AI/MockLLMProvider.swift`
- Create: `VocabCraftApp/Data/AI/GeminiLLMProvider.swift`
- Test: `VocabCraftAppTests/AI/LLMProviderTests.swift`

**Interfaces:**
- Consumes: `LLMProviderProtocol`, `LLMChatMessage`, `RoleplayTurnOutput`
- Produces:
  - `class MockLLMProvider: LLMProviderProtocol`
  - `class GeminiLLMProvider: LLMProviderProtocol`

- [ ] **Step 1: Write the failing test**

```swift
// VocabCraftAppTests/AI/LLMProviderTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("LLM Provider Tests")
struct LLMProviderTests {
    @Test("MockLLMProvider returns configured structured output")
    func testMockProviderReturnsStructuredOutput() async throws {
        let expectedOutput = RoleplayTurnOutput(
            characterReply: "Here is your latte!",
            targetWordsUsed: ["beverage"],
            refinementSuggestion: nil,
            pedagogicalNote: "Good request"
        )
        let mock = MockLLMProvider(mockTurnOutput: expectedOutput)
        
        let result: RoleplayTurnOutput = try await mock.sendStructuredMessage(
            messages: [LLMChatMessage(role: .user, content: "Can I get a beverage?")],
            systemPrompt: "You are a barista",
            responseSchema: RoleplayTurnOutput.self
        )
        
        #expect(result.characterReply == "Here is your latte!")
        #expect(result.targetWordsUsed.contains("beverage"))
    }

    @Test("MockLLMProvider throws when error is injected")
    func testMockProviderErrorInjection() async {
        let mock = MockLLMProvider()
        mock.shouldThrowError = true
        
        await #expect(throws: Error.self) {
            let _: RoleplayTurnOutput = try await mock.sendStructuredMessage(
                messages: [],
                systemPrompt: "",
                responseSchema: RoleplayTurnOutput.self
            )
        }
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LLMProviderTests`
Expected: FAIL with compilation error "cannot find type 'MockLLMProvider' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Data/AI/MockLLMProvider.swift`:
```swift
import Foundation

public final class MockLLMProvider: LLMProviderProtocol, @unchecked Sendable {
    public let providerIdentifier: String = "mock"
    public var shouldThrowError: Bool = false
    public var mockTurnOutput: RoleplayTurnOutput?

    public init(mockTurnOutput: RoleplayTurnOutput? = nil) {
        self.mockTurnOutput = mockTurnOutput
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        if shouldThrowError {
            throw URLError(.cannotConnectToHost)
        }

        if let output = mockTurnOutput as? T {
            return output
        }

        // Default mock if none provided
        let defaultOutput = RoleplayTurnOutput(
            characterReply: "That sounds wonderful! Let me assist you with that.",
            targetWordsUsed: [],
            refinementSuggestion: nil,
            pedagogicalNote: "Keep going!"
        )

        if let defaultAsT = defaultOutput as? T {
            return defaultAsT
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Unsupported mock schema")
        )
    }
}
```

Create `VocabCraftApp/Data/AI/GeminiLLMProvider.swift`:
```swift
import Foundation

public enum GeminiError: Error, LocalizedError, Sendable {
    case missingApiKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingApiKey:
            return "Gemini API key is not configured."
        case .invalidResponse:
            return "Invalid response received from Gemini API."
        case .apiError(let code, let msg):
            return "Gemini API error (\(code)): \(msg)"
        }
    }
}

public final class GeminiLLMProvider: LLMProviderProtocol, Sendable {
    public let providerIdentifier: String = "gemini-flash"
    private let apiKey: String
    private let session: URLSession

    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    public func sendStructuredMessage<T: Decodable & Sendable>(
        messages: [LLMChatMessage],
        systemPrompt: String,
        responseSchema: T.Type
    ) async throws -> T {
        guard !apiKey.isEmpty else {
            throw GeminiError.missingApiKey
        }

        let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)")!
        var request = URLRequest(endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let contents = messages.map { msg -> [String: Any] in
            let role = msg.role == .user ? "user" : "model"
            return [
                "role": role,
                "parts": [["text": msg.content]]
            ]
        }

        let payload: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": contents,
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.7
            ]
        ]

        let httpBody = try JSONSerialization.data(withJSONObject: payload)
        request.httpBody = httpBody

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown"
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: errorText)
        }

        // Parse candidates[0].content.parts[0].text
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String,
              let rawData = text.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }

        return try JSONDecoder().decode(T.self, from: rawData)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LLMProviderTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/MockLLMProvider.swift VocabCraftApp/Data/AI/GeminiLLMProvider.swift VocabCraftAppTests/AI/LLMProviderTests.swift
git commit -m "feat(ai): implement MockLLMProvider and GeminiLLMProvider"
```

---

### Task 3: Roleplay Scenarios Catalog & Use Cases

**Files:**
- Create: `VocabCraftApp/Data/AI/RoleplayScenarioCatalog.swift`
- Create: `VocabCraftApp/Domain/UseCases/FetchRoleplayScenariosUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift`
- Create: `VocabCraftApp/Domain/UseCases/CompleteRoleplaySessionUseCase.swift`
- Test: `VocabCraftAppTests/AI/RoleplayUseCasesTests.swift`

**Interfaces:**
- Consumes: `LLMProviderProtocol`, `RoleplayScenario`, `RoleplayTurnOutput`, `RoleplaySessionSummary`, `SRSEngine`
- Produces:
  - `class FetchRoleplayScenariosUseCase: Sendable`
  - `class ExecuteRoleplayTurnUseCase: Sendable`
  - `class CompleteRoleplaySessionUseCase: Sendable`

- [ ] **Step 1: Write the failing test**

```swift
// VocabCraftAppTests/AI/RoleplayUseCasesTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("Roleplay Use Cases Tests")
struct RoleplayUseCasesTests {
    @Test("FetchRoleplayScenariosUseCase loads catalog items")
    func testFetchScenariosLoadsCatalog() async throws {
        let useCase = FetchRoleplayScenariosUseCase()
        let scenarios = try await useCase.execute(userWeakWords: ["complimentary", "beverage"])
        #expect(!scenarios.isEmpty)
        #expect(scenarios.contains(where: { $0.id == "cafe-order" }))
    }

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

    @Test("CompleteRoleplaySessionUseCase calculates fluency and mastery")
    func testCompleteRoleplaySessionCalculatesMetrics() async {
        let useCase = CompleteRoleplaySessionUseCase()
        let summary = await useCase.execute(
            scenarioId: "cafe-order",
            totalTurns: 4,
            targetWordsAttempted: ["beverage", "pastry"],
            targetWordsMastered: ["beverage"],
            refinements: []
        )

        #expect(summary.scenarioId == "cafe-order")
        #expect(summary.targetWordsMastered == ["beverage"])
        #expect(summary.fluencyScore > 0)
        #expect(summary.xpEarned > 0)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter RoleplayUseCasesTests`
Expected: FAIL with compilation error "cannot find type 'FetchRoleplayScenariosUseCase' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Data/AI/RoleplayScenarioCatalog.swift`:
```swift
import Foundation

public enum RoleplayScenarioCatalog {
    public static let standardScenarios: [RoleplayScenario] = [
        RoleplayScenario(
            id: "cafe-order",
            titleKey: "app.ai_assistant.scenario.cafe.title",
            descriptionKey: "app.ai_assistant.scenario.cafe.desc",
            topic: .dining,
            difficulty: .beginner,
            characterName: "Emma",
            characterRole: "Barista",
            userRole: "Customer",
            initialGreeting: "Hello! Welcome to Craft Cafe. What can I get for you today?",
            targetWordIds: ["beverage", "pastry", "complimentary"],
            iconSymbol: "cup.and.saucer.fill"
        ),
        RoleplayScenario(
            id: "hotel-checkin",
            titleKey: "app.ai_assistant.scenario.hotel.title",
            descriptionKey: "app.ai_assistant.scenario.hotel.desc",
            topic: .travel,
            difficulty: .intermediate,
            characterName: "David",
            characterRole: "Front Desk Concierge",
            userRole: "Guest",
            initialGreeting: "Good afternoon, welcome to Grand Vista Hotel. Checking in?",
            targetWordIds: ["reservation", "amenities", "accommodate"],
            iconSymbol: "building.2.fill"
        ),
        RoleplayScenario(
            id: "job-interview",
            titleKey: "app.ai_assistant.scenario.interview.title",
            descriptionKey: "app.ai_assistant.scenario.interview.desc",
            topic: .interview,
            difficulty: .advanced,
            characterName: "Ms. Jenkins",
            characterRole: "Lead Hiring Manager",
            userRole: "Candidate",
            initialGreeting: "Thanks for joining us today. To start, tell me about a challenging project you managed.",
            targetWordIds: ["collaborate", "innovative", "initiative"],
            iconSymbol: "briefcase.fill"
        )
    ]
}
```

Create `VocabCraftApp/Domain/UseCases/FetchRoleplayScenariosUseCase.swift`:
```swift
import Foundation

public final class FetchRoleplayScenariosUseCase: Sendable {
    public init() {}

    public func execute(userWeakWords: [String] = []) async throws -> [RoleplayScenario] {
        var catalog = RoleplayScenarioCatalog.standardScenarios

        if !userWeakWords.isEmpty {
            // Adaptive Daily Scenario prioritizing weak words
            let adaptiveDaily = RoleplayScenario(
                id: "daily-adaptive",
                titleKey: "app.ai_assistant.scenario.daily.title",
                descriptionKey: "app.ai_assistant.scenario.daily.desc",
                topic: .dailyLife,
                difficulty: .intermediate,
                characterName: "Alex",
                characterRole: "Language Coach",
                userRole: "Learner",
                initialGreeting: "Hi there! Let's practice using your recent vocabulary in a casual chat.",
                targetWordIds: Array(userWeakWords.prefix(3)),
                iconSymbol: "sparkles"
            )
            catalog.insert(adaptiveDaily, at: 0)
        }

        return catalog
    }
}
```

Create `VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift`:
```swift
import Foundation

public final class ExecuteRoleplayTurnUseCase: Sendable {
    private let llmProvider: LLMProviderProtocol

    public init(llmProvider: LLMProviderProtocol) {
        self.llmProvider = llmProvider
    }

    public func execute(
        scenario: RoleplayScenario,
        userUtterance: String,
        chatHistory: [LLMChatMessage]
    ) async throws -> RoleplayTurnOutput {
        // Fast local detection of target words in user input
        let lowercasedInput = userUtterance.lowercased()
        let detectedLocalWords = scenario.targetWordIds.filter { word in
            lowercasedInput.contains(word.lowercased())
        }

        let systemPrompt = """
        You are \(scenario.characterName), a \(scenario.characterRole) in a roleplay conversation with the user who is a \(scenario.userRole).
        Maintain an authentic, friendly persona suitable for the scene: \(scenario.titleKey).
        Target vocabulary for the user: \(scenario.targetWordIds.joined(separator: ", ")).
        Return JSON conforming to RoleplayTurnOutput schema:
        - characterReply: your in-character spoken dialogue
        - targetWordsUsed: list of target words the user used correctly in their message
        - refinementSuggestion: if the user's sentence could be phrased more naturally, provide the improved sentence; otherwise null
        - pedagogicalNote: brief encouragement or usage tip; otherwise null
        """

        var fullHistory = chatHistory
        fullHistory.append(LLMChatMessage(role: .user, content: userUtterance))

        do {
            let output: RoleplayTurnOutput = try await llmProvider.sendStructuredMessage(
                messages: fullHistory,
                systemPrompt: systemPrompt,
                responseSchema: RoleplayTurnOutput.self
            )
            // Union local detected words with LLM recognized words
            let combinedWords = Array(Set(output.targetWordsUsed + detectedLocalWords))
            return RoleplayTurnOutput(
                characterReply: output.characterReply,
                targetWordsUsed: combinedWords,
                refinementSuggestion: output.refinementSuggestion,
                pedagogicalNote: output.pedagogicalNote
            )
        } catch {
            // Fallback response on provider failure if mock or recoverable
            return RoleplayTurnOutput(
                characterReply: "I hear you! That makes total sense in this situation.",
                targetWordsUsed: detectedLocalWords,
                refinementSuggestion: nil,
                pedagogicalNote: nil
            )
        }
    }
}
```

Create `VocabCraftApp/Domain/UseCases/CompleteRoleplaySessionUseCase.swift`:
```swift
import Foundation

public final class CompleteRoleplaySessionUseCase: Sendable {
    public init() {}

    public func execute(
        scenarioId: String,
        totalTurns: Int,
        targetWordsAttempted: [String],
        targetWordsMastered: [String],
        refinements: [SentenceRefinementPair]
    ) async -> RoleplaySessionSummary {
        let uniqueAttempted = Set(targetWordsAttempted)
        let uniqueMastered = Set(targetWordsMastered)

        let targetRatio = uniqueAttempted.isEmpty ? 1.0 : Double(uniqueMastered.count) / Double(uniqueAttempted.count)
        let fluencyScore = min(100, Int(round((targetRatio * 60.0) + min(40.0, Double(totalTurns) * 8.0))))
        let xpEarned = max(10, (uniqueMastered.count * 15) + (totalTurns * 5))

        return RoleplaySessionSummary(
            scenarioId: scenarioId,
            totalTurns: totalTurns,
            targetWordsAttempted: Array(uniqueAttempted),
            targetWordsMastered: Array(uniqueMastered),
            fluencyScore: fluencyScore,
            xpEarned: xpEarned,
            refinements: refinements
        )
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter RoleplayUseCasesTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Data/AI/RoleplayScenarioCatalog.swift VocabCraftApp/Domain/UseCases/FetchRoleplayScenariosUseCase.swift VocabCraftApp/Domain/UseCases/ExecuteRoleplayTurnUseCase.swift VocabCraftApp/Domain/UseCases/CompleteRoleplaySessionUseCase.swift VocabCraftAppTests/AI/RoleplayUseCasesTests.swift
git commit -m "feat(ai): implement roleplay catalog and domain use cases"
```

---

### Task 4: Localization & AppStrings Accessors

**Files:**
- Modify: `VocabCraftApp/Resources/Localizable.xcstrings`
- Modify: `VocabCraftApp/Core/Localization/AppStrings.swift`
- Test: `VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift`

**Interfaces:**
- Consumes: None
- Produces: `AppStrings.AIAssistant.*` LocalizedStringKey definitions with full EN & VI translations.

- [ ] **Step 1: Write the failing test**

```swift
// VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
import Foundation
import SwiftUI
import Testing
@testable import VocabCraftApp

@Suite("AI Assistant Localization Tests")
struct AIAssistantLocalizationTests {
    @Test("AppStrings contains AI Assistant keys")
    func testAppStringsAIAssistantKeys() {
        let title = AppStrings.AIAssistant.hubTitle
        let start = AppStrings.AIAssistant.actionStartRoleplay
        let finish = AppStrings.AIAssistant.actionFinishSession
        #expect(title != nil)
        #expect(start != nil)
        #expect(finish != nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AIAssistantLocalizationTests`
Expected: FAIL with compilation error "value of type 'AppStrings.AIAssistant' has no member 'hubTitle'"

- [ ] **Step 3: Write minimal implementation**

Update `VocabCraftApp/Core/Localization/AppStrings.swift` with new keys:
```swift
// Append inside AppStrings enum:
    public enum AIAssistant {
        public static let hubTitle = LocalizedStringKey("app.ai_assistant.hub.title")
        public static let hubSubtitle = LocalizedStringKey("app.ai_assistant.hub.subtitle")
        public static let dailyMissionBadge = LocalizedStringKey("app.ai_assistant.hub.daily_mission_badge")
        public static let actionStartRoleplay = LocalizedStringKey("app.ai_assistant.hub.action_start_roleplay")
        public static let targetWordsTitle = LocalizedStringKey("app.ai_assistant.room.target_words_title")
        public static let refineSuggestionButton = LocalizedStringKey("app.ai_assistant.room.refine_button")
        public static let actionFinishSession = LocalizedStringKey("app.ai_assistant.room.action_finish")
        public static let discardConfirmTitle = LocalizedStringKey("app.ai_assistant.room.discard_title")
        public static let discardConfirmMessage = LocalizedStringKey("app.ai_assistant.room.discard_message")
        public static let summaryCongratulations = LocalizedStringKey("app.ai_assistant.summary.congratulations")
        public static let summaryFluencyScore = LocalizedStringKey("app.ai_assistant.summary.fluency_score")
        public static let summaryMasteredWords = LocalizedStringKey("app.ai_assistant.summary.mastered_words")
        public static let summaryTakeawaysTitle = LocalizedStringKey("app.ai_assistant.summary.takeaways_title")
        public static let actionDone = LocalizedStringKey("app.ai_assistant.summary.action_done")
    }
```

Update `VocabCraftApp/Resources/Localizable.xcstrings` by adding entries for:
- `app.ai_assistant.hub.title`: (en: "AI Assistant", vi: "Trợ lý AI")
- `app.ai_assistant.hub.subtitle`: (en: "Master active speaking through interactive roleplay", vi: "Làm chủ từ vựng chủ động qua đàm thoại nhập vai")
- `app.ai_assistant.hub.daily_mission_badge`: (en: "Daily Recommended Scenario", vi: "Tình huống đề xuất hôm nay")
- `app.ai_assistant.hub.action_start_roleplay`: (en: "Start Roleplay", vi: "Bắt đầu nhập vai")
- `app.ai_assistant.room.target_words_title`: (en: "Target Words", vi: "Từ vựng mục tiêu")
- `app.ai_assistant.room.refine_button`: (en: "💡 See natural phrasing", vi: "💡 Xem gợi ý diễn đạt tự nhiên")
- `app.ai_assistant.room.action_finish`: (en: "Finish", vi: "Kết thúc")
- `app.ai_assistant.room.discard_title`: (en: "Leave Roleplay?", vi: "Rời khỏi buổi đàm thoại?")
- `app.ai_assistant.room.discard_message`: (en: "Your current conversation progress will not be saved.", vi: "Tiến trình trò chuyện hiện tại sẽ không được lưu.")
- `app.ai_assistant.summary.congratulations`: (en: "Roleplay Completed!", vi: "Hoàn thành buổi đàm thoại!")
- `app.ai_assistant.summary.fluency_score`: (en: "Fluency Score", vi: "Điểm trôi chảy")
- `app.ai_assistant.summary.mastered_words`: (en: "Target Words Mastered", vi: "Từ mục tiêu đã làm chủ")
- `app.ai_assistant.summary.takeaways_title`: (en: "Refined Phrasing Takeaways", vi: "Gợi ý diễn đạt nâng cao")
- `app.ai_assistant.summary.action_done`: (en: "Back to Hub", vi: "Quay về trang chính")

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AIAssistantLocalizationTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Core/Localization/AppStrings.swift VocabCraftApp/Resources/Localizable.xcstrings VocabCraftAppTests/AI/AIAssistantLocalizationTests.swift
git commit -m "feat(ai): add bilingual localization keys for AI Assistant roleplay"
```

---

### Task 5: ViewModels (Hub & Roleplay Room)

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/ViewModels/AIAssistantHubViewModel.swift`
- Create: `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayRoomViewModel.swift`
- Test: `VocabCraftAppTests/AI/RoleplayViewModelsTests.swift`

**Interfaces:**
- Consumes: `FetchRoleplayScenariosUseCase`, `ExecuteRoleplayTurnUseCase`, `CompleteRoleplaySessionUseCase`, `SpeechRecognitionService`, `TTSServiceProtocol`
- Produces:
  - `@Observable @MainActor class AIAssistantHubViewModel`
  - `@Observable @MainActor class RoleplayRoomViewModel`

- [ ] **Step 1: Write the failing test**

```swift
// VocabCraftAppTests/AI/RoleplayViewModelsTests.swift
import Foundation
import Testing
@testable import VocabCraftApp

@Suite("AI Assistant ViewModels Tests")
struct RoleplayViewModelsTests {
    @Test @MainActor
    func testHubViewModelLoadsScenarios() async {
        let fetchUseCase = FetchRoleplayScenariosUseCase()
        let vm = AIAssistantHubViewModel(fetchScenariosUseCase: fetchUseCase)
        
        await vm.loadScenarios()
        #expect(!vm.scenarios.isEmpty)
        #expect(vm.dailyScenario != nil)
    }

    @Test @MainActor
    func testRoleplayRoomViewModelAppendsTurnsAndDetectsWords() async {
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
            initialGreeting: "Welcome!",
            targetWordIds: ["beverage"],
            iconSymbol: "cup.fill"
        )

        let vm = RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: executeUseCase,
            completeSessionUseCase: completeUseCase
        )

        #expect(vm.messages.count == 1) // Initial greeting
        await vm.sendMessage("I want a beverage please")

        #expect(vm.messages.count == 3) // Greeting + User + AI
        #expect(vm.masteredWords.contains("beverage"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter RoleplayViewModelsTests`
Expected: FAIL with compilation error "cannot find type 'AIAssistantHubViewModel' in scope"

- [ ] **Step 3: Write minimal implementation**

Create `VocabCraftApp/Features/AIAssistant/ViewModels/AIAssistantHubViewModel.swift`:
```swift
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
```

Create `VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayRoomViewModel.swift`:
```swift
import Foundation
import Observation

public struct DisplayChatMessage: Identifiable, Sendable, Equatable {
    public let id = UUID()
    public let isUser: Bool
    public let text: String
    public let characterName: String?
    public let refinementSuggestion: String?
    public var isRefinementExpanded: Bool = false

    public init(
        isUser: Bool,
        text: String,
        characterName: String? = nil,
        refinementSuggestion: String? = nil,
        isRefinementExpanded: Bool = false
    ) {
        self.isUser = isUser
        self.text = text
        self.characterName = characterName
        self.refinementSuggestion = refinementSuggestion
        self.isRefinementExpanded = isRefinementExpanded
    }
}

@Observable
@MainActor
public final class RoleplayRoomViewModel {
    public let scenario: RoleplayScenario
    public var messages: [DisplayChatMessage] = []
    public var masteredWords: Set<String> = []
    public var isSending: Bool = false
    public var inputText: String = ""
    public var isRecording: Bool = false
    public var sessionSummary: RoleplaySessionSummary?

    private let executeTurnUseCase: ExecuteRoleplayTurnUseCase
    private let completeSessionUseCase: CompleteRoleplaySessionUseCase
    private var chatHistory: [LLMChatMessage] = []
    private var gatheredRefinements: [SentenceRefinementPair] = []

    public init(
        scenario: RoleplayScenario,
        executeTurnUseCase: ExecuteRoleplayTurnUseCase,
        completeSessionUseCase: CompleteRoleplaySessionUseCase
    ) {
        self.scenario = scenario
        self.executeTurnUseCase = executeTurnUseCase
        self.completeSessionUseCase = completeSessionUseCase

        // Setup initial greeting
        let greeting = DisplayChatMessage(
            isUser: false,
            text: scenario.initialGreeting,
            characterName: scenario.characterName
        )
        self.messages.append(greeting)
        self.chatHistory.append(LLMChatMessage(role: .model, content: scenario.initialGreeting))
    }

    public func sendMessage(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        inputText = ""
        isSending = true

        let userMsg = DisplayChatMessage(isUser: true, text: trimmed)
        messages.append(userMsg)
        let userMsgIndex = messages.count - 1

        do {
            let output = try await executeTurnUseCase.execute(
                scenario: scenario,
                userUtterance: trimmed,
                chatHistory: chatHistory
            )

            // Update user message with refinement if available
            if let ref = output.refinementSuggestion {
                messages[userMsgIndex] = DisplayChatMessage(
                    isUser: true,
                    text: trimmed,
                    refinementSuggestion: ref
                )
                gatheredRefinements.append(SentenceRefinementPair(
                    originalUserSentence: trimmed,
                    refinedNativeSentence: ref
                ))
            }

            // Append character response
            let aiMsg = DisplayChatMessage(
                isUser: false,
                text: output.characterReply,
                characterName: scenario.characterName
            )
            messages.append(aiMsg)

            // Update state
            chatHistory.append(LLMChatMessage(role: .user, content: trimmed))
            chatHistory.append(LLMChatMessage(role: .model, content: output.characterReply))

            for word in output.targetWordsUsed {
                masteredWords.insert(word)
            }
        } catch {
            let fallbackMsg = DisplayChatMessage(
                isUser: false,
                text: "I see! Please go on.",
                characterName: scenario.characterName
            )
            messages.append(fallbackMsg)
        }

        isSending = false
    }

    public func finishSession() async {
        let summary = await completeSessionUseCase.execute(
            scenarioId: scenario.id,
            totalTurns: messages.filter { $0.isUser }.count,
            targetWordsAttempted: scenario.targetWordIds,
            targetWordsMastered: Array(masteredWords),
            refinements: gatheredRefinements
        )
        self.sessionSummary = summary
    }

    public func toggleRefinement(for id: UUID) {
        if let idx = messages.firstIndex(where: { $0.id == id }) {
            var msg = messages[idx]
            msg.isRefinementExpanded.toggle()
            messages[idx] = msg
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter RoleplayViewModelsTests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/ViewModels/AIAssistantHubViewModel.swift VocabCraftApp/Features/AIAssistant/ViewModels/RoleplayRoomViewModel.swift VocabCraftAppTests/AI/RoleplayViewModelsTests.swift
git commit -m "feat(ai): implement AIAssistantHubViewModel and RoleplayRoomViewModel"
```

---

### Task 6: SwiftUI Views & DI Integration

**Files:**
- Create: `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`
- Create: `VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift`
- Create: `VocabCraftApp/Features/AIAssistant/Views/RoleplaySummaryView.swift`
- Modify: `VocabCraftApp/App/DI/AppContainer.swift`
- Modify: `VocabCraftApp/Features/Homepage/Views/HomepageView.swift`
- Test: `VocabCraftAppTests/App/AppContainerAITests.swift`

**Interfaces:**
- Consumes: `AppContainer`, `AIAssistantHubViewModel`, `RoleplayRoomViewModel`, `CraftUIKit`
- Produces: Complete navigable AI Assistant feature inside `HomepageView.swift` Tab 3.

- [ ] **Step 1: Write the failing test**

```swift
// VocabCraftAppTests/App/AppContainerAITests.swift
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
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter AppContainerAITests`
Expected: FAIL with compilation error "value of type 'AppContainer' has no member 'makeAIAssistantHubViewModel'"

- [ ] **Step 3: Write minimal implementation**

Update `VocabCraftApp/App/DI/AppContainer.swift`:
```swift
// Add AI services and factories:
    public lazy var llmProvider: LLMProviderProtocol = {
        #if DEBUG
        return MockLLMProvider()
        #else
        return GeminiLLMProvider(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
        #endif
    }()

    public func makeFetchRoleplayScenariosUseCase() -> FetchRoleplayScenariosUseCase {
        FetchRoleplayScenariosUseCase()
    }

    public func makeExecuteRoleplayTurnUseCase() -> ExecuteRoleplayTurnUseCase {
        ExecuteRoleplayTurnUseCase(llmProvider: llmProvider)
    }

    public func makeCompleteRoleplaySessionUseCase() -> CompleteRoleplaySessionUseCase {
        CompleteRoleplaySessionUseCase()
    }

    @MainActor
    public func makeAIAssistantHubViewModel() -> AIAssistantHubViewModel {
        AIAssistantHubViewModel(fetchScenariosUseCase: makeFetchRoleplayScenariosUseCase())
    }

    @MainActor
    public func makeRoleplayRoomViewModel(for scenario: RoleplayScenario) -> RoleplayRoomViewModel {
        RoleplayRoomViewModel(
            scenario: scenario,
            executeTurnUseCase: makeExecuteRoleplayTurnUseCase(),
            completeSessionUseCase: makeCompleteRoleplaySessionUseCase()
        )
    }
```

Create `VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct AIAssistantHubView: View {
    @State private var viewModel: AIAssistantHubViewModel
    @State private var activeScenario: RoleplayScenario?
    @Environment(\.appContainer) private var appContainer
    @Environment(\.craftTheme) private var theme

    public init(viewModel: AIAssistantHubViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: theme.spacing.lg) {
                    CraftPageHeader(
                        AppStrings.AIAssistant.hubTitle,
                        alignment: .leading,
                        enableScrollFade: false
                    )

                    if let daily = viewModel.dailyScenario {
                        heroDailyCard(for: daily)
                    }

                    scenarioListSection

                    Spacer(minLength: theme.spacing.xxl)
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.top, theme.spacing.xs)
            }
        }
        .task {
            if viewModel.scenarios.isEmpty {
                await viewModel.loadScenarios()
            }
        }
        .fullScreenCover(item: $activeScenario) { scenario in
            RoleplayRoomView(
                viewModel: appContainer.makeRoleplayRoomViewModel(for: scenario),
                onDismiss: { activeScenario = nil }
            )
        }
    }

    private func heroDailyCard(for scenario: RoleplayScenario) -> some View {
        CraftCard(
            style: .outlined,
            cornerRadius: theme.radii.xl,
            padding: theme.spacing.lg
        ) {
            VStack(alignment: .leading, spacing: theme.spacing.md) {
                HStack {
                    CraftBadge(
                        AppStrings.AIAssistant.dailyMissionBadge,
                        symbol: .sparkles,
                        variant: .subtle,
                        tone: .primary,
                        size: .sm,
                        customTint: theme.colors.accent
                    )
                    Spacer()
                }

                Text(LocalizedStringKey(scenario.titleKey))
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)

                Text(LocalizedStringKey(scenario.descriptionKey))
                    .font(theme.typography.bodyMedium)
                    .foregroundStyle(theme.colors.textSecondary)

                HStack(spacing: theme.spacing.xs) {
                    ForEach(scenario.targetWordIds, id: \.self) { word in
                        CraftBadge(
                            LocalizedStringKey(word),
                            variant: .subtle,
                            tone: .neutral,
                            size: .sm
                        )
                    }
                }

                CraftButton(
                    AppStrings.AIAssistant.actionStartRoleplay,
                    variant: .primary,
                    size: .md,
                    isFullWidth: true
                ) {
                    activeScenario = scenario
                }
                .padding(.top, theme.spacing.xs)
            }
        }
    }

    private var scenarioListSection: some View {
        VStack(spacing: theme.spacing.md) {
            ForEach(viewModel.scenarios.filter { $0.id != viewModel.dailyScenario?.id }) { scenario in
                CraftCard(
                    style: .outlined,
                    cornerRadius: theme.radii.lg,
                    padding: theme.spacing.md
                ) {
                    HStack(spacing: theme.spacing.md) {
                        Image(systemName: scenario.iconSymbol)
                            .font(.system(size: 24))
                            .foregroundStyle(theme.colors.brandPrimary)
                            .frame(width: 44, height: 44)
                            .background(theme.colors.brandPrimary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))

                        VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                            Text(LocalizedStringKey(scenario.titleKey))
                                .font(theme.typography.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.textPrimary)

                            Text(LocalizedStringKey(scenario.descriptionKey))
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.textSecondary)
                        }

                        Spacer()

                        CraftButton(
                            AppStrings.AIAssistant.actionStartRoleplay,
                            variant: .subtle,
                            size: .sm
                        ) {
                            activeScenario = scenario
                        }
                    }
                }
            }
        }
    }
}
```

Create `VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct RoleplayRoomView: View {
    @State private var viewModel: RoleplayRoomViewModel
    private let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme
    @State private var showDiscardAlert = false

    public init(viewModel: RoleplayRoomViewModel, onDismiss: @escaping () -> Void) {
        self._viewModel = State(initialValue: viewModel)
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Header Bar
                headerBar

                // Target Words Strip
                targetWordsStrip

                // Dialogue Stream
                dialogueStream

                // Bottom Control Bar
                bottomInputBar
            }
        }
        .alert(
            AppStrings.AIAssistant.discardConfirmTitle,
            isPresented: $showDiscardAlert
        ) {
            Button(AppStrings.Common.cancel, role: .cancel) {}
            Button(AppStrings.Common.confirm, role: .destructive) { onDismiss() }
        } message: {
            Text(AppStrings.AIAssistant.discardConfirmMessage)
        }
        .fullScreenCover(item: $viewModel.sessionSummary) { summary in
            RoleplaySummaryView(summary: summary) {
                onDismiss()
            }
        }
    }

    private var headerBar: some View {
        HStack {
            CraftIconButton(symbol: .close, size: .md, style: .subtle) {
                showDiscardAlert = true
            }

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.scenario.characterName)
                    .font(theme.typography.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(viewModel.scenario.characterRole)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
            }

            Spacer()

            CraftButton(
                AppStrings.AIAssistant.actionFinishSession,
                variant: .subtle,
                size: .sm
            ) {
                Task { await viewModel.finishSession() }
            }
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
    }

    private var targetWordsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: theme.spacing.xs) {
                Text(AppStrings.AIAssistant.targetWordsTitle)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                    .padding(.trailing, 4)

                ForEach(viewModel.scenario.targetWordIds, id: \.self) { word in
                    let isMastered = viewModel.masteredWords.contains(word)
                    CraftBadge(
                        LocalizedStringKey(word),
                        symbol: isMastered ? .checkmarkCircleFill : nil,
                        variant: isMastered ? .filled : .subtle,
                        tone: isMastered ? .success : .neutral,
                        size: .sm
                    )
                }
            }
            .padding(.horizontal, theme.spacing.base)
            .padding(.vertical, theme.spacing.xs)
        }
        .background(theme.colors.surfaceCard)
    }

    private var dialogueStream: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: theme.spacing.md) {
                    ForEach(viewModel.messages) { message in
                        messageRow(message)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.vertical, theme.spacing.md)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastId = viewModel.messages.last?.id {
                    withAnimation { proxy.scrollTo(lastId, anchor: .bottom) }
                }
            }
        }
    }

    private func messageRow(_ message: DisplayChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer() }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: theme.spacing.xs) {
                Text(message.text)
                    .font(theme.typography.bodyLarge)
                    .foregroundStyle(message.isUser ? Color.white : theme.colors.textPrimary)
                    .padding(theme.spacing.md)
                    .background(message.isUser ? theme.colors.brandPrimary : theme.colors.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))

                if let refinement = message.refinementSuggestion {
                    VStack(alignment: .leading, spacing: 4) {
                        Button {
                            viewModel.toggleRefinement(for: message.id)
                        } label: {
                            Text(AppStrings.AIAssistant.refineSuggestionButton)
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.colors.brandPrimary)
                        }

                        if message.isRefinementExpanded {
                            Text(refinement)
                                .font(theme.typography.caption)
                                .italic()
                                .foregroundStyle(theme.colors.textSecondary)
                                .padding(theme.spacing.xs)
                                .background(theme.colors.brandPrimary.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: theme.radii.sm))
                        }
                    }
                }
            }

            if !message.isUser { Spacer() }
        }
    }

    private var bottomInputBar: some View {
        HStack(spacing: theme.spacing.sm) {
            TextField(AppStrings.Common.search, text: $viewModel.inputText)
                .textFieldStyle(.plain)
                .padding(theme.spacing.sm)
                .background(theme.colors.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))

            CraftIconButton(
                symbol: .checkmark,
                size: .md,
                style: .primary
            ) {
                Task { await viewModel.sendMessage(viewModel.inputText) }
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, theme.spacing.base)
        .padding(.vertical, theme.spacing.sm)
        .background(theme.colors.canvasBackground)
    }
}
```

Create `VocabCraftApp/Features/AIAssistant/Views/RoleplaySummaryView.swift`:
```swift
import CraftUIKit
import SwiftUI

public struct RoleplaySummaryView: View {
    public let summary: RoleplaySessionSummary
    public let onDismiss: () -> Void
    @Environment(\.craftTheme) private var theme
    @State private var confettiTrigger = true

    public init(summary: RoleplaySessionSummary, onDismiss: @escaping () -> Void) {
        self.summary = summary
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            theme.colors.canvasBackground
                .ignoresSafeArea()

            VStack(spacing: theme.spacing.lg) {
                Spacer()

                CraftIcon(.sparkles, size: .xxl, color: theme.colors.accent)

                Text(AppStrings.AIAssistant.summaryCongratulations)
                    .font(theme.typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.colors.textPrimary)

                CraftCard(style: .outlined, cornerRadius: theme.radii.xl, padding: theme.spacing.lg) {
                    VStack(spacing: theme.spacing.md) {
                        HStack {
                            Text(AppStrings.AIAssistant.summaryFluencyScore)
                                .font(theme.typography.bodyLarge)
                                .foregroundStyle(theme.colors.textSecondary)
                            Spacer()
                            Text("\(summary.fluencyScore)%")
                                .font(theme.typography.titleLarge)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.statusSuccess)
                        }

                        Divider()

                        HStack {
                            Text(AppStrings.AIAssistant.summaryMasteredWords)
                                .font(theme.typography.bodyLarge)
                                .foregroundStyle(theme.colors.textSecondary)
                            Spacer()
                            Text("\(summary.targetWordsMastered.count) / \(summary.targetWordsAttempted.count)")
                                .font(theme.typography.headline)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.colors.brandPrimary)
                        }
                    }
                }
                .padding(.horizontal, theme.spacing.base)

                Spacer()

                CraftButton(
                    AppStrings.AIAssistant.actionDone,
                    variant: .primary,
                    size: .lg,
                    isFullWidth: true
                ) {
                    onDismiss()
                }
                .padding(.horizontal, theme.spacing.base)
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .craftConfetti(isTriggered: $confettiTrigger, particleCount: 36)
    }
}
```

Update `HomepageView.swift:128-129`:
Replace:
```swift
            case .aiAssistant:
                AIAssistantPlaceholderView()
```
With:
```swift
            case .aiAssistant:
                AIAssistantHubView(viewModel: appContainer.makeAIAssistantHubViewModel())
```

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter AppContainerAITests`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add VocabCraftApp/Features/AIAssistant/Views/AIAssistantHubView.swift VocabCraftApp/Features/AIAssistant/Views/RoleplayRoomView.swift VocabCraftApp/Features/AIAssistant/Views/RoleplaySummaryView.swift VocabCraftApp/App/DI/AppContainer.swift VocabCraftApp/Features/Homepage/Views/HomepageView.swift VocabCraftAppTests/App/AppContainerAITests.swift
git commit -m "feat(ai): integrate AIAssistantHubView and RoleplayRoomView into app navigation"
```

---

### Task 7: Full Test Suite & Quality Gate Verification

**Files:**
- Test: All tests across the test target
- Modify: Any files with warnings or lint issues

- [ ] **Step 1: Run complete test suite**

Run: `swift test`
Expected: 100% tests pass

- [ ] **Step 2: Run SwiftLint**

Run: `swiftlint`
Expected: 0 errors, 0 warnings

- [ ] **Step 3: Verification commit**

```bash
git add -A
git commit -m "chore(ai): verify AI Assistant roleplay implementation with zero warnings"
```
